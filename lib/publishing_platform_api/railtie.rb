require_relative "middleware/publishing_platform_header_sniffer"

module PublishingPlatformApi
  class Railtie < Rails::Railtie
    initializer "publishing_platform_api.initialize_publishing_platform_request_id_sniffer" do |app|
      Rails.logger.debug "Using middleware PublishingPlatformApi::PublishingPlatformHeaderSniffer to sniff for PublishingPlatform-Request-Id header"
      app.middleware.use PublishingPlatformApi::PublishingPlatformHeaderSniffer, "HTTP_PUBLISHING_PLATFORM_REQUEST_ID"
    end

    initializer "publishing_platform_api.initialize_publishing_platform_original_url_sniffer" do |app|
      Rails.logger.debug "Using middleware PublishingPlatformApi::PublishingPlatformHeaderSniffer to sniff for PublishingPlatform-Original-Url header"
      app.middleware.use PublishingPlatformApi::PublishingPlatformHeaderSniffer, "HTTP_PUBLISHING_PLATFORM_ORIGINAL_URL"
    end

    initializer "publishing_platform_api.initialize_publishing_platform_authenticated_user_sniffer" do |app|
      Rails.logger.debug "Using middleware PublishingPlatformApi::PublishingPlatformHeaderSniffer to sniff for X-PublishingPlatform-Authenticated-User header"
      app.middleware.use PublishingPlatformApi::PublishingPlatformHeaderSniffer, "HTTP_X_PUBLISHING_PLATFORM_AUTHENTICATED_USER"
    end

    initializer "publishing_platform_api.initialize_publishing_platform_authenticated_user_organisation_sniffer" do |app|
      Rails.logger.debug "Using middleware PublishingPlatformApi::PublishingPlatformHeaderSniffer to sniff for X-PublishingPlatform-Authenticated-User-Organisation header"
      app.middleware.use PublishingPlatformApi::PublishingPlatformHeaderSniffer, "HTTP_X_PUBLISHING_PLATFORM_AUTHENTICATED_USER_ORGANISATION"
    end

    initializer "publishing_platform_api.initialize_publishing_platform_content_id_sniffer" do |app|
      Rails.logger.debug "Using middleware PublishingPlatformApi::PublishingPlatformHeaderSniffer to sniff for PublishingPlatform-Auth-Bypass-Id header"
      app.middleware.use PublishingPlatformApi::PublishingPlatformHeaderSniffer, "HTTP_PUBLISHING_PLATFORM_AUTH_BYPASS_ID"
    end
  end
end
