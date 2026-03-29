defmodule AuthWeb.AdminsController do
  use AuthWeb, :controller

  alias Auth.Accounts

  @doc """
  List systems admin (people that have `admin` flag set and flag `deleted` is not true)

  returns list
  [
    %{
      id: 1,
      email: "email@example.com"
    },
    ...
  ]
  """
  def list_admins(conn, _params) do
    admins =
      Accounts.list_admins()
      |> Enum.map(fn admin ->
        %{
          id: Map.get(admin, :id),
          email: Map.get(admin, :email)
        }
      end)

    conn
    |> put_status(:ok)
    |> json(%{
      admins: admins
    })
  end

  @doc """
  Updates given email's user admin value

  Inputs:
  - User updating it must be an admin
  - email: email of user we want to update
  - is_admin: boolean value to update user status (either true for set to admin or false to unset admin)
  """
  def set_admin(conn, %{"email" => email, "is_admin" => admin?}) do
    # IO.inspect(conn.assigns.current_user)
    if conn.assigns.current_user.admin do
      case Accounts.get_user_by_email(email) do
        nil ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "User with given email not found"})

        %Accounts.User{} = user ->
          {:ok, new_user} = Accounts.set_user_admin(user, admin?)

          conn
          |> put_status(:ok)
          |> json(%{
            message:
              if(new_user.admin,
                do: "Successfully set a new admin!",
                else: "Successfully removed admin!"
              )
          })
      end
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Unauthorized"})
    end
  end
end
