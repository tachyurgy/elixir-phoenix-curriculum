# ============================================================================
# Lesson 10: Supervision Strategies
# ============================================================================
#
# Supervision strategies determine how a supervisor responds when a child
# process crashes. Choosing the right strategy depends on the relationships
# between your child processes and how failures should propagate.
#
# Learning Objectives:
# - Understand the three supervision strategies
# - Know when to use each strategy
# - Configure max_restarts and max_seconds
# - Design supervision trees with appropriate strategies
#
# Prerequisites:
# - Supervisor basics (Lesson 09)
# - GenServer callbacks
#
# ============================================================================

IO.puts("=" |> String.duplicate(70))
IO.puts("Lesson 10: Supervision Strategies")
IO.puts("=" |> String.duplicate(70))

# -----------------------------------------------------------------------------
# Section 1: Overview of Strategies
# -----------------------------------------------------------------------------
#
# Elixir/OTP provides three supervision strategies:
# - :one_for_one  - Restart only the failed child
# - :one_for_all  - Restart all children when one fails
# - :rest_for_one - Restart the failed child and those started after it
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 1: Overview of Strategies ---\n")

IO.puts("""
Supervision Strategies:

┌─────────────────────────────────────────────────────────────────────┐
│                         :one_for_one                                │
│                                                                     │
│  Before:    [A] [B] [C]       A crashes → Only A restarts          │
│  After:     [A'] [B] [C]      B and C are unaffected               │
│                                                                     │
│  Use when: Children are independent of each other                  │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         :one_for_all                                │
│                                                                     │
│  Before:    [A] [B] [C]       B crashes → All restart              │
│  After:     [A'] [B'] [C']   Everyone gets fresh state             │
│                                                                     │
│  Use when: Children share state or depend on each other           │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         :rest_for_one                               │
│                                                                     │
│  Before:    [A] [B] [C]       B crashes → B and C restart          │
│  After:     [A] [B'] [C']    A stays, later children restart       │
│                                                                     │
│  Use when: Later children depend on earlier ones (pipeline)        │
└─────────────────────────────────────────────────────────────────────┘
""")

# -----------------------------------------------------------------------------
# Section 2: Helper Modules for Demonstrations
# -----------------------------------------------------------------------------
#
# Let's create some worker modules that we'll use to demonstrate each strategy.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 2: Helper Modules for Demonstrations ---\n")

defmodule DemoWorker do
  @moduledoc """
  A configurable worker that logs its lifecycle events.
  Used to demonstrate supervision strategies.
  """
  use GenServer

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def get_info(name), do: GenServer.call(name, :get_info)
  def crash!(name), do: GenServer.cast(name, :crash)

  @impl true
  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    id = Keyword.get(opts, :id, name)
    IO.puts("  [#{id}] Starting (PID: #{inspect(self())})")
    {:ok, %{name: name, id: id, started_at: System.monotonic_time(:millisecond)}}
  end

  @impl true
  def handle_call(:get_info, _from, state) do
    {:reply, Map.put(state, :pid, self()), state}
  end

  @impl true
  def handle_cast(:crash, state) do
    IO.puts("  [#{state.id}] Crashing!")
    raise "Intentional crash in #{state.id}"
  end

  @impl true
  def terminate(reason, state) do
    IO.puts("  [#{state.id}] Terminating (reason: #{inspect(reason)})")
    :ok
  end
end

IO.puts("DemoWorker module defined for strategy demonstrations.")

# -----------------------------------------------------------------------------
# Section 3: :one_for_one Strategy
# -----------------------------------------------------------------------------
#
# The :one_for_one strategy only restarts the child that crashed.
# Other children are unaffected. This is the most common strategy.
#
# Use when:
# - Children are independent
# - Children don't share state
# - One child's failure doesn't affect others
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 3: :one_for_one Strategy ---\n")

defmodule OneForOneSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      Supervisor.child_spec({DemoWorker, [name: :worker_a, id: "A"]}, id: :worker_a),
      Supervisor.child_spec({DemoWorker, [name: :worker_b, id: "B"]}, id: :worker_b),
      Supervisor.child_spec({DemoWorker, [name: :worker_c, id: "C"]}, id: :worker_c)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

IO.puts("Starting OneForOneSupervisor...")
{:ok, sup1} = OneForOneSupervisor.start_link([])

