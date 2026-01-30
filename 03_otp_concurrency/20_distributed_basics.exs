# ============================================================================
# Lesson 20: Distributed Elixir Basics
# ============================================================================
#
# Elixir/Erlang's distribution capabilities allow multiple BEAM nodes to
# communicate seamlessly. Processes can send messages to processes on other
# nodes as easily as local processes.
#
# Learning Objectives:
# - Understand BEAM distribution model
# - Start named nodes and connect them
# - Use Node.connect/1 and Node.list/0
# - Execute code remotely with :rpc.call/4
# - Send messages between nodes
# - Understand global process registration
# - Work with distributed ETS
#
# Prerequisites:
# - Strong understanding of processes and message passing
# - GenServer knowledge
# - ETS basics
#
# NOTE: This lesson contains code examples that demonstrate distributed
# concepts. Some examples require running multiple IEx sessions or nodes.
# Instructions for running these examples are provided throughout.
#
# ============================================================================

IO.puts("=" |> String.duplicate(70))
IO.puts("Lesson 20: Distributed Elixir Basics")
IO.puts("=" |> String.duplicate(70))

# -----------------------------------------------------------------------------
# Section 1: Introduction to Distribution
# -----------------------------------------------------------------------------
#
# The BEAM VM was built for distribution from the ground up. Key concepts:
#
# - Node: A running BEAM instance with a name
# - Cluster: Multiple connected nodes
# - Location transparency: Same messaging API for local/remote processes
# - Epmd: Erlang Port Mapper Daemon (manages node connections)
#
# Distribution features:
# - Automatic reconnection
# - Process monitoring across nodes
# - Distributed process groups
# - Global process registration
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 1: Introduction to Distribution ---\n")

IO.puts("""
BEAM Distribution Model:
========================

Each BEAM instance can become a "node" by giving it a name.
Nodes can connect to form a cluster where processes communicate
transparently across machine boundaries.

Key Characteristics:
- Fully connected mesh (by default)
- Automatic TCP connections between nodes
- Same send/receive API for local and remote
- Built-in support for node monitoring
- Distributed process registration

Node Name Types:
- Short names: 'foo@hostname' (same machine or same subnet)
- Long names: 'foo@192.168.1.1' or 'foo@example.com' (full DNS)

Starting a Named Node:
  # Short name (default)
  iex --sname node1

  # Long name
  iex --name node1@192.168.1.100

  # With cookie (shared secret for cluster)
  iex --sname node1 --cookie my_secret_cookie
""")

# Check if we're running as a distributed node
case Node.self() do
  :nonode@nohost ->
    IO.puts("\nCurrently running WITHOUT a node name.")
    IO.puts("To enable distribution, start with: iex --sname mynode")

  name ->
    IO.puts("\nRunning as distributed node: #{name}")
end

# -----------------------------------------------------------------------------
# Section 2: Node Basics
# -----------------------------------------------------------------------------
#
# The Node module provides functions for working with nodes.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 2: Node Basics ---\n")

# Node.self() returns the current node's name
IO.puts("Current node: #{Node.self()}")

# Node.alive?() checks if the node is distributed
IO.puts("Node is distributed: #{Node.alive?()}")

# Node.list() returns connected nodes
IO.puts("Connected nodes: #{inspect(Node.list())}")

# Get all nodes including self
IO.puts("All known nodes: #{inspect([Node.self() | Node.list()])}")

# Node cookie (shared secret)
IO.puts("Node cookie: #{inspect(Node.get_cookie())}")

IO.puts("""

To experiment with distribution, open TWO terminals:

Terminal 1:
  iex --sname node1

Terminal 2:
  iex --sname node2

Then in node1's IEx:
  Node.connect(:node2@your_hostname)
  Node.list()  # Should show [:node2@your_hostname]
""")

# -----------------------------------------------------------------------------
# Section 3: Connecting Nodes
# -----------------------------------------------------------------------------
#
# Nodes connect using Node.connect/1. Once connected, they form a cluster.
# By default, BEAM creates a fully connected mesh (all nodes connect to all).
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 3: Connecting Nodes ---\n")

