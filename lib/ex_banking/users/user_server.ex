defmodule ExBanking.Users.Server do
  @moduledoc """
  This module serves as a GenServer for managing user accounts related operations
  within the application.
  """
  use GenServer, restart: :transient

  alias ExBanking.Types.{Account, User}

  import ExBanking.Utils, only: [to_float: 1]

  require Logger

  defmodule State do
    @moduledoc false
    defstruct user: nil, accounts: %{}
  end

  #########################################################################
  # Public APIs
  #########################################################################

  @spec start_link([{:user, User.name()}, ...]) :: GenServer.on_start()
  def start_link(user: user_name) do
    Logger.info("Starting user: #{user_name} server")
    GenServer.start_link(__MODULE__, user_name, name: via_tuple(user_name))
  end

  @spec get_user(user_name :: User.name()) :: User.t()
  def get_user(user_name) do
    GenServer.call(via_tuple(user_name), :get_user)
  end

  @spec get_accounts(user_name :: User.name()) :: [Account.t()]
  def get_accounts(user_name) do
    GenServer.call(via_tuple(user_name), :get_accounts)
  end

  @spec get_balance(user_name :: User.name(), currency :: Account.currency()) :: balance
        when balance: Account.balance()
  def get_balance(user_name, currency) do
    GenServer.call(via_tuple(user_name), {:get_balance, currency})
  end

  @spec deposit(user_name :: User.name(), amount :: amount, currency :: Account.currency()) ::
          balance
        when amount: float() | non_neg_integer(), balance: Account.balance()
  def deposit(user_name, amount, currency) do
    GenServer.call(via_tuple(user_name), {:deposit, amount, currency})
  end

  @spec withdraw(user_name :: User.name(), amount :: amount, currency :: Account.currency()) ::
          {:error, :not_enough_money} | balance
        when amount: float() | non_neg_integer(), balance: Account.balance()
  def withdraw(user_name, amount, currency) do
    GenServer.call(via_tuple(user_name), {:withdraw, amount, currency})
  end

  @spec stop(user_name :: User.name()) :: :ok
  def stop(user_name) do
    GenServer.stop(via_tuple(user_name))
  end

  #########################################################################
  # Callbacks
  #########################################################################

  @impl true
  def init(user_name) do
    Logger.info("Init user: #{user_name} ...")

    {:ok, %State{user: %User{name: user_name}}}
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
    Logger.info("Received deposit request for user: #{state.user.name} in #{currency}
      with amount #{amount}")

    # get balance if doesn't have account in the given currency returns 0.0 balance
    balance = get_in(accounts, [currency, Access.key(:balance)]) || 0.0
    updated_balance = to_float(balance + amount)

    # update account and accounts
    updated_account = %Account{currency: currency, balance: updated_balance}
    updated_accounts = Map.put(accounts, currency, updated_account)

    {:reply, updated_balance, %{state | accounts: updated_accounts}}
  end

  def handle_call({:withdraw, amount, currency}, _from, %State{accounts: accounts} = state) do
    user_name = state.user.name

    Logger.info("Received withdrawal request for user: #{user_name} in #{currency}
      with amount #{amount}")

    account = Map.get(accounts, currency, %Account{currency: currency})

    case enough_balance?(account, amount) do
      true ->
        updated_balance = to_float(account.balance - amount)
        updated_account = %Account{currency: currency, balance: updated_balance}

        updated_accounts = Map.put(accounts, currency, updated_account)
        {:reply, updated_balance, %{state | accounts: updated_accounts}}

      false ->
        Logger.warning("Insufficient funds in user: #{user_name} account: #{currency} with
          balance: #{account.balance} and withdraw amount: #{amount}")
        {:reply, {:error, :not_enough_money}, state}
    end
  end

  #########################################################################
  # Private Functions
  #########################################################################
  defp enough_balance?(%Account{balance: balance}, withdraw_amount),
    do: balance >= withdraw_amount

  # To register user in the UserRegistry
  defp via_tuple(user) do
    {:via, Registry, {ExBanking.UserRegistry, user}}
  end
end