# Get initial PIDs
pid_a_before = DemoWorker.get_info(:worker_a).pid
pid_b_before = DemoWorker.get_info(:worker_b).pid
pid_c_before = DemoWorker.get_info(:worker_c).pid

IO.puts("\nInitial PIDs:")
IO.puts("  A: #{inspect(pid_a_before)}")
IO.puts("  B: #{inspect(pid_b_before)}")
IO.puts("  C: #{inspect(pid_c_before)}")

# Crash worker B
IO.puts("\nCrashing worker B...")
DemoWorker.crash!(:worker_b)
Process.sleep(100)

# Get new PIDs
pid_a_after = DemoWorker.get_info(:worker_a).pid
pid_b_after = DemoWorker.get_info(:worker_b).pid
pid_c_after = DemoWorker.get_info(:worker_c).pid

IO.puts("\nAfter crash PIDs:")
IO.puts("  A: #{inspect(pid_a_after)} #{if pid_a_after == pid_a_before, do: "(unchanged)", else: "(CHANGED)"}")
IO.puts("  B: #{inspect(pid_b_after)} #{if pid_b_after == pid_b_before, do: "(unchanged)", else: "(CHANGED)"}")
IO.puts("  C: #{inspect(pid_c_after)} #{if pid_c_after == pid_c_before, do: "(unchanged)", else: "(CHANGED)"}")

IO.puts("\n:one_for_one result: Only B was restarted!")

Supervisor.stop(sup1)
Process.sleep(50)

# -----------------------------------------------------------------------------
# Section 4: :one_for_all Strategy
# -----------------------------------------------------------------------------
#
# The :one_for_all strategy restarts ALL children when any one crashes.
# All children are terminated and then restarted in order.
#
# Use when:
# - Children share state
# - Children's states must be consistent with each other
# - All children depend on each other
#
# Example: A pool of workers that share a database connection
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 4: :one_for_all Strategy ---\n")

defmodule OneForAllSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      Supervisor.child_spec({DemoWorker, [name: :all_a, id: "A"]}, id: :all_a),
      Supervisor.child_spec({DemoWorker, [name: :all_b, id: "B"]}, id: :all_b),
      Supervisor.child_spec({DemoWorker, [name: :all_c, id: "C"]}, id: :all_c)
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end

IO.puts("Starting OneForAllSupervisor...")
{:ok, sup2} = OneForAllSupervisor.start_link([])

# Get initial PIDs
pid_a_before = DemoWorker.get_info(:all_a).pid
pid_b_before = DemoWorker.get_info(:all_b).pid
pid_c_before = DemoWorker.get_info(:all_c).pid

IO.puts("\nInitial PIDs:")
IO.puts("  A: #{inspect(pid_a_before)}")
IO.puts("  B: #{inspect(pid_b_before)}")
IO.puts("  C: #{inspect(pid_c_before)}")

# Crash worker B
IO.puts("\nCrashing worker B...")
DemoWorker.crash!(:all_b)
Process.sleep(100)

# Get new PIDs
pid_a_after = DemoWorker.get_info(:all_a).pid
pid_b_after = DemoWorker.get_info(:all_b).pid
pid_c_after = DemoWorker.get_info(:all_c).pid

IO.puts("\nAfter crash PIDs:")
IO.puts("  A: #{inspect(pid_a_after)} #{if pid_a_after == pid_a_before, do: "(unchanged)", else: "(CHANGED)"}")
IO.puts("  B: #{inspect(pid_b_after)} #{if pid_b_after == pid_b_before, do: "(unchanged)", else: "(CHANGED)"}")
IO.puts("  C: #{inspect(pid_c_after)} #{if pid_c_after == pid_c_before, do: "(unchanged)", else: "(CHANGED)"}")

IO.puts("\n:one_for_all result: ALL workers were restarted!")

Supervisor.stop(sup2)
Process.sleep(50)

# -----------------------------------------------------------------------------
# Section 5: :rest_for_one Strategy
# -----------------------------------------------------------------------------
#
# The :rest_for_one strategy restarts the crashed child AND all children
# that were started AFTER it. Children started before are unaffected.
#
# Use when:
# - You have a pipeline of dependent processes
# - Later processes depend on earlier ones
# - Earlier processes are independent of later ones
#
# Example: Logger -> Formatter -> Writer (if Formatter crashes, Writer must restart)
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 5: :rest_for_one Strategy ---\n")

