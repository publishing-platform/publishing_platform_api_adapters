# require "gds_api/response"

RSpec.describe PublishingPlatformApi::Response::CacheControl do
  it "takes no args and initializes with an empty set of values" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new

    expect(cache_control.empty?).to be true
    expect(cache_control.to_s).to eql ""
  end

  it "takes a String and parses it into a Hash when created" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("max-age=600, foo")

    expect(cache_control["foo"]).to be_truthy
    expect(cache_control["max-age"]).to eql "600"
  end

  it "takes a String with a single name=value pair" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("max-age=600")
    expect(cache_control["max-age"]).to eql "600"
  end

  it "takes a String with multiple name=value pairs" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("max-age=600, max-stale=300, min-fresh=570")

    expect(cache_control["max-age"]).to eql "600"
    expect(cache_control["max-stale"]).to eql "300"
    expect(cache_control["min-fresh"]).to eql "570"
  end

  it "takes a String with a single flag value" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("no-cache")

    expect(cache_control.include?("no-cache")).to be true
    expect(cache_control["no-cache"]).to be true
  end

  it "takes a String with a bunch of all kinds of stuff" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("max-age=600,must-revalidate,min-fresh=3000,foo=bar,baz")

    expect(cache_control["max-age"]).to eql "600"
    expect(cache_control["must-revalidate"]).to be true
    expect(cache_control["min-fresh"]).to eql "3000"
    expect(cache_control["foo"]).to eql "bar"
    expect(cache_control["baz"]).to be true
  end

  it "strips leading and trailing spaces from header value" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("   public,   max-age =   600  ")

    expect(cache_control.include?("public")).to be true
    expect(cache_control.include?("max-age")).to be true
    expect(cache_control["max-age"]).to eql "600"
  end

  it "strips blank segments" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("max-age=600,,max-stale=300")

    expect(cache_control.size).to eql 2
    expect(cache_control["max-age"]).to eql "600"
    expect(cache_control["max-stale"]).to eql "300"
  end

  it "removes all directives with #clear" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("max-age=600, must-revalidate")
    cache_control.clear

    expect(cache_control.empty?).to be true
  end

  it "converts self into header String with #to_s" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new
    cache_control["public"] = true
    cache_control["max-age"] = "600"

    expect(cache_control.to_s.split(", ").sort).to eql ["max-age=600", "public"]
  end

  it "sorts alphabetically with boolean directives before value directives" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("foo=bar, z, x, y, bling=baz, zoom=zib, b, a")
    expect(cache_control.to_s).to eql "a, b, x, y, z, bling=baz, foo=bar, zoom=zib"
  end

  it "responds to #max_age with an integer when max-age directive present" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("public, max-age=600")
    expect(cache_control.max_age).to eql 600
  end

  it "responds to #max_age with nil when no max-age directive present" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("public")
    expect(cache_control.max_age.nil?).to be true
  end

  it "responds to #shared_max_age with an integer when s-maxage directive present" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("public, s-maxage=600")
    expect(cache_control.shared_max_age).to eql 600
  end

  it "responds to #shared_max_age with nil when no s-maxage directive present" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("public")
    expect(cache_control.shared_max_age.nil?).to be true
  end

  it "responds to #reverse_max_age with an integer when r-maxage directive present" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("public, r-maxage=600")
    expect(cache_control.reverse_max_age).to eql 600
  end

  it "responds to #reverse_max_age with nil when no r-maxage directive present" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("public")
    expect(cache_control.reverse_max_age.nil?).to be true
  end

  it "responds to #public? truthfully when public directive present" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("public")
    expect(cache_control.public?).to be true
  end

  it "responds to #public? non-truthfully when no public directive present" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("private")
    expect(cache_control.public?).to be_falsey
  end

  it "responds to #private? truthfully when private directive present" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("private")
    expect(cache_control.private?).to be true
  end

  it "responds to #private? non-truthfully when no private directive present" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("public")
    expect(cache_control.private?).to be_falsey
  end

  it "responds to #no_cache? truthfully when no-cache directive present" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("no-cache")
    expect(cache_control.no_cache?).to be true
  end

  it "responds to #no_cache? non-truthfully when no no-cache directive present" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("max-age=600")
    expect(cache_control.no_cache?).to be_falsey
  end

  it "responds to #must_revalidate? truthfully when must-revalidate directive present" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("must-revalidate")
    expect(cache_control.must_revalidate?).to be true
  end

  it "responds to #must_revalidate? non-truthfully when no must-revalidate directive present" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("max-age=600")
    expect(cache_control.no_cache?).to be_falsey
  end

  it "responds to #proxy_revalidate? truthfully when proxy-revalidate directive present" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("proxy-revalidate")
    expect(cache_control.proxy_revalidate?).to be true
  end

  it "responds to #proxy_revalidate? non-truthfully when no proxy-revalidate directive present" do
    cache_control = PublishingPlatformApi::Response::CacheControl.new("max-age=600")
    expect(cache_control.proxy_revalidate?).to be_falsey
  end
end
