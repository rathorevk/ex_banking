defmodule ExBanking.Types.User do
  @moduledoc false

  defstruct [:name]

  @type t :: %__MODULE__{
          name: String.t()
        }
end
