require "publishing_platform_api/test_helpers/asset_manager"

RSpec.describe PublishingPlatformApi::AssetManager do
  include PublishingPlatformApi::TestHelpers::AssetManager
  include FixtureHelpers

  let(:base_api_url) { PublishingPlatformLocation.find("asset-manager") }
  let(:api) { PublishingPlatformApi::AssetManager.new(base_api_url) }

  let(:file_fixture) { load_fixture_file("hello.txt") }

  let(:asset_url) { [base_api_url, "assets", asset_id].join("/") }
  let(:asset_id) { "new-asset-id" }

  let(:stub_asset_manager_response) do
    {
      asset: {
        id: asset_url,
      },
    }
  end

  it "creates the asset with a file" do
    req = stub_request(:post, "#{base_api_url}/assets")
            .with { |request|
              request.body =~ %r{Content-Disposition: form-data; name="asset\[file\]"; filename="hello\.txt"\r\nContent-Type: text/plain}
            }.to_return(body: JSON.dump(stub_asset_manager_response), status: 201)

    response = api.create_asset(file: file_fixture)

    expect(response["asset"]["id"]).to eql asset_url
    assert_requested(req)
  end

  it "returns not found when the asset does not exist" do
    stub_asset_manager_does_not_have_an_asset("not-really-here")

    expect {
      api.asset("not-really-here")
    }.to raise_error(PublishingPlatformApi::HTTPNotFound)

    expect {
      api.delete_asset("not-really-here")
    }.to raise_error(PublishingPlatformApi::HTTPNotFound)
  end

  describe "the asset exists" do
    before do
      stub_asset_manager_has_an_asset(
        asset_id,
        {
          "name" => "photo.jpg",
          "content_type" => "image/jpeg",
          "file_url" => "http://fooey.publishing-platform.co.uk/media/photo.jpg",
        },
        "photo.jpg",
      )
    end

    let(:asset_id) { "test-id" }

    it "updates the asset with a file" do
      req = stub_request(:put, "#{base_api_url}/assets/test-id")
              .to_return(body: JSON.dump(stub_asset_manager_response), status: 200)

      response = api.update_asset(asset_id, file: file_fixture)

      expect(response["asset"]["id"]).to eql "#{base_api_url}/assets/#{asset_id}"
      assert_requested(req)
    end

    it "retrieves the asset's metadata" do
      asset = api.asset(asset_id)

      expect(asset["name"]).to eql "photo.jpg"
      expect(asset["content_type"]).to eql "image/jpeg"
      expect(asset["file_url"]).to eql "http://fooey.publishing-platform.co.uk/media/photo.jpg"
    end

    it "retrieves the asset from media" do
      asset = api.media(asset_id, "photo.jpg")

      expect(asset.body).to eql "Some file content"
    end
  end

  it "deletes the asset for the given id" do
    req = stub_request(:delete, "#{base_api_url}/assets/#{asset_id}")
            .to_return(body: JSON.dump(stub_asset_manager_response), status: 200)

    response = api.delete_asset(asset_id)

    expect(response["asset"]["id"]).to eql "#{base_api_url}/assets/#{asset_id}"
    assert_requested(req)
  end

  it "restores the asset for the given id" do
    req = stub_request(:post, "#{base_api_url}/assets/#{asset_id}/restore")
            .to_return(body: JSON.dump(stub_asset_manager_response), status: 200)

    response = api.restore_asset(asset_id)

    expect(response["asset"]["id"]).to eql "#{base_api_url}/assets/#{asset_id}"
    assert_requested(req)
  end
end