IO.puts("""
Connecting Nodes:
=================

Node.connect(:node2@hostname)
  - Returns true if connection succeeds
  - Returns false if connection fails
  - Node must be reachable and have same cookie

Node.disconnect(:node2@hostname)
  - Disconnects from a node

Node.list()
  - Lists all connected nodes

Node.ping(:node2@hostname)
  - Returns :pong if node is reachable
  - Returns :pang if not reachable

Connection Requirements:
1. Target node must be running
2. Target node must be reachable (network)
3. EPMD must be running on both machines
4. Same cookie on both nodes

Example Session:
----------------
# On node1:
iex(node1@machine)> Node.connect(:node2@machine)
true

iex(node1@machine)> Node.list()
[:node2@machine]

# Automatic bidirectional connection!
# On node2:
iex(node2@machine)> Node.list()
[:node1@machine]
""")

# Demonstrate connection attempt (will fail without actual nodes)
if Node.alive?() do
  test_node = :"test_node@localhost"
  IO.puts("Attempting to connect to #{test_node}...")
  result = Node.connect(test_node)
  IO.puts("Connection result: #{result}")
else
  IO.puts("(Skipping connection demo - not running as distributed node)")
end

# -----------------------------------------------------------------------------
# Section 4: Remote Procedure Calls with :rpc
# -----------------------------------------------------------------------------
#
# The :rpc module allows executing functions on remote nodes.
# This is a powerful way to distribute work across a cluster.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 4: Remote Procedure Calls ---\n")

IO.puts("""
:rpc Module Functions:
======================

:rpc.call(node, module, function, args)
  - Synchronous call to remote node
  - Waits for result
  - Returns {:badrpc, reason} on failure

:rpc.call(node, module, function, args, timeout)
  - Same but with timeout in milliseconds

:rpc.cast(node, module, function, args)
  - Asynchronous call (fire and forget)
  - Returns :true immediately

:rpc.multicall(nodes, module, function, args)
  - Call function on multiple nodes
  - Returns {results, bad_nodes}

:rpc.async_call(node, module, function, args)
  - Async with ability to fetch result later
  - Returns a key to use with :rpc.yield/1

Example Usage:
--------------
# Get list of processes on remote node
:rpc.call(:node2@machine, Process, :list, [])

# Get memory info from remote node
:rpc.call(:node2@machine, :erlang, :memory, [])

# Execute anonymous function remotely
:rpc.call(:node2@machine, Kernel, :apply, [fn -> Node.self() end, []])

# Async call to multiple nodes
{results, bad_nodes} = :rpc.multicall([node1, node2], Enum, :sum, [[1,2,3]])
""")

# Demonstrate RPC on local node (works even without distribution)
IO.puts("RPC call to self (demonstration):")
result = :rpc.call(Node.self(), Enum, :sum, [[1, 2, 3, 4, 5]])
IO.puts("  :rpc.call(self, Enum, :sum, [[1,2,3,4,5]]) = #{result}")

result = :rpc.call(Node.self(), String, :upcase, ["hello distributed world"])
IO.puts("  :rpc.call(self, String, :upcase, ['hello...']) = #{result}")

# Multi-call example
IO.puts("\nMulticall to self:")
{results, bad_nodes} = :rpc.multicall([Node.self()], :erlang, :node, [])
IO.puts("  Results: #{inspect(results)}")
IO.puts("  Bad nodes: #{inspect(bad_nodes)}")

# -----------------------------------------------------------------------------
# Section 5: Distributed Message Passing
# -----------------------------------------------------------------------------
#
# The same send/receive mechanism works across nodes!
# Just need to know the PID or registered name of the remote process.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 5: Distributed Message Passing ---\n")

