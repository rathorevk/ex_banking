defmodule ExBanking do
  @moduledoc """
  ExBanking keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias ExBanking.Types.{Account, User}
  alias ExBanking.Users
  alias ExBanking.Validators

  import ExBanking.Utils, only: [get_user: 2]

  @doc """
  Creates a user.

  ## Examples

      iex> create_user("John Doe")
      :ok

      iex> create_user(123)
      {:error, :wrong_arguments}
  """
  @spec create_user(user :: User.name()) ::
          :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    with :ok <- Validators.validate_user(user),
         :ok <- Users.create(user) do
      :ok
    else
      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Allows users to deposit funds into their bank account.

  Returns updated user balance.

  ## Examples

      iex> deposit("John Doe", 500.5, "USD")
      {:ok, 10.5}

      iex> deposit(nil, 500.5, "USD")
      {:error, :wrong_arguments}
  """
  @spec deposit(user_name :: User.name(), amount :: amount, currency :: Account.currency()) ::
          {:ok, balance}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
        when amount: float() | non_neg_integer(), balance: Account.balance()
  def deposit(user, amount, currency) do
    with :ok <- Validators.validate_user(user),
         :ok <- Validators.validate_account(currency, amount),
         {:ok, _user} <- Users.get_user(user),
         {:ok, balance} <- Users.deposit(user, amount, currency) do
      {:ok, balance}
    else
      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Allows users to withdraw funds from their bank account.

  Returns updated user balance.

  ## Examples

      iex> withdraw("John Doe", 100.5, "USD")
      {:ok, 400.5}

      iex> withdraw("John Doe", 1000.5, "USD")
      {:error, :not_enough_money}
  """
  @spec withdraw(user_name :: User.name(), amount :: amount, currency :: Account.currency()) ::
          {:ok, balance}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
        when amount: float() | non_neg_integer(), balance: Account.balance()
  def withdraw(user, amount, currency) do
    with :ok <- Validators.validate_user(user),
         :ok <- Validators.validate_account(currency, amount),
         {:ok, _user} <- Users.get_user(user),
         {:ok, balance} <- Users.withdraw(user, amount, currency) do
      {:ok, balance}
    else
      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Retrieves the current balance of the user's bank account in the given Currency.

  ## Examples

      iex> get_balance("John Doe", 10.5, "USD")
      {:ok,

      iex> get_balance(nil, 10.5, "USD")
      {:error, :wrong_arguments}
  """
  @spec get_balance(user :: User.name(), currency :: Account.currency()) ::
          {:ok, balance}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
        when balance: Account.balance()
  def get_balance(user, currency) do
    with :ok <- Validators.validate_user(user),
         :ok <- Validators.validate_account(currency),
         {:ok, _user} <- Users.get_user(user),
         {:ok, balance} <- Users.get_balance(user, currency) do
      {:ok, balance}
    else
      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Allows users to send money from one account to another.

  Returns updated balances of sender and receiver.

  ## Examples

      iex> send("John Doe", "Joseph", 10, "USD")
      {:ok, 390, 10}

      iex> send("John Doe",  "Joseph", 100.5, "USD")
      {:error, :not_enough_money}
  """
  @spec send(
          from_user :: User.name(),
          to_user :: User.name(),
          amount :: amount,
          currency :: Account.currency()
        ) ::
          {:error,
           :wrong_arguments
           | :not_enough_money
           | :receiver_does_not_exist
           | :sender_does_not_exist
           | :too_many_requests_to_sender
           | :too_many_requests_to_receiver}
          | {:ok, from_user_balance, to_user_balance}
        when amount: float() | non_neg_integer(),
             from_user_balance: Account.balance(),
             to_user_balance: Account.balance()
  def send(from_user, to_user, amount, currency) do
    with :ok <- Validators.validate_user(from_user),
         :ok <- Validators.validate_user(to_user),
         :ok <- Validators.validate_account(currency, amount),
         {:ok, _user} <- get_user(from_user, :sender),
         {:ok, _user} <- get_user(to_user, :receiver),
         {:ok, from_user_balance} <- Users.withdraw(from_user, amount, currency),
         {:ok, to_user_balance} <- Users.deposit(to_user, amount, currency) do
      {:ok, from_user_balance, to_user_balance}
    else
      {:error, _reason} = error ->
        error
    end
  end
end
