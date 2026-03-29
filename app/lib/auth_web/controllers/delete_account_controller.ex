defmodule AuthWeb.DeleteAccountController do
  use AuthWeb, :controller

  alias Auth.Accounts
  alias Auth.Accounts.User
  alias Auth.Repo

  def delete_account(conn, _params) do
    user = conn.assigns.current_user

    user
    |> delete_user_and_sync()
    |> handle_response(conn)
  end

  defp delete_user_and_sync(%User{} = user) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:delete_user, fn _repo, _changes ->
      Accounts.delete_account(user)
    end)
    |> Ecto.Multi.run(:backend_delete, fn _repo, %{delete_user: _} ->
      delete_user_from_backend(user)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _} -> {:ok, user}
      {:error, _step, reason, _changes_so_far} -> {:error, reason}
    end
  end

  defp delete_user_from_backend(%User{} = user) do
    # Stub: DELETE /backend/api/v1/users/{id} → 200 OK
    _stub = %{status: 200, body: %{id: user.id, deleted: true}}
    {:ok, :deleted}
  end

  defp handle_response({:ok, _user}, conn) do
    conn
    |> put_status(:ok)
    |> json(%{message: "Account deleted successfully"})
  end

  defp handle_response({:error, %{status: status, body: body}}, conn) do
    conn
    |> put_status(status)
    |> json(%{errors: body})
  end

  defp handle_response({:error, reason}, conn) do
    conn
    |> put_status(500)
    |> json(%{error: inspect(reason)})
  end
end
