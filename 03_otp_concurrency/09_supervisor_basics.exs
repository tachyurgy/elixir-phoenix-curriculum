# ============================================================================
# Lesson 09: Supervisor Basics
# ============================================================================
#
# Supervisors are the foundation of fault-tolerant Elixir applications. They
# monitor child processes and restart them when they fail, implementing the
# "let it crash" philosophy that makes BEAM applications so resilient.
#
# Learning Objectives:
# - Understand the Supervisor behaviour and its role in OTP
# - Define child specifications for supervised processes
# - Start supervisors with Supervisor.start_link
# - Use the simplified Supervisor.start_link/2 with a list of children
# - Implement the Supervisor behaviour for custom supervisors
#
# Prerequisites:
# - GenServer basics (Lessons 05-08)
# - Process links and monitors (Lesson 04)
#
# ============================================================================

IO.puts("=" |> String.duplicate(70))
IO.puts("Lesson 09: Supervisor Basics")
IO.puts("=" |> String.duplicate(70))

# -----------------------------------------------------------------------------
# Section 1: Why Supervisors?
# -----------------------------------------------------------------------------
#
# In traditional programming, we try to prevent crashes at all costs. In Elixir
# and Erlang, we embrace crashes but ensure they don't bring down the system.
# Supervisors watch over processes and restart them when they fail.
#
# Benefits:
# - Automatic recovery from failures
# - Isolation of failures
# - Clean process state after restart
# - Hierarchical fault tolerance
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 1: Why Supervisors? ---\n")

IO.puts("""
The "Let it Crash" Philosophy:

Traditional approach:
  - Try to handle every possible error
  - Complex error handling code
  - State can become corrupted

Elixir/OTP approach:
  - Let processes crash when something unexpected happens
  - Supervisors automatically restart crashed processes
  - Fresh state after restart
  - Simpler, more reliable code

Supervision Tree Concept:
  ┌─────────────────────────────────────────┐
  │              Application                 │
  │                  │                       │
  │           ┌──────┴──────┐               │
  │           ▼             ▼               │
  │      Supervisor    Supervisor           │
  │       │     │          │                │
  │       ▼     ▼          ▼                │
  │    Worker Worker    Worker              │
  └─────────────────────────────────────────┘
""")

# -----------------------------------------------------------------------------
# Section 2: A Simple Worker Process
# -----------------------------------------------------------------------------
#
# Before we can supervise processes, we need processes to supervise.
# Let's create a simple GenServer that we'll use throughout this lesson.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 2: A Simple Worker Process ---\n")

defmodule Counter do
  @moduledoc """
  A simple counter GenServer that can be supervised.
  """
  use GenServer

  # Client API

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    initial_value = Keyword.get(opts, :initial_value, 0)
    GenServer.start_link(__MODULE__, initial_value, name: name)
  end

  def increment(server \\ __MODULE__) do
    GenServer.call(server, :increment)
  end

  def decrement(server \\ __MODULE__) do
    GenServer.call(server, :decrement)
  end

  def get_value(server \\ __MODULE__) do
    GenServer.call(server, :get_value)
  end

  def crash(server \\ __MODULE__) do
    GenServer.cast(server, :crash)
  end

  # Server Callbacks

  @impl true
  def init(initial_value) do
    IO.puts("Counter starting with initial value: #{initial_value}")
    {:ok, initial_value}
  end

  @impl true
  def handle_call(:increment, _from, state) do
    new_state = state + 1
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:decrement, _from, state) do
    new_state = state - 1
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:get_value, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:crash, _state) do
    raise "Intentional crash!"
  end

  @impl true
  def terminate(reason, state) do
    IO.puts("Counter terminating. Reason: #{inspect(reason)}, Final state: #{state}")
    :ok
  end
end

IO.puts("Counter module defined. This GenServer can be supervised.")

# -----------------------------------------------------------------------------
# Section 3: Child Specifications
# -----------------------------------------------------------------------------
#
# A child specification tells the supervisor how to start, stop, and restart
# a child process. It's a map with specific keys that describe the child.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 3: Child Specifications ---\n")

IO.puts("""
Child Specification Keys:

  :id        - Unique identifier for the child (required)
  :start     - {Module, :function, [args]} tuple (required)
  :restart   - When to restart: :permanent, :temporary, :transient
  :shutdown  - How long to wait for graceful shutdown
  :type      - :worker or :supervisor

Restart Strategies:
  :permanent  - Always restart (default for GenServer)
  :temporary  - Never restart
  :transient  - Restart only if terminated abnormally

Shutdown Values:
  :brutal_kill - Immediately kill the process
  5000         - Wait 5 seconds for graceful shutdown (default)
  :infinity    - Wait forever (common for supervisors)
""")

