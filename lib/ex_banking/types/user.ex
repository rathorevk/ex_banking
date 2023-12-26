defmodule ExBanking.Types.User do
  @moduledoc """
  This module defines the `User` struct and provides a validator function
  for ensuring the integrity of user data.
  """
  use Domo

  defstruct name: ""

  #########################################################################
  # Types
  #########################################################################
  @type name :: String.t()

  @type t :: %__MODULE__{
          name: name()
        }

  #########################################################################
  # Public APIs
  #########################################################################
  @spec validate(username :: name()) :: :ok | {:error, :wrong_arguments}
  def validate(username) do
    %__MODULE__{name: username}
    |> ensure_type()
    |> case do
      {:ok, _user} -> :ok
      {:error, _reason} -> {:error, :wrong_arguments}
    end
  end
end
