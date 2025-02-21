defmodule ExW3Test do
  use ExUnit.Case
  doctest ExW3

  setup_all do
    start_supervised!(ExW3.Contract)

    start_supervised!(
      Supervisor.child_spec(
        {ExW3.Contract, [name: :alt, url: "http://localhost:9545"]},
        id: :alt
      )
    )

    %{
      simple_storage_abi: ExW3.Abi.load_abi("test/examples/build/SimpleStorage.abi"),
      array_tester_abi: ExW3.Abi.load_abi("test/examples/build/ArrayTester.abi"),
      event_tester_abi: ExW3.Abi.load_abi("test/examples/build/EventTester.abi"),
      complex_abi: ExW3.Abi.load_abi("test/examples/build/Complex.abi"),
      address_tester_abi: ExW3.Abi.load_abi("test/examples/build/AddressTester.abi"),
      accounts: ExW3.accounts()
    }
  end

  # Only works with ganache-cli

  # test "mines a block" do
  #   block_number = ExW3.block_number()
  #   ExW3.mine()
  #   assert ExW3.block_number() == block_number + 1
  # end

  # test "mines multiple blocks" do
  #   block_number = ExW3.block_number()
  #   ExW3.mine(5)
  #   assert ExW3.block_number() == block_number + 5
  # end
  #
  test "starts two Contract GenServer for simple storage contract", context do
    ExW3.Contract.register(:SimpleStorage, abi: context[:simple_storage_abi])
    ExW3.Contract.register({:alt, :SimpleStorage}, abi: context[:simple_storage_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        :SimpleStorage,
        bin: ExW3.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
        args: [],
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    {:ok, alt_address, _} =
      ExW3.Contract.deploy(
        {:alt, :SimpleStorage},
        bin: ExW3.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
        args: [],
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    ExW3.Contract.at(:SimpleStorage, address)
    ExW3.Contract.at({:alt, :SimpleStorage}, alt_address)

    assert address == ExW3.Contract.address(:SimpleStorage)
    assert alt_address == ExW3.Contract.address({:alt, :SimpleStorage})
    refute address == alt_address

    {:ok, data} = ExW3.Contract.call(:SimpleStorage, :get)
    {:ok, alt_data} = ExW3.Contract.call({:alt, :SimpleStorage}, :get)

    assert data == 0
    assert alt_data == 0

    ExW3.Contract.send(:SimpleStorage, :set, [1], %{
      from: Enum.at(context[:accounts], 0),
      gas: 50_000
    })

    ExW3.Contract.send({:alt, :SimpleStorage}, :set, [2], %{
      from: Enum.at(context[:accounts], 0),
      gas: 50_000
    })

    {:ok, data} = ExW3.Contract.call(:SimpleStorage, :get)
    {:ok, alt_data} = ExW3.Contract.call({:alt, :SimpleStorage}, :get)

    assert data == 1
    assert alt_data == 2
  end

  test "starts a Contract GenServer for simple storage contract", context do
    ExW3.Contract.register(:SimpleStorage, abi: context[:simple_storage_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        :SimpleStorage,
        bin: ExW3.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
        args: [],
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    ExW3.Contract.at(:SimpleStorage, address)

    assert address == ExW3.Contract.address(:SimpleStorage)

    {:ok, data} = ExW3.Contract.call(:SimpleStorage, :get)

    assert data == 0

    ExW3.Contract.send(:SimpleStorage, :set, [1], %{
      from: Enum.at(context[:accounts], 0),
      gas: 50_000
    })

    {:ok, data} = ExW3.Contract.call(:SimpleStorage, :get)

    assert data == 1
  end

  test "starts an alternative Contract GenServer for simple storage contract", context do
    ExW3.Contract.register({:alt, :SimpleStorage}, abi: context[:simple_storage_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        {:alt, :SimpleStorage},
        bin: ExW3.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
        args: [],
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    ExW3.Contract.at({:alt, :SimpleStorage}, address)

    assert address == ExW3.Contract.address({:alt, :SimpleStorage})

    {:ok, data} = ExW3.Contract.call({:alt, :SimpleStorage}, :get)

    assert data == 0

    ExW3.Contract.send({:alt, :SimpleStorage}, :set, [1], %{
      from: Enum.at(context[:accounts], 0),
      gas: 50_000
    })

    {:ok, data} = ExW3.Contract.call({:alt, :SimpleStorage}, :get)

    assert data == 1
  end

  test "starts a Contract GenServer for array tester contract", context do
    ExW3.Contract.register(:ArrayTester, abi: context[:array_tester_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        :ArrayTester,
        bin: ExW3.Abi.load_bin("test/examples/build/ArrayTester.bin"),
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    ExW3.Contract.at(:ArrayTester, address)

    assert address == ExW3.Contract.address(:ArrayTester)

    arr = [1, 2, 3, 4, 5]

    {:ok, result} = ExW3.Contract.call(:ArrayTester, :staticUint, [arr])

    assert result == arr

    {:ok, result} = ExW3.Contract.call(:ArrayTester, :dynamicUint, [arr])

    assert result == arr
  end

  test "starts an alternative Contract GenServer for array tester contract", context do
    ExW3.Contract.register({:alt, :ArrayTester}, abi: context[:array_tester_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        {:alt, :ArrayTester},
        bin: ExW3.Abi.load_bin("test/examples/build/ArrayTester.bin"),
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    ExW3.Contract.at({:alt, :ArrayTester}, address)

    assert address == ExW3.Contract.address({:alt, :ArrayTester})

    arr = [1, 2, 3, 4, 5]

    {:ok, result} = ExW3.Contract.call({:alt, :ArrayTester}, :staticUint, [arr])

    assert result == arr

    {:ok, result} = ExW3.Contract.call({:alt, :ArrayTester}, :dynamicUint, [arr])

    assert result == arr
  end

  test "starts a Contract GenServer for event tester contract", context do
    ExW3.Contract.register(:EventTester, abi: context[:event_tester_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        :EventTester,
        bin: ExW3.Abi.load_bin("test/examples/build/EventTester.bin"),
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    ExW3.Contract.at(:EventTester, address)

    assert address == ExW3.Contract.address(:EventTester)

    {:ok, tx_hash} =
      ExW3.Contract.send(:EventTester, :simple, ["Hello, World!"], %{
        from: Enum.at(context[:accounts], 0),
        gas: 30_000
      })

    {:ok, {receipt, logs}} = ExW3.Contract.tx_receipt(:EventTester, tx_hash)

    assert receipt |> is_map

    data =
      logs
      |> Enum.at(0)
      |> Map.get("data")
      |> ExW3.Utils.bytes_to_string()

    assert data == "Hello, World!"

    {:ok, tx_hash2} =
      ExW3.Contract.send(:EventTester, :simpleIndex, ["Hello, World!"], %{
        from: Enum.at(context[:accounts], 0),
        gas: 30_000
      })

    {:ok, {_receipt, logs}} = ExW3.Contract.tx_receipt(:EventTester, tx_hash2)

    otherNum =
      logs
      |> Enum.at(0)
      |> Map.get("otherNum")

    assert otherNum == 42

    num =
      logs
      |> Enum.at(0)
      |> Map.get("num")

    assert num == 46

    data =
      logs
      |> Enum.at(0)
      |> Map.get("data")
      |> ExW3.Utils.bytes_to_string()

    assert data == "Hello, World!"
  end

  test "starts an alternative Contract GenServer for event tester contract", context do
    ExW3.Contract.register({:alt, :EventTester}, abi: context[:event_tester_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        {:alt, :EventTester},
        bin: ExW3.Abi.load_bin("test/examples/build/EventTester.bin"),
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    ExW3.Contract.at({:alt, :EventTester}, address)

    assert address == ExW3.Contract.address({:alt, :EventTester})

    {:ok, tx_hash} =
      ExW3.Contract.send({:alt, :EventTester}, :simple, ["Hello, World!"], %{
        from: Enum.at(context[:accounts], 0),
        gas: 30_000
      })

    {:ok, {receipt, logs}} = ExW3.Contract.tx_receipt({:alt, :EventTester}, tx_hash)

    assert receipt |> is_map

    data =
      logs
      |> Enum.at(0)
      |> Map.get("data")
      |> ExW3.Utils.bytes_to_string()

    assert data == "Hello, World!"

    {:ok, tx_hash2} =
      ExW3.Contract.send({:alt, :EventTester}, :simpleIndex, ["Hello, World!"], %{
        from: Enum.at(context[:accounts], 0),
        gas: 30_000
      })

    {:ok, {_receipt, logs}} = ExW3.Contract.tx_receipt({:alt, :EventTester}, tx_hash2)

    otherNum =
      logs
      |> Enum.at(0)
      |> Map.get("otherNum")

    assert otherNum == 42

    num =
      logs
      |> Enum.at(0)
      |> Map.get("num")

    assert num == 46

    data =
      logs
      |> Enum.at(0)
      |> Map.get("data")
      |> ExW3.Utils.bytes_to_string()

    assert data == "Hello, World!"
  end

  test "Testing formatted get filter changes", context do
    ExW3.Contract.register(:EventTester, abi: context[:event_tester_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        :EventTester,
        bin: ExW3.Abi.load_bin("test/examples/build/EventTester.bin"),
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    ExW3.Contract.at(:EventTester, address)

    # Test non indexed events

    {:ok, filter_id} = ExW3.Contract.filter(:EventTester, "Simple")

    {:ok, _tx_hash} =
      ExW3.Contract.send(
        :EventTester,
        :simple,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    {:ok, change_logs} = ExW3.Contract.get_filter_changes(filter_id)

    event_log = Enum.at(change_logs, 0)

    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 42
    assert ExW3.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"

    ExW3.Contract.uninstall_filter(filter_id)

    # Test indexed events

    {:ok, indexed_filter_id} = ExW3.Contract.filter(:EventTester, "SimpleIndex")

    {:ok, _tx_hash} =
      ExW3.Contract.send(
        :EventTester,
        :simpleIndex,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    {:ok, change_logs} = ExW3.Contract.get_filter_changes(indexed_filter_id)

    event_log = Enum.at(change_logs, 0)

    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 46
    assert ExW3.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"
    assert Map.get(log_data, "otherNum") == 42
    ExW3.Contract.uninstall_filter(indexed_filter_id)

    # Test Indexing Indexed Events

    {:ok, indexed_filter_id} =
      ExW3.Contract.filter(
        :EventTester,
        "SimpleIndex",
        %{
          topics: [nil, ["Hello, World", "Hello, World!"]],
          fromBlock: 1,
          toBlock: "latest"
        }
      )

    {:ok, _tx_hash} =
      ExW3.Contract.send(
        :EventTester,
        :simpleIndex,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    {:ok, change_logs} = ExW3.Contract.get_filter_changes(indexed_filter_id)

    event_log = Enum.at(change_logs, 0)
    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 46
    assert ExW3.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"
    assert Map.get(log_data, "otherNum") == 42

    ExW3.Contract.uninstall_filter(indexed_filter_id)

    # Tests filter with map params

    {:ok, indexed_filter_id} =
      ExW3.Contract.filter(
        :EventTester,
        "SimpleIndex",
        %{
          topics: %{num: 46, data: "Hello, World!"}
        }
      )

    {:ok, _tx_hash} =
      ExW3.Contract.send(
        :EventTester,
        :simpleIndex,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    # Demonstrating the delay capability
    {:ok, change_logs} = ExW3.Contract.get_filter_changes(indexed_filter_id)

    event_log = Enum.at(change_logs, 0)
    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 46
    assert ExW3.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"
    assert Map.get(log_data, "otherNum") == 42

    ExW3.Contract.uninstall_filter(indexed_filter_id)
  end

  test "Testing formatted get filter changes on alternative GenServer", context do
    ExW3.Contract.register({:alt, :EventTester}, abi: context[:event_tester_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        {:alt, :EventTester},
        bin: ExW3.Abi.load_bin("test/examples/build/EventTester.bin"),
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    ExW3.Contract.at({:alt, :EventTester}, address)

    # Test non indexed events

    {:ok, filter_id} = ExW3.Contract.filter({:alt, :EventTester}, "Simple")

    {:ok, _tx_hash} =
      ExW3.Contract.send(
        {:alt, :EventTester},
        :simple,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    {:ok, change_logs} = ExW3.Contract.get_filter_changes({:alt, filter_id})

    event_log = Enum.at(change_logs, 0)

    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 42
    assert ExW3.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"

    ExW3.Contract.uninstall_filter({:alt, filter_id})

    # Test indexed events

    {:ok, indexed_filter_id} = ExW3.Contract.filter({:alt, :EventTester}, "SimpleIndex")

    {:ok, _tx_hash} =
      ExW3.Contract.send(
        {:alt, :EventTester},
        :simpleIndex,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    {:ok, change_logs} = ExW3.Contract.get_filter_changes({:alt, indexed_filter_id})

    event_log = Enum.at(change_logs, 0)

    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 46
    assert ExW3.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"
    assert Map.get(log_data, "otherNum") == 42
    ExW3.Contract.uninstall_filter({:alt, indexed_filter_id})

    # Test Indexing Indexed Events

    {:ok, indexed_filter_id} =
      ExW3.Contract.filter(
        {:alt, :EventTester},
        "SimpleIndex",
        %{
          topics: [nil, ["Hello, World", "Hello, World!"]],
          fromBlock: 1,
          toBlock: "latest"
        }
      )

    {:ok, _tx_hash} =
      ExW3.Contract.send(
        {:alt, :EventTester},
        :simpleIndex,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    {:ok, change_logs} = ExW3.Contract.get_filter_changes({:alt, indexed_filter_id})

    event_log = Enum.at(change_logs, 0)
    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 46
    assert ExW3.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"
    assert Map.get(log_data, "otherNum") == 42

    ExW3.Contract.uninstall_filter({:alt, indexed_filter_id})

    # Tests filter with map params

    {:ok, indexed_filter_id} =
      ExW3.Contract.filter(
        {:alt, :EventTester},
        "SimpleIndex",
        %{
          topics: %{num: 46, data: "Hello, World!"}
        }
      )

    {:ok, _tx_hash} =
      ExW3.Contract.send(
        {:alt, :EventTester},
        :simpleIndex,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    # Demonstrating the delay capability
    {:ok, change_logs} = ExW3.Contract.get_filter_changes({:alt, indexed_filter_id})

    event_log = Enum.at(change_logs, 0)
    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 46
    assert ExW3.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"
    assert Map.get(log_data, "otherNum") == 42

    ExW3.Contract.uninstall_filter({:alt, indexed_filter_id})
  end

  test "starts a Contract GenServer for Complex contract", context do
    ExW3.Contract.register(:Complex, abi: context[:complex_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        :Complex,
        bin: ExW3.Abi.load_bin("test/examples/build/Complex.bin"),
        args: [42, "Hello, world!"],
        options: %{
          from: Enum.at(context[:accounts], 0),
          gas: 300_000
        }
      )

    ExW3.Contract.at(:Complex, address)

    assert address == ExW3.Contract.address(:Complex)

    {:ok, foo, foobar} = ExW3.Contract.call(:Complex, :getBoth)

    assert foo == 42

    assert ExW3.Utils.bytes_to_string(foobar) == "Hello, world!"
  end

  test "starts an alternative Contract GenServer for Complex contract", context do
    ExW3.Contract.register({:alt, :Complex}, abi: context[:complex_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        {:alt, :Complex},
        bin: ExW3.Abi.load_bin("test/examples/build/Complex.bin"),
        args: [42, "Hello, world!"],
        options: %{
          from: Enum.at(context[:accounts], 0),
          gas: 300_000
        }
      )

    ExW3.Contract.at({:alt, :Complex}, address)

    assert address == ExW3.Contract.address({:alt, :Complex})

    {:ok, foo, foobar} = ExW3.Contract.call({:alt, :Complex}, :getBoth)

    assert foo == 42

    assert ExW3.Utils.bytes_to_string(foobar) == "Hello, world!"
  end

  test "starts a Contract GenServer for AddressTester contract", context do
    ExW3.Contract.register(:AddressTester, abi: context[:address_tester_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        :AddressTester,
        bin: ExW3.Abi.load_bin("test/examples/build/AddressTester.bin"),
        options: %{
          from: Enum.at(context[:accounts], 0),
          gas: 300_000
        }
      )

    ExW3.Contract.at(:AddressTester, address)

    assert address == ExW3.Contract.address(:AddressTester)

    formatted_address =
      Enum.at(context[:accounts], 0)
      |> ExW3.Utils.format_address()

    {:ok, same_address} = ExW3.Contract.call(:AddressTester, :get, [formatted_address])

    assert %ExW3.Address{bytes: same_address} |> ExW3.Address.to_hex() == Enum.at(context[:accounts], 0)
  end

  test "starts an alternative Contract GenServer for AddressTester contract", context do
    ExW3.Contract.register({:alt, :AddressTester}, abi: context[:address_tester_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        {:alt, :AddressTester},
        bin: ExW3.Abi.load_bin("test/examples/build/AddressTester.bin"),
        options: %{
          from: Enum.at(context[:accounts], 0),
          gas: 300_000
        }
      )

    ExW3.Contract.at({:alt, :AddressTester}, address)

    assert address == ExW3.Contract.address({:alt, :AddressTester})

    formatted_address =
      Enum.at(context[:accounts], 0)
      |> ExW3.Utils.format_address()

    {:ok, same_address} = ExW3.Contract.call({:alt, :AddressTester}, :get, [formatted_address])

    assert ExW3.Utils.to_address(same_address) == Enum.at(context[:accounts], 0)
  end

  test "returns proper error messages at contract deployment", context do
    ExW3.Contract.register(:SimpleStorage, abi: context[:simple_storage_abi])

    assert {:error, :missing_gas} ==
             ExW3.Contract.deploy(
               :SimpleStorage,
               bin: ExW3.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
               args: [],
               options: %{
                 from: Enum.at(context[:accounts], 0)
               }
             )

    assert {:error, :missing_sender} ==
             ExW3.Contract.deploy(
               :SimpleStorage,
               bin: ExW3.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
               args: [],
               options: %{
                 gas: 300_000
               }
             )

    assert {:error, :missing_binary} ==
             ExW3.Contract.deploy(
               :SimpleStorage,
               args: [],
               options: %{
                 gas: 300_000,
                 from: Enum.at(context[:accounts], 0)
               }
             )
  end

  test "returns proper error messages at contract deployment on alternative GenServer", context do
    ExW3.Contract.register({:alt, :SimpleStorage}, abi: context[:simple_storage_abi])

    assert {:error, :missing_gas} ==
             ExW3.Contract.deploy(
               {:alt, :SimpleStorage},
               bin: ExW3.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
               args: [],
               options: %{
                 from: Enum.at(context[:accounts], 0)
               }
             )

    assert {:error, :missing_sender} ==
             ExW3.Contract.deploy(
               {:alt, :SimpleStorage},
               bin: ExW3.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
               args: [],
               options: %{
                 gas: 300_000
               }
             )

    assert {:error, :missing_binary} ==
             ExW3.Contract.deploy(
               {:alt, :SimpleStorage},
               args: [],
               options: %{
                 gas: 300_000,
                 from: Enum.at(context[:accounts], 0)
               }
             )
  end

  test "return proper error messages at send and call", context do
    ExW3.Contract.register(:SimpleStorage, abi: context[:simple_storage_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        :SimpleStorage,
        bin: ExW3.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
        args: [],
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    assert {:error, :missing_address} == ExW3.Contract.call(:SimpleStorage, :get)

    assert {:error, :missing_address} ==
             ExW3.Contract.send(:SimpleStorage, :set, [1], %{
               from: Enum.at(context[:accounts], 0),
               gas: 50_000
             })

    ExW3.Contract.at(:SimpleStorage, address)

    assert {:error, :missing_sender} ==
             ExW3.Contract.send(:SimpleStorage, :set, [1], %{gas: 50_000})

    assert {:error, :missing_gas} ==
             ExW3.Contract.send(:SimpleStorage, :set, [1], %{from: Enum.at(context[:accounts], 0)})
  end

  test "return proper error messages at send and call on alternative GenServer", context do
    ExW3.Contract.register({:alt, :SimpleStorage}, abi: context[:simple_storage_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        {:alt, :SimpleStorage},
        bin: ExW3.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
        args: [],
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    assert {:error, :missing_address} == ExW3.Contract.call({:alt, :SimpleStorage}, :get)

    assert {:error, :missing_address} ==
             ExW3.Contract.send({:alt, :SimpleStorage}, :set, [1], %{
               from: Enum.at(context[:accounts], 0),
               gas: 50_000
             })

    ExW3.Contract.at({:alt, :SimpleStorage}, address)

    assert {:error, :missing_sender} ==
             ExW3.Contract.send({:alt, :SimpleStorage}, :set, [1], %{gas: 50_000})

    assert {:error, :missing_gas} ==
             ExW3.Contract.send({:alt, :SimpleStorage}, :set, [1], %{
               from: Enum.at(context[:accounts], 0)
             })
  end

  test "Rpc.get_logs/1", context do
    ExW3.Contract.register(:EventTester, abi: context[:event_tester_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        :EventTester,
        bin: ExW3.Abi.load_bin("test/examples/build/EventTester.bin"),
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    ExW3.Contract.at(:EventTester, address)

    {:ok, current_block} = ExW3.block_number()
    {:ok, from_block} = ExW3.Utils.integer_to_hex(current_block)

    {:ok, simple_tx_hash} =
      ExW3.Contract.send(:EventTester, :simple, ["Hello, World!"], %{
        from: Enum.at(context[:accounts], 0),
        gas: 30_000
      })

    {:ok, _} =
      ExW3.Contract.send(:EventTester, :simpleIndex, ["Hello, World!"], %{
        from: Enum.at(context[:accounts], 0),
        gas: 30_000
      })

    filter = %{
      fromBlock: from_block,
      toBlock: "latest",
      topics: [ExW3.Utils.keccak256("Simple(uint256,bytes32)")]
    }

    assert {:ok, logs} = ExW3.get_logs(filter)
    assert Enum.count(logs) == 1

    log = Enum.at(logs, 0)
    assert log["transactionHash"] == simple_tx_hash
  end

  test "Rpc.get_logs/1 on alternative GenServer", context do
    ExW3.Contract.register({:alt, :EventTester}, abi: context[:event_tester_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        {:alt, :EventTester},
        bin: ExW3.Abi.load_bin("test/examples/build/EventTester.bin"),
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    ExW3.Contract.at({:alt, :EventTester}, address)

    {:ok, opts} = ExW3.Contract.opts(:alt)
    {:ok, current_block} = ExW3.block_number(opts)
    {:ok, from_block} = ExW3.Utils.integer_to_hex(current_block)

    {:ok, simple_tx_hash} =
      ExW3.Contract.send({:alt, :EventTester}, :simple, ["Hello, World!"], %{
        from: Enum.at(context[:accounts], 0),
        gas: 30_000
      })

    {:ok, _} =
      ExW3.Contract.send({:alt, :EventTester}, :simpleIndex, ["Hello, World!"], %{
        from: Enum.at(context[:accounts], 0),
        gas: 30_000
      })

    filter = %{
      fromBlock: from_block,
      toBlock: "latest",
      topics: [ExW3.Utils.keccak256("Simple(uint256,bytes32)")]
    }

    assert {:ok, logs} = ExW3.get_logs(filter, opts)
    assert Enum.count(logs) == 1

    log = Enum.at(logs, 0)
    assert log["transactionHash"] == simple_tx_hash
  end

  test "Testing formatted get logs", context do
    ExW3.Contract.register(:EventTester, abi: context[:event_tester_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        :EventTester,
        bin: ExW3.Abi.load_bin("test/examples/build/EventTester.bin"),
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    ExW3.Contract.at(:EventTester, address)

    {:ok, block_number} = ExW3.block_number()

    # Test non indexed events

    {:ok, []} = ExW3.Contract.get_logs(:EventTester, %{fromBlock: block_number})

    {:ok, _tx_hash} =
      ExW3.Contract.send(
        :EventTester,
        :simple,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    {:ok, [event_log]} = ExW3.Contract.get_logs(:EventTester, %{fromBlock: block_number})

    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 42
    assert ExW3.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"

    # Test indexed events

    {:ok, _tx_hash} =
      ExW3.Contract.send(
        :EventTester,
        :simpleIndex,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    {:ok, logs} = ExW3.Contract.get_logs(:EventTester, %{fromBlock: block_number})

    event_log = logs |> List.last()

    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 46
    assert ExW3.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"
    assert Map.get(log_data, "otherNum") == 42

    # # Test Indexing Indexed Events

    {:ok, _tx_hash} =
      ExW3.Contract.send(
        :EventTester,
        :simpleIndex,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    {:ok, logs} = ExW3.Contract.get_logs(:EventTester, %{fromBlock: block_number})

    event_log = logs |> List.last()
    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 46
    assert ExW3.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"
    assert Map.get(log_data, "otherNum") == 42

    # Tests filter with map params

    {:ok, _tx_hash} =
      ExW3.Contract.send(
        :EventTester,
        :simpleIndex,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    {:ok, logs} =
      ExW3.Contract.get_logs(:EventTester, %{
        fromBlock: block_number,
        topics: %{num: 46, data: "Hello, World!"}
      })

    event_log = logs |> List.last()
    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 46
    assert ExW3.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"
    assert Map.get(log_data, "otherNum") == 42
  end

  test "Testing formatted get logs on alternative GenServer", context do
    ExW3.Contract.register({:alt, :EventTester}, abi: context[:event_tester_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        {:alt, :EventTester},
        bin: ExW3.Abi.load_bin("test/examples/build/EventTester.bin"),
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    ExW3.Contract.at({:alt, :EventTester}, address)

    {:ok, opts} = ExW3.Contract.opts(:alt)
    {:ok, block_number} = ExW3.block_number(opts)

    # Test non indexed events

    {:ok, []} = ExW3.Contract.get_logs({:alt, :EventTester}, %{fromBlock: block_number})

    {:ok, _tx_hash} =
      ExW3.Contract.send(
        {:alt, :EventTester},
        :simple,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    {:ok, [event_log]} = ExW3.Contract.get_logs({:alt, :EventTester}, %{fromBlock: block_number})

    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 42
    assert ExW3.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"

    # Test indexed events

    {:ok, _tx_hash} =
      ExW3.Contract.send(
        {:alt, :EventTester},
        :simpleIndex,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    {:ok, logs} = ExW3.Contract.get_logs({:alt, :EventTester}, %{fromBlock: block_number})

    event_log = logs |> List.last()

    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 46
    assert ExW3.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"
    assert Map.get(log_data, "otherNum") == 42

    # # Test Indexing Indexed Events

    {:ok, _tx_hash} =
      ExW3.Contract.send(
        {:alt, :EventTester},
        :simpleIndex,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    {:ok, logs} = ExW3.Contract.get_logs({:alt, :EventTester}, %{fromBlock: block_number})

    event_log = logs |> List.last()
    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 46
    assert ExW3.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"
    assert Map.get(log_data, "otherNum") == 42

    # Tests filter with map params

    {:ok, _tx_hash} =
      ExW3.Contract.send(
        {:alt, :EventTester},
        :simpleIndex,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    {:ok, logs} =
      ExW3.Contract.get_logs({:alt, :EventTester}, %{
        fromBlock: block_number,
        topics: %{num: 46, data: "Hello, World!"}
      })

    event_log = logs |> List.last()
    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 46
    assert ExW3.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"
    assert Map.get(log_data, "otherNum") == 42
  end
end