IO.puts("""
Message Passing Across Nodes:
=============================

PIDs are globally unique and include node information.
You can send messages to remote PIDs just like local ones.

Ways to reference remote processes:

1. By PID (if you have it):
   send(remote_pid, {:hello, "world"})

2. By registered name (local registry):
   send({:registered_name, :node2@machine}, message)

3. By global registration:
   :global.register_name(:my_process, self())
   send(:global.whereis_name(:my_process), message)

4. By pg (process groups):
   :pg.join(:my_group, self())
   :pg.get_members(:my_group)

Example - Sending to named process on remote node:
--------------------------------------------------
# On node2, register a process:
Process.register(self(), :echo_server)

# On node1, send to it:
send({:echo_server, :node2@machine}, {:ping, self()})

# Receive response
receive do
  {:pong, from} -> IO.puts("Got pong from \#{inspect(from)}")
end
""")

# Demonstrate local named process messaging
defmodule EchoServer do
  def start do
    spawn(fn -> loop() end)
  end

  defp loop do
    receive do
      {:ping, from} ->
        IO.puts("EchoServer received ping from #{inspect(from)}")
        send(from, {:pong, self()})
        loop()

      {:echo, from, message} ->
        IO.puts("EchoServer echoing: #{message}")
        send(from, {:echoed, message})
        loop()

      :stop ->
        IO.puts("EchoServer stopping")
        :ok
    end
  end
end

echo_pid = EchoServer.start()
Process.register(echo_pid, :echo_server)

IO.puts("Started and registered :echo_server")

# Send via registered name (same as remote node pattern)
send({:echo_server, Node.self()}, {:ping, self()})

receive do
  {:pong, from} -> IO.puts("Received pong from #{inspect(from)}")
after
  1000 -> IO.puts("No response")
end

# Clean up
send(echo_pid, :stop)
Process.sleep(50)

# -----------------------------------------------------------------------------
# Section 6: Global Process Registration
# -----------------------------------------------------------------------------
#
# While Process.register/2 is local to a node, :global allows
# registering processes that can be found from any node in the cluster.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 6: Global Process Registration ---\n")

IO.puts("""
Global Process Registration:
============================

:global.register_name(name, pid)
  - Registers pid under name across the cluster
  - Returns :yes or :no

:global.whereis_name(name)
  - Finds globally registered process
  - Returns pid or :undefined

:global.unregister_name(name)
  - Removes global registration

:global.registered_names()
  - Lists all globally registered names

:global.re_register_name(name, pid)
  - Re-registers (useful after process restart)

Example:
--------
# Register globally
:global.register_name(:cluster_coordinator, self())

# Find from any node
pid = :global.whereis_name(:cluster_coordinator)

# Send message
send(:global.whereis_name(:cluster_coordinator), :hello)

Conflict Resolution:
-------------------
When two nodes try to register the same name, one wins.
You can provide a conflict resolver function:

:global.register_name(:my_name, pid, fn name, pid1, pid2 ->
  # Choose which one survives
  pid1  # or pid2
end)
""")

# Demonstrate global registration
demo_pid = spawn(fn ->
  receive do
    msg -> IO.puts("Global process received: #{inspect(msg)}")
  end
end)

result = :global.register_name(:demo_global_process, demo_pid)
IO.puts("Global registration result: #{result}")

IO.puts("Registered names: #{inspect(:global.registered_names())}")

found_pid = :global.whereis_name(:demo_global_process)
IO.puts("Found process: #{inspect(found_pid)}")

# Send to globally registered process
if found_pid != :undefined do
  send(found_pid, :hello_from_global)
  Process.sleep(50)
end

:global.unregister_name(:demo_global_process)

# -----------------------------------------------------------------------------
# Section 7: Process Groups with :pg
# -----------------------------------------------------------------------------
#
# Process groups allow organizing processes into named groups.
# Useful for pub/sub patterns and load distribution.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 7: Process Groups ---\n")

IO.puts("""
Process Groups (:pg module):
============================

:pg.start_link()
  - Starts the pg server (needed before use)

:pg.join(group, pid)
  - Adds pid to group

:pg.leave(group, pid)
  - Removes pid from group

:pg.get_members(group)
  - Returns all pids in group

:pg.get_local_members(group)
  - Returns local node's members only

:pg.which_groups()
  - Lists all groups

Use Cases:
- Pub/sub: broadcast to all members
- Load balancing: pick random member
- Discovery: find services by group
""")

