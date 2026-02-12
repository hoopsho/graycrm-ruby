# frozen_string_literal: true

module GrayCRM
  class Error < StandardError
    attr_reader :status, :code, :details

    def initialize(message = nil, status: nil, code: nil, details: nil)
      @status = status
      @code = code
      @details = details
      super(message)
    end

    def self.from_response(status, body)
      error_data = body.is_a?(Hash) ? body["error"] || body : {}
      message = error_data["message"] || "HTTP #{status}"
      code = error_data["code"]
      details = error_data["details"]

      klass = case status
      when 401 then AuthenticationError
      when 403 then ForbiddenError
      when 404 then NotFoundError
      when 409 then ConflictError
      when 422 then ValidationError
      when 429 then RateLimitError
      when 500..599 then ServerError
      else Error
      end

      klass.new(message, status: status, code: code, details: details)
    end
  end

  class AuthenticationError < Error; end
  class ForbiddenError < Error; end
  class NotFoundError < Error; end
  class ConflictError < Error; end
  class ServerError < Error; end

  class ValidationError < Error
    def validation_errors
      details || {}
    end
  end

  class RateLimitError < Error
    attr_reader :retry_after

    def initialize(message = nil, status: nil, code: nil, details: nil, retry_after: nil)
      @retry_after = retry_after
      super(message, status: status, code: code, details: details)
    end
  end
end
