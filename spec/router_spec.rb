require "publishing_platform_api/test_helpers/router"

RSpec.describe PublishingPlatformApi::Router do
  include PublishingPlatformApi::TestHelpers::Router

  before do
    @base_api_url = PublishingPlatformLocation.find("router-api")
    @api = PublishingPlatformApi::Router.new(@base_api_url, bearer_token: "token")
  end

  around do |test|
    ClimateControl.modify ROUTER_API_BEARER_TOKEN: "token" do
      test.call
    end
  end

  describe "managing routes" do
    describe "fetching a route" do
      it "returns the backend route details" do
        req = stub_router_has_backend_route("/foo", backend_id: "foo")

        response = @api.get_route("/foo")
        expect(response.code).to eql 200
        expect(response["backend_id"]).to eql "foo"

        assert_requested(req)
      end

      it "raises if nothing found" do
        req = stub_router_doesnt_have_route("/foo")

        expect {
          @api.get_route("/foo")
        }.to raise_error(PublishingPlatformApi::HTTPNotFound)

        assert_requested(req)
      end

      it "returns the gone route details" do
        stub_router_has_gone_route("/foo")

        response = @api.get_route("/foo")
        expect(response.code).to eql 200
        expect(response["handler"]).to eql "gone"
      end

      it "returns the redirect route details" do
        stub_router_has_redirect_route("/foo", redirect_to: "/bar")

        response = @api.get_route("/foo")
        expect(response.code).to eql 200
        expect(response["handler"]).to eql "redirect"
        expect(response["redirect_to"]).to eql "/bar"
      end

      it "escapes the params" do
        # The WebMock query matcher matches unescaped params.  The call blows up if they're not escaped

        req = WebMock.stub_request(:get, "#{@base_api_url}/routes")
          .with(query: { "incoming_path" => "/foo bar" })
          .to_return(status: 404)

        expect {
          @api.get_route("/foo bar")
        }.to raise_error(PublishingPlatformApi::HTTPNotFound)

        assert_requested(req)
      end
    end

    describe "creating/updating a route" do
      it "allows creating/updating a route" do
        route_data = { "incoming_path" => "/foo", "route_type" => "exact", "handler" => "backend", "backend_id" => "foo" }
        req = WebMock.stub_request(:put, "#{@base_api_url}/routes")
          .with(body: { "route" => route_data }.to_json)
          .to_return(status: 201, body: route_data.to_json, headers: { "Content-type" => "application/json" })

        response = @api.add_route("/foo", "exact", "foo")
        expect(response.code).to eql 201
        expect(response["backend_id"]).to eql "foo"

        assert_requested(req)
      end

      it "raises an error if creating/updating the route fails" do
        route_data = { "incoming_path" => "/foo", "route_type" => "exact", "handler" => "backend", "backend_id" => "foo" }
        response_data = route_data.merge("errors" => { "backend_id" => "does not exist" })

        req = WebMock.stub_request(:put, "#{@base_api_url}/routes")
          .with(body: { "route" => route_data }.to_json)
          .to_return(status: 400, body: response_data.to_json, headers: { "Content-type" => "application/json" })

        expect {
          @api.add_route("/foo", "exact", "foo")
        }.to raise_error(PublishingPlatformApi::HTTPErrorResponse) { |e|
          expect(e.code).to eql 400
          expect(e.error_details).to eql response_data
        }

        assert_requested(req)
      end
    end

    describe "creating/updating a redirect route" do
      it "allows creating/updating a redirect route" do
        route_data = { "incoming_path" => "/foo",
                       "route_type" => "exact",
                       "handler" => "redirect",
                       "redirect_to" => "/bar",
                       "redirect_type" => "permanent",
                       "segments_mode" => nil }
        req = WebMock.stub_request(:put, "#{@base_api_url}/routes")
          .with(body: { "route" => route_data }.to_json)
          .to_return(status: 201, body: route_data.to_json, headers: { "Content-type" => "application/json" })

        response = @api.add_redirect_route("/foo", "exact", "/bar")
        expect(response.code).to eql 201
        expect(response["redirect_to"]).to eql "/bar"

        assert_requested(req)
      end

      it "allows creating/updating a temporary redirect route" do
        route_data = { "incoming_path" => "/foo",
                       "route_type" => "exact",
                       "handler" => "redirect",
                       "redirect_to" => "/bar",
                       "redirect_type" => "temporary",
                       "segments_mode" => nil }
        req = WebMock.stub_request(:put, "#{@base_api_url}/routes")
          .with(body: { "route" => route_data }.to_json)
          .to_return(status: 201, body: route_data.to_json, headers: { "Content-type" => "application/json" })

        response = @api.add_redirect_route("/foo", "exact", "/bar", "temporary")
        expect(response.code).to eql 201
        expect(response["redirect_to"]).to eql "/bar"

        assert_requested(req)
      end

      it "allows creating/updating a redirect route which preserves segments" do
        route_data = { "incoming_path" => "/foo",
                       "route_type" => "exact",
                       "handler" => "redirect",
                       "redirect_to" => "/bar",
                       "redirect_type" => "temporary",
                       "segments_mode" => "preserve" }
        req = WebMock.stub_request(:put, "#{@base_api_url}/routes")
          .with(body: { "route" => route_data }.to_json)
          .to_return(status: 201, body: route_data.to_json, headers: { "Content-type" => "application/json" })

        response = @api.add_redirect_route("/foo", "exact", "/bar", "temporary", segments_mode: "preserve")
        expect(response.code).to eql 201
        expect(response["redirect_to"]).to eql "/bar"

        assert_requested(req)
      end

      it "raises an error if creating/updating the redirect route fails" do
        route_data = { "incoming_path" => "/foo",
                       "route_type" => "exact",
                       "handler" => "redirect",
                       "redirect_to" => "bar",
                       "redirect_type" => "permanent",
                       "segments_mode" => nil }
        response_data = route_data.merge("errors" => { "redirect_to" => "is not a valid URL path" })

        req = WebMock.stub_request(:put, "#{@base_api_url}/routes")
          .with(body: { "route" => route_data }.to_json)
          .to_return(status: 400, body: response_data.to_json, headers: { "Content-type" => "application/json" })

        expect {
          @api.add_redirect_route("/foo", "exact", "bar")
        }.to raise_error(PublishingPlatformApi::HTTPErrorResponse) { |e|
          expect(e.code).to eql 400
          expect(e.error_details).to eql response_data
        }

        assert_requested(req)
      end
    end

    describe "#add_gone_route" do
      it "allows creating/updating a gone route" do
        route_data = { "incoming_path" => "/foo", "route_type" => "exact", "handler" => "gone" }
        req = WebMock.stub_request(:put, "#{@base_api_url}/routes")
          .with(body: { "route" => route_data }.to_json)
          .to_return(status: 201, body: route_data.to_json, headers: { "Content-type" => "application/json" })

        response = @api.add_gone_route("/foo", "exact")
        expect(response.code).to eql 201
        expect(response["incoming_path"]).to eql "/foo"

        assert_requested(req)
      end

      it "raises an error if creating/updating the gone route fails" do
        route_data = { "incoming_path" => "foo", "route_type" => "exact", "handler" => "gone" }
        response_data = route_data.merge("errors" => { "incoming_path" => "is not a valid URL path" })

        req = WebMock.stub_request(:put, "#{@base_api_url}/routes")
          .with(body: { "route" => route_data }.to_json)
          .to_return(status: 400, body: response_data.to_json, headers: { "Content-type" => "application/json" })

        expect {
          @api.add_gone_route("foo", "exact")
        }.to raise_error(PublishingPlatformApi::HTTPErrorResponse) { |e|
          expect(e.code).to eql 400
          expect(e.error_details).to eql response_data
        }

        assert_requested(req)
      end
    end

    describe "deleting a route" do
      it "allows deleting a route" do
        route_data = { "incoming_path" => "/foo", "route_type" => "exact", "handler" => "backend", "backend_id" => "foo" }
        req = WebMock.stub_request(:delete, "#{@base_api_url}/routes")
          .with(query: { "incoming_path" => "/foo" })
          .to_return(status: 200, body: route_data.to_json, headers: { "Content-type" => "application/json" })

        response = @api.delete_route("/foo")
        expect(response.code).to eql 200
        expect(response["backend_id"]).to eql "foo"

        assert_requested(req)
      end

      it "raises HTTPNotFound if nothing found" do
        req = WebMock.stub_request(:delete, "#{@base_api_url}/routes")
          .with(query: { "incoming_path" => "/foo" })
          .to_return(status: 404)

        expect {
          @api.delete_route("/foo")
        }.to raise_error(PublishingPlatformApi::HTTPNotFound) { |e|
          expect(e.code).to eql 404
        }

        assert_requested(req)
      end

      it "escapes the params" do
        # The WebMock query matcher matches unescaped params.  The call blows up if they're not escaped

        req = WebMock.stub_request(:delete, "#{@base_api_url}/routes")
          .with(query: { "incoming_path" => "/foo bar" })
          .to_return(status: 404)

        expect {
          @api.delete_route("/foo bar")
        }.to raise_error(PublishingPlatformApi::HTTPNotFound)

        assert_requested(req)
      end
    end
  end
end
