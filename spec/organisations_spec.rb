require "publishing_platform_api/test_helpers/organisations"

RSpec.describe PublishingPlatformApi::Organisations do
  include PublishingPlatformApi::TestHelpers::Organisations

  before do
    @base_api_url = PublishingPlatformLocation.new.website_root
    @api = PublishingPlatformApi::Organisations.new(@base_api_url)
  end

  describe "fetching list of organisations" do
    it "gets the organisations" do
      organisation_slugs = %w[ministry-of-fun tea-agency]
      stub_organisations_api_has_organisations(organisation_slugs)

      response = @api.organisations
      expect(response.map { |r| r["details"]["slug"] }).to eql organisation_slugs
      expect(response["results"][1]["title"]).to eql "Tea Agency"
    end

    it "handles pagination" do
      organisation_slugs = (1..50).map { |n| "organisation-#{n}" }
      stub_organisations_api_has_organisations(organisation_slugs)

      response = @api.organisations
      expect(response.with_subsequent_pages.map { |r| r["details"]["slug"] }).to eql organisation_slugs
    end

    it "raises error if endpoint 404s" do
      stub_request(:get, "#{@base_api_url}/api/organisations").to_return(status: 404)

      expect {
        @api.organisations
      }.to raise_error(PublishingPlatformApi::HTTPNotFound)
    end
  end

  describe "fetching an organisation" do
    it "returns the details" do
      stub_organisations_api_has_organisation("ministry-of-fun")

      response = @api.organisation("ministry-of-fun")
      expect(response["title"]).to eql "Ministry Of Fun"
    end

    it "raises for a non-existent organisation" do
      stub_organisations_api_does_not_have_organisation("non-existent")

      expect {
        @api.organisation("non-existent")
      }.to raise_error(PublishingPlatformApi::HTTPNotFound)
    end
  end
end
