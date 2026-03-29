defmodule AuthWeb.DeleteAccountControllerTest do
  use AuthWeb.ConnCase, async: true

  import Mox
  alias Auth.Accounts.User
  alias Auth.Repo

  setup :verify_on_exit!

  describe "DELETE /auth/api/v1/users/delete_account (authenticated)" do
    setup %{conn: conn} do
      {:ok, user} =
        %User{}
        |> User.registration_changeset(%{
          email: "test@example.com",
          password: "supersecret123"
        })
        |> Repo.insert()

      token = Auth.User.Auth.generate_jwt(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")

      %{conn: conn, user: user}
    end

    test "successfully deletes account when backend responds with 200", %{conn: conn, user: user} do
      Auth.BackendClientMock
      |> expect(:request, fn _req ->
        {:ok, %Finch.Response{status: 200, body: ""}}
      end)

      conn = delete(conn, ~p"/auth/api/v1/users/delete_account")

      assert json_response(conn, 200)["message"] == "Account deleted successfully"

      db_user = Repo.get(User, user.id)
      assert db_user.deleted == true
      assert String.contains?(db_user.email, "+deleted-")
    end

    test "returns 401 when unauthenticated" do
      conn = build_conn() |> delete(~p"/auth/api/v1/users/delete_account")
      assert json_response(conn, 401)["error"] == "Unauthorized"
    end

    test "returns 500 and rolls back when backend fails", %{conn: conn, user: user} do
      Auth.BackendClientMock
      |> expect(:request, fn _req ->
        {:ok, %Finch.Response{status: 500, body: "Backend failure"}}
      end)

      conn = delete(conn, ~p"/auth/api/v1/users/delete_account")

      assert json_response(conn, 500)["errors"] == "Backend failure"

      # Verify rollback — user still exists and not marked deleted
      db_user = Repo.get(User, user.id)
      refute db_user.deleted
      refute String.contains?(db_user.email, "+deleted-")
    end
  end
end
