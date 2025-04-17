require "publishing_platform_api/test_helpers/content_store"

RSpec.describe PublishingPlatformApi::ContentStore do
  include PublishingPlatformApi::TestHelpers::ContentStore

  before do
    @base_api_url = PublishingPlatformLocation.find("content-store")
    @api = PublishingPlatformApi::ContentStore.new(@base_api_url)
  end

  describe "#content_item" do
    it "returns the item" do
      base_path = "/test-from-content-store"
      stub_content_store_has_item(base_path)

      response = @api.content_item(base_path)

      expect(response["base_path"]).to eql base_path
    end

    it "raises if the item doesn't exist" do
      stub_content_store_does_not_have_item("/non-existent")

      expect {
        @api.content_item("/non-existent")
      }.to raise_error(PublishingPlatformApi::HTTPNotFound)
    end

    it "raises if the item is gone" do
      stub_content_store_has_gone_item("/it-is-gone")

      expect {
        @api.content_item("/it-is-gone")
      }.to raise_error(PublishingPlatformApi::HTTPGone)
    end
  end

  describe ".redirect_for_path" do
    before do
      @content_item = content_item_for_base_path("/test").merge("redirects" => [])
    end

    def create_redirect(
      path:,
      destination: "/destination",
      type: "exact",
      segments_mode: "ignore"
    )
      {
        "path" => path,
        "destination" => destination,
        "type" => type,
        "segments_mode" => segments_mode,
      }
    end

    it "raises when there are no redirects on the content item" do
      @content_item["redirects"] = []

      expect {
        PublishingPlatformApi::ContentStore.redirect_for_path(@content_item, "/test")
      }.to raise_error(PublishingPlatformApi::ContentStore::UnresolvedRedirect)
    end

    it "raises when no redirects match the request path" do
      @content_item["redirects"] = [
        create_redirect(path: "/not-going-to-match"),
      ]

      expect {
        PublishingPlatformApi::ContentStore.redirect_for_path(@content_item, "/test")
      }.to raise_error(PublishingPlatformApi::ContentStore::UnresolvedRedirect)
    end

    it "creates an absolute URL when a redirect redirects internally" do
      @content_item["redirects"] = [
        create_redirect(path: "/a", destination: "/b"),
      ]

      destination, = PublishingPlatformApi::ContentStore.redirect_for_path(@content_item, "/a")
      expect(destination).to eql "http://www.dev.publishing-platform.co.uk/b"
    end

    it "returns an absolute URL redirect unmodified" do
      @content_item["redirects"] = [
        create_redirect(path: "/a", destination: "https://example.com/b"),
      ]

      destination, = PublishingPlatformApi::ContentStore.redirect_for_path(@content_item, "/a")
      expect(destination).to eql "https://example.com/b"
    end

    it "includes a 301 status code for a redirect" do
      @content_item["redirects"] = [
        create_redirect(path: "/a"),
      ]

      _, status_code = PublishingPlatformApi::ContentStore.redirect_for_path(@content_item, "/a")
      expect(status_code).to eql 301
    end

    it "returns an absolute URL redirect unmodified" do
      @content_item["redirects"] = [
        create_redirect(path: "/a", destination: "https://example.com/b"),
      ]

      destination, = PublishingPlatformApi::ContentStore.redirect_for_path(@content_item, "/a")
      expect(destination).to eql "https://example.com/b"
    end

    describe "when a redirect has segment_mode ignore" do
      it "ignores query string for an exact route" do
        @content_item["redirects"] = [
          create_redirect(path: "/a", destination: "/b", segments_mode: "ignore"),
        ]

        destination, = PublishingPlatformApi::ContentStore.redirect_for_path(@content_item, "/a", "query=1")
        expect(destination).to eql "http://www.dev.publishing-platform.co.uk/b"
      end

      it "ignores segments for a prefix route" do
        @content_item["redirects"] = [
          create_redirect(
            path: "/a", destination: "/b", segments_mode: "ignore", type: "prefix",
          ),
        ]

        destination, = PublishingPlatformApi::ContentStore.redirect_for_path(@content_item, "/a/b")
        expect(destination).to eql "http://www.dev.publishing-platform.co.uk/b"
      end
    end

    describe "when a redirect has segment_mode preserve" do
      it "maintains a query string for an exact route" do
        @content_item["redirects"] = [
          create_redirect(path: "/a", destination: "/b", segments_mode: "preserve"),
        ]

        destination, = PublishingPlatformApi::ContentStore.redirect_for_path(@content_item, "/a", "query=1")
        expect(destination).to eql "http://www.dev.publishing-platform.co.uk/b?query=1"
      end

      it "maintains segments for a prefix route" do
        @content_item["redirects"] = [
          create_redirect(
            path: "/path", destination: "/destination", segments_mode: "preserve", type: "prefix",
          ),
        ]

        destination, = PublishingPlatformApi::ContentStore.redirect_for_path(@content_item, "/path/segment", "query=0")
        expect(destination).to eql "http://www.dev.publishing-platform.co.uk/destination/segment?query=0"
      end

      it "maintains segments for an absolute prefix route" do
        @content_item["redirects"] = [
          create_redirect(
            path: "/path", destination: "http://example.com/destination", segments_mode: "preserve", type: "prefix",
          ),
        ]

        destination, = PublishingPlatformApi::ContentStore.redirect_for_path(@content_item, "/path/segment")
        expect(destination).to eql "http://example.com/destination/segment"
      end
    end

    it "matches identical path in multiple exact redirects" do
      @content_item["redirects"] = [
        create_redirect(path: "/a", destination: "/x", type: "exact"),
        create_redirect(path: "/a/b", destination: "/x/y", type: "exact"),
      ]

      destination, = PublishingPlatformApi::ContentStore.redirect_for_path(@content_item, "/a/b")
      expect(destination).to eql "http://www.dev.publishing-platform.co.uk/x/y"
    end

    it "matches most relevant in multiple prefix matches" do
      @content_item["redirects"] = [
        create_redirect(path: "/a", destination: "/x", type: "prefix", segments_mode: "preserve"),
        create_redirect(path: "/a/b", destination: "/x/y", type: "prefix", segments_mode: "preserve"),
      ]

      destination, = PublishingPlatformApi::ContentStore.redirect_for_path(@content_item, "/a/b/c")
      expect(destination).to eql "http://www.dev.publishing-platform.co.uk/x/y/c"
    end
  end
end
