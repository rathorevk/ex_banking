defmodule ExBanking.Utils do
  @moduledoc """
  This module provides a collection of utility functions that can be used
  across various parts of the application.
  """

  alias ExBanking.Types.User
  alias ExBanking.RateLimiter
  alias ExBanking.Users

  @spec get_user(user_name :: User.name(), user_type) ::
          {:error, :receiver_does_not_exist | :sender_does_not_exist}
          | {:ok, user :: User.t()}
        when user_type: :sender | :receiver
  def get_user(user_name, user_type) do
    case Users.get_user(user_name) do
      {:error, :user_does_not_exist} when user_type == :sender ->
        {:error, :sender_does_not_exist}

      {:error, :user_does_not_exist} when user_type == :receiver ->
        {:error, :receiver_does_not_exist}

      {:ok, user} ->
        {:ok, user}
    end
  end

  @spec validate_rate_limit(user :: User.name(), user_type) ::
          :ok | {:error, :too_many_requests_to_receiver | :too_many_requests_to_sender}
        when user_type: :sender | :receiver
  def validate_rate_limit(user, user_type) do
    case RateLimiter.track(user) do
      {:error, :too_many_requests_to_user} when user_type == :sender ->
        {:error, :too_many_requests_to_sender}

      {:error, :too_many_requests_to_user} when user_type == :receiver ->
        {:error, :too_many_requests_to_receiver}

      :ok ->
        :ok
    end
  end

  @spec to_float(balance :: non_neg_integer() | float()) :: balance :: float()
  def to_float(balance) when is_integer(balance),
    do: balance |> :erlang.float()

  def to_float(balance) when is_float(balance),
    do: Float.round(balance, 2)

  def to_float(balance), do: balance
end
