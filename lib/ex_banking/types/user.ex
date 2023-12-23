defmodule ExBanking.Types.User do
  @moduledoc false
  use Domo

  defstruct [:name]

  @type name :: String.t()

  @type t :: %__MODULE__{
          name: name()
        }

  @spec validate(name()) :: :ok | {:error, :wrong_arguments}
  def validate(name) do
    %__MODULE__{name: name}
    |> ensure_type()
    |> case do
      {:ok, _user} -> :ok
      {:error, _reason} -> {:error, :wrong_arguments}
    end
  end
end
