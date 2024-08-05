require "addressable"
require "publishing_platform_location"
require "time"
require "publishing_platform_api/publishing_api"
require "publishing_platform_api/content_store"

# @api documented
module PublishingPlatformApi
  # Creates a PublishingPlatformApi::PublishingApi adapter
  #
  # This will set a bearer token if a PUBLISHING_API_BEARER_TOKEN environment
  # variable is set
  #
  # @return [PublishingPlatformApi::PublishingApi]
  def self.publishing_api(options = {})
    PublishingPlatformApi::PublishingApi.new(
      PublishingPlatformLocation.find("publishing-api"),
      { bearer_token: ENV["PUBLISHING_API_BEARER_TOKEN"] }.merge(options),
    )
  end

  # Creates a PublishingPlatformApi::ContentStore adapter
  #
  # This will set a bearer token if a CONTENT_STORE_BEARER_TOKEN environment
  # variable is set
  #
  # @return [PublishingPlatformApi::ContentStore]
  def self.content_store(options = {})
    PublishingPlatformApi::ContentStore.new(
      PublishingPlatformLocation.find("content-store"),
      { bearer_token: ENV["CONTENT_STORE_BEARER_TOKEN"] }.merge(options),
    )
  end
end
