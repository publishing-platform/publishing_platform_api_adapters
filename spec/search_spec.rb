RSpec.describe PublishingPlatformApi::Search do
  describe "#search" do
    before(:each) do
      stub_request(:get, /example.com\/search/).to_return(body: "[]")
    end

    it "should raise an exception if the service at the search URI returns a 500" do
      stub_request(:get, /example.com\/search.json/).to_return(status: [500, "Internal Server Error"])
      expect {
        PublishingPlatformApi::Search.new("http://example.com").search(q: "query")
      }.to raise_error(PublishingPlatformApi::HTTPServerError)
    end

    it "should raise an exception if the service at the search URI returns a 404" do
      stub_request(:get, /example.com\/search/).to_return(status: [404, "Not Found"])
      expect {
        PublishingPlatformApi::Search.new("http://example.com").search(q: "query")
      }.to raise_error(PublishingPlatformApi::HTTPNotFound)
    end

    it "should raise an exception if the service at the search URI returns a 400" do
      stub_request(:get, /example.com\/search/).to_return(
        status: [400, "Bad Request"],
        body: '"error":"Filtering by \"coffee\" is not allowed"',
      )
      expect {
        PublishingPlatformApi::Search.new("http://example.com").search(q: "query", filter_coffee: "tea")
      }.to raise_error(PublishingPlatformApi::HTTPClientError)
    end

    it "should raise an exception if the service at the search URI returns a 422" do
      stub_request(:get, /example.com\/search/).to_return(
        status: [422, "Bad Request"],
        body: '"error":"Filtering by \"coffee\" is not allowed"',
      )
      expect {
        PublishingPlatformApi::Search.new("http://example.com").search(q: "query", filter_coffee: "tea")
      }.to raise_error(PublishingPlatformApi::HTTPUnprocessableEntity)
    end

    it "should raise an exception if the service at the search URI times out" do
      stub_request(:get, /example.com\/search/).to_timeout
      expect {
        PublishingPlatformApi::Search.new("http://example.com").search(q: "query")
      }.to raise_error(PublishingPlatformApi::TimedOutException)
    end

    it "should return the search deserialized from json" do
      search_results = [{ "title" => "document-title" }]
      stub_request(:get, /example.com\/search/).to_return(body: search_results.to_json)
      results = PublishingPlatformApi::Search.new("http://example.com").search(q: "query")

      expect(search_results).to eql results.to_hash
    end

    it "should request the search results in JSON format" do
      PublishingPlatformApi::Search.new("http://example.com").search(q: "query")

      assert_requested :get, /.*/, headers: { "Accept" => "application/json" }
    end

    it "should issue a request for all the params supplied" do
      PublishingPlatformApi::Search.new("http://example.com").search(
        q: "query & stuff",
        filter_document_type: %w[1 2],
        order: "-public_timestamp",
      )

      assert_requested :get, /q=query%20%26%20stuff/
      assert_requested :get, /filter_document_type\[\]=1&filter_document_type\[\]=2/
      assert_requested :get, /order=-public_timestamp/
    end

    it "can pass additional headers" do
      PublishingPlatformApi::Search.new("http://example.com").search({ q: "query" }, "authorization" => "token")

      assert_requested :get, /.*/, headers: { "authorization" => "token" }
    end
  end
end
