# ============================================================================
# Lesson 12: Supervision Trees
# ============================================================================
#
# Supervision trees are hierarchical structures of supervisors and workers
# that form the backbone of fault-tolerant Elixir applications. Understanding
# how to design and implement supervision trees is crucial for building
# robust, production-ready systems.
#
# Learning Objectives:
# - Understand supervision tree architecture
# - Nest supervisors to create hierarchies
# - Design supervision trees for real applications
# - Implement application supervision trees
# - Use different strategies at different levels
#
# Prerequisites:
# - Supervisor basics (Lesson 09)
# - Supervision strategies (Lesson 10)
# - DynamicSupervisor (Lesson 11)
#
# ============================================================================

IO.puts("=" |> String.duplicate(70))
IO.puts("Lesson 12: Supervision Trees")
IO.puts("=" |> String.duplicate(70))

# -----------------------------------------------------------------------------
# Section 1: Understanding Supervision Trees
# -----------------------------------------------------------------------------
#
# A supervision tree is a hierarchical structure where:
# - The root is typically an Application supervisor
# - Internal nodes are supervisors
# - Leaves are workers (GenServers, Tasks, etc.)
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 1: Understanding Supervision Trees ---\n")

IO.puts("""
Supervision Tree Concepts:

┌─────────────────────────────────────────────────────────────────────┐
│                      Application                                    │
│                          │                                         │
│                    ┌─────┴─────┐                                   │
│                    ▼           ▼                                   │
│              Supervisor    Supervisor                              │
│              (Core)        (API)                                   │
│               │  │            │                                    │
│          ┌────┘  └────┐      │                                    │
│          ▼            ▼      ▼                                     │
│       Worker      Supervisor DynamicSupervisor                     │
│       (Cache)     (Database)  (Connections)                        │
│                    │    │                                          │
│                    ▼    ▼                                          │
│                 Worker Worker                                      │
│                 (Repo) (Pool)                                      │
└─────────────────────────────────────────────────────────────────────┘

Key Principles:

1. Isolation: Failures in one subtree don't affect siblings
2. Hierarchy: Each level can have different restart strategies
3. Responsibility: Supervisors manage, workers do work
4. Recovery: System can recover from failures at any level
""")

# -----------------------------------------------------------------------------
# Section 2: Basic Nested Supervisors
# -----------------------------------------------------------------------------
#
# Let's build a simple nested supervision tree step by step.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 2: Basic Nested Supervisors ---\n")

# Define some worker modules
defmodule CacheWorker do
  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def get(server, key), do: GenServer.call(server, {:get, key})
  def put(server, key, value), do: GenServer.call(server, {:put, key, value})

  @impl true
  def init(_opts) do
    IO.puts("    CacheWorker started")
    {:ok, %{}}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end

  @impl true
  def handle_call({:put, key, value}, _from, state) do
    {:reply, :ok, Map.put(state, key, value)}
  end
end

defmodule DatabaseWorker do
  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(_opts) do
    IO.puts("    DatabaseWorker started")
    {:ok, %{connected: true}}
  end
end

defmodule QueueWorker do
  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(_opts) do
    IO.puts("    QueueWorker started")
    {:ok, []}
  end
end

