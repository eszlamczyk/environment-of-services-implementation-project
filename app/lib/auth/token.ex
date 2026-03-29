defmodule Auth.Token do
  @moduledoc """
  Base module for Joken, currently there is no config, but during config it might be required to create
  custom signer to protect from forging
  """

  use Joken.Config
end
