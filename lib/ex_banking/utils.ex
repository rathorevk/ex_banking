defmodule ExBanking.Utils do
  @moduledoc false

  alias ExBanking.RateLimiter
  alias ExBanking.Users

  def get_user(user, user_type) do
    case Users.get_user(user) do
      {:error, :user_does_not_exist} when user_type == :sender ->
        {:error, :sender_does_not_exist}

      {:error, :user_does_not_exist} when user_type == :receiver ->
        {:error, :receiver_does_not_exist}

      {:ok, user} ->
        {:ok, user}
    end
  end

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

  def to_float(balance) when is_integer(balance),
    do: balance |> :erlang.float()

  def to_float(balance),
    do: Float.round(balance, 2)
end
