module Hubspot
  class Config
    class << self
      attr_reader :hapikey
      attr_reader :base_url
      attr_reader :portal_id

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def configure(config)
        config.stringify_keys!
        @hapikey = config["hapikey"]
        @sleep_on_network_errors = config["sleep_on_network_errors"] || false
        @retry_on_network_errors = config["retry_on_network_errors"] || true
        @base_url = config["base_url"] || "https://api.hubapi.com"
        @portal_id = config["portal_id"]
        self
      end

      # Do we sleep when retrying on network errors? Good for background jobs,
      # bad for web heads
      def sleep_on_network_errors?
        !! @sleep_on_network_errors
      end

      def retry_on_network_errors?
        !! @retry_on_network_errors
      end

      def reset!
        @hapikey = nil
        @base_url = "https://api.hubapi.com"
        @portal_id = nil
      end

      def ensure!(*params)
        params.each do |p|
          raise ConfigurationError.new("'#{p}' not configured") unless instance_variable_get "@#{p}"
        end
      end
    end

    reset!
  end
end
