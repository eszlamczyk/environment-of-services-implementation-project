defmodule Auth.BackendClient.Real do
  @moduledoc """
  Implementation of backend client, uses Finch for HTTP requests
  """
  @behaviour Auth.BackendClient

  def request(req) do
    Finch.request(req, Auth.Finch)
  end
end
