# ExBanking
Simple banking application using Elixir/OTP with the features of creating users, deposits, withdrawals, get balances and send money.

## Getting Started

To run the application locally, follow these steps:

### 1. Prerequisites:
   ```bash
   elixir 1.15.0-otp-26
   erlang 26.0.1
   ```
* Elixir and Erlang versions are already added to `.tool-versions`.

### 2. Clone the Repository:
   ```bash
   git clone git@github.com:rathorevk/ex_banking.git
   cd ex_banking
   ```
### 3. Setup
To start your Phoenix server:
-  Run `mix setup` to install and setup dependencies
-  Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`.
-  Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


## Configuration

- Default rate-limiting config  -
  - Implemented rate-limiting mechanism using the sliding window technique.
  - Maximum 10 requests are allowed in 60 seconds.
  - After every 120 seconds, it performs the cleanup operation and deletes data older than the previous window.

```elixir
config :ex_banking, :rate_limit,
  # Size of the rate-limiting window in milliseconds.
  window_size_ms: 60 * 1000,
  # Rate limit — i.e. the maximum number of requests allowed for the window.
  maximum_request_count: 10,
  # Interval in the milliseconds for removing outdated data from the usage table.
  cleanup_interval_ms: 120 * 1000
```


## API Reference

### 1. Create User
- Creates new user in the system.
- New user has zero balance of any currency.

**Request:**

```elixir
ExBanking.create_user(name)
```

**Response:**

```elixir
:ok | {:error, :wrong_arguments | :user_already_exists}
```

**Example:**
```elixir
ExBanking.create_user("John Doe")
```

### 2. Deposit Funds

Deposit funds into a user account.
- Increases user’s balance in then given currency by amount value.
- Returns the updated balance of the user in the given currency.

**Request:**

```elixir
ExBanking.deposit(name, amount, currency)
```

**Response:**

```elixir
{:ok, updated_balance :: number} | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
```

**Example:**
```elixir
{:ok, 100.5} = ExBanking.deposit("John Doe", 100.50, "USD")
```

### 3. Withdraw Funds

Withdraw funds from a user account.
- Decreases the user’s balance in the given currency by amount value.
- Returns the updated balance of the user in the given currency.

**Request:**

```elixir
ExBanking.withdraw(name, amount, currency)
```

**Response:**

```elixir
 {:ok, updated_balance :: number} | {:error, :wrong_arguments | :user_does_not_exist | :not_enough_money | :too_many_requests_to_user}
```

**Example:**
```elixir
{:ok, 90.0} = ExBanking.withdraw("John Doe", 10.50, "USD")
```

### 4. Get balance

Retrieves the current balance of the user in the given currency.

**Request:**

```elixir
ExBanking.get_balance(name, currency)
```

**Response:**

```elixir
 {:ok, updated_balance :: number} | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
```

**Example:**
```elixir
{:ok, 90.0} = ExBanking.get_balance("John Doe", "USD")
```

### 5. Send Money

Sends money from one account to another.
- Decreases from_user’s balance in given currency by amount value.
- Increases to_user’s balance in given currency by amount value.
- Returns updated balances of from_user and to_user.

**Request:**

```elixir
ExBanking.send(from_user, to_user, amount, currency)
```

**Response:**

```elixir
 {:ok, from_user_balance :: number, to_user_balance :: number} | {:error, :wrong_arguments | :not_enough_money | :sender_does_not_exist | :receiver_does_not_exist | :too_many_requests_to_sender | :too_many_requests_to_receiver}
```

**Example:**
```elixir
{:ok, 80.0, 10.0} = ExBanking.send("John Doe", "Jason", 10, "USD")
```


## Tests

To run the tests for this project, simply run in your terminal:

```shell
mix test
```

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
