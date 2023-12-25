defmodule ExBanking.Users.ServerTest do
  use ExUnit.Case, async: true

  alias ExBanking.Types.Account
  alias ExBanking.Types.User
  alias ExBanking.Users.Server, as: UserServer

  setup_all do
    user = Faker.Person.name()
    {:ok, pid} = UserServer.start_link(user: user)

    {:ok, user: user, pid: pid}
  end

  describe "start_link/1" do
    test "with valid params start the genserver" do
      user = Faker.Person.name()

      assert {:ok, pid} = UserServer.start_link(user: user)
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "returns error if process with the username exists" do
      user = Faker.Person.name()

      assert {:ok, pid} = UserServer.start_link(user: user)
      assert {:error, {:already_started, pid}} == UserServer.start_link(user: user)
    end
  end

  describe "GET functions" do
    setup do
      user = Faker.Person.name()
      {:ok, pid} = start_process(user)

      {:ok, user: user, pid: pid}
    end

    test "get_user/1 returns the user", %{user: user, pid: pid} do
      assert %User{name: user} == UserServer.get_user(user)
      assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, :get_user}}, 5000
    end

    test "get_balance/1 returns the user", %{user: user, pid: pid} do
      currency = "EURO"
      amount = 100.0

      assert _balance = UserServer.deposit(user, amount, currency)

      assert amount == UserServer.get_balance(user, currency)
      assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, {:get_balance, _currency}}}
    end
  end

  describe "deposit/3" do
    setup do
      user = Faker.Person.name()
      {:ok, pid} = start_process(user)

      {:ok, user: user, pid: pid}
    end

    test "deposit/3 returns user balance when account doesn't exist", %{user: user, pid: pid} do
      currency = "GBP"
      amount = 100.0
      assert amount == UserServer.deposit(user, amount, currency)

      assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, {:deposit, _amount, _currency}}}
    end

    test "deposit/3 returns updated user balance", %{user: user, pid: pid} do
      currency = "EURO"
      amount_1 = 100.0

      assert balance = UserServer.deposit(user, amount_1, currency)
      assert balance == amount_1

      amount_2 = 200.0
      assert balance = UserServer.deposit(user, amount_2, currency)
      assert balance == amount_1 + amount_2

      assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, {:deposit, _amount, _currency}}}
    end
  end

  describe "withdraw/3" do
    setup do
      user = Faker.Person.name()
      {:ok, pid} = start_process(user)

      {:ok, user: user, pid: pid}
    end

    test "returns error when user doesn't have enough balance", %{user: user, pid: pid} do
      currency = "USD"
      amount = 10.0
      assert {:error, :not_enough_money} == UserServer.withdraw(user, amount, currency)

      assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, {:withdraw, _amount, _currency}}}
    end

    test "returns updated user balance", %{user: user, pid: pid} do
      currency = "EURO"
      withdraw_amount = 10.0

      # deposit money into user account
      deposit_amount = 20.0
      UserServer.deposit(user, 20.0, currency)

      balance = UserServer.withdraw(user, withdraw_amount, currency)
      assert balance == deposit_amount - withdraw_amount

      assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, {:withdraw, _amount, _currency}}}
    end
  end

  test "get_accounts/1 returns the accounts" do
    user = Faker.Person.name()
    {:ok, pid} = start_process(user)

    UserServer.deposit(user, 10.0, "USD")

    assert [%Account{currency: "USD", balance: 10.0}] == UserServer.get_accounts(user)

    assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, :get_accounts}}
  end

  test "stop/1 terminates the process" do
    user = Faker.Person.name()
    {:ok, pid} = start_process(user)

    assert :ok == UserServer.stop(user)
    refute Process.alive?(pid)
  end

  defp start_process(user) do
    {:ok, pid} = UserServer.start_link(user: user)
    :erlang.trace(pid, true, [:receive])

    {:ok, pid}
  end
end
