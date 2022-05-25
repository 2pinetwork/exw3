defmodule EXW3.ContractTest do
  use ExUnit.Case
  doctest ExW3.Contract

  @simple_storage_abi ExW3.Abi.load_abi("test/examples/build/SimpleStorage.abi")

  setup_all do
    start_supervised!(ExW3.Contract)
    start_supervised!(
      Supervisor.child_spec(
        {ExW3.Contract, [name: :alt, url: "http://localhost:9545"]}, id: :alt
      )
    )
    :ok
  end

  test ".at assigns the address to the state of the registered contract" do
    ExW3.Contract.register(:SimpleStorage, abi: @simple_storage_abi)

    assert ExW3.Contract.address(:SimpleStorage) == nil

    accounts = ExW3.accounts()

    {:ok, address, _} =
      ExW3.Contract.deploy(
        :SimpleStorage,
        bin: ExW3.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
        args: [],
        options: %{
          gas: 300_000,
          from: Enum.at(accounts, 0)
        }
      )

    assert ExW3.Contract.at(:SimpleStorage, address) == :ok

    state = :sys.get_state(ContractManager)
    contract_state = state[:SimpleStorage]
    assert Keyword.get(contract_state, :address) == address
    assert Keyword.get(contract_state, :abi) == @simple_storage_abi
  end

  test ".at assigns the address to the state of the registered contract on alternative GenServer" do
    ExW3.Contract.register({:alt, :SimpleStorage}, abi: @simple_storage_abi)

    assert ExW3.Contract.address({:alt, :SimpleStorage}) == nil

    accounts = ExW3.accounts()

    {:ok, address, _} =
      ExW3.Contract.deploy(
        {:alt, :SimpleStorage},
        bin: ExW3.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
        args: [],
        options: %{
          gas: 300_000,
          from: Enum.at(accounts, 0)
        }
      )

    assert ExW3.Contract.at({:alt, :SimpleStorage}, address) == :ok

    state = :sys.get_state(:alt)
    contract_state = state[:SimpleStorage]
    assert Keyword.get(contract_state, :address) == address
    assert Keyword.get(contract_state, :abi) == @simple_storage_abi
  end

  test ".address returns the registered address for the contract" do
    ExW3.Contract.register(:SimpleStorage, abi: @simple_storage_abi)

    assert ExW3.Contract.address(:SimpleStorage) == nil

    accounts = ExW3.accounts()

    {:ok, address, _} =
      ExW3.Contract.deploy(
        :SimpleStorage,
        bin: ExW3.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
        args: [],
        options: %{
          gas: 300_000,
          from: Enum.at(accounts, 0)
        }
      )

    assert ExW3.Contract.at(:SimpleStorage, address) == :ok
    assert ExW3.Contract.address(:SimpleStorage) == address
  end

  test ".address returns the registered address for the contract on alternative GenServer" do
    ExW3.Contract.register({:alt, :SimpleStorage}, abi: @simple_storage_abi)

    assert ExW3.Contract.address({:alt, :SimpleStorage}) == nil

    accounts = ExW3.accounts()

    {:ok, address, _} =
      ExW3.Contract.deploy(
        {:alt, :SimpleStorage},
        bin: ExW3.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
        args: [],
        options: %{
          gas: 300_000,
          from: Enum.at(accounts, 0)
        }
      )

    assert ExW3.Contract.at({:alt, :SimpleStorage}, address) == :ok
    assert ExW3.Contract.address({:alt, :SimpleStorage}) == address
  end

  test ".abi returns the registered abi for the contract" do
    assert ExW3.Contract.abi(:SimpleStorageAbiTest) == nil

    ExW3.Contract.register(:SimpleStorageAbiTest, abi: @simple_storage_abi)

    assert ExW3.Contract.abi(:SimpleStorageAbiTest) == @simple_storage_abi
  end

  test ".abi returns the registered abi for the contract on alternative GenServer" do
    assert ExW3.Contract.abi({:alt, :SimpleStorageAbiTest}) == nil

    ExW3.Contract.register({:alt, :SimpleStorageAbiTest}, abi: @simple_storage_abi)

    assert ExW3.Contract.abi({:alt, :SimpleStorageAbiTest}) == @simple_storage_abi
  end

  test ".opts returns the registered options for the contract" do
    assert {:ok, []} == ExW3.Contract.opts()
    assert {:ok, [url: "http://localhost:9545"]} == ExW3.Contract.opts(:alt)
  end
end
