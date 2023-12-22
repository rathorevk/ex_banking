defmodule ExBanking.Users do
  @moduledoc """
  The Users context.
  """

  alias ExBanking.Types.Account
  alias ExBanking.Types.User
  alias ExBanking.Users.Server, as: UserServer
  alias ExBanking.Users.Supervisor, as: UserSupervisor

  @spec create(User.name()) :: :ok
  def create(username) do
    {:ok, _child} = UserSupervisor.start_child(user: username)
    :ok
  end

  @spec deposit(User.name(), Account.balance(), Account.currency()) ::
          {:ok, Account.balance()}
  def deposit(username, amount, currency) do
    {:ok, UserServer.deposit(username, amount, currency)}
  end

  @spec withdraw(User.name(), Account.balance(), Account.currency()) ::
          {:ok, Account.balance()} | {:error, :not_enough_money}
  def withdraw(username, amount, currency) do
    with balance when is_number(balance) <- UserServer.withdraw(username, amount, currency) do
      {:ok, balance}
    else
      {:error, _reason} = error -> error
    end
  end

  @spec user_exists?(User.name()) :: boolean()
  def user_exists?(user) do
    case Registry.lookup(ExBanking.UserRegistry, user) do
      [] -> false
      [{_, _}] -> true
    end
  end

  @spec get_balance(User.name(), Account.currency()) ::
          {:ok, Account.balance()}
  def get_balance(username, currency) do
    {:ok, UserServer.get_balance(username, currency)}
  end
end
