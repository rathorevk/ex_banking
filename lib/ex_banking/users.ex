defmodule ExBanking.Users do
  @moduledoc """
  This module provides a context for handling user-related operations.
  """

  alias ExBanking.Types.{Account, User}
  alias ExBanking.Users.Server, as: UserServer
  alias ExBanking.Users.Supervisor, as: UserSupervisor

  @spec create(username :: User.name()) :: :ok
  def create(username) do
    case lookup(username) do
      [{_pid, _value}] ->
        {:error, :user_already_exists}

      [] ->
        {:ok, _child} = UserSupervisor.start_child(user: username)
        :ok
    end
  end

  @spec deposit(user_name :: User.name(), amount :: amount, currency :: Account.currency()) ::
          {:ok, balance}
        when amount: float() | non_neg_integer(), balance: Account.balance()
  def deposit(username, amount, currency) do
    {:ok, UserServer.deposit(username, amount, currency)}
  end

  @spec withdraw(user_name :: User.name(), amount :: amount, currency :: Account.currency()) ::
          {:error, :not_enough_money} | {:ok, balance}
        when amount: float() | non_neg_integer(), balance: Account.balance()
  def withdraw(username, amount, currency) do
    case UserServer.withdraw(username, amount, currency) do
      {:error, _reason} = error -> error
      balance when is_float(balance) -> {:ok, balance}
    end
  end

  @spec get_user(username :: User.name()) ::
          {:error, :user_does_not_exist | :too_many_requests_to_user} | {:ok, user :: User.t()}
  def get_user(username) do
    case lookup(username) do
      [] ->
        {:error, :user_does_not_exist}

      [{pid, _value}] ->
        ## checking request-count
        case UserServer.request_allowed?(pid) do
          true -> {:ok, %User{name: username}}
          false -> {:error, :too_many_requests_to_user}
        end
    end
  end

  @spec get_balance(user_name :: User.name(), currency :: Account.currency()) ::
          {:ok, Account.balance()}
  def get_balance(username, currency) do
    {:ok, UserServer.get_balance(username, currency)}
  end

  @spec delete_user(username :: User.name()) :: :ok
  def delete_user(username) do
    case lookup(username) do
      [{_pid, _value}] -> UserServer.stop(username)
      [] -> :ok
    end
  end

  defp lookup(user) do
    Registry.lookup(ExBanking.UserRegistry, user)
  end
end