# Manual child specification
manual_child_spec = %{
  id: Counter,
  start: {Counter, :start_link, [[name: Counter]]},
  restart: :permanent,
  shutdown: 5000,
  type: :worker
}

IO.puts("Manual child specification:")
IO.inspect(manual_child_spec, pretty: true)

# Using child_spec/1 - GenServer and other OTP behaviours define this
# When you `use GenServer`, a default child_spec/1 is generated
IO.puts("\nChild spec generated by Counter module:")
IO.inspect(Counter.child_spec([]), pretty: true)

# You can override child_spec defaults in your module
defmodule CustomCounter do
  use GenServer, restart: :transient, shutdown: 10_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts), do: {:ok, Keyword.get(opts, :initial_value, 0)}
end

IO.puts("\nCustom child spec with overrides:")
IO.inspect(CustomCounter.child_spec([]), pretty: true)

# -----------------------------------------------------------------------------
# Section 4: Starting a Supervisor with start_link/2
# -----------------------------------------------------------------------------
#
# The simplest way to start a supervisor is with Supervisor.start_link/2,
# passing a list of child specifications and options.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 4: Starting a Supervisor with start_link/2 ---\n")

defmodule WorkerA do
  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    IO.puts("WorkerA (#{inspect(Keyword.get(opts, :name, __MODULE__))}) started")
    {:ok, opts}
  end
end

defmodule WorkerB do
  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    IO.puts("WorkerB (#{inspect(Keyword.get(opts, :name, __MODULE__))}) started")
    {:ok, opts}
  end
end

# Start a supervisor with children
children = [
  # Simplest form - just the module (uses default child_spec)
  WorkerA,

  # With options passed to start_link
  {WorkerB, [name: :worker_b_instance]}
]

IO.puts("Starting supervisor with children...")
{:ok, sup_pid} = Supervisor.start_link(children, strategy: :one_for_one)
IO.puts("Supervisor started with PID: #{inspect(sup_pid)}")

# Check which children are running
IO.puts("\nSupervisor children:")
Supervisor.which_children(sup_pid)
|> Enum.each(fn {id, pid, type, modules} ->
  IO.puts("  #{inspect(id)}: PID=#{inspect(pid)}, Type=#{type}, Modules=#{inspect(modules)}")
end)

# Count children
counts = Supervisor.count_children(sup_pid)
IO.puts("\nChild counts: #{inspect(counts)}")

# Clean up
Supervisor.stop(sup_pid)
IO.puts("\nSupervisor stopped")

# -----------------------------------------------------------------------------
# Section 5: Implementing the Supervisor Behaviour
# -----------------------------------------------------------------------------
#
# For more control, you can implement the Supervisor behaviour in a module.
# This is the recommended approach for production applications.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 5: Implementing the Supervisor Behaviour ---\n")

