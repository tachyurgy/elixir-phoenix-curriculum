# ============================================================================
# Lesson 11: Dynamic Supervisors
# ============================================================================
#
# DynamicSupervisor is designed for scenarios where you need to start and
# stop children at runtime. Unlike regular Supervisors that define children
# at startup, DynamicSupervisors start with no children and add them on demand.
#
# Learning Objectives:
# - Understand when to use DynamicSupervisor vs Supervisor
# - Start and configure DynamicSupervisors
# - Add and remove children at runtime
# - Handle child termination and cleanup
# - Implement common DynamicSupervisor patterns
#
# Prerequisites:
# - Supervisor basics (Lesson 09)
# - Supervision strategies (Lesson 10)
#
# ============================================================================

IO.puts("=" |> String.duplicate(70))
IO.puts("Lesson 11: Dynamic Supervisors")
IO.puts("=" |> String.duplicate(70))

# -----------------------------------------------------------------------------
# Section 1: When to Use DynamicSupervisor
# -----------------------------------------------------------------------------
#
# Regular Supervisors are great when you know your children at compile time.
# DynamicSupervisor is for when children need to be created/removed at runtime.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 1: When to Use DynamicSupervisor ---\n")

IO.puts("""
Supervisor vs DynamicSupervisor:

┌─────────────────────────────────────────────────────────────────────┐
│                      Regular Supervisor                             │
├─────────────────────────────────────────────────────────────────────┤
│ • Children defined at compile time in init/1                       │
│ • Fixed number of children                                         │
│ • Children identified by ID in child_spec                          │
│ • Supports all three strategies                                    │
│                                                                     │
│ Use for: Database pools, configuration servers, core services      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                     DynamicSupervisor                               │
├─────────────────────────────────────────────────────────────────────┤
│ • Children added at runtime with start_child/2                     │
│ • Variable number of children                                      │
│ • Children identified by PID                                       │
│ • Only supports :one_for_one strategy                              │
│                                                                     │
│ Use for: User sessions, game rooms, file handlers, connections     │
└─────────────────────────────────────────────────────────────────────┘

Common DynamicSupervisor Use Cases:
• Chat rooms (created when users join)
• WebSocket connections (one per client)
• Background jobs (started on demand)
• Game sessions (created per game)
• File upload handlers (one per upload)
""")

# -----------------------------------------------------------------------------
# Section 2: Basic DynamicSupervisor Setup
# -----------------------------------------------------------------------------
#
# DynamicSupervisors are started with no children. Children are added later
# using DynamicSupervisor.start_child/2.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 2: Basic DynamicSupervisor Setup ---\n")