defmodule RestForOneSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Order matters! A starts first, then B, then C
    children = [
      Supervisor.child_spec({DemoWorker, [name: :rest_a, id: "A"]}, id: :rest_a),
      Supervisor.child_spec({DemoWorker, [name: :rest_b, id: "B"]}, id: :rest_b),
      Supervisor.child_spec({DemoWorker, [name: :rest_c, id: "C"]}, id: :rest_c)
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end

IO.puts("Starting RestForOneSupervisor...")
{:ok, sup3} = RestForOneSupervisor.start_link([])

# Get initial PIDs
pid_a_before = DemoWorker.get_info(:rest_a).pid
pid_b_before = DemoWorker.get_info(:rest_b).pid
pid_c_before = DemoWorker.get_info(:rest_c).pid

IO.puts("\nInitial PIDs (started in order A -> B -> C):")
IO.puts("  A: #{inspect(pid_a_before)}")
IO.puts("  B: #{inspect(pid_b_before)}")
IO.puts("  C: #{inspect(pid_c_before)}")

# Crash worker B (the middle one)
IO.puts("\nCrashing worker B...")
DemoWorker.crash!(:rest_b)
Process.sleep(100)

# Get new PIDs
pid_a_after = DemoWorker.get_info(:rest_a).pid
pid_b_after = DemoWorker.get_info(:rest_b).pid
pid_c_after = DemoWorker.get_info(:rest_c).pid

IO.puts("\nAfter crash PIDs:")
IO.puts("  A: #{inspect(pid_a_after)} #{if pid_a_after == pid_a_before, do: "(unchanged)", else: "(CHANGED)"}")
IO.puts("  B: #{inspect(pid_b_after)} #{if pid_b_after == pid_b_before, do: "(unchanged)", else: "(CHANGED)"}")
IO.puts("  C: #{inspect(pid_c_after)} #{if pid_c_after == pid_c_before, do: "(unchanged)", else: "(CHANGED)"}")

IO.puts("\n:rest_for_one result: B and C restarted, A unchanged!")

Supervisor.stop(sup3)
Process.sleep(50)

# -----------------------------------------------------------------------------
# Section 6: Real-World Strategy Examples
# -----------------------------------------------------------------------------
#
# Let's look at some practical examples of when to use each strategy.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 6: Real-World Strategy Examples ---\n")

IO.puts("""
Example 1: Web Server Workers (:one_for_one)
────────────────────────────────────────────
Each request handler is independent. If one crashes serving a request,
only that handler needs to restart. Other requests continue normally.

  children = [
    {RequestHandler, name: :handler_1},
    {RequestHandler, name: :handler_2},
    {RequestHandler, name: :handler_3}
  ]
  Supervisor.init(children, strategy: :one_for_one)


Example 2: Database Connection Pool (:one_for_all)
──────────────────────────────────────────────────
All connections share pool state. If the pool manager crashes,
all connections must restart to maintain consistent state.

  children = [
    {PoolManager, name: :pool},
    {Connection, pool: :pool, id: 1},
    {Connection, pool: :pool, id: 2},
    {Connection, pool: :pool, id: 3}
  ]
  Supervisor.init(children, strategy: :one_for_all)


Example 3: ETL Pipeline (:rest_for_one)
───────────────────────────────────────
Data flows: Extractor -> Transformer -> Loader
If Transformer crashes, Loader must restart (it may have stale data),
but Extractor can keep running.

  children = [
    {Extractor, name: :extractor},
    {Transformer, name: :transformer, source: :extractor},
    {Loader, name: :loader, source: :transformer}
  ]
  Supervisor.init(children, strategy: :rest_for_one)
""")

# -----------------------------------------------------------------------------
# Section 7: max_restarts and max_seconds
# -----------------------------------------------------------------------------
#
# Supervisors track restart intensity to prevent infinite restart loops.
# If a child crashes too many times in a short period, the supervisor
# itself will terminate.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 7: max_restarts and max_seconds ---\n")

IO.puts("""
Restart Intensity Configuration:

  max_restarts: 3    # Maximum number of restarts allowed
  max_seconds: 5     # Time window for counting restarts

Default: 3 restarts per 5 seconds

If exceeded, the supervisor terminates with reason :shutdown.
This prevents infinite restart loops and bubbles up the failure.
""")

defmodule UnstableWorker do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    crash_immediately = Keyword.get(opts, :crash, false)

    if crash_immediately do
      IO.puts("  UnstableWorker: Crashing immediately!")
      {:stop, :intentional_crash}
    else
      IO.puts("  UnstableWorker: Started successfully")
      {:ok, %{}}
    end
  end
end

defmodule RestartIntensitySupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    crash = Keyword.get(opts, :crash, false)

    children = [
      {UnstableWorker, [crash: crash]}
    ]

    # Low threshold for demonstration
    Supervisor.init(children,
      strategy: :one_for_one,
      max_restarts: 3,
      max_seconds: 5
    )
  end
end

# First, let's start with a stable worker
IO.puts("Starting with stable worker...")
{:ok, stable_sup} = RestartIntensitySupervisor.start_link(crash: false)
IO.puts("Supervisor running: #{Process.alive?(stable_sup)}")
Supervisor.stop(stable_sup)

# Now let's demonstrate restart intensity
IO.puts("\nStarting with unstable worker (will crash repeatedly)...")
IO.puts("Watch the supervisor exceed max_restarts...\n")

# Trap exits to observe supervisor termination
Process.flag(:trap_exit, true)

# Start supervisor with a child that crashes immediately
spawn_link(fn ->
  RestartIntensitySupervisor.start_link(crash: true)
end)

# Wait for and receive the exit message
receive do
  {:EXIT, _pid, reason} ->
    IO.puts("\nReceived EXIT with reason: #{inspect(reason)}")
    IO.puts("Supervisor terminated due to too many restarts!")
after
  2000 ->
    IO.puts("Timeout waiting for exit")
end

Process.flag(:trap_exit, false)

# -----------------------------------------------------------------------------
# Section 8: Choosing the Right Strategy
# -----------------------------------------------------------------------------
#
# A decision guide for selecting supervision strategies.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 8: Choosing the Right Strategy ---\n")

IO.puts("""
Strategy Selection Guide:

┌────────────────────────────────────────────────────────────────────┐
│                        Decision Tree                                │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  Are children independent of each other?                          │
│  │                                                                 │
│  ├── YES → Use :one_for_one                                       │
│  │         (Most common, safest default)                          │
│  │                                                                 │
│  └── NO  → Do later children depend on earlier children?          │
│            │                                                       │
│            ├── YES → Use :rest_for_one                            │
│            │         (Pipeline pattern)                           │
│            │                                                       │
│            └── NO  → Do they all share state?                     │
│                      │                                             │
│                      ├── YES → Use :one_for_all                   │
│                      │         (Shared state, must be consistent) │
│                      │                                             │
│                      └── NO  → Consider splitting into            │
│                                multiple supervisors                │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘

Tips:
• When in doubt, start with :one_for_one
• Use separate supervisors for groups with different strategies
• Test failure scenarios to validate your choice
• Consider using DynamicSupervisor for runtime-added children
""")

# -----------------------------------------------------------------------------
# Section 9: Practical Example - Multi-Strategy Supervision Tree
# -----------------------------------------------------------------------------
#
# Real applications often combine multiple strategies at different levels.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 9: Practical Example - Multi-Strategy Tree ---\n")

# A simple cache worker
defmodule CacheWorker do
  use GenServer

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    IO.puts("    CacheWorker #{name} started")
    {:ok, %{name: name}}
  end
end

# A simple API worker
defmodule APIWorker do
  use GenServer

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    IO.puts("    APIWorker #{name} started")
    {:ok, %{name: name}}
  end
end

# Supervisor for cache workers - independent workers
defmodule CacheSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    IO.puts("  CacheSupervisor starting...")
    children = [
      Supervisor.child_spec({CacheWorker, [name: :cache_1]}, id: :cache_1),
      Supervisor.child_spec({CacheWorker, [name: :cache_2]}, id: :cache_2)
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

# Supervisor for API workers - need consistent state
defmodule APISupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    IO.puts("  APISupervisor starting...")
    children = [
      Supervisor.child_spec({APIWorker, [name: :api_1]}, id: :api_1),
      Supervisor.child_spec({APIWorker, [name: :api_2]}, id: :api_2)
    ]
    Supervisor.init(children, strategy: :one_for_all)
  end
end

# Top-level supervisor
defmodule ApplicationSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    IO.puts("ApplicationSupervisor starting...")
    children = [
      # Cache supervisor with :one_for_one
      CacheSupervisor,
      # API supervisor with :one_for_all
      APISupervisor
    ]
    # Top level uses :one_for_one - subsystems are independent
    Supervisor.init(children, strategy: :one_for_one)
  end
end

IO.puts("Starting multi-strategy supervision tree:\n")
{:ok, app_sup} = ApplicationSupervisor.start_link([])

IO.puts("""

Supervision Tree Structure:
───────────────────────────
ApplicationSupervisor (:one_for_one)
├── CacheSupervisor (:one_for_one)
│   ├── CacheWorker :cache_1
│   └── CacheWorker :cache_2
└── APISupervisor (:one_for_all)
    ├── APIWorker :api_1
    └── APIWorker :api_2

• If cache_1 crashes, only cache_1 restarts
• If api_1 crashes, both api_1 and api_2 restart
• If CacheSupervisor crashes, only CacheSupervisor subtree restarts
""")

Supervisor.stop(app_sup)

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Exercise 1: Strategy Identification
Difficulty: Easy

For each scenario, identify the best supervision strategy:

a) Three independent HTTP request handlers
b) A connection pool with shared metadata
c) A data pipeline: Parser -> Validator -> Persister
d) Three microservices that communicate via message passing
e) A primary database and its replica synchronizer

