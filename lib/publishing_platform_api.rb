require "addressable"
require "publishing_platform_location"
require "time"
require "publishing_platform_api/publishing_api"

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
end
