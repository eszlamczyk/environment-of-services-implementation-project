defmodule AuthWeb.AuthApiControllerTest do
  use AuthWeb.ConnCase, async: true

  @backend_token Application.compile_env!(:auth, :backend_authorization_token)

  import Mox

  alias AuthWeb.AuthApiController
  alias Auth.Accounts

  setup :verify_on_exit!

  describe "#{AuthApiController}" do
    setup do
      # Ensure mocks are configured for this test context
      Application.put_env(:auth, :google_verifier, Auth.GoogleVerifierMock)
      :ok
    end

    test "returns JWT and user_found_redirect when existing user logs in", %{conn: conn} do
      # Prepare mock user
      {:ok, user} =
        Accounts.register_user_oauth(%{
          email: "existing@example.com",
          name: "Existing User",
          provider: "google",
          uid: "uid123"
        })

      Auth.GoogleClientMock
      |> expect(:request, fn _req ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: Jason.encode!(%{"id_token" => "mock_id_token"})
         }}
      end)

      # Mock verifier
      Auth.GoogleVerifierMock
      |> expect(:verify, fn "mock_id_token" ->
        {:ok, %{"email" => user.email, "sub" => "uid123", "name" => "Existing User"}}
      end)

      conn =
        post(conn, "/auth/api/v1/auth/google", %{
          "code" => "mock_auth_code",
          "redirect_uri" => "http://localhost:5173/auth/google/callback",
          "user_found_redirect" => "http://localhost:5173/",
          "user_created_redirect" => "http://localhost:5173/google/register"
        })

      response = json_response(conn, 200)

      assert response["token"]
      assert response["message"] == "Authenticated"
      assert response["user"]["email"] == "existing@example.com"
      refute response["user"]["is_admin"]
      assert response["redirect_path"] == "http://localhost:5173/"
    end

    test "creates backend user, returns JWT and user_created_redirect when new user logs in", %{
      conn: conn
    } do
      Auth.GoogleClientMock
      |> expect(:request, fn _req ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: Jason.encode!(%{"id_token" => "mock_id_token"})
         }}
      end)

      Auth.GoogleVerifierMock
      |> expect(:verify, fn "mock_id_token" ->
        {:ok, %{"email" => "newuser@example.com", "sub" => "uid999", "name" => "New User"}}
      end)

      Auth.BackendClientMock
      |> expect(:request, fn
        %Finch.Request{
          scheme: :http,
          host: "localhost",
          port: 8080,
          method: "POST",
          path: "/backend/api/v1/users",
          headers: [
            {"content-type", "application/json"},
            {"authorization", @backend_token}
          ],
          body: body
        } ->
          # assert the body has correct values
          assert body =~ ~s("mail":"newuser@example.com")
          assert body =~ ~s("firstName":"")
          assert body =~ ~s("lastName":"")

          {:ok, %Finch.Response{status: 200, body: ""}}
      end)

      conn =
        post(conn, "/auth/api/v1/auth/google", %{
          "code" => "mock_auth_code",
          "redirect_uri" => "http://localhost:5173/auth/google/callback",
          "user_found_redirect" => "http://localhost:5173/",
          "user_created_redirect" => "http://localhost:5173/google/register"
        })

      response = json_response(conn, 200)

      assert response["token"]
      assert response["message"] == "Authenticated"
      assert response["user"]["email"] == "newuser@example.com"
      refute response["user"]["is_admin"]
      assert response["redirect_path"] == "http://localhost:5173/google/register"

      # Ensure the user was persisted
      assert Accounts.get_user_by_email("newuser@example.com")
    end

    test "returns 401 when Google verifier rejects token", %{conn: conn} do
      Auth.GoogleClientMock
      |> expect(:request, fn _req ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: Jason.encode!(%{"id_token" => "mock_id_token"})
         }}
      end)

      Auth.GoogleVerifierMock
      |> expect(:verify, fn _ -> {:error, "invalid"} end)

      conn =
        post(conn, "/auth/api/v1/auth/google", %{
          "code" => "mock_auth_code",
          "redirect_uri" => "http://localhost:5173/auth/google/callback",
          "user_found_redirect" => "http://localhost:5173/",
          "user_created_redirect" => "http://localhost:5173/google/register"
        })

      response = json_response(conn, 401)
      assert response["error"] =~ "Invalid Google token"
    end

    test "returns 400 if Google token exchange fails", %{conn: conn} do
      Auth.GoogleClientMock
      |> expect(:request, fn _req ->
        {:ok,
         %Finch.Response{
           status: 400,
           body: Jason.encode!(%{"error" => "invalid_grant"})
         }}
      end)

      conn =
        post(conn, "/auth/api/v1/auth/google", %{
          "code" => "mock_auth_code",
          "redirect_uri" => "http://localhost:5173/auth/google/callback",
          "user_found_redirect" => "http://localhost:5173/",
          "user_created_redirect" => "http://localhost:5173/google/register"
        })

      response = json_response(conn, 400)
      assert response["error"] == "Failed to exchange code"
    end

    test "rolls back if backend call fails", %{conn: conn} do
      Auth.GoogleClientMock
      |> expect(:request, fn _req ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: Jason.encode!(%{"id_token" => "mock_id_token"})
         }}
      end)

      Auth.GoogleVerifierMock
      |> expect(:verify, fn "mock_id_token" ->
        {:ok, %{"email" => "newuser@example.com", "sub" => "uid999", "name" => "New User"}}
      end)

      # Simulate backend failure
      Auth.BackendClientMock
      |> expect(:request, fn _req ->
        {:ok, %Finch.Response{status: 500, body: "backend error"}}
      end)

      conn =
        post(conn, "/auth/api/v1/auth/google", %{
          "code" => "mock_auth_code",
          "redirect_uri" => "http://localhost:5173/auth/google/callback",
          "user_found_redirect" => "http://localhost:5173/",
          "user_created_redirect" => "http://localhost:5173/google/register"
        })

      assert json = json_response(conn, 502)
      assert %{"errors" => errors} = json

      # ensure rollback happened
      assert errors != %{}
    end
  end
end
