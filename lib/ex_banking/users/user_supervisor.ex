defmodule ExBanking.Users.Supervisor do
  @moduledoc """
  This module serves as a Supervisor for user GenServers.
  """
  use DynamicSupervisor

  alias ExBanking.Types.User
  alias ExBanking.Users.Server, as: UserServer

  require Logger

  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(init_arg) do
    Logger.info("Starting User Supervisor...")
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @spec start_child([{:user, User.name()}, ...]) :: DynamicSupervisor.on_start_child()
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
