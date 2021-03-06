require "spec_helper"

describe NightcrawlerSwift::Connection do

  let :opts do
    {
      bucket: "my-bucket-name",
      tenant_name: "tenant_username1",
      username: "username1",
      password: "some-pass",
      auth_url: "https://auth.url.com:123/v2.0/tokens"
    }
  end

  let :unauthorized_error do
    response = OpenStruct.new(body: "error", code: 401)
    RestClient::Unauthorized.new response, response.code
  end

  subject do
    NightcrawlerSwift::Connection.new opts
  end

  before do
    NightcrawlerSwift.logger = Logger.new(StringIO.new)
  end

  describe "initialization" do
    it "creates the opts struct with the given values" do
      expect(subject.opts).to_not be_nil
      opts.keys.each do |key|
        expect(subject.opts.send(key)).to eql(opts[key])
      end
    end
  end

  describe "#connect!" do
    let :auth_json do
      {
        auth: {
          tenantName: opts[:tenant_name],
          passwordCredentials: {username: opts[:username], password: opts[:password]}
        }
      }.to_json
    end

    let :auth_success_response do
      path = File.join(File.dirname(__FILE__), "../..", "fixtures/auth_success.json")
      OpenStruct.new(body: File.read(File.expand_path(path)))
    end

    let :auth_success_json do
      JSON.parse(auth_success_response.body)
    end

    describe "when it connects" do
      before do
        allow(RestClient).to receive(:post).
          with(opts[:auth_url], auth_json, content_type: :json, accept: :json).
          and_return(auth_success_response)
      end

      it "stores the token id" do
        subject.connect!
        expect(subject.token_id).to eql(auth_success_json["access"]["token"]["id"])
      end

      it "stores the expires_at" do
        subject.connect!
        expires_at = DateTime.parse(auth_success_json["access"]["token"]["expires"]).to_time
        expect(subject.expires_at).to eql(expires_at)
      end

      it "stores the admin_url" do
        subject.connect!
        expect(subject.admin_url).to eql(auth_success_json["access"]["serviceCatalog"].first["endpoints"].first["adminURL"])
      end

      it "stores the upload_url" do
        subject.connect!
        expect(subject.upload_url).to eql("#{subject.admin_url}/#{opts[:bucket]}")
      end

      it "stores the public_url" do
        subject.connect!
        expect(subject.public_url).to eql(auth_success_json["access"]["serviceCatalog"].first["endpoints"].first["publicURL"])
      end

      it "returns self" do
        expect(subject.connect!).to eql(subject)
      end
    end

    describe "when some error happens" do
      before do
        allow(RestClient).to receive(:post).
          with(opts[:auth_url], auth_json, content_type: :json, accept: :json).
          and_raise(unauthorized_error)
      end

      it "raises NightcrawlerSwift::Exceptions::ConnectionError" do
        expect { subject.connect! }.to raise_error(NightcrawlerSwift::Exceptions::ConnectionError)
      end
    end
  end

  describe "#connected?" do
    it "checks if token_id exists and is still valid" do
      expect(subject.token_id).to be_nil
      expect(subject.connected?).to be false

      expires_at = DateTime.now.to_time + 11
      allow(subject).to receive(:expires_at).and_return(expires_at)
      allow(subject).to receive(:token_id).and_return("token")
      expect(subject.connected?).to be true
    end
  end

end