# Level 2 Supervisors
defmodule StorageSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    IO.puts("  StorageSupervisor starting...")
    children = [
      {CacheWorker, [name: :cache]},
      {DatabaseWorker, [name: :database]}
    ]
    # Cache and Database are independent
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule ProcessingSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    IO.puts("  ProcessingSupervisor starting...")
    children = [
      {QueueWorker, [name: :queue]}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

# Level 1: Top-level supervisor
defmodule TopSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    IO.puts("TopSupervisor starting...")
    children = [
      # Nested supervisors as children
      StorageSupervisor,
      ProcessingSupervisor
    ]
    # Subsystems are independent of each other
    Supervisor.init(children, strategy: :one_for_one)
  end
end

IO.puts("Starting nested supervision tree:\n")
{:ok, top_sup} = TopSupervisor.start_link([])

IO.puts("\nSupervision tree structure:")
IO.puts("""
TopSupervisor
├── StorageSupervisor
│   ├── CacheWorker (:cache)
│   └── DatabaseWorker (:database)
└── ProcessingSupervisor
    └── QueueWorker (:queue)
""")

# Demonstrate that children are running
IO.puts("Testing workers:")
CacheWorker.put(:cache, :test_key, "test_value")
IO.puts("  Cache put :test_key => \"test_value\"")
IO.puts("  Cache get :test_key => #{inspect(CacheWorker.get(:cache, :test_key))}")

Supervisor.stop(top_sup)
Process.sleep(50)

# -----------------------------------------------------------------------------
# Section 3: Supervisor Shutdown Order
# -----------------------------------------------------------------------------
#
# When a supervisor stops, it terminates children in reverse order.
# This is important for cleanup and dependencies.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 3: Supervisor Shutdown Order ---\n")

defmodule OrderedWorker do
  use GenServer

  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    GenServer.start_link(__MODULE__, opts, name: :"worker_#{id}")
  end

  @impl true
  def init(opts) do
    id = Keyword.fetch!(opts, :id)
    IO.puts("  Worker #{id} STARTED")
    {:ok, %{id: id}}
  end

  @impl true
  def terminate(reason, state) do
    IO.puts("  Worker #{state.id} STOPPED (#{inspect(reason)})")
    :ok
  end
end

defmodule OrderDemoSupervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      Supervisor.child_spec({OrderedWorker, [id: 1]}, id: :w1),
      Supervisor.child_spec({OrderedWorker, [id: 2]}, id: :w2),
      Supervisor.child_spec({OrderedWorker, [id: 3]}, id: :w3)
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

IO.puts("Starting supervisor (watch the order)...")
{:ok, order_sup} = OrderDemoSupervisor.start_link([])

IO.puts("\nStopping supervisor (children stop in REVERSE order)...")
Supervisor.stop(order_sup)
Process.sleep(50)

IO.puts("""

Note: Workers started 1, 2, 3 but stopped 3, 2, 1!
This allows later workers to clean up before their dependencies stop.
""")

# -----------------------------------------------------------------------------
# Section 4: Application Supervision Trees
# -----------------------------------------------------------------------------
#
# In a real Elixir application, the supervision tree is typically started
# by the Application module, which is configured in mix.exs.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 4: Application Supervision Trees ---\n")

IO.puts("""
In a Mix project, the supervision tree is started by the Application module:

# lib/my_app/application.ex
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts MyApp.Repo (Ecto)
      MyApp.Repo,
      # Starts the PubSub system
      {Phoenix.PubSub, name: MyApp.PubSub},
      # Starts the Endpoint (HTTP server)
      MyAppWeb.Endpoint,
      # Starts your custom supervisor
      MyApp.WorkerSupervisor
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# Configure in mix.exs:
def application do
  [
    mod: {MyApp.Application, []},
    extra_applications: [:logger]
  ]
end
""")

# Let's simulate an application-like structure
defmodule MyApp.Repo do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    IO.puts("    MyApp.Repo started (simulated database)")
    {:ok, %{}}
  end
end

defmodule MyApp.PubSub do
  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, [], name: name)
  end

  @impl true
  def init(_) do
    IO.puts("    MyApp.PubSub started (simulated pubsub)")
    {:ok, %{}}
  end
end

defmodule MyApp.Endpoint do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    IO.puts("    MyApp.Endpoint started (simulated HTTP server)")
    {:ok, %{}}
  end
end

defmodule MyApp.Application do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    IO.puts("MyApp.Application starting (simulated)...")
    children = [
      MyApp.Repo,
      {MyApp.PubSub, name: MyApp.PubSub},
      MyApp.Endpoint
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

IO.puts("Starting simulated application supervision tree:\n")
{:ok, app} = MyApp.Application.start_link([])
Supervisor.stop(app)

# -----------------------------------------------------------------------------
# Section 5: Combining Strategies in a Tree
# -----------------------------------------------------------------------------
#
# Different parts of your application may need different supervision strategies.
# Nested supervisors allow you to use the right strategy for each subsystem.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 5: Combining Strategies in a Tree ---\n")

# Workers for our example
defmodule Pool.Manager do
  use GenServer
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_), do: (IO.puts("      Pool.Manager started"); {:ok, %{}})
end

