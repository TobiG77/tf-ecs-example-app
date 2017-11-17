defmodule HelloWorldApiWeb.BaseView do
  use HelloWorldApiWeb, :view

  def render("up.json", _assigns) do
    %{
      status: "up"
    }
  end

end