# Start pg if not already started
case :pg.start_link() do
  {:ok, _} -> IO.puts("Started :pg")
  {:error, {:already_started, _}} -> IO.puts(":pg already running")
end

# Create some worker processes
workers = for i <- 1..3 do
  spawn(fn ->
    receive do
      {:work, from, data} ->
        result = "Worker #{i} processed: #{data}"
        send(from, {:result, result})
    end
  end)
end

# Join them to a group
Enum.each(workers, &:pg.join(:workers, &1))

IO.puts("\nProcess group :workers has #{length(:pg.get_members(:workers))} members")
IO.puts("Groups: #{inspect(:pg.which_groups())}")

# Send work to a random worker (load balancing pattern)
worker = Enum.random(:pg.get_members(:workers))
send(worker, {:work, self(), "important task"})

receive do
  {:result, result} -> IO.puts("Result: #{result}")
after
  1000 -> IO.puts("No response")
end

# Broadcast to all workers
IO.puts("\nBroadcasting to all workers:")
:pg.get_members(:workers)
|> Enum.each(fn pid ->
  send(pid, {:work, self(), "broadcast message"})
end)

# Collect results
for _ <- 1..length(:pg.get_members(:workers)) do
  receive do
    {:result, result} -> IO.puts("  #{result}")
  after
    100 -> :ok
  end
end

# -----------------------------------------------------------------------------
# Section 8: Node Monitoring
# -----------------------------------------------------------------------------
#
# Monitor nodes to detect disconnections and failures.
# Critical for building resilient distributed systems.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 8: Node Monitoring ---\n")

IO.puts("""
Node Monitoring:
================

Node.monitor(node, flag)
  - flag = true to start monitoring
  - flag = false to stop monitoring
  - Returns the previous monitoring state

When monitored node disconnects, you receive:
  {:nodedown, node}

When monitored node reconnects:
  {:nodeup, node}

Example:
--------
# Start monitoring
Node.monitor(:node2@machine, true)

# Handle in receive or handle_info
receive do
  {:nodedown, node} ->
    IO.puts("Node \#{node} went down!")

  {:nodeup, node} ->
    IO.puts("Node \#{node} is up!")
end

:net_kernel.monitor_nodes(true)
  - Monitor ALL node connects/disconnects
  - Simpler than monitoring individual nodes
""")

# Demonstrate local monitoring setup
IO.puts("Setting up node monitoring...")

# This would receive nodeup/nodedown for all nodes
# In a GenServer, use handle_info to process these
monitor_demo = spawn(fn ->
  :net_kernel.monitor_nodes(true)
  IO.puts("Node monitor started")

  receive do
    {:nodeup, node} ->
      IO.puts("NODE UP: #{node}")

    {:nodedown, node} ->
      IO.puts("NODE DOWN: #{node}")
  after
    100 -> IO.puts("(No node events during demo)")
  end
end)

Process.sleep(150)

# -----------------------------------------------------------------------------
# Section 9: Distributed ETS (DETS Alternative)
# -----------------------------------------------------------------------------
#
# ETS is local to a node. For distributed storage, you have options:
# - :mnesia (distributed database built into OTP)
# - :pg2/:pg for process groups (coordination)
# - Custom replication over message passing
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 9: Distributed Storage Options ---\n")

IO.puts("""
Distributed Storage in Elixir/Erlang:
=====================================

ETS is LOCAL - each node has its own tables.

Options for distributed storage:

1. Mnesia (built-in distributed database):
   - ACID transactions
   - Table replication across nodes
   - Schema management
   - Complex queries

   :mnesia.create_schema([node1, node2])
   :mnesia.create_table(:users, [
     disc_copies: [node1, node2],
     attributes: [:id, :name, :email]
   ])

2. Message-based replication:
   - Custom GenServer that syncs ETS changes
   - Publish changes to other nodes
   - Eventually consistent

3. External databases:
   - PostgreSQL, Redis, etc.
   - Consistent storage outside BEAM
   - Ecto for Phoenix apps

4. Libraries:
   - :syn - global process registry
   - Horde - distributed supervisor/registry
   - Swarm - process distribution
""")

