defmodule AuthWeb.ChangePasswordController do
  use AuthWeb, :controller

  def change_password(conn, %{
        "current_password" => old_password,
        "password" => new_password,
        "password_confirmation" => password_confirmation
      }) do
    user = conn.assigns.current_user

    attrs = %{
      current_password: old_password,
      password: new_password,
      password_confirmation: password_confirmation
    }

    case Auth.Accounts.update_user_password(user, attrs) do
      {:ok, _} ->
        conn
        |> put_status(:ok)
        |> json(%{
          message: "Password Changed Successfully"
        })

      {:error, changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            parse_errors(msg, opts)
          end)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          message: "Password change failed",
          errors: errors
        })
    end
  end

  defp parse_errors(msg, opts) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
