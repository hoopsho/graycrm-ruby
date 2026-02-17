# frozen_string_literal: true

require_relative "graycrm/version"
require_relative "graycrm/configuration"
require_relative "graycrm/error"
require_relative "graycrm/client"
require_relative "graycrm/collection"
require_relative "graycrm/resource"
require_relative "graycrm/relation"
require_relative "graycrm/resources/contact"
require_relative "graycrm/resources/property"
require_relative "graycrm/resources/tag"
require_relative "graycrm/resources/flag"
require_relative "graycrm/resources/note"
require_relative "graycrm/resources/activity"
require_relative "graycrm/resources/custom_attribute"
require_relative "graycrm/resources/contact_email"
require_relative "graycrm/resources/contact_phone"
require_relative "graycrm/resources/contact_property"
require_relative "graycrm/resources/audit_event"
require_relative "graycrm/resources/webhook"
require_relative "graycrm/resources/export"
require_relative "graycrm/resources/batch"
require_relative "graycrm/resources/search"
require_relative "graycrm/resources/stats"

module GrayCRM
  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def client
      thread_config = Thread.current[:graycrm_config]
      config = thread_config || configuration
      config.validate!
      Client.new(config)
    end

    # Thread-safe per-request configuration for multi-tenant apps
    def with_config(api_key: nil, host: nil, **overrides)
      config = Configuration.new
      config.host = host || configuration.host
      config.api_key = api_key || configuration.api_key
      config.timeout = overrides[:timeout] || configuration.timeout
      config.open_timeout = overrides[:open_timeout] || configuration.open_timeout
      config.logger = overrides.key?(:logger) ? overrides[:logger] : configuration.logger
      config.per_page = overrides[:per_page] || configuration.per_page
      config.max_retries = overrides[:max_retries] || configuration.max_retries

      Thread.current[:graycrm_config] = config
      yield
    ensure
      Thread.current[:graycrm_config] = nil
    end

    def reset!
      @configuration = Configuration.new
      Thread.current[:graycrm_config] = nil
      Thread.current[:graycrm_http_cache] = nil
    end
  end
end
