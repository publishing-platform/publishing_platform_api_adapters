RSpec.describe PublishingPlatformApi::JsonClient do
  let(:client) { PublishingPlatformApi::JsonClient.new }

  def options
    {}
  end

  it "raises timeout error for long get requests" do
    url = "http://www.example.com/timeout.json"
    stub_request(:get, url).to_timeout
    expect { client.get_json(url) }.to(raise_error(PublishingPlatformApi::TimedOutException))
  end

  it "raises timeout error for long connections" do
    url = "http://www.example.com/timeout.json"
    exception = defined?(Net::OpenTimeout) ? Net::OpenTimeout : TimeoutError
    stub_request(:get, url).to_raise(exception)

    expect {
      client.get_json(url)
    }.to raise_error(PublishingPlatformApi::TimedOutException)
  end

  it "raises invalid url error for an invalid url" do
    url = "http://www.example.com/there-is-a-space-in-this-slug /"
    expect { client.get_json(url) }.to(raise_error(PublishingPlatformApi::InvalidUrl))
  end

  it "raises endpoint not found error if connection refused" do
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_raise(Errno::ECONNREFUSED)
    expect { client.get_json(url) }.to(raise_error(PublishingPlatformApi::EndpointNotFound))
  end

  it "raises endpoint not found error for post requests if connection refused" do
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).to_raise(Errno::ECONNREFUSED)
    expect { client.post_json(url, {}) }.to(raise_error(PublishingPlatformApi::EndpointNotFound))
  end

  it "raises timeout error for long post requests" do
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).to_timeout
    expect { client.post_json(url, {}) }.to(raise_error(PublishingPlatformApi::TimedOutException))
  end

  it "raised socket error" do
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_raise(SocketError)
    expect { client.get_json(url) }.to(raise_error(PublishingPlatformApi::SocketErrorException))
  end

  it "raises error on restclient error" do
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_raise(RestClient::ServerBrokeConnection)
    expect { client.get_json(url) }.to(raise_error(PublishingPlatformApi::HTTPErrorResponse))
  end

  it "fetches and parses json into response" do
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "{}", status: 200)
    expect(client.get_json(url).class).to(eq(PublishingPlatformApi::Response))
  end

  it "includes body for http error" do
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "response body goes here", status: 404)

    expect {
      client.get_json(url)
    }.to raise_error(PublishingPlatformApi::HTTPErrorResponse) { |error|
      expect(error.http_body).to(eq("response body goes here"))
    }
  end

  it "raises http not found if 404 returned from endpoint" do
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "{}", status: 404)
    expect { client.get_json(url) }.to(raise_error(PublishingPlatformApi::HTTPNotFound))
  end

  it "raises http gone if 410 returned from endpoint" do
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "{}", status: 410)
    expect { client.get_json(url) }.to(raise_error(PublishingPlatformApi::HTTPGone))
  end

  it "raises http forbidden if 403 returned from endpoint" do
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "{}", status: 403)
    expect { client.get_json(url) }.to(raise_error(PublishingPlatformApi::HTTPForbidden))
  end

  it "raises http not found if 404 returned from endpoint on raw get" do
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "{}", status: 404)
    expect { client.get_raw(url) }.to(raise_error(PublishingPlatformApi::HTTPNotFound))
  end

  it "raises http gone if 410 returned from endpoint on raw get" do
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "{}", status: 410)
    expect { client.get_raw(url) }.to(raise_error(PublishingPlatformApi::HTTPGone))
  end

  it "raises error if non 404 / 410 error code returned from endpoint" do
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "{}", status: 500)
    expect { client.get_json(url) }.to(raise_error(PublishingPlatformApi::HTTPServerError))
  end

  it "raises conflict for 409 on delete request" do
    url = "http://some.endpoint/some.json"
    stub_request(:delete, url).to_return(body: "{}", status: 409)
    expect { client.delete_json(url) }.to(raise_error(PublishingPlatformApi::HTTPConflict))
  end

  it "follows permanent redirect" do
    url = "http://some.endpoint/some.json"
    new_url = "http://some.endpoint/other.json"
    stub_request(:get, url).to_return(body: "", status: 301, headers: { "Location" => new_url })
    stub_request(:get, new_url).to_return(body: "{\"a\": 1}", status: 200)
    result = client.get_json(url)
    expect(result["a"]).to(eq(1))
  end

  it "follows found redirect" do
    url = "http://some.endpoint/some.json"
    new_url = "http://some.endpoint/other.json"
    stub_request(:get, url).to_return(body: "", status: 302, headers: { "Location" => new_url })
    stub_request(:get, new_url).to_return(body: "{\"a\": 1}", status: 200)
    result = client.get_json(url)
    expect(result["a"]).to(eq(1))
  end

  it "follows see other" do
    url = "http://some.endpoint/some.json"
    new_url = "http://some.endpoint/other.json"
    stub_request(:get, url).to_return(body: "", status: 303, headers: { "Location" => new_url })
    stub_request(:get, new_url).to_return(body: "{\"a\": 1}", status: 200)
    result = client.get_json(url)
    expect(result["a"]).to(eq(1))
  end

  it "follows temporary redirect" do
    url = "http://some.endpoint/some.json"
    new_url = "http://some.endpoint/other.json"
    stub_request(:get, url).to_return(body: "", status: 307, headers: { "Location" => new_url })
    stub_request(:get, new_url).to_return(body: "{\"a\": 1}", status: 200)
    result = client.get_json(url)
    expect(result["a"]).to(eq(1))
  end

  it "handles infinite redirects" do
    url = "http://some.endpoint/some.json"
    redirect = { body: "", status: 302, headers: { "Location" => url } }
    failure = ->(_request) { flunk("Request called too many times") }
    stub_request(:get, url).to_return(redirect).times(11).then.to_return(failure)
    expect { client.get_json(url) }.to(raise_error(PublishingPlatformApi::HTTPErrorResponse))
  end

  it "handles mutual redirects" do
    first_url = "http://some.endpoint/some.json"
    second_url = "http://some.endpoint/some-other.json"
    first_redirect = { body: "", status: 302, headers: { "Location" => second_url } }
    second_redirect = { body: "", status: 302, headers: { "Location" => first_url } }
    failure = ->(_request) { flunk("Request called too many times") }
    stub_request(:get, first_url).to_return(first_redirect).times(6).then.to_return(failure)
    stub_request(:get, second_url).to_return(second_redirect).times(6).then.to_return(failure)
    expect { client.get_json(first_url) }.to(raise_error(PublishingPlatformApi::HTTPErrorResponse))
  end

  it "raises if 404 returned from endpoint for post request" do
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).to_return(body: "{}", status: 404)
    expect { client.post_json(url, {}) }.to(raise_error(PublishingPlatformApi::HTTPNotFound))
  end

  it "raises error if non 404 error code returned from endpoint for post request" do
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).to_return(body: "{}", status: 500)
    expect { client.post_json(url, {}) }.to(raise_error(PublishingPlatformApi::HTTPServerError))
  end

  it "errors on found redirect for post request" do
    url = "http://some.endpoint/some.json"
    new_url = "http://some.endpoint/other.json"
    stub_request(:post, url).to_return(body: "", status: 302, headers: { "Location" => new_url })
    expect { client.post_json(url, {}) }.to(raise_error(PublishingPlatformApi::HTTPErrorResponse))
  end

  it "raises if 404 returned from endpoint for put request" do
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).to_return(body: "{}", status: 404)
    expect { client.put_json(url, {}) }.to(raise_error(PublishingPlatformApi::HTTPNotFound))
  end

  it "raises error if non 404 error code returned from endpoint for put request" do
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).to_return(body: "{}", status: 500)
    expect { client.put_json(url, {}) }.to(raise_error(PublishingPlatformApi::HTTPServerError))
  end

  def empty_response
    net_http_response = stub(body: "{}")
    PublishingPlatformApi::Response.new(net_http_response)
  end

  it "puts with json encoded packet" do
    url = "http://some.endpoint/some.json"
    payload = { a: 1 }
    stub_request(:put, url).with(body: payload.to_json).to_return(body: "{}", status: 200)
    expect(client.put_json(url, payload).to_hash).to(eq({}))
  end

  it "does not encode json if payload is nil" do
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).with(body: nil).to_return(body: "{}", status: 200)
    expect(client.put_json(url, nil).to_hash).to(eq({}))
  end

  it "can build custom response object" do
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "Hello there!")
    response = client.get_json(url, &:body)
    expect(response.is_a?(String)).to(eq(true))
    expect(response).to(eq("Hello there!"))
  end

  it "raises on custom response 404" do
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "", status: 404)
    expect { client.get_json(url, &:body) }.to(raise_error(PublishingPlatformApi::HTTPNotFound))
  end

  it "can build custom response object in bang method" do
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "Hello there!")
    response = client.get_json(url, &:body)
    expect(response.is_a?(String)).to(eq(true))
    expect(response).to(eq("Hello there!"))
  end

  it "can access attributes of response directly" do
    url = "http://some.endpoint/some.json"
    payload = { a: 1 }
    stub_request(:put, url).with(body: payload.to_json).to_return(body: "{\"a\":{\"b\":2}}", status: 200)
    response = client.put_json(url, payload)
    expect(response["a"]["b"]).to(eq(2))
  end

  it "ensures a response is always considered present and not blank" do
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).to_return(body: "{\"a\":1}", status: 200)
    response = client.put_json(url, {})
    expect(!response.blank?).to(be_truthy)
    expect(response.present?).to(eq(true))
  end

  it "allows use of basic auth" do
    client = PublishingPlatformApi::JsonClient.new(basic_auth: { user: "user", password: "password" })
    stub_request(:put, "http://some.endpoint/some.json").with(basic_auth: %w[user password]).to_return(body: "{\"a\":1}", status: 200)
    response = client.put_json("http://some.endpoint/some.json", {})
    expect(response["a"]).to(eq(1))
  end

  it "allows use of bearer token" do
    client = PublishingPlatformApi::JsonClient.new(bearer_token: "SOME_BEARER_TOKEN")
    expected_headers = PublishingPlatformApi::JsonClient.default_request_with_json_body_headers.merge("Authorization" => "Bearer SOME_BEARER_TOKEN")
    stub_request(:put, "http://some.other.endpoint/some.json").with(headers: expected_headers).to_return(body: "{\"a\":2}", status: 200)
    response = client.put_json("http://some.other.endpoint/some.json", {})
    expect(response["a"]).to(eq(2))
  end

  it "allows setting of custom headers on gets" do
    stub_request(:get, "http://some.other.endpoint/some.json").to_return(status: 200)
    PublishingPlatformApi::JsonClient.new.get_json("http://some.other.endpoint/some.json", "HEADER-A" => "B", "HEADER-C" => "D")
    assert_requested(:get, /\/some.json/) do |request|
      headers_with_uppercase_names = request.headers.transform_keys(&:upcase)
      ((headers_with_uppercase_names["HEADER-A"] == "B") and (headers_with_uppercase_names["HEADER-C"] == "D"))
    end
  end

  it "can set custom headers on posts" do
    stub_request(:post, "http://some.other.endpoint/some.json").to_return(status: 200)
    PublishingPlatformApi::JsonClient.new.post_json("http://some.other.endpoint/some.json", {}, "HEADER-A" => "B", "HEADER-C" => "D")
    assert_requested(:post, /\/some.json/) do |request|
      headers_with_uppercase_names = request.headers.transform_keys(&:upcase)
      ((headers_with_uppercase_names["HEADER-A"] == "B") and (headers_with_uppercase_names["HEADER-C"] == "D"))
    end
  end

  it "can set custom headers on puts" do
    stub_request(:put, "http://some.other.endpoint/some.json").to_return(status: 200)
    PublishingPlatformApi::JsonClient.new.put_json("http://some.other.endpoint/some.json", {}, "HEADER-A" => "B", "HEADER-C" => "D")
    assert_requested(:put, /\/some.json/) do |request|
      headers_with_uppercase_names = request.headers.transform_keys(&:upcase)
      ((headers_with_uppercase_names["HEADER-A"] == "B") and (headers_with_uppercase_names["HEADER-C"] == "D"))
    end
  end

  it "can set custom headers on deletes" do
    stub_request(:delete, "http://some.other.endpoint/some.json").to_return(status: 200)
    PublishingPlatformApi::JsonClient.new.delete_json("http://some.other.endpoint/some.json", {}, "HEADER-A" => "B", "HEADER-C" => "D")
    assert_requested(:delete, /\/some.json/) do |request|
      headers_with_uppercase_names = request.headers.transform_keys(&:upcase)
      ((headers_with_uppercase_names["HEADER-A"] == "B") and (headers_with_uppercase_names["HEADER-C"] == "D"))
    end
  end

  it "includes publishing_platform headers in requests if present" do
    PublishingPlatformApi::PublishingPlatformHeaders.set_header(:publishing_platform_request_id, "12345")
    PublishingPlatformApi::PublishingPlatformHeaders.set_header(:publishing_platform_original_url, "http://example.com")
    stub_request(:get, "http://some.other.endpoint/some.json").to_return(status: 200)
    PublishingPlatformApi::JsonClient.new.get_json("http://some.other.endpoint/some.json")
    assert_requested(:get, /\/some.json/) do |request|
      (request.headers["Publishing-Platform-Request-Id"] == "12345") and (request.headers["Publishing-Platform-Original-Url"] == "http://example.com")
    end
  end

  it "ignores publishing_platform headers in requests if not present" do
    PublishingPlatformApi::PublishingPlatformHeaders.set_header(:x_publishing_platform_authenticated_user, "")
    stub_request(:get, "http://some.other.endpoint/some.json").to_return(status: 200)
    PublishingPlatformApi::JsonClient.new.get_json("http://some.other.endpoint/some.json")
    assert_requested(:get, /\/some.json/) do |request|
      !request.headers.key?("X-Publishing-Platform-Authenticated-User")
    end
  end

  it "does not modify additional headers passed in" do
    stub_request(:get, "http://some.other.endpoint/some.json").to_return(status: 200)
    headers = { "HEADER-A" => "A" }
    PublishingPlatformApi::JsonClient.new.get_json("http://some.other.endpoint/some.json", headers)
    expect(headers).to(eq("HEADER-A" => "A"))
  end

  it "does not send content type header for multipart post" do
    expect(RestClient::Request).to receive(:execute) do |args|
      expect(args[:headers]["Content-Type"]).to be_nil
    end

    client.post_multipart("http://example.com", {})
  end

  it "does not send content type header for multipart put" do
    expect(RestClient::Request).to receive(:execute) do |args|
      expect(args[:headers]["Content-Type"]).to be_nil
    end
    client.put_multipart("http://example.com", {})
  end

  it "can post multipart responses" do
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).with(headers: { "Content-Type" => /multipart\/form-data; boundary=----RubyFormBoundary\w+/ }) { |request|
      request.body =~ /------RubyFormBoundary\w+\r\nContent-Disposition: form-data; name="a"\r\n\r\n123\r\n------RubyFormBoundary\w+--\r\n/
    }.to_return(body: "{\"b\": \"1\"}", status: 200)
    response = client.post_multipart("http://some.endpoint/some.json", "a" => "123")
    expect(response["b"]).to(eq("1"))
  end

  it "raises exception if posting multipart and resource not found" do
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).to_return(body: "", status: 404)
    expect {
      client.post_multipart("http://some.endpoint/some.json", "a" => "123")
    }.to(raise_error(PublishingPlatformApi::HTTPNotFound))
  end

  it "raises error responses when posting multipart" do
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).to_return(body: "", status: 500)
    expect {
      client.post_multipart("http://some.endpoint/some.json", "a" => "123")
    }.to(raise_error(PublishingPlatformApi::HTTPServerError))
  end

  it "can put multipart responses" do
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).with(headers: { "Content-Type" => /multipart\/form-data; boundary=----RubyFormBoundary\w+/ }) { |request|
      request.body =~ /------RubyFormBoundary\w+\r\nContent-Disposition: form-data; name="a"\r\n\r\n123\r\n------RubyFormBoundary\w+--\r\n/
    }.to_return(body: "{\"b\": \"1\"}", status: 200)
    response = client.put_multipart("http://some.endpoint/some.json", "a" => "123")
    expect(response["b"]).to(eq("1"))
  end

  it "raises exception if putting multipart and resource not found" do
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).to_return(body: "", status: 404)
    expect {
      client.put_multipart("http://some.endpoint/some.json", "a" => "123")
    }.to(raise_error(PublishingPlatformApi::HTTPNotFound))
  end

  it "raises error responses when putting multipart" do
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).to_return(body: "", status: 500)
    expect {
      client.put_multipart("http://some.endpoint/some.json", "a" => "123")
    }.to(raise_error(PublishingPlatformApi::HTTPServerError))
  end

  it "raises error if attempting to disable timeout" do
    expect { PublishingPlatformApi::JsonClient.new(disable_timeout: true) }.to(raise_error(RuntimeError))
    expect { PublishingPlatformApi::JsonClient.new(timeout: -1) }.to(raise_error(RuntimeError))
  end

  it "adds user agent using env" do
    (previous_publishing_platform_app_name = ENV["PUBLISHING_PLATFORM_APP_NAME"]
     ENV["PUBLISHING_PLATFORM_APP_NAME"] = "api-tests"
     url = "http://some.other.endpoint/some.json"
     stub_request(:get, url).to_return(status: 200)
     PublishingPlatformApi::JsonClient.new.get_json(url)
     assert_requested(:get, /\/some.json/) do |request|
       (request.headers["User-Agent"] == "publishing_platform_api_adapters/#{PublishingPlatformApi::VERSION} (api-tests)")
     end)
  ensure
    ENV["PUBLISHING_PLATFORM_APP_NAME"] = previous_publishing_platform_app_name
  end

  it "defaults to using null logger" do
    expect(client.logger).to equal(NullLogger.instance)
  end

  it "uses custom logger specified in options" do
    custom_logger = double("custom-logger")
    client = PublishingPlatformApi::JsonClient.new(logger: custom_logger)
    expect(client.logger).to equal(custom_logger)
  end

  it "logs publishing_platform request id when available" do
    PublishingPlatformApi::PublishingPlatformHeaders.set_header(:publishing_platform_request_id, "some-request-id")
    custom_logger = double
    client = PublishingPlatformApi::JsonClient.new(logger: custom_logger)
    url = "http://www.example.com/timeout.json"
    stub_request(:get, url).to_timeout
    expected_string = "\"publishing_platform_request_id\":\"some-request-id\""

    expect(custom_logger).to receive(:debug).with(/#{expected_string}/)
    expect(custom_logger).to receive(:error).with(/#{expected_string}/)
    expect { client.get_json(url) }.to(raise_error)
  end

  it "avoids content type header on get without body" do
    url = "http://some.endpoint/some.json"
    stub_request(:any, url)
    client.get_json(url)
    assert_requested(:get, url, headers: PublishingPlatformApi::JsonClient.default_request_headers)
    client.delete_json(url)
    assert_requested(:delete, url, headers: PublishingPlatformApi::JsonClient.default_request_headers)
    client.post_json(url, test: "123")
    assert_requested(:post, url, headers: PublishingPlatformApi::JsonClient.default_request_with_json_body_headers)
    client.put_json(url, test: "123")
    assert_requested(:put, url, headers: PublishingPlatformApi::JsonClient.default_request_with_json_body_headers)
  end
end
