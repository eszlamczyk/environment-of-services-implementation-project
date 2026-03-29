defmodule AuthWeb.TokenController do
  use AuthWeb, :controller

  def verify(conn, _params) do
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{valid: false})

      user ->
        json(conn, %{valid: true, user_id: user.id, email: user.email})
    end
  end
end
