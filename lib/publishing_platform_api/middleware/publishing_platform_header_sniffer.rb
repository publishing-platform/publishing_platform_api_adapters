require_relative "../publishing_platform_headers"

module PublishingPlatformApi
  class PublishingPlatformHeaderSniffer
    def initialize(app, header_name)
      @app = app
      @header_name = header_name
    end

    def call(env)
      PublishingPlatformApi::PublishingPlatformHeaders.set_header(readable_name, env[@header_name])
      @app.call(env)
    end

  private

    def readable_name
      @header_name.sub(/^HTTP_/, "").downcase.to_sym
    end
  end
end
