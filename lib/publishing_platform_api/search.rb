require_relative "base"
require "rack/utils"

module PublishingPlatformApi
  # @api documented
  class Search < Base
    # Perform a search.
    #
    # @param args [Hash] A valid search query. See search-api documentation for options.
    def search(args, additional_headers = {})
      request_url = "#{endpoint}/search.json?#{Rack::Utils.build_nested_query(args)}"
      get_json(request_url, additional_headers)
    end
  end
end
