defmodule HelloWorldApiWeb.BaseController do
  use HelloWorldApiWeb, :controller

  def up(conn, _params) do
    render(conn, "up.json", %{})
  end

end