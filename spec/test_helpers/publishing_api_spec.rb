# require "publishing_platform_api/publishing_api"
require "publishing_platform_api/test_helpers/publishing_api"

RSpec.describe PublishingPlatformApi::TestHelpers::PublishingApi do
  include PublishingPlatformApi::TestHelpers::PublishingApi
  let(:publishing_api) { PublishingPlatformApi::PublishingApi.new(PublishingPlatformLocation.find("publishing-api")) }

  describe "#stub_publishing_api_has_lookups" do
    it "stubs the lookup for content items" do
      lookup_hash = { "/foo" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504" }

      stub_publishing_api_has_lookups(lookup_hash)

      expect(publishing_api.lookup_content_ids(base_paths: ["/foo"])).to eql lookup_hash
      expect(publishing_api.lookup_content_id(base_path: "/foo")).to eql "2878337b-bed9-4e7f-85b6-10ed2cbcd504"
    end
  end

  describe "#stub_publishing_api_has_content" do
    it "stubs the call to get content items" do
      stub_publishing_api_has_content([{ "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504" }])

      response = publishing_api.get_content_items({})["results"]

      expect(response).to eql [{ "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504" }]
    end

    it "allows params" do
      stub_publishing_api_has_content(
        [{
          "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504",
        }],
        document_type: "document_collection",
        query: "query",
      )

      response = publishing_api.get_content_items(
        document_type: "document_collection",
        query: "query",
      )["results"]

      expect(response).to eql [{ "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504" }]
    end

    it "returns paginated results" do
      content_id1 = "2878337b-bed9-4e7f-85b6-10ed2cbcd504"
      content_id2 = "2878337b-bed9-4e7f-85b6-10ed2cbcd505"
      content_id3 = "2878337b-bed9-4e7f-85b6-10ed2cbcd506"

      stub_publishing_api_has_content(
        [
          { "content_id" => content_id1 },
          { "content_id" => content_id2 },
          { "content_id" => content_id3 },
        ],
        page: 1,
        per_page: 2,
      )

      response = publishing_api.get_content_items(page: 1, per_page: 2)
      records = response["results"]

      expect(response["total"]).to eql 3
      expect(response["pages"]).to eql 2
      expect(response["current_page"]).to eql 1

      expect(records.length).to eql 2
      expect(records.first["content_id"]).to eql content_id1
      expect(records.last["content_id"]).to eql content_id2
    end

    it "returns an empty list of results for out-of-bound queries" do
      content_id1 = "2878337b-bed9-4e7f-85b6-10ed2cbcd504"
      content_id2 = "2878337b-bed9-4e7f-85b6-10ed2cbcd505"

      stub_publishing_api_has_content(
        [
          { "content_id" => content_id1 },
          { "content_id" => content_id2 },
        ],
        page: 10,
        per_page: 2,
      )

      response = publishing_api.get_content_items(page: 10, per_page: 2)
      records = response["results"]

      expect(records).to eql []
    end
  end

  describe "#stub_publishing_api_has_item" do
    it "stubs the call to get content items" do
      stub_publishing_api_has_item("content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504")
      response = publishing_api.get_content("2878337b-bed9-4e7f-85b6-10ed2cbcd504").parsed_content

      expect(response).to eql({ "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504" })
    end

    it "allows params" do
      stub_publishing_api_has_item(
        "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504",
        "version" => 3,
      )

      response = publishing_api.get_content(
        "2878337b-bed9-4e7f-85b6-10ed2cbcd504",
        "version" => 3,
      ).parsed_content

      expect(response).to eql(
        {
          "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504",
          "version" => 3,
        },
      )
    end
  end

  describe "#stub_publishing_api_has_expanded_links" do
    it "stubs the call to get expanded links when content_id is a symbol" do
      payload = {
        content_id: "2e20294a-d694-4083-985e-d8bedefc2354",
        organisations: [
          {
            content_id: %w[a8a09822-1729-48a7-8a68-d08300de9d1e],
          },
        ],
      }

      stub_publishing_api_has_expanded_links(payload)
      response = publishing_api.get_expanded_links("2e20294a-d694-4083-985e-d8bedefc2354")

      expect(response.to_h).to eql(
        {
          "content_id" => "2e20294a-d694-4083-985e-d8bedefc2354",
          "organisations" => [
            {
              "content_id" => %w[a8a09822-1729-48a7-8a68-d08300de9d1e],
            },
          ],
        },
      )
    end

    it "stubs the call to get expanded links when content_id is a string" do
      payload = {
        "content_id" => "2e20294a-d694-4083-985e-d8bedefc2354",
        organisations: [
          {
            content_id: %w[a8a09822-1729-48a7-8a68-d08300de9d1e],
          },
        ],
      }

      stub_publishing_api_has_expanded_links(payload)
      response = publishing_api.get_expanded_links("2e20294a-d694-4083-985e-d8bedefc2354")

      expect(response.to_h).to eql(
        {
          "content_id" => "2e20294a-d694-4083-985e-d8bedefc2354",
          "organisations" => [
            {
              "content_id" => %w[a8a09822-1729-48a7-8a68-d08300de9d1e],
            },
          ],
        },
      )
    end

    it "stubs with query parameters" do
      payload = {
        "content_id" => "2e20294a-d694-4083-985e-d8bedefc2354",
        organisations: [
          {
            content_id: %w[a8a09822-1729-48a7-8a68-d08300de9d1e],
          },
        ],
      }

      stub_publishing_api_has_expanded_links(payload, with_drafts: false, generate: true)
      response = publishing_api.get_expanded_links("2e20294a-d694-4083-985e-d8bedefc2354", with_drafts: false, generate: true)

      expect(response.to_h).to eql(
        {
          "content_id" => "2e20294a-d694-4083-985e-d8bedefc2354",
          "organisations" => [
            {
              "content_id" => %w[a8a09822-1729-48a7-8a68-d08300de9d1e],
            },
          ],
        },
      )
    end
  end

  describe "#stub_publishing_api_patch_links" do
    it "stubs a request to patch links" do
      content_id = SecureRandom.uuid
      body = {
        links: {
          my_linkset: %w[link_1],
        },
        previous_version: 4,
      }

      expect {
        publishing_api.patch_links(content_id, body)
      }.to raise_error(WebMock::NetConnectNotAllowedError)

      stub_publishing_api_patch_links(content_id, body)
      response = publishing_api.patch_links(content_id, body)
      expect(response.code).to eql 200
    end
  end

  describe "#stub_publishing_api_patch_links_conflict" do
    it "stubs a request to patch links with a 409 conflict response" do
      content_id = SecureRandom.uuid
      body = {
        links: {
          my_linkset: %w[link_1],
        },
        previous_version: 4,
      }

      stub_publishing_api_patch_links_conflict(content_id, body)

      expect {
        publishing_api.patch_links(content_id, body)
      }.to raise_error(PublishingPlatformApi::HTTPConflict) { |error|
        expect(error.message).to include({
          error: {
            code: 409,
            message: "A lock-version conflict occurred. The `previous_version` you've sent (4) is not the same as the current lock version of the edition (5).",
            fields: { previous_version: ["does not match"] },
          },
        }.to_json)
      }
    end
  end

  describe "#stub_any_publishing_api_publish" do
    it "stubs any publish request to the publishing api" do
      stub_any_publishing_api_publish
      publishing_api.publish("some-content-id")
      assert_publishing_api_publish("some-content-id")
    end
  end

  describe "#stub_any_publishing_api_unpublish" do
    it "stubs any unpublish request to the publishing api" do
      stub_any_publishing_api_unpublish
      publishing_api.unpublish("some-content-id", type: :gone)
      assert_publishing_api_unpublish("some-content-id")
    end
  end

  describe "#stub_any_publishing_api_discard_draft" do
    it "stubs any discard draft request to the publishing api" do
      stub_any_publishing_api_discard_draft
      publishing_api.discard_draft("some-content-id")
      assert_publishing_api_discard_draft("some-content-id")
    end
  end

  describe "#stub_publishing_api_isnt_available" do
    it "raises a PublishingPlatformApi::HTTPUnavailable for any request" do
      stub_publishing_api_isnt_available

      expect {
        publishing_api.get_content_items({})
      }.to raise_error(PublishingPlatformApi::HTTPUnavailable)
    end
  end

  describe "#stub_any_publishing_api_call" do
    it "returns a 200 response for any request" do
      stub_any_publishing_api_call
      response = publishing_api.get_content_items({})
      expect(response.code).to eql 200
    end
  end

  describe "#stub_any_publishing_api_call_to_return_not_found" do
    it "returns a PublishingPlatformApi::HTTPNotFound for any request" do
      stub_any_publishing_api_call_to_return_not_found

      expect {
        publishing_api.get_content_items({})
      }.to raise_error(PublishingPlatformApi::HTTPNotFound)
    end
  end

  describe "#stub_publishing_api_unreserve_path" do
    it "stubs the unreserve path API call" do
      stub_publishing_api_unreserve_path("/foo", "myapp")
      api_response = publishing_api.unreserve_path("/foo", "myapp")
      expect(api_response.code).to eql 200
    end

    it "stubs for any app if not specified" do
      stub_publishing_api_unreserve_path("/foo")
      api_response = publishing_api.unreserve_path("/foo", "myapp")
      expect(api_response.code).to eql 200
    end
  end

  describe "#stub_publishing_api_unreserve_path_not_found" do
    it "stubs the unreserve path API call" do
      stub_publishing_api_unreserve_path_not_found("/foo", "myapp")

      expect {
        publishing_api.unreserve_path("/foo", "myapp")
      }.to raise_error(PublishingPlatformApi::HTTPNotFound)
    end

    it "stubs for any app if not specified" do
      stub_publishing_api_unreserve_path_not_found("/foo")

      expect {
        publishing_api.unreserve_path("/foo", "myapp")
      }.to raise_error(PublishingPlatformApi::HTTPNotFound)
    end
  end

  describe "#stub_publishing_api_unreserve_path_invalid" do
    it "stubs the unreserve path API call" do
      stub_publishing_api_unreserve_path_invalid("/foo", "myapp")

      expect {
        publishing_api.unreserve_path("/foo", "myapp")
      }.to raise_error(PublishingPlatformApi::HTTPUnprocessableEntity)
    end

    it "stubs for any app if not specified" do
      stub_publishing_api_unreserve_path_invalid("/foo")

      expect {
        publishing_api.unreserve_path("/foo", "myapp")
      }.to raise_error(PublishingPlatformApi::HTTPUnprocessableEntity)
    end
  end

  describe "#stub_any_publishing_api_unreserve_path" do
    it "stubs a request to unreserve a path" do
      stub_any_publishing_api_unreserve_path

      api_response = publishing_api.unreserve_path("/foo", "myapp")
      expect(api_response.code).to eql 200
    end
  end

  describe "#stub_any_publishing_api_path_reservation" do
    it "stubs a request to reserve a path" do
      stub_any_publishing_api_path_reservation

      api_response = publishing_api.put_path("/foo", {})
      expect(api_response.code).to eql 200
    end

    it "returns the payload with the base_path merged in" do
      stub_any_publishing_api_path_reservation

      api_response = publishing_api.put_path("/foo", publishing_app: "foo-publisher")

      expect(api_response.to_h).to eql(
        {
          "publishing_app" => "foo-publisher",
          "base_path" => "/foo",
        },
      )
    end
  end

  describe "#stub_publishing_api_has_path_reservation_for" do
    it "returns successfully for a request for the path and publishing app" do
      stub_publishing_api_has_path_reservation_for("/foo", "foo-publisher")

      api_response = publishing_api.put_path("/foo", publishing_app: "foo-publisher")
      expect(api_response.code).to eql 200
      expect(api_response.to_h).to eql(
        {
          "publishing_app" => "foo-publisher",
          "base_path" => "/foo",
        },
      )
    end

    it "returns an error response for a request for the path and a different publishing app" do
      stub_publishing_api_has_path_reservation_for("/foo", "foo-publisher")

      expect {
        publishing_api.put_path("/foo", publishing_app: "bar-publisher")
      }.to raise_error(PublishingPlatformApi::HTTPUnprocessableEntity) { |error|
        expect(error.message).to include({
          error: {
            code: 422,
            message: "Base path /foo is already reserved by foo-publisher",
            fields: { base_path: ["/foo is already reserved by foo-publisher"] },
          },
        }.to_json)
      }
    end
  end

  describe "#stub_publishing_api_returns_path_reservation_validation_error_for" do
    it "returns a validation error for a particular path" do
      stub_publishing_api_returns_path_reservation_validation_error_for("/foo")

      expect {
        publishing_api.put_path("/foo", {})
      }.to raise_error(PublishingPlatformApi::HTTPUnprocessableEntity) { |error|
        expect(error.message).to include({
          error: {
            code: 422,
            message: "Base path Computer says no",
            fields: { base_path: ["Computer says no"] },
          },
        }.to_json)
      }
    end

    it "can accept user provided errors" do
      stub_publishing_api_returns_path_reservation_validation_error_for(
        "/foo",
        field: ["error 1", "error 2"],
      )

      expect {
        publishing_api.put_path("/foo", {})
      }.to raise_error(PublishingPlatformApi::HTTPUnprocessableEntity) { |error|
        expect(error.message).to include({
          error: {
            code: 422,
            message: "Field error 1",
            fields: { field: ["error 1", "error 2"] },
          },
        }.to_json)
      }
    end
  end

  describe "#request_json_matching predicate" do
    describe "nested required attribute" do
      let(:matcher) { request_json_matching("a" => { "b" => 1 }) }

      it "matches a body with exact same nested hash strucure" do
        expect(matcher.call(double("request", body: '{"a": {"b": 1}}'))).to be true
      end

      it "matches a body with exact same nested hash strucure and an extra attribute at the top level" do
        expect(matcher.call(double("request", body: '{"a": {"b": 1}, "c": 3}'))).to be true
      end

      it "does not match a body where the inner hash has the required attribute and an extra one" do
        expect(matcher.call(double("request", body: '{"a": {"b": 1, "c": 2}}'))).to be false
      end

      it "does not match a body where the inner hash has the required attribute with the wrong value" do
        expect(matcher.call(double("request", body: '{"a": {"b": 0}}'))).to be false
      end

      it "does not match a body where the inner hash lacks the required attribute" do
        expect(matcher.call(double("request", body: '{"a": {"c": 1}}'))).to be false
      end
    end

    describe "hash to match uses symbol keys" do
      let(:matcher) { request_json_matching(a: 1) }

      it "matches a json body" do
        expect(matcher.call(double("request", body: '{"a": 1}'))).to be true
      end
    end
  end

  describe "#request_json_including predicate" do
    describe "no required attributes" do
      let(:matcher) { request_json_including({}) }

      it "matches an empty body" do
        expect(matcher.call(double("request", body: "{}"))).to be true
      end

      it "matches a body with some attributes" do
        expect(matcher.call(double("request", body: '{"a": 1}'))).to be true
      end
    end

    describe "one required attribute" do
      let(:matcher) { request_json_including("a" => 1) }

      it "does not match an empty body" do
        expect(matcher.call(double("request", body: "{}"))).to be false
      end

      it "does not match a body with the required attribute if the value is different" do
        expect(matcher.call(double("request", body: '{"a": 2}'))).to be false
      end

      it "matches a body with the required attribute and value" do
        expect(matcher.call(double("request", body: '{"a": 1}'))).to be true
      end

      it "matches a body with the required attribute and value and extra attributes" do
        expect(matcher.call(double("request", body: '{"a": 1, "b": 2}'))).to be true
      end
    end

    describe "nested required attribute" do
      let(:matcher) { request_json_including("a" => { "b" => 1 }) }

      it "matches a body with exact same nested hash strucure" do
        expect(matcher.call(double("request", body: '{"a": {"b": 1}}'))).to be true
      end

      it "matches a body where the inner hash has the required attribute and an extra one" do
        expect(matcher.call(double("request", body: '{"a": {"b": 1, "c": 2}}'))).to be true
      end

      it "does not match a body where the inner hash has the required attribute with the wrong value" do
        expect(matcher.call(double("request", body: '{"a": {"b": 0}}'))).to be false
      end

      it "does not match a body where the inner hash lacks the required attribute" do
        expect(matcher.call(double("request", body: '{"a": {"c": 1}}'))).to be false
      end
    end

    describe "hash to match uses symbol keys" do
      let(:matcher) { request_json_including(a: { b: 1 }) }

      it "matches a json body" do
        expect(matcher.call(double("request", body: '{"a": {"b": 1}}'))).to be true
      end
    end

    describe "nested arrays" do
      let(:matcher) { request_json_including("a" => [1]) }

      it "matches a body with exact same inner array" do
        expect(matcher.call(double("request", body: '{"a": [1]}'))).to be true
      end

      it "does not match a body with an array with extra elements" do
        expect(matcher.call(double("request", body: '{"a": [1, 2]}'))).to be false
      end
    end

    describe "hashes in nested arrays" do
      let(:matcher) { request_json_including("a" => [{ "b" => 1 }, 2]) }

      it "matches a body with exact same inner array" do
        expect(matcher.call(double("request", body: '{"a": [{"b": 1}, 2]}'))).to be true
      end

      it "matches a body with an inner hash with extra elements" do
        expect(matcher.call(double("request", body: '{"a": [{"b": 1, "c": 3}, 2]}'))).to be true
      end
    end
  end
end