defmodule MyApp.Supervisor do
  @moduledoc """
  Application supervisor that manages worker processes.
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # Using the Supervisor.child_spec/2 helper to customize specs
      Supervisor.child_spec(
        {Counter, [name: :counter_one, initial_value: 0]},
        id: :counter_one
      ),
      Supervisor.child_spec(
        {Counter, [name: :counter_two, initial_value: 100]},
        id: :counter_two
      )
    ]

    # Initialize the supervisor with children and strategy
    Supervisor.init(children, strategy: :one_for_one)
  end
end

IO.puts("Starting MyApp.Supervisor...")
{:ok, app_sup} = MyApp.Supervisor.start_link([])

# Interact with supervised processes
IO.puts("\nInteracting with supervised counters:")
IO.puts("Counter one value: #{Counter.get_value(:counter_one)}")
IO.puts("Counter two value: #{Counter.get_value(:counter_two)}")

Counter.increment(:counter_one)
Counter.increment(:counter_one)
IO.puts("After incrementing counter_one twice: #{Counter.get_value(:counter_one)}")

# Show the supervision tree
IO.puts("\nSupervision tree:")
Supervisor.which_children(app_sup)
|> Enum.each(fn {id, pid, type, _modules} ->
  IO.puts("  #{inspect(id)}: #{inspect(pid)} (#{type})")
end)

Supervisor.stop(app_sup)

# -----------------------------------------------------------------------------
# Section 6: Observing Restart Behavior
# -----------------------------------------------------------------------------
#
# Let's see what happens when a supervised process crashes.
# The supervisor should automatically restart it.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 6: Observing Restart Behavior ---\n")

defmodule CrashableWorker do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_state, do: GenServer.call(__MODULE__, :get_state)
  def set_state(value), do: GenServer.call(__MODULE__, {:set_state, value})
  def crash!, do: GenServer.cast(__MODULE__, :crash)

  @impl true
  def init(opts) do
    IO.puts("CrashableWorker starting... (PID: #{inspect(self())})")
    {:ok, Keyword.get(opts, :initial_state, :fresh)}
  end

  @impl true
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call({:set_state, value}, _from, _state), do: {:reply, :ok, value}

  @impl true
  def handle_cast(:crash, _state) do
    raise "Intentional crash to demonstrate supervision!"
  end
end

defmodule CrashDemo.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {CrashableWorker, [initial_state: :initial]}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

IO.puts("Starting supervisor with CrashableWorker...")
{:ok, crash_sup} = CrashDemo.Supervisor.start_link([])

# Get the initial PID
initial_pid = Process.whereis(CrashableWorker)
IO.puts("Initial PID: #{inspect(initial_pid)}")
IO.puts("Initial state: #{inspect(CrashableWorker.get_state())}")

# Modify state
CrashableWorker.set_state(:modified)
IO.puts("Modified state: #{inspect(CrashableWorker.get_state())}")

# Crash the worker
IO.puts("\nCrashing the worker...")
CrashableWorker.crash!()

# Give the supervisor time to restart
Process.sleep(100)

# Check the new PID and state
new_pid = Process.whereis(CrashableWorker)
IO.puts("\nAfter crash:")
IO.puts("New PID: #{inspect(new_pid)}")
IO.puts("PIDs different? #{initial_pid != new_pid}")
IO.puts("State after restart: #{inspect(CrashableWorker.get_state())}")
IO.puts("\nNotice: State is back to :fresh (clean restart)")

Supervisor.stop(crash_sup)

# -----------------------------------------------------------------------------
# Section 7: Supervisor Options and Configuration
# -----------------------------------------------------------------------------
#
# Supervisors have several configuration options that control their behavior.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 7: Supervisor Options and Configuration ---\n")

IO.puts("""
Supervisor.init/2 Options:

  :strategy     - How to restart children (covered in next lesson)
                  :one_for_one, :one_for_all, :rest_for_one

  :max_restarts - Maximum restarts allowed in time period (default: 3)

  :max_seconds  - Time period for max_restarts (default: 5)

  :name         - Name to register the supervisor under

Example: max_restarts: 3, max_seconds: 5
  If a child crashes more than 3 times in 5 seconds,
  the supervisor itself will crash (and be restarted by its parent).

