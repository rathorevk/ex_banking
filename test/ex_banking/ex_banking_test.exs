defmodule ExBanking.ExBankingTest do
  use ExUnit.Case, async: true

  alias ExBanking.Users

  describe "create_user/1" do
    test "with invalid params returns error wrong arguments" do
      assert {:error, :wrong_arguments} == ExBanking.create_user(nil)
      assert {:error, :wrong_arguments} == ExBanking.create_user(1)
    end

    test "with valid params creates user" do
      assert :ok == ExBanking.create_user(Faker.Person.name())
    end

    test "returns error when user already exists" do
      user = Faker.Person.name()
      assert :ok == ExBanking.create_user(user)
      assert {:error, :user_already_exists} == ExBanking.create_user(user)
    end
  end

  describe "deposit/3" do
    setup do
      user = create_user()
      currency = "USD"

      on_exit(fn ->
        Users.delete_user(user)
      end)

      {:ok, user: user, ccy: currency}
    end

    test "returns error when user doesn't exist", %{ccy: currency} do
      assert {:error, :user_does_not_exist} ==
               ExBanking.deposit(Faker.Person.name(), _amount = 100, currency)
    end

    test "with invalid params returns error wrong arguments", %{user: user, ccy: currency} do
      assert {:error, :wrong_arguments} ==
               ExBanking.deposit(nil, _amount = "100", currency)

      assert {:error, :wrong_arguments} ==
               ExBanking.deposit(user, _amount = "100", currency)

      assert {:error, :wrong_arguments} ==
               ExBanking.deposit(user, _amount = "100", _currency = :USD)
    end

    test "with valid params deposits money to user account", %{user: user, ccy: currency} do
      amount_1 = 100
      assert {:ok, balance} = ExBanking.deposit(user, amount_1, currency)
      assert balance == amount_1

      amount_2 = 2000.20
      assert {:ok, new_balance} = ExBanking.deposit(user, amount_2, currency)
      assert new_balance == amount_1 + amount_2
    end

    test "returns error when too many requests are made", %{ccy: currency} do
      ## creating new user with request_count=0
      user = create_user()
      amount = 0.0

      ## max_request_count = 10  i.e. request allowed per user in 5 seconds for Test Environment
      Enum.each(1..10, fn _x ->
        assert {:ok, amount} == ExBanking.deposit(user, amount, currency)
      end)

      ## hence 11th request should not be allowed
      assert {:error, :too_many_requests_to_user} ==
               ExBanking.deposit(user, amount, currency)

      ## This should be allowed in the next window
      :timer.sleep(5_000)
      assert {:ok, amount} == ExBanking.deposit(user, amount, currency)
    end
  end

  describe "withdraw/3" do
    setup do
      user = create_user()
      currency = "USD"

      on_exit(fn ->
        Users.delete_user(user)
      end)

      {:ok, user: user, ccy: currency}
    end

    test "returns error when user doesn't exist", %{ccy: ccy} do
      assert {:error, :user_does_not_exist} == ExBanking.withdraw(Faker.Person.name(), 100, ccy)
    end

    test "with invalid params returns error wrong arguments", %{user: user, ccy: currency} do
      assert {:error, :wrong_arguments} ==
               ExBanking.withdraw(nil, _amount = 100, currency)

      assert {:error, :wrong_arguments} ==
               ExBanking.withdraw(user, _amount = "100", currency)

      assert {:error, :wrong_arguments} ==
               ExBanking.withdraw(user, _amount = 100, _currency = :USD)
    end

    test "returns error when user doesn't have enough money", %{user: user, ccy: currency} do
      assert {:error, :not_enough_money} ==
               ExBanking.withdraw(user, _amount = 100, currency)
    end

    test "with valid params withdraws money from user account", %{user: user, ccy: currency} do
      ## Deposit 100 into user account
      assert {:ok, balance} = ExBanking.deposit(user, 100, currency)

      ## withdrawl - 1
      amount_1 = 10
      assert {:ok, rem_balance_1} = ExBanking.withdraw(user, amount_1, currency)
      ## balance = 100 - 10 = 90
      assert rem_balance_1 == balance - amount_1

      ## withdrawl - 2
      amount_2 = 20.2261
      assert {:ok, rem_balance_2} = ExBanking.withdraw(user, amount_2, currency)
      ## balance = 90 - 20.23 = 69.77
      assert rem_balance_2 == Float.round(rem_balance_1 - amount_2, 2)
    end

    test "returns error when too many requests are made", %{ccy: currency} do
      user = create_user()

      ## max_request_count = 10  i.e. request allowed per user in 10 seconds

      ## deposit - request-1
      {:ok, balance} = ExBanking.deposit(user, _amount = 10, currency)

      amount_to_withdraw = 0.0

      ## withdraw request-9
      Enum.each(1..9, fn _x ->
        assert {:ok, balance} == ExBanking.withdraw(user, amount_to_withdraw, currency)
      end)

      ## request_count = 1(deposit) + 9 (withdraw) + 1(withdraw) = 11
      ## hence 11th request should not be allowed
      assert {:error, :too_many_requests_to_user} ==
               ExBanking.withdraw(user, amount_to_withdraw, currency)
    end
  end

  describe "get_balance/2" do
    setup do
      user = create_user()
      currency = "USD"

      on_exit(fn ->
        Users.delete_user(user)
      end)

      {:ok, user: user, ccy: currency}
    end

    test "returns error when user doesn't exist", %{ccy: currency} do
      assert {:error, :user_does_not_exist} ==
               ExBanking.get_balance(Faker.Person.name(), currency)
    end

    test "with invalid params returns error wrong arguments", %{user: user, ccy: currency} do
      assert {:error, :wrong_arguments} == ExBanking.get_balance(nil, currency)
      assert {:error, :wrong_arguments} == ExBanking.get_balance(user, :EURO)
    end

    test "when user doesn't have currency account returns 0 balance", %{user: user} do
      assert {:ok, 0.0} == ExBanking.get_balance(user, _currency = "GBP")
    end

    test "with valid params returns updated balance", %{user: user, ccy: currency} do
      deposit_amount = 20.40
      {:ok, _balance} = ExBanking.deposit(user, deposit_amount, currency)

      assert {:ok, balance} = ExBanking.get_balance(user, currency)
      assert balance == deposit_amount

      withdraw_amount = 10.20
      {:ok, _balance} = ExBanking.withdraw(user, withdraw_amount, currency)

      assert {:ok, new_balance} = ExBanking.get_balance(user, currency)
      assert new_balance == balance - withdraw_amount
    end

    test "returns error when too many requests are made", %{ccy: currency} do
      user = create_user()

      ## max_request_count = 10
      Enum.each(1..10, fn _x ->
        assert {:ok, 0.0} == ExBanking.get_balance(user, currency)
      end)

      ## hence 11th request should not be allowed
      assert {:error, :too_many_requests_to_user} == ExBanking.get_balance(user, currency)
    end
  end

  describe "send/4" do
    setup do
      from_user = create_user()
      to_user = create_user()

      currency = "USD"

      on_exit(fn ->
        [from_user, to_user]
        |> Enum.each(&Users.delete_user/1)
      end)

      {:ok, from_user: from_user, to_user: to_user, ccy: currency}
    end

    test "returns error when sender doesn't exist", %{to_user: to_user, ccy: currency} do
      assert {:error, :sender_does_not_exist} ==
               ExBanking.send("test-to-user-1", to_user, _amount = 10, currency)
    end

    test "returns error when receiver doesn't exist", %{from_user: from_user, ccy: currency} do
      assert {:error, :receiver_does_not_exist} ==
               ExBanking.send(from_user, "test-from-user-1", _amount = 10, currency)
    end

    test "with invalid params returns error wrong arguments", %{
      from_user: from_user,
      to_user: to_user,
      ccy: currency
    } do
      assert {:error, :wrong_arguments} ==
               ExBanking.send(nil, from_user, _amount = 10, currency)

      assert {:error, :wrong_arguments} ==
               ExBanking.send(to_user, nil, _amount = 10, currency)

      assert {:error, :wrong_arguments} ==
               ExBanking.send(to_user, from_user, _amount = nil, currency)

      assert {:error, :wrong_arguments} ==
               ExBanking.send(to_user, from_user, _amount = 10, _currency = nil)
    end

    test "returns error when user doesn't have enough money", %{
      from_user: from_user,
      to_user: to_user,
      ccy: currency
    } do
      assert {:error, :not_enough_money} ==
               ExBanking.send(from_user, to_user, _amount = 100, currency)
    end

    test "with valid params send money from userA to userB and vice-versa", %{
      from_user: userA,
      to_user: userB,
      ccy: currency
    } do
      ## deposit money into userA's account
      deposit_amount = 20.50
      {:ok, _userA_balance} = ExBanking.deposit(userA, deposit_amount, currency)

      ## send money from userA's account to userB's Account
      amount_to_send = 10

      assert {:ok, userA_balance, userB_balance} =
               ExBanking.send(userA, userB, amount_to_send, currency)

      ## userA's balance = 20.50 - 10 = 10.50
      ## userB's balance = 10
      assert userA_balance == deposit_amount - amount_to_send
      assert userB_balance == amount_to_send

      ## send money from userB's account to userA's Account
      amount_to_send_1 = 5.555

      assert {:ok, new_userB_balance, new_userA_balance} =
               ExBanking.send(userB, userA, amount_to_send_1, currency)

      ## userA's balance = 20.50 + 5.56 = 25.56
      ## userB's balance = 10 - 5.56 = 4.44
      assert new_userA_balance == Float.round(userA_balance + amount_to_send_1, 2)
      assert new_userB_balance == Float.round(userB_balance - amount_to_send_1, 2)
    end

    test "returns error when got too many requests from a user", %{ccy: currency} do
      from_user = create_user()
      to_user = create_user()

      ## max_request_count = 10  i.e. request allowed per user in 10 seconds
      ## request_count = 1(deposit)
      {:ok, _balance} = ExBanking.deposit(from_user, _amount = 10, currency)

      amount_to_send = 0.0

      ## request_count = 1(deposit) + 9 (send) = 10
      Enum.each(1..9, fn _x ->
        assert {:ok, _from_user_balance, _to_user_balance} =
                 ExBanking.send(from_user, to_user, amount_to_send, currency)
      end)

      ## request_count = 1(deposit) + 9 (send) + 1(send) = 11
      ## hence 11th request should not be allowed
      assert {:error, :too_many_requests_to_sender} ==
               ExBanking.send(from_user, to_user, amount_to_send, currency)
    end
  end

  defp create_user do
    user = Faker.Person.name()
    :ok = ExBanking.create_user(user)
    user
  end
end
