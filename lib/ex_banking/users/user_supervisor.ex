defmodule ExBanking.Users.Supervisor do
  @moduledoc false
  use DynamicSupervisor

  alias ExBanking.Users.Server, as: UserServer

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(args) do
    spec = {UserServer, args}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(init_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [init_arg]
    )
  end
end
