require_relative "base"
require_relative "exceptions"

# Adapter for the Publishing API.
#
# @api documented
class PublishingPlatformApi::PublishingApi < PublishingPlatformApi::Base
  class NoLiveVersion < PublishingPlatformApi::BaseError; end

  # Put a content item
  #
  # @param content_id [UUID]
  # @param payload [Hash] A valid content item  
  def put_content(content_id, payload)
    put_json(content_url(content_id), payload)
  end

  # Return a content item
  #
  # Raises exception if the item doesn't exist.
  #
  # @param content_id [UUID]
  # @param params [Hash]
  #
  # @return [PublishingPlatformApi::Response] a content item
  #
  # @raise [HTTPNotFound] when the content item is not found
  def get_content(content_id, params = {})
    get_json(content_url(content_id, params))
  end

  # Publish a content item
  #
  # The publishing-api will "publish" a draft item, so that it will be visible
  # on the public site.
  #
  # @param content_id [UUID]
  # @param options [Hash]
  def publish(content_id, options = {})
    optional_keys = %i[previous_version]

    params = merge_optional_keys({}, options, optional_keys)

    post_json(publish_url(content_id), params)
  end

  # Republish a content item
  #
  # The publishing-api will "republish" a live edition. This can be used to remove an unpublishing or to
  # re-send a published edition downstream
  #
  # @param content_id [UUID]
  # @param options [Hash]
  def republish(content_id, options = {})
    optional_keys = %i[previous_version]

    params = merge_optional_keys({}, options, optional_keys)

    post_json(republish_url(content_id), params)
  end

  # Unpublish a content item
  #
  # The publishing API will "unpublish" a live item, to remove it from the public
  # site, or update an existing unpublishing.
  #
  # @param content_id [UUID]
  # @param type [String] Either 'withdrawal', 'gone' or 'redirect'.
  # @param explanation [String] (optional) Text to show on the page.
  # @param alternative_path [String] (optional) Alternative path to show on the page or redirect to.
  # @param discard_drafts [Boolean] (optional) Whether to discard drafts on that item.  Defaults to false.
  # @param previous_version [Integer] (optional) A lock version number for optimistic locking.
  # @param unpublished_at [Time] (optional) The time the content was withdrawn. Ignored for types other than withdrawn
  # @param redirects [Array] (optional) Required if no alternative_path is given. An array of redirect values, ie: { path:, type:, destination: }
  def unpublish(content_id, type:, explanation: nil, alternative_path: nil, discard_drafts: false, allow_draft: false, previous_version: nil, unpublished_at: nil, redirects: nil)
    params = {
      type:,
    }

    params[:explanation] = explanation if explanation
    params[:alternative_path] = alternative_path if alternative_path
    params[:previous_version] = previous_version if previous_version
    params[:discard_drafts] = discard_drafts if discard_drafts
    params[:allow_draft] = allow_draft if allow_draft
    params[:unpublished_at] = unpublished_at.utc.iso8601 if unpublished_at
    params[:redirects] = redirects if redirects

    post_json(unpublish_url(content_id), params)
  end

  # Discard a draft
  #
  # Deletes the draft content item.
  #
  # @param options [Hash]
  # @option options [Integer] previous_version used to ensure the request is discarding the latest lock version of the draft
  def discard_draft(content_id, options = {})
    optional_keys = %i[previous_version]

    params = merge_optional_keys({}, options, optional_keys)

    post_json(discard_url(content_id), params)
  end

  # Patch the links of a content item
  #
  # @param content_id [UUID]
  # @param params [Hash]
  # @option params [Hash] links A "links hash"
  # @option params [Integer] previous_version The previous version (returned by `get_links`). If this version is not the current version, the publishing-api will reject the change and return 409 Conflict. (optional)  
  # @example
  #
  #   publishing_api.patch_links(
  #     '86963c13-1f57-4005-b119-e7cf3cb92ecf',
  #     links: {
  #       topics: ['d6e1527d-d0c0-40d5-9603-b9f3e6866b8a'],
  #       mainstream_browse_pages: ['d6e1527d-d0c0-40d5-9603-b9f3e6866b8a'],
  #     },
  #     previous_version: 10,
  #     bulk_publishing: true
  #   )
  #
  def patch_links(content_id, params)
    payload = {
      links: params.fetch(:links),
    }

    payload = merge_optional_keys(payload, params, %i[previous_version bulk_publishing])

    patch_json(links_url(content_id), payload)
  end

  # Get a list of content items from the Publishing API.
  #
  # The only required key in the params hash is `document_type`. These will be used to filter down the content items being returned by the API. Other allowed options can be seen from the link below.
  #
  # @param params [Hash] At minimum, this hash has to include the `document_type` of the content items we wish to see. All other optional keys are documented above.
  #
  # @example
  #
  #   publishing_api.get_content_items(
  #     document_type: 'taxon',
  #     q: 'Driving',
  #     page: 1,
  #     per_page: 50,
  #     publishing_app: 'content-tagger',
  #     fields: ['title', 'description', 'public_updated_at'],
  #     order: '-public_updated_at'
  #   )
  def get_content_items(params)
    query = query_string(params)
    get_json("#{endpoint}/content#{query}")
  end

  # Reserves a path for a publishing application
  #
  # Returns success or failure only.
  #
  # @param payload [Hash]
  # @option payload [Hash] publishing_app The publishing application, like `content-tagger`
  def put_path(base_path, payload)
    url = "#{endpoint}/paths#{base_path}"
    put_json(url, payload)
  end

  def unreserve_path(base_path, publishing_app)
    payload = { publishing_app: }
    delete_json(unreserve_url(base_path), payload)
  end

private

  def content_url(content_id, params = {})
    validate_content_id(content_id)
    query = query_string(params)
    "#{endpoint}/content/#{content_id}#{query}"
  end

  def links_url(content_id)
    validate_content_id(content_id)
    "#{endpoint}/links/#{content_id}"
  end

  def publish_url(content_id)
    validate_content_id(content_id)
    "#{endpoint}/content/#{content_id}/publish"
  end

  def republish_url(content_id)
    validate_content_id(content_id)
    "#{endpoint}/content/#{content_id}/republish"
  end

  def unpublish_url(content_id)
    validate_content_id(content_id)
    "#{endpoint}/content/#{content_id}/unpublish"
  end

  def discard_url(content_id)
    validate_content_id(content_id)
    "#{endpoint}/content/#{content_id}/discard-draft"
  end

  def unreserve_url(base_path)
    "#{endpoint}/paths#{base_path}"
  end

  def merge_optional_keys(params, options, optional_keys)
    optional_keys.each_with_object(params) do |optional_key, hash|
      hash.merge!(optional_key => options[optional_key]) if options[optional_key]
    end
  end

  def validate_content_id(content_id)
    raise ArgumentError, "content_id cannot be nil" unless content_id
  end
end