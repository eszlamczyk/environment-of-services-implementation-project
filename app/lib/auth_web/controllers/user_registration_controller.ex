defmodule AuthWeb.UserRegistrationController do
  use AuthWeb, :controller

  def create(conn, user_params) do
    user_params
    |> Auth.User.Register.register_user()
    |> handle_response(conn)
  end

  defp handle_response({:ok, user}, conn) do
    token = Auth.User.Auth.generate_jwt(user)

    conn
    |> put_status(:created)
    |> json(%{
      message: "User created successfully",
      token: token,
      user: %{id: user.id, email: user.email, is_admin: user.admin}
    })
  end

  defp handle_response({:error, %Ecto.Changeset{} = changeset}, conn) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: format_errors(changeset)})
  end

  defp handle_response({:error, %{status: status, body: body}}, conn) do
    conn
    |> put_status(status)
    |> json(%{errors: body})
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", inspect(value))
      end)
    end)
  end
end
