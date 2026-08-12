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

  # Find the content_ids for a list of base_paths.
  #
  # @param base_paths [Array]
  # @param exclude_document_types [Array] (optional)
  # @param exclude_unpublishing_types [Array] (optional)
  # @param with_drafts [Boolean] (optional)
  # @return [Hash] a hash, keyed by `base_path` with `content_id` as value
  # @example
  #
  #   publishing_api.lookup_content_ids(base_paths: ['/foo', '/bar'])
  #   # => { "/foo" => "51ac4247-fd92-470a-a207-6b852a97f2db", "/bar" => "261bd281-f16c-48d5-82d2-9544019ad9ca" }
  def lookup_content_ids(base_paths:, exclude_document_types: nil, exclude_unpublishing_types: nil, with_drafts: false)
    options = { base_paths: }
    options[:exclude_document_types] = exclude_document_types if exclude_document_types
    options[:exclude_unpublishing_types] = exclude_unpublishing_types if exclude_unpublishing_types
    options[:with_drafts] = with_drafts if with_drafts
    response = post_json("#{endpoint}/lookup-by-base-path", options)
    response.to_hash
  end

  # Find the content_id for a base_path.
  #
  # Convenience method if you only need to look up one content_id for a
  # base_path. For multiple base_paths, use {PublishingPlatformApi::PublishingApi#lookup_content_ids}.
  #
  # @param base_path [String]
  # @param exclude_document_types [Array] (optional)
  # @param exclude_unpublishing_types [Array] (optional)
  # @param with_drafts [Boolean] (optional)
  #
  # @return [UUID] the `content_id` for the `base_path`
  #
  # @example
  #
  #   publishing_api.lookup_content_id(base_path: '/foo')
  #   # => "51ac4247-fd92-470a-a207-6b852a97f2db"
  def lookup_content_id(base_path:, exclude_document_types: nil, exclude_unpublishing_types: nil, with_drafts: false)
    lookups = lookup_content_ids(
      base_paths: [base_path],
      exclude_document_types:,
      exclude_unpublishing_types:,
      with_drafts:,
    )
    lookups[base_path]
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

  # Get the link set for the given content_id.
  #
  # Given a Content ID, it fetchs the existing link set and their version.
  #
  # @param content_id [String]
  #
  # @return [PublishingPlatformApi::Response] A response containing `links` and `version`.
  #
  # @example
  #
  #   publishing_api.get_links("a-content-id")
  #   # => {
  #     "content_id" => "a-content-id",
  #     "links" => [
  #       "organisation" => "organisation-content-id",
  #       "document_collection" => "document-collection-content-id"
  #     ],
  #     "version" => 17
  #   }
  def get_links(content_id)
    get_json(links_url(content_id))
  end

  # Get expanded links
  #
  # Return the expanded links of the item.
  #
  # @param content_id [UUID]
  # @param with_drafts [Bool] Whether links to draft-only editions are returned, defaulting to `true`.
  # @param generate [Bool] Whether to require publishing-api to generate the expanded links, which may be slow. Defaults to `false`.
  #
  # @example
  #
  #   publishing_api.get_expanded_links("8157589b-65e2-4df6-92ba-2c91d80006c0", with_drafts: false).to_h
  #
  #   #=> {
  #     "generated" => "2017-08-01T10:42:49Z",
  #     "expanded_links" => {
  #       "organisations" => [
  #         {
  #           "content_id" => "21aa83a2-a47f-4189-a252-b02f8c322012",
  #           ... (and more attributes)
  #         }
  #       ]
  #     }
  #   }
  def get_expanded_links(content_id, with_drafts: true, generate: false)
    params = {}
    params[:with_drafts] = "false" unless with_drafts
    params[:generate] = "true" if generate
    query = query_string(params)
    validate_content_id(content_id)
    get_json("#{endpoint}/expanded-links/#{content_id}#{query}")
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

  # Get events for a specific content_id
  #
  # @param content_id [UUID]
  # @param params [Hash]
  #
  #  publishing_api.get_events_for_content_id(
  #     "7ac47b33-c09c-4c1d-a9a7-0cfef99081ac",
  #     { action: "PutContent", from: "2023-01-01T00:00:00Z", to: "2023-01-05T10:00:00Z" }
  #  )
  #
  # @return [PublishingPlatformApi::Response] A response containing a list of events for that content ID
  def get_events_for_content_id(content_id, params = {})
    query = query_string(params)
    get_json("#{endpoint}/content/#{content_id}/events#{query}")
  end

  # FIXME: Add documentation
  def get_linkables(document_type: nil)
    if document_type.nil?
      raise ArgumentError, "Please provide a `document_type`"
    end

    get_json("#{endpoint}/linkables?document_type=#{document_type}")
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
