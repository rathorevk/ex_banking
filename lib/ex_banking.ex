defmodule ExBanking do
  @moduledoc """
  ExBanking keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias ExBanking.RateLimiter
  alias ExBanking.Users
  alias ExBanking.Validators

  import ExBanking.Utils, only: [get_user: 2, validate_rate_limit: 2]

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
  @spec deposit(User.name(), Account.balance(), Account.currency()) ::
          {:ok, Account.balance()}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency) do
    with :ok <- Validators.validate_user(user),
         :ok <- Validators.validate_account(currency, amount),
         {:ok, _user} <- Users.get_user(user),
         :ok <- RateLimiter.track(user),
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
  @spec withdraw(User.name(), Account.balance(), Account.currency()) ::
          {:error,
           :wrong_arguments
           | :user_does_not_exist
           | :not_enough_money
           | :too_many_requests_to_user}
          | {:ok, Account.balance()}
  def withdraw(user, amount, currency) do
    with :ok <- Validators.validate_user(user),
         :ok <- Validators.validate_account(currency, amount),
         {:ok, _user} <- Users.get_user(user),
         :ok <- RateLimiter.track(user),
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
  @spec get_balance(User.name(), Account.currency()) ::
          {:ok, Account.balance()} | {:error, :wrong_arguments | :user_does_not_exist}
  def get_balance(user, currency) do
    with :ok <- Validators.validate_user(user),
         :ok <- Validators.validate_account(currency),
         {:ok, _user} <- Users.get_user(user),
         :ok <- RateLimiter.track(user),
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
  @spec send(User.name(), User.name(), Account.balance(), Account.currency()) ::
          {:error,
           :wrong_arguments
           | :not_enough_money
           | :receiver_does_not_exist
           | :sender_does_not_exist
           | :too_many_requests_to_sender
           | :too_many_requests_to_receiver}
          | {:ok, Account.balance(), Account.balance()}
  def send(from_user, to_user, amount, currency) do
    with :ok <- Validators.validate_user(from_user),
         :ok <- Validators.validate_user(to_user),
         :ok <- Validators.validate_account(currency, amount),
         {:ok, _user} <- get_user(from_user, :sender),
         {:ok, _user} <- get_user(to_user, :receiver),
         :ok <- validate_rate_limit(from_user, :sender),
         :ok <- validate_rate_limit(to_user, :receiver),
         {:ok, from_user_balance} <- Users.withdraw(from_user, amount, currency),
         {:ok, to_user_balance} <- Users.deposit(to_user, amount, currency) do
      {:ok, from_user_balance, to_user_balance}
    else
      {:error, _reason} = error ->
        error
    end
  end
end
