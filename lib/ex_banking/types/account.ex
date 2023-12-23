defmodule ExBanking.Types.Account do
  @moduledoc false
  use Domo

  alias ExBanking.Currencies

  defmodule Currency do
    @moduledoc false
    use Domo

    defstruct [:name]

    @type name :: String.t()

    @type t :: %__MODULE__{
            name: String.t()
          }
  end

  defstruct [:currency, balance: 0.0]

  @type currency :: Currency.t()
  precond(currency: &(&1 in Currencies.list()))

  @type balance :: float()
  precond(balance: &(&1 >= 0.0))

  @type t :: %__MODULE__{
          currency: currency(),
          balance: balance()
        }

  @spec validate(Currency.t(), balance() | non_neg_integer()) ::
          :ok | {:error, :wrong_arguments}
  def validate(currency, balance \\ 0.0) do
    %__MODULE__{currency: %Currency{name: currency}, balance: to_float(balance)}
    |> ensure_type()
    |> case do
      {:ok, _account} -> :ok
      {:error, _reason} -> {:error, :wrong_arguments}
    end
  end

  defp to_float(number) when is_integer(number) do
    :erlang.float(number)
  end

  defp to_float(number), do: number
end