Write your answers and explain your reasoning.


Exercise 2: Verify :one_for_one Behavior
Difficulty: Easy

Create a supervisor with 3 workers using :one_for_one strategy.
Write code that:
1. Records all initial PIDs
2. Crashes worker 2
3. Verifies only worker 2 has a new PID
4. Verifies workers 1 and 3 kept their original PIDs


Exercise 3: Verify :one_for_all Behavior
Difficulty: Easy

Create a supervisor with 3 workers using :one_for_all strategy.
Write code that:
1. Records all initial PIDs
2. Crashes any worker
3. Verifies ALL workers have new PIDs


Exercise 4: Pipeline with :rest_for_one
Difficulty: Medium

Implement a simple data processing pipeline:
- Producer: Generates numbers
- Transformer: Doubles the numbers
- Consumer: Stores the results

Use :rest_for_one strategy. Test that:
1. Crashing Consumer only restarts Consumer
2. Crashing Transformer restarts Transformer and Consumer
3. Crashing Producer restarts all three


Exercise 5: Restart Intensity Handling
Difficulty: Medium

Create a supervisor that:
1. Uses max_restarts: 2, max_seconds: 10
2. Has a worker that crashes based on a counter
3. The worker crashes on its first 2 starts, then stabilizes
4. Observe and log each restart attempt
5. Verify the supervisor survives (doesn't exceed limit)

Bonus: Make a version where the worker always crashes and handle
the supervisor's termination gracefully.


Exercise 6: Multi-Level Supervision Tree
Difficulty: Hard

Design and implement a supervision tree for a chat application:

TopSupervisor (:one_for_one)
├── RoomSupervisor (:one_for_one)
│   ├── Room "general"
│   └── Room "random"
├── UserSupervisor (:one_for_all)  # Users share auth state
│   ├── AuthManager
│   └── UserRegistry
└── MessagePipeline (:rest_for_one)
    ├── MessageReceiver
    ├── MessageFormatter
    └── MessageBroadcaster

Implement skeleton versions of each worker and test that:
1. Crashing a Room only affects that Room
2. Crashing AuthManager restarts both AuthManager and UserRegistry
3. Crashing MessageFormatter restarts Formatter and Broadcaster
""")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Key takeaways from this lesson:

1. Three Supervision Strategies:
   - :one_for_one  → Restart only the crashed child (default)
   - :one_for_all  → Restart all children
   - :rest_for_one → Restart crashed child and those after it

2. Strategy Selection:
   - :one_for_one for independent workers
   - :one_for_all for shared state/dependencies
   - :rest_for_one for pipelines/sequential dependencies

3. Restart Intensity:
   - max_restarts: Maximum restarts in time window (default: 3)
   - max_seconds: Time window size (default: 5)
   - Exceeding causes supervisor to terminate

4. Child Order Matters:
   - Children start in order defined
   - For :rest_for_one, put dependencies first
   - For :one_for_all, order affects restart sequence

5. Multi-Strategy Trees:
   - Use different strategies at different levels
   - Nest supervisors to isolate failure domains
   - Match strategy to relationship between children

6. Best Practices:
   - Default to :one_for_one unless you need otherwise
   - Test failure scenarios explicitly
   - Keep supervision trees shallow when possible
   - Document why you chose each strategy

Next: 11_dynamic_supervisors.exs - Learn how to add and remove children
      at runtime with DynamicSupervisor.
""")
