require "publishing_platform_api/middleware/publishing_platform_header_sniffer"

RSpec.describe PublishingPlatformApi::PublishingPlatformHeaderSniffer do
  include Rack::Test::Methods

  let(:inner_app) do
    ->(_env) { [200, { "Content-Type" => "text/plain" }, ["All good!"]] }
  end

  let(:app) { PublishingPlatformApi::PublishingPlatformHeaderSniffer.new(inner_app, "HTTP_PUBLISHING_PLATFORM_REQUEST_ID") }

  it "sniffs custom request headers and stores them for later use" do
    header "Publishing-Platform-Request-Id", "12345"
    get "/"
    expect(PublishingPlatformApi::PublishingPlatformHeaders.headers[:publishing_platform_request_id]).to eql "12345"
  end
end