# Define a worker that we'll dynamically supervise
defmodule SessionWorker do
  use GenServer

  def start_link(opts) do
    session_id = Keyword.fetch!(opts, :session_id)
    user_id = Keyword.fetch!(opts, :user_id)
    GenServer.start_link(__MODULE__, opts, name: via_tuple(session_id))
  end

  defp via_tuple(session_id) do
    {:via, Registry, {SessionRegistry, session_id}}
  end

  def get_info(session_id) do
    GenServer.call(via_tuple(session_id), :get_info)
  end

  @impl true
  def init(opts) do
    session_id = Keyword.fetch!(opts, :session_id)
    user_id = Keyword.fetch!(opts, :user_id)
    IO.puts("  Session #{session_id} started for user #{user_id}")
    {:ok, %{session_id: session_id, user_id: user_id, created_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_call(:get_info, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def terminate(reason, state) do
    IO.puts("  Session #{state.session_id} terminated: #{inspect(reason)}")
    :ok
  end
end

# Start a registry for our sessions (we'll cover Registry in detail later)
{:ok, _registry} = Registry.start_link(keys: :unique, name: SessionRegistry)

# Method 1: Start DynamicSupervisor directly
IO.puts("Method 1: Start DynamicSupervisor.start_link/1")
{:ok, dsup1} = DynamicSupervisor.start_link(strategy: :one_for_one, name: :session_sup_1)
IO.puts("DynamicSupervisor started: #{inspect(dsup1)}")

# Check - no children initially
count1 = DynamicSupervisor.count_children(dsup1)
IO.puts("Initial children count: #{inspect(count1)}")

# Method 2: Using a module-based DynamicSupervisor
defmodule SessionSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # Convenience function to start a session
  def start_session(session_id, user_id) do
    child_spec = {SessionWorker, [session_id: session_id, user_id: user_id]}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  # Convenience function to stop a session
  def stop_session(session_id) do
    case Registry.lookup(SessionRegistry, session_id) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      [] -> {:error, :not_found}
    end
  end
end

IO.puts("\nMethod 2: Module-based DynamicSupervisor")
{:ok, _dsup2} = SessionSupervisor.start_link([])
IO.puts("SessionSupervisor started")

# Clean up dsup1
DynamicSupervisor.stop(dsup1)

# -----------------------------------------------------------------------------
# Section 3: Adding Children Dynamically
# -----------------------------------------------------------------------------
#
# Use DynamicSupervisor.start_child/2 to add children at runtime.
# Each child gets a unique process, supervised by the DynamicSupervisor.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 3: Adding Children Dynamically ---\n")

# Start some sessions
IO.puts("Starting sessions dynamically...")

{:ok, pid1} = SessionSupervisor.start_session("session_001", "alice")
{:ok, pid2} = SessionSupervisor.start_session("session_002", "bob")
{:ok, pid3} = SessionSupervisor.start_session("session_003", "charlie")

IO.puts("\nStarted sessions:")
IO.puts("  session_001: #{inspect(pid1)}")
IO.puts("  session_002: #{inspect(pid2)}")
IO.puts("  session_003: #{inspect(pid3)}")

# Count children
count = DynamicSupervisor.count_children(SessionSupervisor)
IO.puts("\nChildren count: #{inspect(count)}")

# List all children
IO.puts("\nAll children:")
DynamicSupervisor.which_children(SessionSupervisor)
|> Enum.each(fn {:undefined, pid, :worker, [SessionWorker]} ->
  IO.puts("  PID: #{inspect(pid)}")
end)

# Get info from a specific session
info = SessionWorker.get_info("session_001")
IO.puts("\nSession 001 info: #{inspect(info)}")

# -----------------------------------------------------------------------------
# Section 4: Removing Children
# -----------------------------------------------------------------------------
#
# Children can be removed with DynamicSupervisor.terminate_child/2.
# You need the PID of the child to terminate it.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 4: Removing Children ---\n")

IO.puts("Current session count: #{DynamicSupervisor.count_children(SessionSupervisor).active}")

# Terminate session_002
IO.puts("\nTerminating session_002...")
:ok = SessionSupervisor.stop_session("session_002")

IO.puts("Session count after termination: #{DynamicSupervisor.count_children(SessionSupervisor).active}")

# Try to get info from terminated session (should fail)
IO.puts("\nTrying to access terminated session...")
try do
  SessionWorker.get_info("session_002")
rescue
  e -> IO.puts("Error: #{inspect(e)}")
catch
  :exit, reason -> IO.puts("Exit: #{inspect(reason)}")
end

# -----------------------------------------------------------------------------
# Section 5: DynamicSupervisor Options
# -----------------------------------------------------------------------------
#
# DynamicSupervisor supports several configuration options.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 5: DynamicSupervisor Options ---\n")

IO.puts("""
DynamicSupervisor.init/1 Options:

  :strategy     - Always :one_for_one (only supported strategy)

  :max_restarts - Maximum restarts allowed in time period (default: 3)

  :max_seconds  - Time period for max_restarts (default: 5)

  :max_children - Maximum number of children allowed (default: :infinity)

  :extra_arguments - Additional arguments prepended to child's start_link
""")

defmodule LimitedSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      max_restarts: 5,
      max_seconds: 60,
      max_children: 3  # Only allow 3 children!
    )
  end
end

defmodule SimpleWorker do
  use GenServer

  def start_link(id) do
    GenServer.start_link(__MODULE__, id)
  end

  @impl true
  def init(id) do
    IO.puts("  SimpleWorker #{id} started")
    {:ok, id}
  end
end

{:ok, _} = LimitedSupervisor.start_link([])

IO.puts("Starting workers with max_children: 3...")
{:ok, _} = DynamicSupervisor.start_child(LimitedSupervisor, {SimpleWorker, 1})
{:ok, _} = DynamicSupervisor.start_child(LimitedSupervisor, {SimpleWorker, 2})
{:ok, _} = DynamicSupervisor.start_child(LimitedSupervisor, {SimpleWorker, 3})

# Try to add a 4th child
IO.puts("\nTrying to add 4th child...")
result = DynamicSupervisor.start_child(LimitedSupervisor, {SimpleWorker, 4})
IO.puts("Result: #{inspect(result)}")

DynamicSupervisor.stop(LimitedSupervisor)

# -----------------------------------------------------------------------------
# Section 6: Restart Behavior
# -----------------------------------------------------------------------------
#
# DynamicSupervisor uses :one_for_one strategy, so crashed children are
# restarted individually (unless restart: :temporary).
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 6: Restart Behavior ---\n")

defmodule CrashableSessionWorker do
  use GenServer

  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    GenServer.start_link(__MODULE__, opts, name: :"session_#{id}")
  end

  def crash!(id) do
    GenServer.cast(:"session_#{id}", :crash)
  end

  def get_pid(id) do
    Process.whereis(:"session_#{id}")
  end

  @impl true
  def init(opts) do
    id = Keyword.fetch!(opts, :id)
    IO.puts("  CrashableSession #{id} started (PID: #{inspect(self())})")
    {:ok, %{id: id}}
  end

  @impl true
  def handle_cast(:crash, state) do
    raise "Intentional crash!"
    {:noreply, state}
  end
end

defmodule CrashableSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

{:ok, _} = CrashableSupervisor.start_link([])

# Start two sessions
{:ok, _} = DynamicSupervisor.start_child(CrashableSupervisor, {CrashableSessionWorker, [id: 1]})
{:ok, _} = DynamicSupervisor.start_child(CrashableSupervisor, {CrashableSessionWorker, [id: 2]})

pid1_before = CrashableSessionWorker.get_pid(1)
pid2_before = CrashableSessionWorker.get_pid(2)

IO.puts("\nBefore crash:")
IO.puts("  Session 1 PID: #{inspect(pid1_before)}")
IO.puts("  Session 2 PID: #{inspect(pid2_before)}")

# Crash session 1
IO.puts("\nCrashing session 1...")
CrashableSessionWorker.crash!(1)
Process.sleep(100)

pid1_after = CrashableSessionWorker.get_pid(1)
pid2_after = CrashableSessionWorker.get_pid(2)

IO.puts("\nAfter crash:")
IO.puts("  Session 1 PID: #{inspect(pid1_after)} #{if pid1_after != pid1_before, do: "(restarted)"}")
IO.puts("  Session 2 PID: #{inspect(pid2_after)} #{if pid2_after == pid2_before, do: "(unchanged)"}")

DynamicSupervisor.stop(CrashableSupervisor)

# -----------------------------------------------------------------------------
# Section 7: Temporary Children
# -----------------------------------------------------------------------------
#
# By default, children use restart: :permanent. Use restart: :temporary
# for children that shouldn't be restarted when they crash.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 7: Temporary Children ---\n")

defmodule TemporaryWorker do
  use GenServer, restart: :temporary

  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    GenServer.start_link(__MODULE__, opts, name: :"temp_#{id}")
  end

  def crash!(id) do
    GenServer.cast(:"temp_#{id}", :crash)
  end

  @impl true
  def init(opts) do
    id = Keyword.fetch!(opts, :id)
    IO.puts("  TemporaryWorker #{id} started")
    {:ok, %{id: id}}
  end

  @impl true
  def handle_cast(:crash, _state) do
    raise "Crash!"
  end
end

defmodule TempSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

{:ok, _} = TempSupervisor.start_link([])

{:ok, _} = DynamicSupervisor.start_child(TempSupervisor, {TemporaryWorker, [id: 1]})
{:ok, _} = DynamicSupervisor.start_child(TempSupervisor, {TemporaryWorker, [id: 2]})

IO.puts("\nChildren before crash: #{DynamicSupervisor.count_children(TempSupervisor).active}")

IO.puts("\nCrashing temporary worker 1...")
TemporaryWorker.crash!(1)
Process.sleep(100)

IO.puts("Children after crash: #{DynamicSupervisor.count_children(TempSupervisor).active}")
IO.puts("Temporary workers are NOT restarted!")

DynamicSupervisor.stop(TempSupervisor)

# -----------------------------------------------------------------------------
# Section 8: Practical Example - Connection Pool
# -----------------------------------------------------------------------------
#
# A common pattern: using DynamicSupervisor to manage a pool of connections.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 8: Practical Example - Connection Pool ---\n")

defmodule Connection do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def execute(pid, query) do
    GenServer.call(pid, {:execute, query})
  end

  @impl true
  def init(opts) do
    pool_name = Keyword.get(opts, :pool, :default)
    IO.puts("    Connection started for pool #{pool_name}")
    {:ok, %{pool: pool_name, queries: 0}}
  end

  @impl true
  def handle_call({:execute, query}, _from, state) do
    # Simulate query execution
    Process.sleep(10)
    new_state = %{state | queries: state.queries + 1}
    {:reply, {:ok, "Result for: #{query}"}, new_state}
  end
end

defmodule ConnectionPool do
  use DynamicSupervisor

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    DynamicSupervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    # Start with some initial connections
    result = DynamicSupervisor.init(strategy: :one_for_one)

    # Schedule initial pool population
    pool_size = Keyword.get(opts, :pool_size, 3)
    send(self(), {:init_pool, pool_size, opts})

    result
  end

  def checkout(pool \\ __MODULE__) do
    children = DynamicSupervisor.which_children(pool)
    case children do
      [] -> {:error, :no_connections}
      list ->
        # Simple round-robin (in production, use a proper pool like poolboy)
        {_, pid, _, _} = Enum.random(list)
        {:ok, pid}
    end
  end

  def add_connection(pool \\ __MODULE__, opts \\ []) do
    DynamicSupervisor.start_child(pool, {Connection, opts})
  end

  def pool_size(pool \\ __MODULE__) do
    DynamicSupervisor.count_children(pool).active
  end
end

IO.puts("Starting connection pool with 3 connections...")
{:ok, pool} = ConnectionPool.start_link(pool_size: 3, name: :my_pool)

# Manually add connections (in production, init would handle this)
ConnectionPool.add_connection(:my_pool, [pool: :my_pool])
ConnectionPool.add_connection(:my_pool, [pool: :my_pool])
ConnectionPool.add_connection(:my_pool, [pool: :my_pool])

IO.puts("Pool size: #{ConnectionPool.pool_size(:my_pool)}")

# Use the pool
IO.puts("\nExecuting queries...")
{:ok, conn} = ConnectionPool.checkout(:my_pool)
{:ok, result} = Connection.execute(conn, "SELECT * FROM users")
IO.puts("Query result: #{result}")

DynamicSupervisor.stop(pool)

# Clean up SessionSupervisor from earlier
DynamicSupervisor.stop(SessionSupervisor)

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Exercise 1: Basic DynamicSupervisor
Difficulty: Easy

Create a DynamicSupervisor called TaskRunner that:
1. Can start "task" workers dynamically
2. Each task worker has a unique ID
3. Provides functions: run_task(id), stop_task(id), list_tasks()

Test by starting 3 tasks, listing them, and stopping one.


Exercise 2: Max Children Limit
Difficulty: Easy

Create a DynamicSupervisor with max_children: 5.
Write code that:
1. Tries to start 7 children
2. Handles the error for children 6 and 7 gracefully
3. Reports how many children were successfully started


Exercise 3: Session Manager
Difficulty: Medium

Implement a user session manager:
- SessionManager (DynamicSupervisor)
- Session (GenServer) with state: user_id, login_time, last_activity

Functions to implement:
- SessionManager.login(user_id) - creates a session, returns session_id
- SessionManager.logout(session_id) - terminates the session
- SessionManager.activity(session_id) - updates last_activity
- SessionManager.get_session(session_id) - returns session info
- SessionManager.active_sessions() - returns count


Exercise 4: Rate-Limited Worker Pool
Difficulty: Medium

Create a worker pool that:
1. Has a maximum of 10 workers
2. Tracks how many jobs each worker has processed
3. When a new job comes in:
   - If workers available, use least-busy worker
   - If at max capacity, queue the job
4. Workers process jobs and become available again

Implement: start_pool(), submit_job(job), get_stats()


Exercise 5: Graceful Shutdown
Difficulty: Medium

Create a DynamicSupervisor that:
1. Starts multiple workers that simulate long-running tasks
2. Implements a shutdown function that:
   - Signals all workers to finish current work
   - Waits for all workers to complete (with timeout)
   - Terminates any remaining workers
3. Tracks shutdown progress


Exercise 6: Hot-Swap Workers
Difficulty: Hard

Implement a system where:
1. Workers can be "upgraded" at runtime
2. DynamicSupervisor starts workers with version: 1
3. upgrade_all() function:
   - Starts new worker (version: 2) for each existing worker
   - Transfers state from old to new worker
   - Terminates old worker
4. Workers should continue serving requests during upgrade

This simulates blue-green deployment at the process level.

defmodule UpgradeableWorker do
  # Implement state transfer mechanism
end

defmodule UpgradeableSupervisor do
  # Implement upgrade_all/0
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

1. DynamicSupervisor vs Supervisor:
   - Supervisor: Fixed children defined at compile time
   - DynamicSupervisor: Children added/removed at runtime
   - DynamicSupervisor only supports :one_for_one strategy

2. Starting DynamicSupervisor:
   - DynamicSupervisor.start_link/1 for simple cases
   - `use DynamicSupervisor` for module-based approach
   - Always starts with zero children

3. Managing Children:
   - start_child/2: Add a new child
   - terminate_child/2: Stop a child by PID
   - which_children/1: List all children
   - count_children/1: Get child statistics

4. Configuration Options:
   - :max_children - Limit number of children
   - :max_restarts/:max_seconds - Restart intensity
   - :extra_arguments - Arguments added to all children

5. Restart Behavior:
   - Default restart: :permanent (always restart)
   - Use restart: :temporary for fire-and-forget workers
   - Use restart: :transient for workers that should only restart on crash

6. Common Patterns:
   - Session management
   - Connection pools
   - Job workers
   - Game rooms / chat rooms
   - File upload handlers

7. Best Practices:
   - Use Registry for named lookup of dynamic children
   - Implement convenience functions in supervisor module
   - Consider max_children to prevent resource exhaustion
   - Handle start_child errors gracefully

Next: 12_supervision_trees.exs - Learn how to compose supervisors into
      hierarchical supervision trees for complex applications.
""")
