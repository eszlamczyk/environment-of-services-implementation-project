defmodule Auth.User.Register do
  @moduledoc false

  alias Auth.Accounts
  alias Auth.Accounts.User

  defp backend_url, do: Application.get_env(:auth, :backend_url)
  defp backend_token, do: Application.get_env(:auth, :backend_authorization_token)

  @doc """
  Given user params, creates record in the local db and calls backend to
  create new user there
  """
  @spec register_user(map()) :: {:ok, User.t()} | {:error, any()}
  def register_user(user_params) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:user, fn _repo, _changes ->
      Accounts.register_user(user_params)
    end)
    |> Ecto.Multi.run(:backend_sync, fn _repo, %{user: user} ->
      sync_user_with_backend(user, user_params)
    end)
    |> Auth.Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, _step, reason, _changes_so_far} -> {:error, reason}
    end
  end

  @spec register_user_oauth(map()) :: {:ok, User.t()} | {:error, any()}
  def register_user_oauth(user_params) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:user, fn _repo, _changes ->
      Accounts.register_user_oauth(user_params)
    end)
    |> Ecto.Multi.run(:backend_sync, fn _repo, %{user: user} ->
      sync_user_with_backend(user, %{"first_name" => "", "last_name" => ""})
    end)
    |> Auth.Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, _step, reason, _changes_so_far} -> {:error, reason}
    end
  end

  @spec sync_user_with_backend(User.t(), map()) :: {:ok, User.t()} | {:error, map()}
  defp sync_user_with_backend(%User{} = user, %{
         "first_name" => first_name,
         "last_name" => last_name
       }) do
    body =
      %{
        id: user.id,
        mail: user.email,
        firstName: first_name,
        lastName: last_name
      }
      |> Jason.encode!()

    request =
      Finch.build(
        :post,
        "#{backend_url()}/backend/api/v1/users",
        [
          {"content-type", "application/json"},
          {"authorization", backend_token()}
        ],
        body
      )

    case Auth.BackendClient.Adapter.request(request) do
      {:ok, %Finch.Response{status: 200}} ->
        {:ok, user}

      {:ok, %Finch.Response{status: status, body: resp_body}} ->
        {:error, %{status: status, body: resp_body}}

      {:error, reason} ->
        {:error, %{error: reason}}
    end
  end
end