# Simple distributed cache concept
defmodule DistributedCache do
  @moduledoc """
  Conceptual distributed cache using message passing.
  In practice, use a library like Cachex with distributed features.
  """

  def create_local_table do
    :ets.new(:dist_cache, [:set, :public, :named_table])
  end

  def put(key, value) do
    # Store locally
    :ets.insert(:dist_cache, {key, value})

    # Replicate to other nodes
    for node <- Node.list() do
      :rpc.cast(node, __MODULE__, :replicate_put, [key, value])
    end
  end

  def replicate_put(key, value) do
    :ets.insert(:dist_cache, {key, value})
  end

  def get(key) do
    case :ets.lookup(:dist_cache, key) do
      [{^key, value}] -> {:ok, value}
      [] -> :not_found
    end
  end
end

IO.puts("Distributed Cache concept module defined.")
IO.puts("(Would need actual nodes to demonstrate replication)")

# -----------------------------------------------------------------------------
# Section 10: Practical Distributed Patterns
# -----------------------------------------------------------------------------
#
# Common patterns for building distributed Elixir applications.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 10: Practical Distributed Patterns ---\n")

IO.puts("""
Common Distributed Patterns:
============================

1. Leader Election:
   - Use :global registration race
   - First to register becomes leader
   - Handle conflicts with resolver function

   defmodule Leader do
     def try_become_leader do
       case :global.register_name(:leader, self()) do
         :yes -> {:ok, :became_leader}
         :no -> {:ok, :follower}
       end
     end
   end

2. Work Distribution:
   - Use :pg process groups
   - Distribute work across group members
   - Round-robin or random selection

   def distribute_work(task) do
     workers = :pg.get_members(:workers)
     worker = Enum.random(workers)
     send(worker, {:task, task})
   end

3. Service Discovery:
   - Register services in :global or :pg
   - Find services by name/group

4. Cluster Formation:
   - libcluster library for automatic discovery
   - Kubernetes, DNS, or gossip-based

5. Consistent Hashing:
   - :hash_ring library
   - Distribute data/work by key

6. Circuit Breaker:
   - Track node failures
   - Stop sending to failed nodes
   - Retry after timeout
""")

# Demonstrate leader election pattern
defmodule LeaderElection do
  def start do
    spawn(__MODULE__, :run, [])
  end

  def run do
    # Try to become leader
    case :global.register_name(:cluster_leader, self()) do
      :yes ->
        IO.puts("#{inspect(self())} became the LEADER!")
        leader_loop()

      :no ->
        IO.puts("#{inspect(self())} is a follower")
        follower_loop()
    end
  end

  defp leader_loop do
    receive do
      {:get_leader, from} ->
        send(from, {:leader, self()})
        leader_loop()

      :step_down ->
        :global.unregister_name(:cluster_leader)
        IO.puts("Leader stepping down")
    end
  end

  defp follower_loop do
    receive do
      {:get_leader, from} ->
        leader = :global.whereis_name(:cluster_leader)
        send(from, {:leader, leader})
        follower_loop()

      :try_leader ->
        run()
    end
  end
end

# Demo leader election
:global.unregister_name(:cluster_leader)  # Clean slate

leader1 = LeaderElection.start()
Process.sleep(50)

leader2 = LeaderElection.start()
Process.sleep(50)

leader3 = LeaderElection.start()
Process.sleep(50)

# Find who's leader
send(leader2, {:get_leader, self()})
receive do
  {:leader, pid} -> IO.puts("Current leader: #{inspect(pid)}")
after
  100 -> IO.puts("Couldn't determine leader")
end

# Clean up
:global.unregister_name(:cluster_leader)

# -----------------------------------------------------------------------------
# Section 11: Running the Examples
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 11: Hands-On Exercise Setup ---\n")

