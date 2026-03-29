defmodule AuthWeb.Router do
  alias Auth.User

  use AuthWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :auth_api do
    plug(:accepts, ["json"])
    plug(User.Auth, :fetch_api_user)
  end

  scope "/auth", AuthWeb do
    pipe_through :api

    get "/health", HealthController, :index
  end

  scope "/auth/api/v1", AuthWeb do
    pipe_through(:api)

    post "/auth/google", AuthApiController, :google_auth
    post "/users/register", UserRegistrationController, :create
    post "/users/login", UserSessionController, :create
    delete "/users/logout", UserSessionController, :delete
  end

  scope "/auth/api/v1", AuthWeb do
    pipe_through(:auth_api)

    get "/token/verify", TokenController, :verify
    put "/users/update_password", ChangePasswordController, :change_password
    delete "/users/delete_account", DeleteAccountController, :delete_account
  end

  scope "/auth/api/v1/admins", AuthWeb do
    pipe_through(:auth_api)

    get "/", AdminsController, :list_admins
    put "/", AdminsController, :set_admin
  end
end
