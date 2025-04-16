RSpec.describe PublishingPlatformApi::Base do
  # rubocop:disable Lint/ConstantDefinitionInBlock
  class ConcreteApi < PublishingPlatformApi::Base
    def base_url
      endpoint
    end
  end
  # rubocop:enable Lint/ConstantDefinitionInBlock

  after :each do
    PublishingPlatformApi::Base.default_options = nil
  end

  it "constructs escaped query string" do
    api = ConcreteApi.new("http://foo")
    url = api.url_for_slug("slug", "a" => " ", "b" => "/")
    u = URI.parse(url)

    expect(u.query).to eql "a=+&b=%2F"
  end

  it "constructs escaped query string for rails" do
    api = ConcreteApi.new("http://foo")

    url = api.url_for_slug("slug", "b" => %w[123])
    u = URI.parse(url)

    expect(u.query).to eql "b%5B%5D=123"

    url = api.url_for_slug("slug", "b" => %w[123 456])
    u = URI.parse(url)
    expect(u.query).to eql "b%5B%5D=123&b%5B%5D=456"
  end

  it "does not add a question mark if there are no parameters" do
    api = ConcreteApi.new("http://foo")
    url = api.url_for_slug("slug")

    expect(url).not_to match(/\?/)
  end

  it "uses endpoint in url" do
    api = ConcreteApi.new("http://foobarbaz")
    url = api.url_for_slug("slug")
    u = URI.parse(url)

    expect(u.host).to match(/foobarbaz$/)
  end

  it "accepts options as second arg" do
    api = ConcreteApi.new("http://foo", foo: "bar")
    expect(api.options[:foo]).to eql "bar"
  end

  it "barfs if not given valid url" do
    expect {
      ConcreteApi.new("invalid-url")
    }.to raise_error(PublishingPlatformApi::Base::InvalidAPIURL)
  end

  it "sets json client logger to own logger by default" do
    api = ConcreteApi.new("http://bar")
    expect(api.client.logger).to equal PublishingPlatformApi::Base.logger
  end

  it "sets json client logger to logger in default options" do
    custom_logger = double("custom-logger")
    PublishingPlatformApi::Base.default_options = { logger: custom_logger }
    api = ConcreteApi.new("http://bar")
    expect(api.client.logger).to equal custom_logger
  end

  it "sets json client logger to logger in_options" do
    custom_logger = double("custom-logger")
    PublishingPlatformApi::Base.default_options = { logger: custom_logger }
    another_logger = double("another-logger")
    api = ConcreteApi.new("http://bar", logger: another_logger)
    expect(api.client.logger).to equal another_logger
  end
end
