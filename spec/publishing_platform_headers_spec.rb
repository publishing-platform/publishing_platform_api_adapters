RSpec.describe PublishingPlatformApi::PublishingPlatformHeaders do
  before :each do
    Thread.current[:headers] = nil if Thread.current[:headers]
  end

  after :each do
    PublishingPlatformApi::PublishingPlatformHeaders.clear_headers
  end

  it "supports read/write of headers" do
    PublishingPlatformApi::PublishingPlatformHeaders.set_header("PP-Request-Id", "123-456")
    PublishingPlatformApi::PublishingPlatformHeaders.set_header("Content-Type", "application/pdf")

    expect(PublishingPlatformApi::PublishingPlatformHeaders.headers).to eql({
      "PP-Request-Id" => "123-456",
      "Content-Type" => "application/pdf",
    })
  end

  it "supports clearing of headers" do
    PublishingPlatformApi::PublishingPlatformHeaders.set_header("PP-Request-Id", "123-456")

    PublishingPlatformApi::PublishingPlatformHeaders.clear_headers

    expect(PublishingPlatformApi::PublishingPlatformHeaders.headers).to eql({})
  end
end
