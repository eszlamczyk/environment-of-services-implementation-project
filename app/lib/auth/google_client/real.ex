defmodule Auth.GoogleClient.Real do
  @moduledoc """
  Implementation of google client, uses Finch for HTTP requests
  """
  @behaviour Auth.GoogleClient

  def request(req) do
    Finch.request(req, Auth.Finch)
  end
end
