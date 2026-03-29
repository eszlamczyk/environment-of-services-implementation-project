defmodule AuthWeb.AdminsControllerTest do
  use AuthWeb.ConnCase, async: true

  #
  # Helper: create user and JWT
  #
  defp create_user(attrs) do
    defaults = %{
      email: "user_#{System.unique_integer([:positive])}@example.com",
      hashed_password: Bcrypt.hash_pwd_salt("password123"),
      admin: false,
      deleted: false
    }

    params = Map.merge(defaults, attrs)

    %Auth.Accounts.User{}
    |> Auth.Accounts.User.registration_changeset(%{
      email: params.email,
      password: "password123"
    })
    |> Ecto.Changeset.change(%{
      admin: params.admin,
      deleted: params.deleted
    })
    |> Auth.Repo.insert!()
  end

  defp auth_conn(conn, user) do
    token = Auth.User.Auth.generate_jwt(user)

    conn
    |> put_req_header("authorization", "Bearer #{token}")
    |> put_req_header("accept", "application/json")
  end

  describe "GET /auth/api/v1/admins list_admins/2" do
    test "returns empty list when no admins exist", %{conn: conn} do
      user = create_user(%{admin: false})
      conn = auth_conn(conn, user)

      conn = get(conn, "/auth/api/v1/admins")

      assert %{"admins" => []} = json_response(conn, 200)
    end

    test "returns only non-deleted admins", %{conn: conn} do
      requester = create_user(%{admin: true})
      conn = auth_conn(conn, requester)

      admin1 = create_user(%{admin: true})
      admin2 = create_user(%{admin: true})
      deleted_admin = create_user(%{admin: true, deleted: true})

      conn = get(conn, "/auth/api/v1/admins")
      %{"admins" => admins} = json_response(conn, 200)

      emails = Enum.map(admins, & &1["email"])

      assert requester.email in emails
      assert admin1.email in emails
      assert admin2.email in emails
      refute Enum.any?(admins, fn admin -> admin["email"] == deleted_admin.email end)
      assert length(admins) == 3
    end
  end

  describe "PUT /auth/api/v1/admins set_admin/2" do
    test "returns 401 when the requester is not admin", %{conn: conn} do
      non_admin = create_user(%{admin: false})
      conn = auth_conn(conn, non_admin)

      conn =
        put(conn, "/auth/api/v1/admins", %{
          "email" => "someone@example.com",
          "is_admin" => true
        })

      assert %{"error" => "Unauthorized"} = json_response(conn, 401)
    end

    test "returns 404 when target user does not exist", %{conn: conn} do
      admin = create_user(%{admin: true})
      conn = auth_conn(conn, admin)

      conn =
        put(conn, "/auth/api/v1/admins", %{
          "email" => "not_found@example.com",
          "is_admin" => true
        })

      assert %{"error" => "User with given email not found"} = json_response(conn, 404)
    end

    test "successfully sets a user as admin", %{conn: conn} do
      admin = create_user(%{admin: true})
      conn = auth_conn(conn, admin)

      target = create_user(%{admin: false})

      conn =
        put(conn, "/auth/api/v1/admins", %{
          "email" => target.email,
          "is_admin" => true
        })

      assert %{"message" => "Successfully set a new admin!"} =
               json_response(conn, 200)

      assert Auth.Accounts.get_user!(target.id).admin == true
    end

    test "successfully removes admin from a user", %{conn: conn} do
      admin = create_user(%{admin: true})
      conn = auth_conn(conn, admin)

      target = create_user(%{admin: true})

      conn =
        put(conn, "/auth/api/v1/admins", %{
          "email" => target.email,
          "is_admin" => false
        })

      assert %{"message" => "Successfully removed admin!"} =
               json_response(conn, 200)

      assert Auth.Accounts.get_user!(target.id).admin == false
    end
  end
end
