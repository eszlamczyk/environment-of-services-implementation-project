defmodule AuthWeb.HealthController do
  use AuthWeb, :controller

  def index(conn, _params) do
    # Returns a simple 200 OK with text body.
    # For health checks
    text(conn, "OK")
  end
end
