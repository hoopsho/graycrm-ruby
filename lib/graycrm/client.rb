# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module GrayCRM
  class Client
    def initialize(config)
      @config = config
    end

    def get(path, params: {}, headers: {})
      uri = build_uri(path, params)
      request = Net::HTTP::Get.new(uri)
      execute(uri, request, headers)
    end

    def post(path, body: nil, headers: {})
      uri = build_uri(path)
      request = Net::HTTP::Post.new(uri)
      request.body = body.to_json if body
      execute(uri, request, headers)
    end

    def patch(path, body: nil, headers: {})
      uri = build_uri(path)
      request = Net::HTTP::Patch.new(uri)
      request.body = body.to_json if body
      execute(uri, request, headers)
    end

    def delete(path, headers: {})
      uri = build_uri(path)
      request = Net::HTTP::Delete.new(uri)
      execute(uri, request, headers)
    end

    private

    def build_uri(path, params = {})
      url = "#{@config.base_url}#{path}"
      uri = URI.parse(url)
      if params.any?
        query = URI.encode_www_form(flatten_params(params))
        uri.query = uri.query ? "#{uri.query}&#{query}" : query
      end
      uri
    end

    def flatten_params(params, prefix = nil)
      params.each_with_object([]) do |(key, value), result|
        full_key = prefix ? "#{prefix}[#{key}]" : key.to_s
        if value.is_a?(Hash)
          result.concat(flatten_params(value, full_key))
        elsif value.is_a?(Array)
          value.each { |v| result << ["#{full_key}[]", v.to_s] }
        else
          result << [full_key, value.to_s]
        end
      end
    end

    def execute(uri, request, extra_headers)
      set_headers(request, extra_headers)
      log_request(request)

      retries = 0

      begin
        http = build_http(uri)
        response = http.request(request)

        log_response(response)
        handle_response(response)
      rescue RateLimitError => e
        if retries < @config.max_retries
          retries += 1
          sleep_seconds = e.retry_after || 1
          sleep(sleep_seconds)
          retry
        end
        raise
      end
    end

    def build_http(uri)
      key = "#{uri.host}:#{uri.port}:#{@config.timeout}:#{@config.open_timeout}"
      cache = Thread.current[:graycrm_http_cache] ||= {}
      http = cache[key]

      unless http
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = @config.timeout
        http.open_timeout = @config.open_timeout
        http.keep_alive_timeout = 30
        cache[key] = http
      end

      http
    end

    def set_headers(request, extra_headers)
      request["Authorization"] = "Bearer #{@config.api_key}"
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request["User-Agent"] = "graycrm-ruby/#{GrayCRM::VERSION}"
      extra_headers.each { |k, v| request[k] = v }
    end

    def handle_response(response)
      body = parse_body(response)

      case response
      when Net::HTTPSuccess
        body
      when Net::HTTPTooManyRequests
        retry_after = response["Retry-After"]&.to_i
        error = RateLimitError.from_response(response.code.to_i, body)
        error.instance_variable_set(:@retry_after, retry_after)
        raise error
      else
        raise Error.from_response(response.code.to_i, body)
      end
    end

    def parse_body(response)
      return nil if response.body.nil? || response.body.empty?

      JSON.parse(response.body)
    rescue JSON::ParserError
      { "raw" => response.body }
    end

    def log_request(request)
      return unless @config.logger

      @config.logger.debug("[GrayCRM] #{request.method} #{request.path}")
    end

    def log_response(response)
      return unless @config.logger

      @config.logger.debug("[GrayCRM] #{response.code} #{response.message} (#{response.body&.bytesize || 0} bytes)")
    end
  end
end
