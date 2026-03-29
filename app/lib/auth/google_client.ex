defmodule Auth.GoogleClient do
  @moduledoc false

  @callback request(Finch.Request.t()) ::
              {:ok, Finch.Response.t()} | {:error, term()}
end
