module PublishingPlatformApi
  # Abstract error class
  class BaseError < StandardError
    # Give Sentry extra context about this event
    # https://docs.sentry.io/clients/ruby/context/
    def sentry_context
      {
        # Make Sentry group exceptions by type instead of message, so all
        # exceptions like `PublishingPlatformApi::TimedOutException` will get grouped as one
        # error and not an error per URL.
        fingerprint: [self.class.name],
      }
    end
  end

  class EndpointNotFound < BaseError; end

  class TimedOutException < BaseError; end

  class InvalidUrl < BaseError; end

  class SocketErrorException < BaseError; end

  # Superclass for all 4XX and 5XX errors
  class HTTPErrorResponse < BaseError
    attr_accessor :code, :error_details, :http_body

    def initialize(code, message = nil, error_details = nil, http_body = nil)
      super(message)
      @code = code
      @error_details = error_details
      @http_body = http_body
    end
  end

  # Superclass & fallback for all 4XX errors
  class HTTPClientError < HTTPErrorResponse; end

  class HTTPIntermittentClientError < HTTPClientError; end

  class HTTPNotFound < HTTPClientError; end

  class HTTPGone < HTTPClientError; end

  class HTTPPayloadTooLarge < HTTPClientError; end

  class HTTPUnauthorized < HTTPClientError; end

  class HTTPForbidden < HTTPClientError; end

  class HTTPConflict < HTTPClientError; end

  class HTTPUnprocessableEntity < HTTPClientError; end

  class HTTPBadRequest < HTTPClientError; end

  class HTTPTooManyRequests < HTTPIntermittentClientError; end

  # Superclass & fallback for all 5XX errors
  class HTTPServerError < HTTPErrorResponse; end

  class HTTPIntermittentServerError < HTTPServerError; end

  class HTTPInternalServerError < HTTPServerError; end

  class HTTPBadGateway < HTTPIntermittentServerError; end

  class HTTPUnavailable < HTTPIntermittentServerError; end

  class HTTPGatewayTimeout < HTTPIntermittentServerError; end

  module ExceptionHandling
    def build_specific_http_error(error, url, details = nil)
      message = "URL: #{url}\nResponse body:\n#{error.http_body}"
      code = error.http_code
      error_class_for_code(code).new(code, message, details, error.http_body)
    end

    def error_class_for_code(code)
      case code
      when 400
        PublishingPlatformApi::HTTPBadRequest
      when 401
        PublishingPlatformApi::HTTPUnauthorized
      when 403
        PublishingPlatformApi::HTTPForbidden
      when 404
        PublishingPlatformApi::HTTPNotFound
      when 409
        PublishingPlatformApi::HTTPConflict
      when 410
        PublishingPlatformApi::HTTPGone
      when 413
        PublishingPlatformApi::HTTPPayloadTooLarge
      when 422
        PublishingPlatformApi::HTTPUnprocessableEntity
      when 429
        PublishingPlatformApi::HTTPTooManyRequests
      when (400..499)
        PublishingPlatformApi::HTTPClientError
      when 500
        PublishingPlatformApi::HTTPInternalServerError
      when 502
        PublishingPlatformApi::HTTPBadGateway
      when 503
        PublishingPlatformApi::HTTPUnavailable
      when 504
        PublishingPlatformApi::HTTPGatewayTimeout
      when (500..599)
        PublishingPlatformApi::HTTPServerError
      else
        PublishingPlatformApi::HTTPErrorResponse
      end
    end
  end
end
