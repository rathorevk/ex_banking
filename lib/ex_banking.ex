defmodule ExBanking do
  @moduledoc """
  ExBanking keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias ExBanking.Types.User
  alias ExBanking.Users

  @spec create_user(User.name()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_binary(user) do
    with false <- Users.user_exists?(user) do
      Users.create(user)
    else
      true ->
        {:error, :user_already_exists}
    end
  end

  def create_user(_user), do: {:error, :wrong_arguments}

  @spec deposit(User.name(), Account.balance(), Account.currency()) ::
          {:ok, Account.balance()} | {:error, :wrong_arguments | :user_does_not_exist}
  def deposit(user, amount, currency)
      when is_binary(user) and is_number(amount) and is_binary(currency) do
    with {:user_exists, true} <- {:user_exists, Users.user_exists?(user)},
         {:ok, balance} <- Users.deposit(user, amount, currency) do
      {:ok, balance}
    else
      {:user_exists, false} ->
        {:error, :user_does_not_exist}

      {:error, _reason} = error ->
        error
    end
  end

  def deposit(_user, _amount, _currency), do: {:error, :wrong_arguments}

  @spec withdraw(User.name(), Account.balance(), Account.currency()) ::
          {:ok, Account.balance()}
          | {:error, :wrong_arguments | :user_does_not_exist | :not_enough_money}
  def withdraw(user, amount, currency)
      when is_binary(user) and is_number(amount) and is_binary(currency) do
    with {:user_exists, true} <- {:user_exists, Users.user_exists?(user)},
         {:ok, balance} <- Users.withdraw(user, amount, currency) do
      {:ok, balance}
    else
      {:user_exists, false} ->
        {:error, :user_does_not_exist}

      {:error, _reason} = error ->
        error
    end
  end

  def withdraw(_user, _amount, _currency), do: {:error, :wrong_arguments}

  @spec get_balance(User.name(), Account.currency()) ::
          {:ok, Account.balance()} | {:error, :wrong_arguments | :user_does_not_exist}
  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    with {:user_exists, true} <- {:user_exists, Users.user_exists?(user)},
         {:ok, balance} <- Users.get_balance(user, currency) do
      {:ok, balance}
    else
      {:user_exists, false} ->
        {:error, :user_does_not_exist}

      {:error, _reason} = error ->
        error
    end
  end

  def get_balance(_user, _currency), do: {:error, :wrong_arguments}

  @spec send(User.name(), User.name(), Account.balance(), Account.currency()) ::
          {:error,
           :wrong_arguments
           | :not_enough_money
           | :receiver_does_not_exist
           | :sender_does_not_exist}
          | {:ok, Account.balance(), Account.balance()}
  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and is_binary(to_user) and is_number(amount) and
             is_binary(currency) do
    with {:user_exists_sender, true} <- {:user_exists_sender, Users.user_exists?(from_user)},
         {:user_exists_receiver, true} <- {:user_exists_receiver, Users.user_exists?(to_user)},
         {:ok, f_balance} <- Users.withdraw(from_user, amount, currency),
         {:ok, d_balance} <- Users.deposit(to_user, amount, currency) do
      {:ok, f_balance, d_balance}
    else
      {:user_exists_sender, false} ->
        {:error, :sender_does_not_exist}

      {:user_exists_receiver, false} ->
        {:error, :receiver_does_not_exist}

      {:error, _reason} = error ->
        error
    end
  end

  def send(_from_user, _to_user, _amount, _currency), do: {:error, :wrong_arguments}
end
