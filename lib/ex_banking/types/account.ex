defmodule ExBanking.Types.Account do
  @moduledoc false
  use Domo

  defstruct [:currency, balance: 0.0]

  @type currency :: String.t()

  @type balance :: float()
  precond(balance: &(&1 >= 0.0))

  @type t :: %__MODULE__{
          currency: currency(),
          balance: balance()
        }

  @spec validate(currency(), balance() | non_neg_integer()) ::
          :ok | {:error, :wrong_arguments}
  def validate(currency, balance \\ 0.0) do
    %__MODULE__{currency: currency, balance: to_float(balance)}
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
