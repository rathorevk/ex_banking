defmodule ExBanking.Users.Server do
  @moduledoc false
  use GenServer

  alias ExBanking.Types.Account
  alias ExBanking.Types.User

  defmodule State do
    defstruct user: nil, accounts: %{}
  end

  def start_link(user: user_name) do
    GenServer.start_link(__MODULE__, user_name, name: via_tuple(user_name))
  end

  def get_user(user_name) do
    GenServer.call(via_tuple(user_name), :get_user)
  end

  def get_balance(user_name, currency) do
    GenServer.call(via_tuple(user_name), {:get_balance, currency})
  end

  def deposit(user_name, amount, currency) do
    GenServer.call(via_tuple(user_name), {:deposit, amount, currency})
  end

  def withdraw(user_name, amount, currency) do
    GenServer.call(via_tuple(user_name), {:withdraw, amount, currency})
  end

  @impl true
  def init(user_name) do
    user = %User{name: user_name}
    {:ok, %State{user: user}}
  end

  @impl true
  def handle_call(:get_user, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get_balance, currency}, _from, %State{accounts: accounts} = state) do
    balance = get_in(accounts, [currency, Access.key(:balance)]) || 0.0

    {:reply, balance, state}
  end

  def handle_call({:deposit, amount, currency}, _from, %State{accounts: accounts} = state) do
    new_balance =
      case accounts[currency] do
        nil -> to_float(amount)
        %Account{balance: balance} -> to_float(balance + amount)
      end

    accounts =
      Map.put(accounts, currency, %Account{currency: currency, balance: new_balance})

    state = %{state | accounts: accounts}
    {:reply, new_balance, state}
  end

  def handle_call({:withdraw, amount, currency}, _from, %State{accounts: accounts} = state) do
    account = accounts[currency]

    with true <- enough_balance?(account, amount) do
      new_balance = to_float(account.balance - amount)

      accounts = Map.put(accounts, currency, %Account{currency: currency, balance: new_balance})
      state = %{state | accounts: accounts}
      {:reply, new_balance, state}
    else
      false ->
        {:reply, {:error, :not_enough_money}, state}
    end
  end

  defp enough_balance?(%Account{balance: balance}, deduct_amount)
       when deduct_amount <= balance,
       do: true

  defp enough_balance?(_account, _deduct_amount), do: false

  defp to_float(balance) when is_integer(balance),
    do: balance |> :erlang.float() |> to_float()

  defp to_float(balance),
    do: Float.round(balance, 2)

  # To register user in the UserRegistry
  defp via_tuple(user) do
    {:via, Registry, {ExBanking.UserRegistry, user}}
  end
end
