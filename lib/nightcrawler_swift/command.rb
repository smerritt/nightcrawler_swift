module NightcrawlerSwift
  class Command

    def connection
      NightcrawlerSwift.connection
    end

    def execute
      raise NotImplemented.new
    end

    protected

    def get url, params = {}
      prepare_params params
      resource = resource_for url
      resource.get(params[:headers])
    end

    def put url, params = {}
      prepare_params params
      resource = resource_for url
      resource.put(params[:body], params[:headers])
    end

    def delete url, params
      prepare_params params
      resource = resource_for url
      resource.delete(params[:headers])
    end

    private

    def resource_for url
      RestClient::Resource.new url, verify_ssl: false
    end

    def prepare_params params
      params[:headers] ||= {}
      params[:headers]["X-Storage-Token"] = connection.token_id
    end
  end
end
