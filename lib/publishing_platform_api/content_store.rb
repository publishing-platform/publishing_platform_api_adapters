require "publishing_platform_location"

require_relative "base"
require_relative "exceptions"

class PublishingPlatformApi::ContentStore < PublishingPlatformApi::Base
  class ItemNotFound < PublishingPlatformApi::HTTPNotFound
    def self.build_from(http_error)
      new(http_error.code, http_error.message, http_error.error_details)
    end
  end

  def content_item(base_path)
    get_json(content_item_url(base_path))
  rescue PublishingPlatformApi::HTTPNotFound => e
    raise ItemNotFound.build_from(e)
  end

private

  def content_item_url(base_path)
    "#{endpoint}/content#{base_path}"
  end
end