This prevents infinite restart loops!
""")

defmodule ConfiguredSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {Counter, [name: :configured_counter]}
    ]

    # Configure restart intensity
    Supervisor.init(children,
      strategy: :one_for_one,
      max_restarts: 5,     # Allow 5 restarts...
      max_seconds: 60      # ...per 60 seconds
    )
  end
end

IO.puts("ConfiguredSupervisor allows 5 restarts per 60 seconds")

# -----------------------------------------------------------------------------
# Section 8: Supervisor Helper Functions
# -----------------------------------------------------------------------------
#
# Supervisors provide several functions for runtime management of children.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 8: Supervisor Helper Functions ---\n")

defmodule RuntimeSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {Counter, [name: :runtime_counter, initial_value: 0]}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

{:ok, runtime_sup} = RuntimeSupervisor.start_link([])

IO.puts("Supervisor helper functions:\n")

# which_children/1 - List all children
IO.puts("1. which_children/1 - List all children:")
children_list = Supervisor.which_children(runtime_sup)
IO.inspect(children_list, pretty: true)

# count_children/1 - Get child counts by category
IO.puts("\n2. count_children/1 - Count children by category:")
counts = Supervisor.count_children(runtime_sup)
IO.inspect(counts)
IO.puts("  specs: #{counts[:specs]}, active: #{counts[:active]}, workers: #{counts[:workers]}, supervisors: #{counts[:supervisors]}")

# terminate_child/2 - Stop a specific child
IO.puts("\n3. terminate_child/2 - Stop a specific child:")
IO.puts("Counter running? #{Process.whereis(:runtime_counter) != nil}")
Supervisor.terminate_child(runtime_sup, Counter)
IO.puts("After terminate - Counter running? #{Process.whereis(:runtime_counter) != nil}")

# restart_child/2 - Restart a terminated child
IO.puts("\n4. restart_child/2 - Restart a terminated child:")
Supervisor.restart_child(runtime_sup, Counter)
IO.puts("After restart - Counter running? #{Process.whereis(:runtime_counter) != nil}")

# delete_child/2 - Remove child spec (must be terminated first)
IO.puts("\n5. delete_child/2 - Remove child specification:")
Supervisor.terminate_child(runtime_sup, Counter)
:ok = Supervisor.delete_child(runtime_sup, Counter)
IO.puts("Child spec deleted")

# start_child/2 - Add a new child at runtime
IO.puts("\n6. start_child/2 - Add new child at runtime:")
new_child_spec = {Counter, [name: :new_counter, initial_value: 42]}
{:ok, _pid} = Supervisor.start_child(runtime_sup, new_child_spec)
IO.puts("New counter value: #{Counter.get_value(:new_counter)}")

Supervisor.stop(runtime_sup)

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Exercise 1: Basic Supervised GenServer
Difficulty: Easy

Create a supervised `KeyValueStore` GenServer with:
- start_link/1 that accepts an initial map
- put(key, value) to store a value
- get(key) to retrieve a value
- delete(key) to remove a value

Then create a supervisor that starts this worker.

defmodule KeyValueStore do
  use GenServer
  # Your implementation
end

defmodule KVSupervisor do
  use Supervisor
  # Your implementation
end


Exercise 2: Multiple Workers
Difficulty: Easy

Create a supervisor that starts three Counter workers with different names:
- :counter_a starting at 0
- :counter_b starting at 100
- :counter_c starting at 1000

Use Supervisor.child_spec/2 to give each worker a unique ID.


Exercise 3: Custom Child Spec
Difficulty: Medium

Create a GenServer module that:
- Defines a custom child_spec/1 that sets restart: :transient
- Only restarts when it exits abnormally
- Exits normally when it receives a :stop message
- Crashes when it receives a :crash message

Test both scenarios and observe the restart behavior.


Exercise 4: Supervisor Runtime Management
Difficulty: Medium

Write a function that:
1. Starts a supervisor with 2 workers
2. Lists all children
3. Terminates one child
4. Verifies it's no longer running
5. Restarts the child
6. Adds a new child dynamically
7. Counts all children

def manage_supervisor do
  # Your implementation
end


Exercise 5: Restart Intensity Testing
Difficulty: Medium

Create a supervisor with max_restarts: 3, max_seconds: 5.
Write code that:
1. Starts the supervisor with a worker
2. Crashes the worker 3 times quickly (within 5 seconds)
3. Observes what happens on the 4th crash
4. Handle the supervisor crash gracefully

Hint: You'll need to trap exits to observe the supervisor crash.


Exercise 6: Worker with Dependencies
Difficulty: Hard

Create a system where:
- WorkerA provides data that WorkerB needs
- WorkerB calls WorkerA.get_data() in its init/1
- If WorkerA isn't running, WorkerB should handle it gracefully

Implement proper startup order using child specs and handle the case
where WorkerA crashes while WorkerB is running.

defmodule WorkerA do
  # Provides data
end

defmodule WorkerB do
  # Depends on WorkerA
end

defmodule DependencySupervisor do
  # Supervises both with proper ordering
end
""")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Key takeaways from this lesson:

1. Supervisors and the "Let it Crash" Philosophy:
   - Supervisors monitor and restart failed processes
   - Clean restart with fresh state
   - Isolates failures from the rest of the system

2. Child Specifications:
   - Define how to start, stop, and restart children
   - Key fields: :id, :start, :restart, :shutdown, :type
   - use GenServer generates default child_spec/1

3. Starting Supervisors:
   - Supervisor.start_link/2 for simple cases
   - `use Supervisor` for custom supervisor modules
   - Implement init/1 callback with Supervisor.init/2

4. Restart Options:
   - :permanent - always restart (default)
   - :temporary - never restart
   - :transient - restart only on abnormal exit

5. Restart Intensity:
   - max_restarts and max_seconds prevent infinite loops
   - Default: 3 restarts per 5 seconds
   - Supervisor crashes if limit exceeded

6. Runtime Management:
   - which_children/1 - list children
   - count_children/1 - count by category
   - terminate_child/2 - stop a child
   - restart_child/2 - restart a terminated child
   - start_child/2 - add new child
   - delete_child/2 - remove child spec

Next: 10_supervision_strategies.exs - Learn about :one_for_one, :one_for_all,
      and :rest_for_one strategies for handling child failures.
""")
