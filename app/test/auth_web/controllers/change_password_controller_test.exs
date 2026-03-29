defmodule AuthWeb.ChangePasswordControllerTest do
  use AuthWeb.ConnCase, async: true

  alias Auth.Accounts.User
  alias Auth.Repo

  @valid_new_password "new_secure_password"
  @short_password "123"

  describe "PUT /users/update_password (authenticated)" do
    setup %{conn: conn} do
      {:ok, user} =
        %User{}
        |> User.registration_changeset(%{email: "test@example.com", password: "old_password"})
        |> Repo.insert()

      # Generate JWT token
      token = Auth.User.Auth.generate_jwt(user)

      # Assign auth header
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")

      %{conn: conn, user: user}
    end

    test "successfully changes password", %{conn: conn, user: user} do
      attrs = %{
        "current_password" => "old_password",
        "password" => @valid_new_password,
        "password_confirmation" => @valid_new_password
      }

      conn = put(conn, ~p"/auth/api/v1/users/update_password", attrs)
      assert json_response(conn, 200)["message"] == "Password Changed Successfully"

      # Ensure the password is actually updated in the database
      user = Repo.get!(User, user.id)
      assert Auth.Accounts.get_user_by_email_and_password(user.email, @valid_new_password)
    end

    test "fails when current password is wrong", %{conn: conn} do
      attrs = %{
        "current_password" => "wrong_password",
        "password" => @valid_new_password,
        "password_confirmation" => @valid_new_password
      }

      conn = put(conn, ~p"/auth/api/v1/users/update_password", attrs)
      assert %{"errors" => %{"current_password" => ["is not valid"]}} = json_response(conn, 422)
    end

    test "fails when password confirmation does not match", %{conn: conn} do
      attrs = %{
        "current_password" => "old_password",
        "password" => @valid_new_password,
        "password_confirmation" => "mismatch"
      }

      conn = put(conn, ~p"/auth/api/v1/users/update_password", attrs)

      assert %{"errors" => %{"password_confirmation" => ["does not match password"]}} =
               json_response(conn, 422)
    end

    test "fails when new password is too short", %{conn: conn} do
      attrs = %{
        "current_password" => "old_password",
        "password" => @short_password,
        "password_confirmation" => @short_password
      }

      conn = put(conn, ~p"/auth/api/v1/users/update_password", attrs)

      assert %{"errors" => %{"password" => ["should be at least 6 character(s)"]}} =
               json_response(conn, 422)
    end

    test "rejects unauthenticated request", %{user: _user} do
      conn = build_conn() |> put(~p"/auth/api/v1/users/update_password", %{})
      assert json_response(conn, 401)["error"] == "Unauthorized"
    end
  end
end
