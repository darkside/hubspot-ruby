module Hubspot
  class RequestError < StandardError
    attr_accessor :response

    def initialize(response, message=nil)
      message += "\n" if message
      me = super("#{message}Response body: #{response.body}",)
      me.response = response
      return me
    end
  end

  class ConfigurationError < StandardError; end
  class MissingInterpolation < StandardError; end
  class ContactExistsError < RequestError; end
  class PropertyExistsError < RequestError; end
  class ServerError < RequestError; end
  class BadGateway  < RequestError; end
end
