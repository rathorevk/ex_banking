defmodule ExBanking.Types.Account do
  @moduledoc false

  defstruct [:currency, :balance]

  @type t :: %__MODULE__{
          currency: String.t(),
          balance: Float.t()
        }
end
