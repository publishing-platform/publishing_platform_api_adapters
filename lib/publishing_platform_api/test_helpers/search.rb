module PublishingPlatformApi
  module TestHelpers
    module Search
      SEARCH_ENDPOINT = PublishingPlatformLocation.find("search-api")

      def stub_any_search
        stub_request(:get, %r{#{SEARCH_ENDPOINT}/search.json})
      end

      def stub_any_search_to_return_no_results
        stub_any_search.to_return(body: { results: [] }.to_json)
      end
    end
  end
end
