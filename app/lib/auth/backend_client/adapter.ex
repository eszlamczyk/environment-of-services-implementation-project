defmodule Auth.BackendClient.Adapter do
  @moduledoc """
  Module used for calling the mock adapter
  """

  def request(req) do
    impl().request(req)
  end

  defp impl do
    Application.get_env(:auth, :backend_client, Auth.BackendClient.Real)
  end
end
