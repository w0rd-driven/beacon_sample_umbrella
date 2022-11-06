defmodule BeaconSampleWeb.PageController do
  use BeaconSampleWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
