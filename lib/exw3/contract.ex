defmodule ExW3.Contract do
  use GenServer

  # Default timeout for GenServer calls
  @timeout Application.get_env(:exw3, :timeout, :infinity)

  @log_integer_attrs [
    "blockNumber",
    "logIndex",
    "transactionIndex"
  ]

  @doc "Begins the Contract process to manage all interactions with smart contracts"
  @spec start_link(list()) :: {:ok, pid()}
  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, ContractManager)

    GenServer.start_link(__MODULE__, %{filters: %{}, opts: opts}, name: name)
  end

  @doc "Deploys contracts with given arguments"
  @spec deploy({atom(), atom()}, list()) :: {:ok, binary(), binary()}
  @spec deploy(atom(), list()) :: {:ok, binary(), binary()}
  def deploy({server, name}, args) do
    GenServer.call(server, {:deploy, {name, args}}, @timeout)
  end

  def deploy(name, args) do
    deploy({ContractManager, name}, args)
  end

  @doc "Registers the contract with the ContractManager process. Only :abi is required field."
  @spec register({atom(), atom()}, list()) :: :ok
  @spec register(atom(), list()) :: :ok
  def register({server, name}, contract_info) do
    GenServer.cast(server, {:register, {name, contract_info}})
  end

  def register(name, contract_info) do
    register({ContractManager, name}, contract_info)
  end

  @doc "Uninstalls the filter, and deletes the data associated with the filter id"
  @spec uninstall_filter({atom(), binary()}) :: :ok
  @spec uninstall_filter(binary()) :: :ok
  def uninstall_filter({server, filter_id}) do
    GenServer.cast(server, {:uninstall_filter, filter_id})
  end

  def uninstall_filter(filter_id) do
    uninstall_filter({ContractManager, filter_id})
  end

  @doc "Sets the address for the contract specified by the name argument"
  @spec at({atom(), atom()}, binary()) :: :ok
  @spec at(atom(), binary()) :: :ok
  def at({server, name}, address) do
    GenServer.cast(server, {:at, {name, address}})
  end

  def at(name, address) do
    at({ContractManager, name}, address)
  end

  @doc "Returns the current Contract GenServer's address"
  @spec address({atom(), atom()}) :: {:ok, binary()}
  @spec address(atom()) :: {:ok, binary()}
  # Prevents raise
  def address({server, nil}) do
    IO.warn("ExW3.Contract.address(#{inspect(server)}, nil)", [])
    nil
  end

  def address({server, name}) do
    GenServer.call(server, {:address, name}, @timeout)
  end

  def address(name) do
    address({ContractManager, name})
  end

  @doc "Returns the current Contract GenServer's abi"
  @spec abi({atom(), atom()}) :: {:ok, binary()}
  @spec abi(atom()) :: {:ok, binary()}
  def abi({server, name}) do
    GenServer.call(server, {:abi, name}, @timeout)
  end

  def abi(name) do
    abi({ContractManager, name})
  end

  @doc "Use a Contract's method with an eth_call"
  @spec call({atom(), atom()}, atom(), list(), any()) :: {:ok, any()}
  @spec call(atom(), atom(), list(), any()) :: {:ok, any()}
  def call(contract_name, method_name, args \\ [], timeout \\ @timeout)

  def call({server, contract_name}, method_name, args, timeout) do
    # prevents raise
    if GenServer.whereis(server) do
      GenServer.call(server, {:call, {contract_name, method_name, args}}, timeout)
    else
      IO.warn("ExW3.Contract.call(#{inspect({server, contract_name})}) server doesn't exist", [])
      nil
    end
  end

  def call(contract_name, method_name, args, timeout) do
    call({ContractManager, contract_name}, method_name, args, timeout)
  end

  @doc "Use a Contract's method with an eth_sendTransaction"
  @spec send({atom(), atom()}, atom(), list(), map()) :: {:ok, binary()}
  @spec send(atom(), atom(), list(), map()) :: {:ok, binary()}
  def send({server, contract_name}, method_name, args, options) do
    GenServer.call(server, {:send, {contract_name, method_name, args, options}}, @timeout)
  end

  def send(contract_name, method_name, args, options) do
    send({ContractManager, contract_name}, method_name, args, options)
  end

  @doc "Returns a formatted transaction receipt for the given transaction hash(id)"
  @spec tx_receipt({atom(), atom()}, binary()) :: map()
  @spec tx_receipt(atom(), binary()) :: map()
  def tx_receipt(contract_name, tx_hash, timeout \\ @timeout)

  def tx_receipt({server, contract_name}, tx_hash, timeout) do
    GenServer.call(server, {:tx_receipt, {contract_name, tx_hash}}, timeout)
  end

  def tx_receipt(contract_name, tx_hash, timeout) do
    tx_receipt({ContractManager, contract_name}, tx_hash, timeout)
  end

  @doc "Installs a filter on the Ethereum node. This also formats the parameters, and saves relevant information to format event logs."
  @spec filter({atom(), atom()}, binary(), map()) :: {:ok, binary()}
  @spec filter(atom(), binary(), map()) :: {:ok, binary()}
  def filter(contract_name, event_name, event_data \\ %{})

  def filter({server, contract_name}, event_name, event_data) do
    GenServer.call(
      server,
      {:filter, {contract_name, event_name, event_data}},
      @timeout
    )
  end

  def filter(contract_name, event_name, event_data) do
    filter({ContractManager, contract_name}, event_name, event_data)
  end

  @doc "Using saved information related to the filter id, event logs are formatted properly"
  @spec get_filter_changes({atom(), binary()}) :: {:ok, list()}
  @spec get_filter_changes(binary()) :: {:ok, list()}
  def get_filter_changes({server, filter_id}) do
    GenServer.call(server, {:get_filter_changes, filter_id}, @timeout)
  end

  def get_filter_changes(filter_id) do
    get_filter_changes({ContractManager, filter_id})
  end

  @doc "Returns formatted event logs for a registered contract"
  @spec get_logs({atom(), atom()}, map()) :: {:ok, list()}
  @spec get_logs(atom(), map()) :: {:ok, list()}
  def get_logs(contract_name, event_data \\ %{})

  def get_logs({server, contract_name}, event_data) do
    GenServer.call(server, {:get_logs, contract_name, event_data}, @timeout)
  end

  def get_logs(contract_name, event_data) do
    get_logs({ContractManager, contract_name}, event_data)
  end

  @doc "Returns opts for the given server"
  @spec opts(atom()) :: {:ok, list()}
  def opts(server \\ ContractManager) do
    GenServer.call(server, {:opts}, @timeout)
  end

  @doc "return a formatted logs for a transaction."
  # @spec register({atom(), atom()}, list()) :: :ok
  # @spec register(atom(), list()) :: :ok
  def decode_tx_logs({server, name}, tx) do
    GenServer.call(server, {:decode_tx_logs, {name, tx}}, @timeout)
  end

  def decode_tx_logs(name, tx) do
    decode_tx_logs({ContractManager, name}, tx)
  end

  def init(state) do
    {:ok, state}
  end

  @doc "Updates info for the given server"
  # @spec uppdate_info(atom()) :: {:ok, list()}
  def update_info({server, name}, keyword_attrs) when is_list(keyword_attrs) do
    attrs = keyword_attrs |> Enum.into(%{})

    update_info({server, name}, attrs)
  end

  def update_info({server, name}, attrs) do
    GenServer.cast(server, {:update_info, {name, attrs}})
  end

  def update_info(name, attrs) do
    update_info({ContractManager, name}, attrs)
  end

  @doc "Returns value for the given server and info key"
  def info({server, name}, key) do
    {server, name} |> info() |> Map.get(key)
  end

  @doc "Returns info for the given server"
  def info({server, name}) do
    # prevents raise
    if GenServer.whereis(server) do
      GenServer.call(server, {:info, name}, @timeout)
    else
      IO.warn("ExW3.Contract.info(#{inspect({server, name})}) server doesn't exist", [])
      nil
    end
  end

  def info(name) do
    info({ContractManager, name})
  end

  @doc "Returns contract_identifiers added to the server"
  # @spec contract_identifiers(atom()) :: {:ok, list()}
  def contract_identifiers(server \\ ContractManager) do
    # prevents raise
    if GenServer.whereis(server) do
      GenServer.call(server, {:contract_identifiers}, @timeout)
    else
      IO.warn("ExW3.Contract.contract_identifiers(#{inspect(server)}) server doesn't exist", [])
      []
    end
  end

  defp data_signature_helper(name, fields) do
    non_indexed_types = Enum.map(fields, &Map.get(&1, "type"))
    Enum.join([name, "(", Enum.join(non_indexed_types, ","), ")"])
  end

  defp topic_types_helper(fields) do
    if length(fields) > 0 do
      Enum.map(fields, fn field ->
        "(#{field["type"]})"
      end)
    else
      []
    end
  end

  defp init_events(abi) do
    events =
      Enum.filter(abi, fn {_, v} ->
        v["type"] == "event"
      end)

    names_and_signature_types_map =
      Enum.map(events, fn {name, v} ->
        types = Enum.map(v["inputs"], &Map.get(&1, "type"))
        signature = Enum.join([name, "(", Enum.join(types, ","), ")"])
        encoded_event_signature = ExW3.Utils.keccak256(signature)

        indexed_fields =
          Enum.filter(v["inputs"], fn input ->
            input["indexed"]
          end)

        indexed_names =
          Enum.map(indexed_fields, fn field ->
            field["name"]
          end)

        non_indexed_fields =
          Enum.filter(v["inputs"], fn input ->
            !input["indexed"]
          end)

        non_indexed_names =
          Enum.map(non_indexed_fields, fn field ->
            field["name"]
          end)

        data_signature = data_signature_helper(name, non_indexed_fields)

        event_attributes = %{
          signature: data_signature,
          non_indexed_names: non_indexed_names,
          topic_types: topic_types_helper(indexed_fields),
          topic_names: indexed_names
        }

        {{encoded_event_signature, event_attributes}, {name, encoded_event_signature}}
      end)

    signature_types_map =
      Enum.map(names_and_signature_types_map, fn {signature_types, _} ->
        signature_types
      end)

    names_map =
      Enum.map(names_and_signature_types_map, fn {_, names} ->
        names
      end)

    [
      events: Enum.into(signature_types_map, %{}),
      event_names: Enum.into(names_map, %{})
    ]
  end

  def deploy_helper(bin, abi, args, opts) do
    constructor_arg_data =
      if arguments = args[:args] do
        constructor_abi =
          Enum.find(abi, fn {_, v} ->
            v["type"] == "constructor"
          end)

        if constructor_abi do
          {_, constructor} = constructor_abi
          input_types = Enum.map(constructor["inputs"], fn x -> x["type"] end)
          types_signature = Enum.join(["(", Enum.join(input_types, ","), ")"])

          arg_count = Enum.count(arguments)
          input_types_count = Enum.count(input_types)

          if input_types_count != arg_count do
            raise "Number of provided arguments to constructor is incorrect. Was given #{arg_count} args, looking for #{input_types_count}."
          end

          bin <>
            (ExW3.Abi.encode_data(types_signature, arguments) |> Base.encode16(case: :lower))
        else
          bin
        end
      else
        bin
      end

    gas = ExW3.Abi.encode_option(args[:options][:gas])
    gasPrice = ExW3.Abi.encode_option(args[:options][:gas_price])

    tx = %{
      from: args[:options][:from],
      data: "0x#{constructor_arg_data}",
      gas: gas,
      gasPrice: gasPrice
    }

    {:ok, tx_hash} = ExW3.Rpc.eth_send([tx, opts])
    {:ok, tx_receipt} = ExW3.Rpc.tx_receipt(tx_hash, opts)

    {tx_receipt["contractAddress"], tx_hash}
  end

  def eth_call_helper(address, abi, method_name, args, opts \\ []) do
    result =
      ExW3.Rpc.eth_call([
        %{
          to: address,
          data: "0x#{ExW3.Abi.encode_method_call(abi, method_name, args)}"
        },
        "latest",
        opts
      ])

    case result do
      {:ok, data} ->
        ([:ok] ++ ExW3.Abi.decode_output(abi, method_name, data)) |> List.to_tuple()

      {:error, err} ->
        {:error, err}
    end
  end

  def eth_send_helper(address, abi, method_name, args, options, opts) do
    encoded_options =
      ExW3.Abi.encode_options(
        options,
        [:gas, :gasPrice, :value, :nonce]
      )

    gas = ExW3.Abi.encode_option(args[:options][:gas])
    gasPrice = ExW3.Abi.encode_option(args[:options][:gas_price])

    ExW3.Rpc.eth_send([
      Map.merge(
        %{
          to: address,
          data: "0x#{ExW3.Abi.encode_method_call(abi, method_name, args)}",
          gas: gas,
          gasPrice: gasPrice
        },
        Map.merge(options, encoded_options)
      ),
      opts
    ])
  end

  defp register_helper(contract_info) do
    if contract_info[:abi] do
      contract_info ++ init_events(contract_info[:abi])
    else
      raise "ABI not provided upon initialization"
    end
  end

  # Options' checkers

  defp check_option(nil, error_atom), do: {:error, error_atom}
  defp check_option([], error_atom), do: {:error, error_atom}
  defp check_option([head | _tail], _atom) when head != nil, do: {:ok, head}
  defp check_option([_head | tail], atom), do: check_option(tail, atom)
  defp check_option(value, _atom), do: {:ok, value}

  # Casts

  def handle_cast({:at, {name, address}}, state) do
    contract_state = state[name]
    contract_state = Keyword.put(contract_state, :address, address)
    state = Map.put(state, name, contract_state)
    {:noreply, state}
  end

  def handle_cast({:register, {name, contract_info}}, state) do
    {:noreply, Map.put(state, name, register_helper(contract_info))}
  end

  def handle_cast({:uninstall_filter, filter_id}, state) do
    ExW3.uninstall_filter(filter_id)
    {:noreply, Map.put(state, :filters, Map.delete(state[:filters], filter_id))}
  end

  def handle_cast({:update_info, {name, attrs}}, state) do
    contract_state = state[name]
    info = (contract_state[:info] || %{}) |> Map.merge(attrs)

    contract_state = contract_state |> Keyword.put(:info, info)
    state = Map.put(state, name, contract_state)

    {:noreply, state}
  end

  # Calls
  defp filter_topics_helper(event_signature, event_data, topic_types, topic_names) do
    topics =
      if is_map(event_data[:topics]) do
        Enum.map(topic_names, fn name ->
          event_data[:topics][String.to_atom(name)]
        end)
      else
        event_data[:topics]
      end

    if topics do
      formatted_topics =
        Enum.map(0..(length(topics) - 1), fn i ->
          topic = Enum.at(topics, i)

          if topic do
            if is_list(topic) do
              topic_type = Enum.at(topic_types, i)

              Enum.map(topic, fn t ->
                "0x" <> (ExW3.Abi.encode_data(topic_type, [t]) |> Base.encode16(case: :lower))
              end)
            else
              topic_type = Enum.at(topic_types, i)
              "0x" <> (ExW3.Abi.encode_data(topic_type, [topic]) |> Base.encode16(case: :lower))
            end
          else
            topic
          end
        end)

      [event_signature] ++ formatted_topics
    else
      [event_signature]
    end
  end

  def from_block_helper(event_data) do
    if event_data[:fromBlock] do
      new_from_block =
        if Enum.member?(["latest", "earliest", "pending"], event_data[:fromBlock]) do
          event_data[:fromBlock]
        else
          ExW3.Abi.encode_data("(uint256)", [event_data[:fromBlock]])
        end

      Map.put(event_data, :fromBlock, new_from_block)
    else
      event_data
    end
  end

  defp param_helper(event_data, key) do
    if event_data[key] do
      new_param =
        if Enum.member?(["latest", "earliest", "pending"], event_data[key]) do
          event_data[key]
        else
          event_data[key]
          |> Integer.to_string(16)
          |> String.downcase()
          |> String.replace_prefix("", "0x")
        end

      Map.put(event_data, key, new_param)
    else
      event_data
    end
  end

  defp event_data_format_helper(event_data) do
    event_data
    |> param_helper(:fromBlock)
    |> param_helper(:toBlock)
    |> Map.delete(:topics)
  end

  def get_event_attributes(state, contract_name, event_name) do
    contract_info = state[contract_name]
    contract_info[:events][contract_info[:event_names][event_name]]
  end

  defp extract_non_indexed_fields(data, names, signature) do
    Enum.zip(names, ExW3.Abi.decode_event(data, signature)) |> Enum.into(%{})
  end

  defp format_log_data(_log, event_attributes) when event_attributes == %{} do
    %{}
  end

  defp format_log_data(log, event_attributes) do
    non_indexed_fields =
      extract_non_indexed_fields(
        Map.get(log, "data"),
        event_attributes[:non_indexed_names],
        event_attributes[:signature]
      )

    indexed_fields =
      if length(log["topics"]) > 1 do
        [_head | tail] = log["topics"]

        decoded_topics =
          Enum.map(0..(length(tail) - 1), fn i ->
            topic_type = Enum.at(event_attributes[:topic_types], i)
            topic_data = Enum.at(tail, i)

            {decoded} = ExW3.Abi.decode_data(topic_type, topic_data)

            decoded
          end)

        Enum.zip(event_attributes[:topic_names], decoded_topics) |> Enum.into(%{})
      else
        %{}
      end

    new_data = Map.merge(indexed_fields, non_indexed_fields)

    Map.put(log, "data", new_data)
  end

  defp format_log(log, event_attributes) do
    Enum.reduce(
      [
        ExW3.Normalize.transform_to_integer(log, @log_integer_attrs),
        format_log_data(log, event_attributes)
      ],
      &Map.merge/2
    )
  end

  def handle_call({:filter, {contract_name, event_name, event_data}}, _from, state) do
    contract_info = state[contract_name]

    event_signature = contract_info[:event_names][event_name]
    topic_types = contract_info[:events][event_signature][:topic_types]
    topic_names = contract_info[:events][event_signature][:topic_names]

    topics = filter_topics_helper(event_signature, event_data, topic_types, topic_names)

    payload =
      Map.merge(
        %{address: contract_info[:address], topics: topics},
        event_data_format_helper(event_data)
      )

    filter_id = ExW3.Rpc.new_filter(payload, state[:opts])

    {:reply, {:ok, filter_id},
     Map.put(
       state,
       :filters,
       Map.put(state[:filters], filter_id, %{
         contract_name: contract_name,
         event_name: event_name
       })
     )}
  end

  def handle_call({:get_filter_changes, filter_id}, _from, state) do
    filter_info = Map.get(state[:filters], filter_id)

    event_attributes =
      get_event_attributes(state, filter_info[:contract_name], filter_info[:event_name])

    formatted_logs =
      filter_id
      |> ExW3.Rpc.get_filter_changes(state[:opts])
      |> Enum.map(&format_log(&1, event_attributes))

    {:reply, {:ok, formatted_logs}, state}
  end

  def handle_call({:get_logs, contract_name, event_data}, _from, state) do
    contract_info = state[contract_name]

    {:ok, logs} =
      event_data
      |> Map.merge(%{address: contract_info[:address]})
      |> event_data_format_helper()
      |> ExW3.Rpc.get_logs(state[:opts])

    formatted_logs =
      logs
      |> Enum.map(fn log ->
        # Per definition:
        # "The first topic usually consists of the signature (a keccak256 hash)
        # of the name of the event that occurred."
        # But just in case we use find
        event_topic = log["topics"] |> Enum.find(fn t -> contract_info[:events][t] end)
        event_attributes = contract_info[:events] |> Map.get(event_topic, %{})

        log |> format_log(event_attributes)
      end)

    {:reply, {:ok, formatted_logs}, state}
  end

  def handle_call({:deploy, {name, args}}, _from, state) do
    contract_info = state[name]

    with {:ok, _} <- check_option(args[:options][:from], :missing_sender),
         {:ok, _} <- check_option(args[:options][:gas], :missing_gas),
         {:ok, bin} <- check_option([state[:bin], args[:bin]], :missing_binary) do
      {contract_addr, tx_hash} = deploy_helper(bin, contract_info[:abi], args, state[:opts])
      result = {:ok, contract_addr, tx_hash}
      {:reply, result, state}
    else
      err -> {:reply, err, state}
    end
  end

  def handle_call({:address, name}, _from, state) do
    {:reply, state[name][:address], state}
  end

  def handle_call({:abi, name}, _from, state) do
    {:reply, state[name][:abi], state}
  end

  def handle_call({:call, {contract_name, method_name, args}}, _from, state) do
    contract_info = state[contract_name]

    with {:ok, address} <- check_option(contract_info[:address], :missing_address) do
      result =
        eth_call_helper(
          address,
          contract_info[:abi],
          Atom.to_string(method_name),
          args,
          state[:opts]
        )

      {:reply, result, state}
    else
      err -> {:reply, err, state}
    end
  end

  def handle_call({:send, {contract_name, method_name, args, options}}, _from, state) do
    contract_info = state[contract_name]

    with {:ok, address} <- check_option(contract_info[:address], :missing_address),
         {:ok, _} <- check_option(options[:from], :missing_sender),
         {:ok, _} <- check_option(options[:gas], :missing_gas) do
      result =
        eth_send_helper(
          address,
          contract_info[:abi],
          Atom.to_string(method_name),
          args,
          options,
          state[:opts]
        )

      {:reply, result, state}
    else
      err -> {:reply, err, state}
    end
  end

  def handle_call({:tx_receipt, {contract_name, tx_hash}}, _from, state) do
    events = state[contract_name][:events]

    {:ok, receipt} = ExW3.tx_receipt(tx_hash, state[:opts])

    logs = receipt["logs"]

    decoded_logs =
      logs
      |> Enum.map(&decode_log(events, &1))
      |> merge_tx_logs(logs)

    {:reply, {:ok, {receipt, decoded_logs}}, state}
  end

  def handle_call({:opts}, _from, state) do
    {:reply, {:ok, state[:opts]}, state}
  end

  def handle_call({:decode_tx_logs, {contract_name, tx}}, _from, state) do
    events = state[contract_name][:events]
    logs = tx["logs"]

    decoded_logs =
      logs
      |> Enum.map(&decode_log(events, &1))
      |> merge_tx_logs(logs)

    decoded_tx = tx |> Map.put("logs", decoded_logs)

    {:reply, {:ok, decoded_tx}, state}
  end

  def handle_call({:info, name}, _from, state) do
    info = state[name][:info] || %{}

    {:reply, info, state}
  end

  def handle_call({:contract_identifiers}, _from, state) do
    server_name =
      self()
      |> Process.info()
      |> Keyword.get(:registered_name)

    contract_keys =
      state
      |> Map.keys()
      |> Kernel.--([:filters, :opts])
      |> add_server_name_to_identifiers(server_name)

    {:reply, contract_keys, state}
  end

  defp decode_log(events, log) do
    topic = Enum.at(log["topics"], 0)
    event_attributes = Map.get(events, topic)

    if event_attributes do
      event_sign = %{"_event" => event_attributes[:signature]}

      non_indexed_fields =
        Enum.zip(
          event_attributes[:non_indexed_names],
          ExW3.Abi.decode_event(log["data"], event_attributes[:signature])
        )
        |> Enum.into(event_sign)

      if length(log["topics"]) > 1 do
        [_head | tail] = log["topics"]

        decoded_topics =
          Enum.map(0..(length(tail) - 1), fn i ->
            topic_type = Enum.at(event_attributes[:topic_types], i)
            topic_data = Enum.at(tail, i)

            {decoded} = ExW3.Abi.decode_data(topic_type, topic_data)

            decoded
          end)

        indexed_fields =
          Enum.zip(event_attributes[:topic_names], decoded_topics) |> Enum.into(%{})

        Map.merge(indexed_fields, non_indexed_fields)
      else
        non_indexed_fields
      end
    else
      nil
    end
  end

  defp merge_tx_logs(decoded_logs, logs) do
    decoded_logs
    |> Enum.with_index()
    |> Enum.map(fn {flog, i} ->
      log = logs |> Enum.at(i)

      if flog do
        log |> Map.put("decoded_data", flog)
      else
        log
      end
    end)
  end

  # Only add server_name to identifiers when it's not the default module
  defp add_server_name_to_identifiers(identifiers, __MODULE__), do: identifiers

  defp add_server_name_to_identifiers(identifiers, server_name) do
    identifiers
    |> Enum.map(fn identifier -> {server_name, identifier} end)
  end
end
