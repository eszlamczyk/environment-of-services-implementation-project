defmodule Auth.GoogleVerifier do
  @moduledoc """
    Abstraction for google verifier
  """
  @callback verify(String.t()) :: {:ok, map()} | {:error, String.t()}
end

defmodule Auth.GoogleVerifier.Real do
  @moduledoc false
  @behaviour Auth.GoogleVerifier

  def aud do
    Application.get_env(:auth, :google_oauth)[:client_id]
  end

  def verify(id_token) do
    # Google has an endpoint we can call to validate tokens
    url = "https://oauth2.googleapis.com/tokeninfo?id_token=#{id_token}"

    case HTTPoison.get(url, [], hackney: [:insecure]) do
      {:ok, %{status_code: 200, body: body}} ->
        data = Jason.decode!(body)
        # Check for "exp" in the future
        if data["aud"] == aud() do
          {:ok, data}
        else
          {:error, "Token audience mismatch"}
        end

      _ ->
        {:error, "Verification failed"}
    end
  end
end
