defmodule ExBanking.Utils do
  @moduledoc """
  This module provides a collection of utility functions that can be used
  across various parts of the application.
  """

  alias ExBanking.Types.User
  alias ExBanking.Users

  @spec get_user(user_name :: User.name(), user_type) ::
          {:error,
           :receiver_does_not_exist
           | :sender_does_not_exist
           | :too_many_requests_to_sender
           | :too_many_requests_to_receiver}
          | {:ok, user :: User.t()}
        when user_type: :sender | :receiver
  def get_user(user_name, user_type) do
    user_name
    |> Users.get_user()
    |> handle_response(user_type)
  end

  @spec to_float(balance :: non_neg_integer() | float()) :: balance :: float()
  def to_float(balance) when is_integer(balance),
    do: balance |> :erlang.float()

  def to_float(balance) when is_float(balance),
    do: Float.round(balance, 2)

  def to_float(balance), do: balance

  defp handle_response({:error, :user_does_not_exist}, :sender = _user_type),
    do: {:error, :sender_does_not_exist}

  defp handle_response({:error, :user_does_not_exist}, :receiver = _user_type),
    do: {:error, :receiver_does_not_exist}

  defp handle_response({:error, :too_many_requests_to_user}, :sender = _user_type),
    do: {:error, :too_many_requests_to_sender}

  defp handle_response({:error, :too_many_requests_to_user}, :receiver = _user_type),
    do: {:error, :too_many_requests_to_receiver}

  defp handle_response({:ok, user}, _user_type),
    do: {:ok, user}
end