IO.puts("""
To practice distributed Elixir, follow these steps:

Step 1: Start Node 1
--------------------
Open a terminal and run:

  iex --sname node1 --cookie secret

Step 2: Start Node 2
--------------------
Open another terminal and run:

  iex --sname node2 --cookie secret

Step 3: Connect the Nodes (in node1)
------------------------------------
  # Get your hostname
  hostname = node() |> to_string() |> String.split("@") |> List.last()

  # Connect to node2
  Node.connect(:"node2@\#{hostname}")

  # Verify connection
  Node.list()  # Should show [:node2@hostname]

Step 4: Try Remote Calls
------------------------
  # From node1, get info from node2
  :rpc.call(:node2@hostname, Node, :self, [])

  # Run code on node2
  :rpc.call(:node2@hostname, fn -> 1 + 1 end, [])

Step 5: Try Message Passing
---------------------------
  # On node2
  Process.register(self(), :shell)

  # On node1
  send({:shell, :node2@hostname}, "Hello from node1!")

  # On node2
  flush()  # See the message

Step 6: Try Global Registration
-------------------------------
  # On node1
  :global.register_name(:coordinator, self())

  # On node2
  :global.whereis_name(:coordinator)  # Returns pid from node1!
  send(:global.whereis_name(:coordinator), :hello)

  # On node1
  flush()  # See the message
""")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Exercise 1: Node Monitor GenServer
Difficulty: Medium

Create a GenServer that monitors all nodes in the cluster and maintains
a list of healthy/unhealthy nodes.

Implement:
- start_link/0
- get_healthy_nodes/0 - returns list of connected, healthy nodes
- get_unhealthy_nodes/0 - returns nodes that disconnected
- get_stats/0 - returns %{healthy: count, unhealthy: count, total: count}

The GenServer should:
1. Use :net_kernel.monitor_nodes(true) to receive node events
2. Track when nodes connect/disconnect
3. Record timestamps for state changes

Your code here:
""")

# defmodule NodeMonitor do
#   use GenServer
#
#   def start_link do
#     GenServer.start_link(__MODULE__, [], name: __MODULE__)
#   end
#
#   def get_healthy_nodes, do: GenServer.call(__MODULE__, :get_healthy)
#   def get_unhealthy_nodes, do: GenServer.call(__MODULE__, :get_unhealthy)
#   def get_stats, do: GenServer.call(__MODULE__, :get_stats)
#
#   @impl true
#   def init(_) do
#     :net_kernel.monitor_nodes(true)
#     {:ok, %{healthy: MapSet.new(), unhealthy: %{}}}
#   end
#
#   @impl true
#   def handle_info({:nodeup, node}, state) do
#     # TODO: Handle node connection
#     {:noreply, state}
#   end
#
#   @impl true
#   def handle_info({:nodedown, node}, state) do
#     # TODO: Handle node disconnection
#     {:noreply, state}
#   end
#
#   # TODO: Implement handle_call callbacks
# end

IO.puts("""

Exercise 2: Distributed Counter
Difficulty: Medium

Create a distributed counter that stays synchronized across nodes.
Use a leader-based approach where:
- One node is the "source of truth"
- Other nodes forward increment/decrement to leader
- Leader broadcasts new value to all nodes

Implement:
- start_link/0
- increment/0
- decrement/0
- get/0 - returns current value
- sync/0 - force sync with leader

Hint: Use :global for leader registration and :pg for follower list.

Your code here:
""")

# defmodule DistributedCounter do
#   use GenServer
#   ...
# end

IO.puts("""

Exercise 3: Service Registry
Difficulty: Medium

Create a distributed service registry where services can register
themselves and clients can discover services.

Features:
- Services register with a type (e.g., :database, :cache, :api)
- Multiple services can register with same type
- Clients can discover all services of a type
- Handle service crashes (remove from registry)

Implement:
- start_link/0
- register_service(type, metadata) - registers calling process
- unregister_service(type) - unregisters calling process
- discover(type) - returns list of {pid, metadata} for type
- discover_one(type) - returns random service of type

Your code here:
""")

# defmodule ServiceRegistry do
#   use GenServer
#   ...
# end

IO.puts("""

Exercise 4: Distributed Task Runner
Difficulty: Hard

Create a system that distributes tasks across cluster nodes.
Features:
- Submit tasks (functions) to be executed
- Tasks run on least-loaded node
- Results are returned to submitter
- Handle node failures (retry on another node)

