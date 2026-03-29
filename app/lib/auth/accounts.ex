defmodule Auth.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Auth.Repo

  alias Auth.Accounts.User

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id) do
    from(u in User, where: u.id == ^id and u.deleted == false)
    |> Repo.one!()
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a user by email and password.

  Returns the user if the email exists and the password is correct.
  Returns nil otherwise.
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email, deleted: false)
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email, deleted: false)

    if user && User.valid_password?(user, password) do
      user
    end
  end

  def register_user_oauth(attrs) do
    %User{}
    |> User.oauth_changeset(attrs)
    |> Repo.insert()
  end

  def delete_account(user) do
    user
    |> User.delete_account_changeset()
    |> Repo.update()
  end

  @doc """
  Updates a user's password after validating the current password.

  ## Examples

      iex> update_user_password(user, %{current_password: "old", password: "new", password_confirmation: "new"})
      {:ok, %User{}}

      iex> update_user_password(user, %{current_password: "wrong", password: "new", password_confirmation: "new"})
      {:error, %Ecto.Changeset{}}
  """
  def update_user_password(user, attrs, opts \\ []) do
    user
    |> User.password_changeset(attrs, opts)
    |> User.validate_current_password(
      Map.get(attrs, "current_password") || Map.get(attrs, :current_password)
    )
    |> Repo.update()
  end

  @doc """
  Changes a user's state of admin role.

  ## Examples

      iex> set_user_admin(user, true)
      {:ok, %User{admin: true}}

      iex> set_user_admin(user, false)
      {:ok, %User{admin: false}}
  """
  def set_user_admin(user, admin?) do
    user
    |> User.admin_changeset(%{admin: admin?})
    |> Repo.update()
  end

  @doc """
  Lists all users that are present admins (have account,
    have admin flag set to true, and have deleted flag set to false)

  ## Example

    iex> list_admins()
    {:ok, [%User{}, %User{}, ...]}
  """
  def list_admins() do
    from(u in User)
    |> where([u], u.deleted == false)
    |> where([u], u.admin == true)
    |> Repo.all()
  end
end
