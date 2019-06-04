defmodule SecretHitlerWeb.PageController do
  use SecretHitlerWeb, :controller
  import Phoenix.LiveView.Controller
  alias SecretHitlerWeb.RealGameLive

  plug :ensure_host_id, :ignored

  def index(conn, %{"game_name" => game_name}) do
    live_render(conn, RealGameLive,
      session: %{
        game_name: game_name,
        host_id: host_id(conn) |> IO.inspect(label: "Discovered Host ID")
      }
    )
  end

  def index(conn, _) do
    game_name = UUID.uuid4()
    redirect(conn, to: Routes.page_path(conn, :index, game_name))
  end

  defp host_id(%Plug.Conn{req_cookies: %{"host_id" => host_id}}), do: host_id
  defp host_id(%Plug.Conn{resp_cookies: %{"host_id" => %{"value" => host_id}}}), do: host_id
  defp host_id(%Plug.Conn{resp_cookies: %{"host_id" => host_id}}), do: host_id
  defp host_id(%Plug.Conn{assigns: %{host_id: host_id}}), do: host_id

  defp ensure_host_id(%Plug.Conn{req_cookies: %{"host_id" => host_id}} = conn, _) do
    IO.inspect(host_id, label: "Host ID")
    conn
  end

  defp ensure_host_id(%Plug.Conn{} = conn, _) do
    IO.inspect("No host ID")
    IO.inspect("==============")
    IO.inspect(conn, label: "Conn")
    IO.inspect("==============")
    host_id = UUID.uuid4()

    conn
    |> put_resp_cookie("host_id", host_id, max_age: div(:timer.hours(24), 1000))
    |> assign(:host_id, host_id)
  end
end
