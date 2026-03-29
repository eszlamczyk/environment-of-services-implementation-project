ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Auth.Repo, :manual)

Mox.defmock(Auth.GoogleVerifierMock, for: Auth.GoogleVerifier)
Application.put_env(:auth, :google_verifier, Auth.GoogleVerifierMock)

Mox.defmock(Auth.BackendClientMock, for: Auth.BackendClient)
Application.put_env(:auth, :backend_client, Auth.BackendClientMock)

Mox.defmock(Auth.GoogleClientMock, for: Auth.GoogleClient)
Application.put_env(:auth, :google_client, Auth.GoogleClientMock)