Implement:
- start_link/0
- submit(fun) - submits anonymous function, returns {:ok, result} or {:error, reason}
- submit_async(fun) - returns task_id immediately
- get_result(task_id) - gets result of async task
- get_stats/0 - returns task counts per node

Your code here:
""")

# defmodule TaskRunner do
#   use GenServer
#
#   # Track tasks per node for load balancing
#   # Track pending async tasks for result retrieval
#
#   def submit(fun) do
#     # Pick least loaded node
#     # Execute task via :rpc.call
#     # Handle failures with retry
#   end
#
#   def submit_async(fun) do
#     # Generate task_id
#     # Spawn task execution
#     # Return task_id
#   end
#
#   ...
# end

IO.puts("""

Exercise 5: Distributed Lock Service
Difficulty: Hard

Create a distributed lock service that ensures only one process
across the cluster can hold a lock at a time.

Features:
- Acquire named locks
- Lock expiration (TTL)
- Lock queueing (wait for lock to be available)
- Handle lock holder crashes

Implement:
- start_link/0
- acquire(name, timeout \\\\ 5000, ttl \\\\ 30000)
  Returns {:ok, lock_ref} or {:error, :timeout}
- release(name, lock_ref)
- force_release(name) - admin function
- status(name) - returns lock info

Hint: Use :global for single-leader lock manager, or implement
consensus across nodes.

Your code here:
""")

# defmodule DistributedLock do
#   use GenServer
#   ...
# end

IO.puts("""

Exercise 6: Cluster Chat System
Difficulty: Hard

Build a simple chat system that works across a cluster:
- Users can join/leave rooms
- Messages sent to a room reach all members (across nodes)
- Room membership survives node failures (replication)

Implement:
- start_link/0
- join_room(room_name, username)
- leave_room(room_name)
- send_message(room_name, message)
- get_room_members(room_name)
- get_rooms/0 - list all rooms

Use :pg for process groups and :global or GenServer for room state.

Your code here:
""")

# defmodule ClusterChat do
#   use GenServer
#
#   # Consider: How to handle room state across nodes?
#   # Consider: What happens when a node with users goes down?
#   # Consider: How to broadcast messages efficiently?
#
#   ...
# end

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Key takeaways from this lesson:

1. Node Basics:
   - Start nodes with: iex --sname name or iex --name name@host
   - Node.self() returns current node name
   - Node.list() returns connected nodes
   - Node.connect(:node@host) connects to another node
   - Nodes must share the same cookie

2. Remote Procedure Calls (:rpc):
   - :rpc.call(node, mod, fun, args) - synchronous remote call
   - :rpc.cast(node, mod, fun, args) - async remote call
   - :rpc.multicall(nodes, mod, fun, args) - call multiple nodes
   - Returns {:badrpc, reason} on failure

3. Distributed Message Passing:
   - PIDs are globally unique (contain node info)
   - send(pid, message) works across nodes
   - send({:name, node}, message) for registered processes
   - Same API as local messaging!

4. Global Registration:
   - :global.register_name(name, pid) - cluster-wide registration
   - :global.whereis_name(name) - find globally registered process
   - Only ONE process can hold a global name

5. Process Groups (:pg):
   - :pg.join(group, pid) - add to group
   - :pg.get_members(group) - get all members
   - Great for pub/sub and load balancing

6. Node Monitoring:
   - Node.monitor(node, true) - monitor specific node
   - :net_kernel.monitor_nodes(true) - monitor all nodes
   - Receive {:nodeup, node} and {:nodedown, node}

7. Distributed Storage Options:
   - ETS is local only
   - Mnesia for distributed database
   - External databases via Ecto
   - Custom replication with messages

8. Common Patterns:
   - Leader election with :global
   - Work distribution with :pg
   - Service discovery
   - Consistent hashing

Best Practices:
- Use the same cookie for all cluster nodes
- Monitor nodes for disconnection handling
- Consider network partitions (split brain)
- Use libraries like libcluster for cluster formation
- Test failure scenarios thoroughly

Congratulations! You've completed the Advanced Concurrency section.
Next: Build the Chat System project to practice these concepts!
""")
