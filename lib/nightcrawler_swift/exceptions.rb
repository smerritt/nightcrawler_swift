module NightcrawlerSwift
  module Exceptions

    class BaseError < StandardError
      attr_accessor :original_exception

      def initialize exception
        super(exception.message)
        @original_exception = exception
      end
    end

    class ConnectionError < BaseError; end
    class NotFoundError < BaseError; end

  end
end
