module NightcrawlerSwift
  class Delete < Command

    def execute path
      response = delete "#{connection.upload_url}/#{path}", headers: {accept: :json }
      JSON.parse(response.body)

    rescue RestClient::ResourceNotFound => e
      raise Exceptions::NotFoundError.new(e)

    rescue StandardError => e
      raise Exceptions::ConnectionError.new(e)
    end

  end
end
