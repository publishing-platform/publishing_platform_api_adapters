require "publishing_platform_schemas/rspec_matchers"
require "publishing_platform_api/publishing_api/special_route_publisher"
require "publishing_platform_api/test_helpers/publishing_api"

RSpec.describe PublishingPlatformApi::PublishingApi::SpecialRoutePublisher do
  include PublishingPlatformApi::TestHelpers::PublishingApi
  include PublishingPlatformSchemas::RSpecMatchers

  let(:content_id) { "a-content-id-of-sorts" }
  let(:special_route) do
    {
      content_id:,
      title: "A title",
      description: "A description",
      base_path: "/favicon.ico",
      type: "exact",
      publishing_app: "publisher",
      rendering_app: "frontend",
    }
  end

  let(:publisher) { PublishingPlatformApi::PublishingApi::SpecialRoutePublisher.new }
  let(:endpoint) { PublishingPlatformLocation.find("publishing-api") }

  describe ".publish" do
    before do
      stub_any_publishing_api_call
    end

    it "publishes valid special routes" do
      Timecop.freeze(Time.now) do
        publisher.publish(special_route)

        expected_payload = {
          base_path: special_route[:base_path],
          document_type: "special_route",
          schema_name: "special_route",
          title: special_route[:title],
          description: special_route[:description],
          routes: [
            {
              path: special_route[:base_path],
              type: special_route[:type],
            },
          ],
          details: {},
          publishing_app: special_route[:publishing_app],
          rendering_app: special_route[:rendering_app],
          public_updated_at: Time.now.iso8601,
          update_type: "major",
        }

        assert_requested(:put, "#{endpoint}/content/#{content_id}", body: expected_payload)
        expect(expected_payload).to be_valid_against_publisher_schema("special_route")
        # assert_valid_against_publisher_schema(expected_payload, "special_route")
        assert_publishing_api_publish(content_id)
      end
    end

    it "publishes customized document type" do
      publisher.publish(special_route.merge(document_type: "other_document_type"))

      assert_requested(:put, "#{endpoint}/content/#{content_id}") do |req|
        JSON.parse(req.body)["document_type"] == "other_document_type"
      end
      assert_publishing_api_publish(content_id)
    end

    it "publishes customized schema_name" do
      publisher.publish(special_route.merge(schema_name: "dummy_schema"))

      assert_requested(:put, "#{endpoint}/content/#{content_id}") do |req|
        JSON.parse(req.body)["schema_name"] == "dummy_schema"
      end
    end

    it "publishes links" do
      links = {
        links: {
          organisations: %w[org-content-id],
        },
      }

      publisher.publish(special_route.merge(links))

      assert_requested(:patch, "#{endpoint}/links/#{content_id}", body: links)
    end

    describe "Timezone handling" do
      let(:publishing_api) do
        double(:publishing_api, put_content_item: nil)
      end
      let(:publisher) do
        PublishingPlatformApi::PublishingApi::SpecialRoutePublisher.new(publishing_api:)
      end

      it "is robust to Time.zone returning nil" do
        Timecop.freeze(Time.now) do
          allow(Time).to receive(:zone).and_return(nil)

          expect(publishing_api).to receive(:put_content).with(
            anything,
            hash_including(public_updated_at: Time.now.iso8601),
          )

          expect(publishing_api).to receive(:publish)

          publisher.publish(special_route)
        end
      end

      it "uses Time.zone if available" do
        Timecop.freeze(Time.now) do
          time_in_zone = double("Time in zone", now: Time.parse("2010-01-01 10:10:10 +04:00"))
          allow(Time).to receive(:zone).and_return(time_in_zone)

          expect(publishing_api).to receive(:put_content).with(
            anything,
            hash_including(public_updated_at: time_in_zone.now.iso8601),
          )

          expect(publishing_api).to receive(:publish)

          publisher.publish(special_route)
        end
      end
    end
  end
end
