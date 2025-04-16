RSpec.describe "Exceptions" do
  it "fingerprints per exception type" do
    exception = PublishingPlatformApi::HTTPBadGateway.new(200)

    expect(exception.sentry_context[:fingerprint]).to eql ["PublishingPlatformApi::HTTPBadGateway"]
  end
end
