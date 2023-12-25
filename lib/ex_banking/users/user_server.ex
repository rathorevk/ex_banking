defmodule ExBanking.Users.Server do
  @moduledoc false
  use GenServer, restart: :transient

  alias ExBanking.Types.Account
  alias ExBanking.Types.User

  import ExBanking.Utils, only: [to_float: 1]

  defmodule State do
    defstruct user: nil, accounts: %{}
  end

  def start_link(user: user_name) do
    GenServer.start_link(__MODULE__, user_name, name: via_tuple(user_name))
  end

  def get_user(user_name) do
    GenServer.call(via_tuple(user_name), :get_user)
  end

  def get_accounts(user_name) do
    GenServer.call(via_tuple(user_name), :get_accounts)
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

  def stop(user_name) do
    GenServer.stop(via_tuple(user_name), :normal)
  end

  @impl true
  def init(user_name) do
    user = %User{name: user_name}
    {:ok, %State{user: user}}
  end

  @impl true
  def handle_call(:get_user, _from, state) do
    {:reply, state.user, state}
  end

  def handle_call(:get_accounts, _from, state) do
    {:reply, Map.values(state.accounts), state}
  end

  def handle_call({:get_balance, currency}, _from, %State{accounts: accounts} = state) do
    balance = get_in(accounts, [currency, Access.key(:balance)]) || 0.0

    {:reply, to_float(balance), state}
  end

  def handle_call({:deposit, amount, currency}, _from, %State{accounts: accounts} = state) do
    new_balance =
      case accounts[currency] do
        nil -> amount
        %Account{balance: balance} -> balance + amount
      end

    accounts =
      Map.put(accounts, currency, %Account{currency: currency, balance: new_balance})

    state = %{state | accounts: accounts}
    {:reply, to_float(new_balance), state}
  end

  def handle_call({:withdraw, amount, currency}, _from, %State{accounts: accounts} = state) do
    account = accounts[currency]

    with true <- enough_balance?(account, amount) do
      new_balance = to_float(account.balance - amount)

      accounts = Map.put(accounts, currency, %Account{currency: currency, balance: new_balance})
      state = %{state | accounts: accounts}
      {:reply, to_float(new_balance), state}
    else
      false ->
        {:reply, {:error, :not_enough_money}, state}
    end
  end

  defp enough_balance?(%Account{balance: balance}, deduct_amount)
       when deduct_amount <= balance,
       do: true

  defp enough_balance?(_account, _deduct_amount), do: false

  # To register user in the UserRegistry
  defp via_tuple(user) do
    {:via, Registry, {ExBanking.UserRegistry, user}}
  end
end