defmodule Pool.Connection do
  use GenServer
  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    GenServer.start_link(__MODULE__, opts, name: :"connection_#{id}")
  end
  @impl true
  def init(opts) do
    id = Keyword.fetch!(opts, :id)
    IO.puts("      Pool.Connection #{id} started")
    {:ok, %{id: id}}
  end
end

defmodule Pipeline.Receiver do
  use GenServer
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_), do: (IO.puts("      Pipeline.Receiver started"); {:ok, %{}})
end

defmodule Pipeline.Processor do
  use GenServer
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_), do: (IO.puts("      Pipeline.Processor started"); {:ok, %{}})
end

defmodule Pipeline.Sender do
  use GenServer
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_), do: (IO.puts("      Pipeline.Sender started"); {:ok, %{}})
end

# :one_for_all - Pool connections share state with manager
defmodule PoolSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    IO.puts("    PoolSupervisor starting (:one_for_all)...")
    children = [
      Pool.Manager,
      Supervisor.child_spec({Pool.Connection, [id: 1]}, id: :conn1),
      Supervisor.child_spec({Pool.Connection, [id: 2]}, id: :conn2)
    ]
    # All connections must restart if manager crashes
    Supervisor.init(children, strategy: :one_for_all)
  end
end

# :rest_for_one - Pipeline has sequential dependencies
defmodule PipelineSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    IO.puts("    PipelineSupervisor starting (:rest_for_one)...")
    children = [
      Pipeline.Receiver,   # First in pipeline
      Pipeline.Processor,  # Depends on Receiver
      Pipeline.Sender      # Depends on Processor
    ]
    # If Processor crashes, Sender must restart too
    Supervisor.init(children, strategy: :rest_for_one)
  end
end

