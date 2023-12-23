defmodule ExBanking.Validators do
  @moduledoc false
  alias ExBanking.Types.{Account, User}

  defdelegate validate_account(currency, balance \\ 0), to: Account, as: :validate
  defdelegate validate_user(username), to: User, as: :validate
end
