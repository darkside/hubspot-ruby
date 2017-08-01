module Hubspot
  class Connection
    include HTTParty
    HEADERS = { 'Content-Type' => 'application/json' }
    NETWORK_ERRORS = [ServerError, BadGateway]

    delegate :logger, :sleep_on_network_errors?, :retry_on_network_errors?, to: Config

    attr_accessor :retries

    def initialize
      self.retries = 0
    end

    def get_json(path, params: {})
      retrying_network_errors do
        url = generate_url(path, params)
        response = self.class.get(url, format: :json)
        handle_response(response)
      end
    end


    def post_json(path, params: {}, body:)
      retrying_network_errors do
        url = generate_url(path, params)
        response = self.class.post(url, body: body.to_json, headers: HEADERS, format: :json)
        handle_response(response)
      end
    end

    def put_json(path, params: {}, body:)
      retrying_network_errors do
        url = generate_url(path, params)
        response = self.class.put(url, body: body.to_json, headers: HEADERS, format: :json)
        handle_response(response)
      end
    end

    def delete_json(path, params: {})
      retrying_network_errors do
        url = generate_url(path, params)
        response = self.class.delete(url, format: :json)
        handle_response(response)
      end
    end

    private

    def param_string(key,value)
      if (key =~ /range/)
        raise "Value must be a range" unless value.is_a?(Range)
        "#{key}=#{converted_value(value.begin)}&#{key}=#{converted_value(value.end)}"
      else
        "#{key}=#{converted_value(value)}"
      end
    end

    def converted_value(value)
      if (value.is_a?(Time))
        (value.to_i * 1000) # convert into milliseconds since epoch
      else
        value
      end
    end

    def retrying_network_errors
      yield
    rescue *NETWORK_ERRORS => e
      if retry_on_network_errors? && self.retries < 3
        self.retries += 1
        logger.warn "Network error caught: #{e.inspect}"
        logger.warn "Sleeping and retrying..."
        sleep self.retries if sleep_on_network_errors?
        retry
      else
        self.retries = 0 # reset retries
        fail e
      end
    end

    def handle_response(response)
      log_request_and_response response
      raise BadGateway.new(response)        if response.code == 502
      raise ServerError.new(response)       if response.code >= 500
      raise DuplicateResource.new(response) if response.code == 409
      raise ResourceNotFound.new(response)  if response.code == 404
      raise RequestError.new(response)  unless response.success?
      self.retries = 0 # reset retries if we had a success
      response.parsed_response
    end

    def log_request_and_response(response, body=nil)
      uri = response.request.path.to_s
      logger.debug { "Hubspot: #{uri}.\nBody: #{body}.\nResponse: #{response.code} #{response.body}" }
    end

    # Generate the API URL for the request
    #
    # @param path [String] The path of the request with leading "/". Parts starting with a ":" will be interpolated
    # @param params [Hash] params to be included in the query string or interpolated into the url.
    #
    # @return [String]
    #
    def generate_url(path, params={}, options={})
      Config.ensure! :hapikey
      path = path.clone
      params = params.clone
      base_url = options[:base_url] || Config.base_url
      params["hapikey"] = Config.hapikey unless options[:hapikey] == false

      if path =~ /:portal_id/
        Config.ensure! :portal_id
        params["portal_id"] = Config.portal_id if path =~ /:portal_id/
      end

      params.each do |k,v|
        if path.match(":#{k}")
          path.gsub!(":#{k}",v.to_s)
          params.delete(k)
        end
      end
      raise MissingInterpolation.new("Interpolation not resolved") if path =~ /:/
      query = params.map{ |k,v| param_string(k,v) }.join("&")
      path += "?" if query.present?
      base_url + path + query
    end

  end
end