# Top level - subsystems are independent
defmodule MixedStrategySupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    IO.puts("  MixedStrategySupervisor starting (:one_for_one)...")
    children = [
      PoolSupervisor,
      PipelineSupervisor
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

IO.puts("Starting mixed-strategy supervision tree:\n")
{:ok, mixed_sup} = MixedStrategySupervisor.start_link([])

IO.puts("""

Tree structure with strategies:
─────────────────────────────────
MixedStrategySupervisor (:one_for_one)
├── PoolSupervisor (:one_for_all)
│   ├── Pool.Manager
│   ├── Pool.Connection 1
│   └── Pool.Connection 2
└── PipelineSupervisor (:rest_for_one)
    ├── Pipeline.Receiver
    ├── Pipeline.Processor
    └── Pipeline.Sender
""")

Supervisor.stop(mixed_sup)

# -----------------------------------------------------------------------------
# Section 6: Designing Supervision Trees
# -----------------------------------------------------------------------------
#
# Guidelines for designing effective supervision trees.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 6: Designing Supervision Trees ---\n")

IO.puts("""
Supervision Tree Design Guidelines:

1. GROUP BY FAILURE DOMAIN
   ─────────────────────────
   Processes that should fail together go under the same supervisor.

   Example: All database-related processes under DatabaseSupervisor

2. SEPARATE CONCERNS
   ──────────────────
   Different subsystems get their own supervisor branches.

   Example:
   AppSupervisor
   ├── WebSupervisor      (HTTP handling)
   ├── WorkerSupervisor   (Background jobs)
   └── CacheSupervisor    (Caching layer)

3. CONSIDER STARTUP ORDER
   ───────────────────────
   Children start in order. Put dependencies first.

   Example: Database must start before API handlers

4. USE DYNAMIC SUPERVISORS APPROPRIATELY
   ──────────────────────────────────────
   For children created at runtime (sessions, connections)

   Example: User sessions under DynamicSupervisor

5. KEEP TREES SHALLOW WHEN POSSIBLE
   ─────────────────────────────────
   Deep trees add latency and complexity.
   Aim for 2-3 levels maximum.

6. NAME YOUR SUPERVISORS
   ──────────────────────
   Makes debugging and introspection easier.
   Use meaningful names like MyApp.WorkerSupervisor.

7. DOCUMENT STRATEGIES
   ────────────────────
   Comment why each strategy was chosen.
   Future maintainers will thank you!
""")

# -----------------------------------------------------------------------------
# Section 7: Inspecting Supervision Trees
# -----------------------------------------------------------------------------
#
# Tools for debugging and understanding supervision trees at runtime.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 7: Inspecting Supervision Trees ---\n")

# Rebuild a simple tree for inspection
defmodule InspectableWorker do
  use GenServer
  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    GenServer.start_link(__MODULE__, opts, name: :"iw_#{id}")
  end
  @impl true
  def init(opts), do: {:ok, opts}
end

defmodule LevelTwoSup do
  use Supervisor
  def start_link(opts) do
    id = Keyword.get(opts, :id, "default")
    Supervisor.start_link(__MODULE__, opts, name: :"level2_#{id}")
  end
  @impl true
  def init(opts) do
    id = Keyword.get(opts, :id, "default")
    children = [
      Supervisor.child_spec({InspectableWorker, [id: "#{id}_1"]}, id: :w1),
      Supervisor.child_spec({InspectableWorker, [id: "#{id}_2"]}, id: :w2)
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule LevelOneSup do
  use Supervisor
  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end
  @impl true
  def init(_) do
    children = [
      {LevelTwoSup, [id: "A"]},
      {LevelTwoSup, [id: "B"]}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

{:ok, _} = LevelOneSup.start_link([])

IO.puts("Inspecting supervision tree:\n")

# which_children shows direct children
IO.puts("1. Supervisor.which_children(LevelOneSup):")
Supervisor.which_children(LevelOneSup)
|> Enum.each(fn {id, pid, type, modules} ->
  IO.puts("   #{inspect(id)}: #{inspect(pid)} (#{type}) - #{inspect(modules)}")
end)

# count_children gives statistics
IO.puts("\n2. Supervisor.count_children(LevelOneSup):")
IO.inspect(Supervisor.count_children(LevelOneSup), label: "   ")

# Recursively show tree
defmodule TreeInspector do
  def print_tree(supervisor, indent \\ 0) do
    prefix = String.duplicate("  ", indent)

    Supervisor.which_children(supervisor)
    |> Enum.each(fn {id, pid, type, _modules} ->
      IO.puts("#{prefix}├── #{inspect(id)} (#{inspect(pid)}) [#{type}]")
      if type == :supervisor and is_pid(pid) do
        print_tree(pid, indent + 1)
      end
    end)
  end
end

IO.puts("\n3. Full tree visualization:")
IO.puts("LevelOneSup (#{inspect(Process.whereis(LevelOneSup))})")
TreeInspector.print_tree(LevelOneSup)

Supervisor.stop(LevelOneSup)

# -----------------------------------------------------------------------------
# Section 8: Real-World Example - Web Application Tree
# -----------------------------------------------------------------------------
#
# Let's look at a supervision tree you might see in a real web application.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 8: Real-World Example - Web Application Tree ---\n")

IO.puts("""
Typical Phoenix/Web Application Supervision Tree:

MyApp.Application
├── MyApp.Repo                           # Ecto database connection pool
├── MyApp.Telemetry                      # Metrics and monitoring
├── MyApp.PubSub                         # Phoenix.PubSub for real-time
├── MyApp.SchedulerSupervisor            # Scheduled jobs
│   ├── MyApp.DailyReportScheduler
│   └── MyApp.CleanupScheduler
├── MyApp.WorkerSupervisor               # Background job workers
│   └── (DynamicSupervisor)
│       ├── Job Worker 1
│       ├── Job Worker 2
│       └── ...
├── MyApp.CacheSupervisor
│   ├── MyApp.SessionCache
│   └── MyApp.QueryCache
└── MyAppWeb.Endpoint                    # Phoenix Endpoint
    ├── MyAppWeb.Socket                  # WebSocket handling
    └── Cowboy/Bandit HTTP Server

Key Design Decisions:
─────────────────────
• Repo starts first - everything else may need database
• PubSub before Endpoint - Endpoint uses PubSub
• Schedulers isolated - if one fails, others continue
• Workers in DynamicSupervisor - created per job
• Caches independent - one cache failure doesn't affect others
• Endpoint last - application ready when HTTP starts
""")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Exercise 1: Two-Level Tree
Difficulty: Easy

Create a supervision tree with:
- MainSupervisor (top level)
  - ServiceA (GenServer)
  - ServiceB (GenServer)
  - HelperSupervisor
    - Helper1 (GenServer)
    - Helper2 (GenServer)

Start the tree and verify all processes are running.


Exercise 2: Startup Order Dependencies
Difficulty: Easy

Create workers where:
- ConfigLoader must start first (loads config)
- DatabaseConnection starts second (needs config)
- CacheWarmer starts third (needs database)

Implement and verify they start in the correct order.
Add logging to prove the order.


Exercise 3: Strategy Selection Exercise
Difficulty: Medium

Design and implement a supervision tree for a notification system:
- NotificationRouter (routes notifications)
- EmailSender (sends emails)
- SMSSender (sends SMS)
- PushSender (sends push notifications)
- NotificationLogger (logs all notifications)

Decide on the appropriate strategy for each level and justify your choice.


Exercise 4: Tree Inspector Tool
Difficulty: Medium

Create a module that can:
1. Take a supervisor PID or name
2. Recursively traverse the supervision tree
3. Output a formatted tree view showing:
   - Process names/IDs
   - PIDs
   - Worker vs Supervisor
   - Restart strategy (if supervisor)


Exercise 5: Failure Propagation Testing
Difficulty: Medium

Create a 3-level supervision tree and write tests that verify:
1. Killing a leaf worker only restarts that worker
2. Killing a level-2 supervisor restarts its subtree
3. Killing the top supervisor restarts everything
4. Max restarts causes supervisor to die

Use Process.exit/2 to simulate failures.


Exercise 6: Dynamic + Static Hybrid Tree
Difficulty: Hard

Build a supervision tree for a game server:

GameSupervisor (:one_for_one)
├── PlayerRegistry (GenServer) - tracks online players
├── RoomSupervisor (DynamicSupervisor) - game rooms
│   ├── Room "lobby"
│   └── Room "arena_1" (dynamically created)
├── MatchmakerSupervisor (:rest_for_one)
│   ├── MatchQueue (GenServer)
│   └── MatchProcessor (GenServer, depends on queue)
└── StatsSupervisor (:one_for_all)
    ├── PlayerStats
    └── LeaderboardCache

Implement:
- Rooms created dynamically when players join
- Matchmaker as a pipeline
- Stats needing consistent state

Test failure scenarios for each branch.
""")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Key takeaways from this lesson:

1. Supervision Tree Structure:
   - Hierarchical tree of supervisors and workers
   - Root is typically the Application supervisor
   - Internal nodes are supervisors, leaves are workers

2. Nesting Supervisors:
   - Supervisors can supervise other supervisors
   - Different strategies at different levels
   - Isolates failure domains

3. Startup/Shutdown Order:
   - Children start in definition order
   - Children stop in reverse order
   - Put dependencies first in the children list

4. Application Integration:
   - use Application for the main supervisor
   - Configure in mix.exs with mod: option
   - Automatic startup when application starts

5. Design Principles:
   - Group by failure domain
   - Separate concerns into branches
   - Consider startup dependencies
   - Use DynamicSupervisor for runtime children
   - Keep trees shallow (2-3 levels)

6. Inspection Tools:
   - Supervisor.which_children/1
   - Supervisor.count_children/1
   - Process.whereis/1 for named processes
   - :observer.start() for GUI (in IEx)

7. Strategy at Each Level:
   - Top level: Usually :one_for_one (independent subsystems)
   - Pools: Often :one_for_all (shared state)
   - Pipelines: Usually :rest_for_one (sequential deps)
   - Dynamic children: DynamicSupervisor

Next: 13_agent.exs - Learn about Agent for simple state management.
""")
