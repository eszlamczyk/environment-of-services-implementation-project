defmodule Auth.GoogleClient.Adapter do
  @moduledoc """
  Module used for calling the mock adapter
  """

  def request(req) do
    impl().request(req)
  end

  defp impl do
    Application.get_env(:auth, :google_client, Auth.GoogleClient.Real)
  end
end
