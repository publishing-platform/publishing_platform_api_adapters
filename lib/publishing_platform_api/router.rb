require_relative "base"

class PublishingPlatformApi::Router < PublishingPlatformApi::Base
  ### Routes

  def get_route(path)
    get_json("#{endpoint}/routes?incoming_path=#{CGI.escape(path)}")
  end

  def add_route(path, type, backend_id)
    put_json(
      "#{endpoint}/routes",
      route: {
        incoming_path: path,
        route_type: type,
        handler: "backend",
        backend_id:,
      },
    )
  end

  def add_redirect_route(path, type, destination, redirect_type = "permanent", options = {})
    put_json(
      "#{endpoint}/routes",
      route: {
        incoming_path: path,
        route_type: type,
        handler: "redirect",
        redirect_to: destination,
        redirect_type:,
        segments_mode: options[:segments_mode],
      },
    )
  end

  def add_gone_route(path, type)
    put_json(
      "#{endpoint}/routes",
      route: { incoming_path: path, route_type: type, handler: "gone" },
    )
  end

  def delete_route(path, hard_delete: false)
    url = "#{endpoint}/routes?incoming_path=#{CGI.escape(path)}"
    url += "&hard_delete=true" if hard_delete

    delete_json(url)
  end
end
