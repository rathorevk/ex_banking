defmodule ExBanking.Currencies do
  @moduledoc false
  use GenServer

  alias ExBanking.Types.Account.Currency

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_currency(ccy) when is_binary(ccy) do
    GenServer.call(__MODULE__, {:add, ccy})
  end

  def add_currency(_ccy), do: {:error, :wrong_arguments}

  def list do
    GenServer.call(__MODULE__, :list)
  end

  def init(_init_arg) do
    currencies =
      Application.get_env(:ex_banking, :currencies, [])
      |> Enum.map(fn ccy -> {ccy, %Currency{name: ccy}} end)
      |> Map.new()

    {:ok, %{currencies: currencies}}
  end

  def handle_call({:add, ccy}, _from, %{currencies: currencies} = state) do
    case currencies[ccy] do
      nil ->
        currencies = Map.put(currencies, ccy, %Currency{name: ccy})
        {:reply, :ok, %{state | currencies: currencies}}

      _old_ccy ->
        {:reply, {:error, :currency_already_exists}, state}
    end
  end

  def handle_call(:list, _from, %{currencies: currencies} = state) do
    {:reply, Map.values(currencies), state}
  end
end
