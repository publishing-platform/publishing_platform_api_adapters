RSpec.describe PublishingPlatformApi::PublishingApi do
  let(:api_client) { PublishingPlatformApi::PublishingApi.new(PublishingPlatformLocation.find("publishing-api")) }

  describe "content ID validation" do
    %i[get_content get_links discard_draft].each do |method|
      it "happens on #{method}" do
        expect {
          api_client.send(method, nil)
        }.to raise_error(ArgumentError)
      end
    end

    it "happens on publish" do
      expect {
        api_client.publish(nil)
      }.to raise_error(ArgumentError)
    end

    it "happens on put_content" do
      expect {
        api_client.put_content(nil, {})
      }.to raise_error(ArgumentError)
    end

    it "happens on patch_links" do
      expect {
        api_client.patch_links(nil, links: {})
      }.to raise_error(ArgumentError)
    end
  end
end
