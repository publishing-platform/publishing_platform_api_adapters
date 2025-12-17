require "addressable"
require "publishing_platform_location"
require "time"
require "publishing_platform_api/asset_manager"
require "publishing_platform_api/content_store"
require "publishing_platform_api/publishing_api"
require "publishing_platform_api/organisations"
require "publishing_platform_api/router"

# @api documented
module PublishingPlatformApi
  # Creates a PublishingPlatformApi::AssetManager adapter
  #
  # This will set a bearer token if a ASSET_MANAGER_BEARER_TOKEN environment
  # variable is set
  #
  # @return [PublishingPlatformApi::AssetManager]
  def self.asset_manager(options = {})
    PublishingPlatformApi::AssetManager.new(
      PublishingPlatformLocation.find("asset-manager"),
      { bearer_token: ENV["ASSET_MANAGER_BEARER_TOKEN"] }.merge(options),
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

  # Creates a PublishingPlatformApi::Organisations adapter for accessing
  # APIs through the origin, where the requests will be handled by
  # Collections frontend.
  #
  # @return [PublishingPlatformApi::Organisations]
  def self.organisations(options = {})
    PublishingPlatformApi::Organisations.new(
      PublishingPlatformLocation.new.website_root,
      options,
    )
  end

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

  # Creates a PublishingPlatformApi::Router adapter for communicating with Router API
  #
  # This will set a bearer token if a ROUTER_API_BEARER_TOKEN environment
  # variable is set
  #
  # @return [PublishingPlatformApi::Router]
  def self.router(options = {})
    PublishingPlatformApi::Router.new(
      PublishingPlatformLocation.find("router-api"),
      { bearer_token: ENV["ROUTER_API_BEARER_TOKEN"] }.merge(options),
    )
  end
end
