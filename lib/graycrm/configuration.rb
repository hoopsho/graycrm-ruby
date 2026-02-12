# frozen_string_literal: true

module GrayCRM
  class Configuration
    attr_accessor :host, :api_key, :timeout, :open_timeout, :logger, :per_page

    def initialize
      @host = nil
      @api_key = nil
      @timeout = 30
      @open_timeout = 10
      @logger = nil
      @per_page = 25
    end

    def base_url
      "https://#{host}/api/v1"
    end

    def validate!
      raise ConfigurationError, "host is required" if host.nil? || host.empty?
      raise ConfigurationError, "api_key is required" if api_key.nil? || api_key.empty?
    end
  end

  class ConfigurationError < StandardError; end
end
