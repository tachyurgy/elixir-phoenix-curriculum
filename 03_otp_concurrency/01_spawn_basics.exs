# ============================================================================
# Lesson 01: Spawn Basics - Processes and PIDs in Elixir
# ============================================================================
#
# The BEAM (Erlang Virtual Machine) implements lightweight processes that are
# fundamental to Elixir's concurrency model. These are NOT operating system
# processes or threads - they are extremely lightweight (starting at ~2KB of
# memory) and managed entirely by the BEAM scheduler.
#
# Key concepts covered:
# - Process creation with spawn/1 and spawn/3
# - Process linking with spawn_link/1 and spawn_link/3
# - Process identifiers (PIDs)
# - The self() function
# - Checking if a process is alive with Process.alive?/1
#
# Run this file with: elixir 01_spawn_basics.exs
# Or in iex: c("01_spawn_basics.exs")
# ============================================================================

IO.puts("""
================================================================================
                    SPAWN BASICS - PROCESSES AND PIDs
================================================================================
""")

# ============================================================================
# Section 1: Understanding Processes and PIDs
# ============================================================================

IO.puts("""
--------------------------------------------------------------------------------
Section 1: Understanding Processes and PIDs
--------------------------------------------------------------------------------

In Elixir, every piece of code runs inside a process. When you start iex or
run a script, you're already in a process. Processes in the BEAM are:

- Lightweight: Each process starts with only ~2KB of memory
- Isolated: Processes share no memory; they communicate via messages
- Preemptively scheduled: The BEAM scheduler manages all processes
- Garbage collected independently: No global GC pauses

Let's explore the current process first:
""")

# The self() function returns the PID of the current process
current_pid = self()
IO.puts("Current process PID: #{inspect(current_pid)}")

# PIDs have a specific format: #PID<node.id1.id2>
# - node: 0 for local node
# - id1, id2: unique identifiers for the process
IO.puts("PID is a reference type: #{is_pid(current_pid)}")

# Check if the current process is alive
IO.puts("Is current process alive? #{Process.alive?(current_pid)}")

# Get process info
info = Process.info(current_pid)
IO.puts("\nCurrent process info (selected):")
IO.puts("  - Heap size: #{info[:heap_size]} words")
IO.puts("  - Stack size: #{info[:stack_size]} words")
IO.puts("  - Reductions: #{info[:reductions]}")
IO.puts("  - Message queue length: #{info[:message_queue_len]}")

# ============================================================================
# Section 2: Creating Processes with spawn/1
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 2: Creating Processes with spawn/1
--------------------------------------------------------------------------------

spawn/1 creates a new process that executes the given function. The function
runs in the new process and when it completes, the process terminates.
""")

# Basic spawn - the simplest form
IO.puts("Spawning a simple process...")

pid1 = spawn(fn ->
  IO.puts("  Hello from spawned process! My PID is #{inspect(self())}")
end)

IO.puts("Spawned process PID: #{inspect(pid1)}")

# Give the spawned process time to execute
Process.sleep(50)

IO.puts("Is spawned process still alive? #{Process.alive?(pid1)}")

# spawn/3 allows you to specify module, function, and arguments
IO.puts("\nUsing spawn/3 with module, function, arguments:")

defmodule Greeter do
  def greet(name) do
    IO.puts("  Hello, #{name}! (from PID #{inspect(self())})")
  end

  def greet_multiple(names) when is_list(names) do
    Enum.each(names, fn name ->
      IO.puts("  Greetings, #{name}!")
    end)
  end
end

pid2 = spawn(Greeter, :greet, ["Alice"])
pid3 = spawn(Greeter, :greet_multiple, [["Bob", "Charlie", "Diana"]])

Process.sleep(50)

# ============================================================================
# Section 3: Process Isolation
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 3: Process Isolation
--------------------------------------------------------------------------------

Each process has its own memory space. Variables defined in one process are
not accessible in another. This is a fundamental property of the BEAM.
""")

my_variable = "I am in the parent process"

spawn(fn ->
  # This process has its own scope
  # It CANNOT access my_variable from the parent directly
  # But we can pass data when creating the process using closures
  IO.puts("  Child process sees nothing from parent scope directly")
end)

# However, closures capture values (not references)
spawn(fn ->
  # This works because the VALUE is copied into the new process
  IO.puts("  Captured value: #{my_variable}")
end)

Process.sleep(50)

# Demonstrating true isolation
counter = 0

spawn(fn ->
  # This creates a NEW variable called counter in this process
  counter = 100
  IO.puts("  Counter in child process: #{counter}")
end)

Process.sleep(50)
IO.puts("Counter in parent process: #{counter}")  # Still 0!

# ============================================================================
# Section 4: spawn_link/1 - Linked Processes
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 4: spawn_link/1 - Linked Processes
--------------------------------------------------------------------------------

spawn_link/1 creates a process AND establishes a bidirectional link between
the parent and child. If either process crashes, the other will receive an
exit signal and (by default) also crash. This is called "let it crash" and
is fundamental to building fault-tolerant systems.
""")

# Demonstrating spawn_link (we'll catch the exit to avoid crashing our script)
defmodule LinkDemo do
  def run_safe_demo do
    IO.puts("Parent process: #{inspect(self())}")

    # Trap exits so we receive exit signals as messages instead of crashing
    Process.flag(:trap_exit, true)

    # Spawn a linked process that will crash
    pid = spawn_link(fn ->
      IO.puts("  Child process #{inspect(self())} starting...")
      Process.sleep(100)
      IO.puts("  Child process completing normally")
    end)

    IO.puts("Spawned linked process: #{inspect(pid)}")

    # Wait for the exit message
    receive do
      {:EXIT, ^pid, reason} ->
        IO.puts("Received EXIT from #{inspect(pid)}, reason: #{inspect(reason)}")
    after
      500 -> IO.puts("No exit message received")
    end

    # Reset trap_exit
    Process.flag(:trap_exit, false)
  end

  def run_crash_demo do
    IO.puts("\nDemonstrating a crashing linked process:")
    Process.flag(:trap_exit, true)

    pid = spawn_link(fn ->
      IO.puts("  Child process starting, about to crash...")
      Process.sleep(50)
      raise "Intentional crash!"
    end)

    receive do
      {:EXIT, ^pid, reason} ->
        IO.puts("Received EXIT from crashed process!")
        IO.puts("Exit reason: #{inspect(reason)}")
    after
      500 -> IO.puts("No exit message received")
    end

    Process.flag(:trap_exit, false)
  end
end

LinkDemo.run_safe_demo()
LinkDemo.run_crash_demo()

# ============================================================================
# Section 5: Creating Many Processes
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 5: Creating Many Processes
--------------------------------------------------------------------------------

One of BEAM's strengths is handling millions of processes. Let's create
many processes to see how lightweight they are.
""")

defmodule MassSpawn do
  def create_processes(n) do
    IO.puts("Creating #{n} processes...")

    {time_microseconds, pids} = :timer.tc(fn ->
      Enum.map(1..n, fn i ->
        spawn(fn ->
          # Each process just stores a number and waits
          receive do
            :done -> :ok
          end
        end)
      end)
    end)

    IO.puts("Created #{length(pids)} processes in #{time_microseconds / 1000} ms")
    IO.puts("All alive? #{Enum.all?(pids, &Process.alive?/1)}")

    # Clean up - send done message to all
    Enum.each(pids, fn pid -> send(pid, :done) end)
    Process.sleep(100)

    IO.puts("After cleanup, all dead? #{Enum.all?(pids, fn p -> !Process.alive?(p) end)}")
  end
end

MassSpawn.create_processes(1000)

# ============================================================================
# Section 6: Process Registration
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 6: Process Registration
--------------------------------------------------------------------------------

Processes can be registered with names (atoms) for easy lookup. This is
useful when you need to communicate with a specific process without
tracking its PID.
""")

defmodule NamedProcess do
  def start do
    spawn(fn -> loop() end)
  end

  defp loop do
    receive do
      {:greet, name} ->
        IO.puts("  Named process says: Hello, #{name}!")
        loop()
      :stop ->
        IO.puts("  Named process stopping...")
        :ok
    end
  end
end

# Start and register a process
pid = NamedProcess.start()
Process.register(pid, :my_greeter)

IO.puts("Registered process :my_greeter with PID #{inspect(pid)}")
IO.puts("Looking up :my_greeter: #{inspect(Process.whereis(:my_greeter))}")

# Send messages using the registered name
send(:my_greeter, {:greet, "World"})
Process.sleep(50)

# Check registered processes
IO.puts("\nAll registered processes: #{inspect(Process.registered() |> Enum.take(5))}...")

# Unregister and stop
send(:my_greeter, :stop)
Process.sleep(50)
Process.unregister(:my_greeter) rescue nil

# ============================================================================
# Section 7: Process Dictionary (Use Sparingly!)
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 7: Process Dictionary (Use Sparingly!)
--------------------------------------------------------------------------------

Each process has a process dictionary - a key-value store local to that
process. While available, it's generally discouraged in favor of explicit
state passing because it introduces implicit state.
""")

# Put and get from process dictionary
Process.put(:my_key, "my value")
IO.puts("Process dictionary value: #{Process.get(:my_key)}")

# Get all keys
Process.put(:another_key, 42)
IO.puts("All process dictionary keys: #{inspect(Process.get_keys())}")

# Delete a key
Process.delete(:my_key)
IO.puts("After delete: #{inspect(Process.get(:my_key))}")

# Note: Each spawned process starts with an empty process dictionary
spawn(fn ->
  IO.puts("  Child process dictionary: #{inspect(Process.get_keys())}")  # Empty!
end)

Process.sleep(50)

# ============================================================================
# EXERCISES
# ============================================================================

IO.puts("""

================================================================================
                              EXERCISES
================================================================================

Exercise 1: Process Counter
---------------------------
Create a function that spawns N processes, where each process prints its
number (1 to N) and its PID. Verify that all processes complete.

Exercise 2: Process Tree
------------------------
Create a function that spawns a "root" process, which in turn spawns 3
"child" processes. Each child should report its PID and its parent's PID.
Use spawn_link to link children to the root.

Exercise 3: Process Info Explorer
---------------------------------
Create a module that spawns a process and then prints detailed information
about it using Process.info/1. Include:
- Memory usage
- Current function
- Status
- Message queue length

Exercise 4: Parallel Computation
--------------------------------
Create a function that takes a list of numbers and spawns a process for
each number to compute its square. Collect the results (hint: you'll need
message passing from the next lesson, but try designing the structure).

Exercise 5: Process Lifecycle Observer
--------------------------------------
Create a function that:
1. Spawns a process
2. Checks if it's alive (should be true)
3. Waits for it to complete its work
4. Checks if it's alive again (should be false)
Use Process.alive?/1 and appropriate timing.

Exercise 6: Named Process Manager
---------------------------------
Create a module that:
1. Starts a process and registers it with a given name
2. Provides a function to check if the named process exists
3. Provides a function to stop and unregister the named process
Handle the case where the process might already be registered.
""")

# ============================================================================
# Exercise Solutions (uncomment to run)
# ============================================================================

IO.puts("""
--------------------------------------------------------------------------------
Exercise Solutions
--------------------------------------------------------------------------------
""")

# Exercise 1 Solution
defmodule Exercise1 do
  def spawn_numbered_processes(n) do
    IO.puts("Exercise 1: Spawning #{n} numbered processes")

    pids = Enum.map(1..n, fn i ->
      spawn(fn ->
        IO.puts("  Process ##{i}: #{inspect(self())}")
      end)
    end)

    Process.sleep(100)
    completed = Enum.count(pids, fn pid -> !Process.alive?(pid) end)
    IO.puts("Completed: #{completed}/#{n} processes")
  end
end

Exercise1.spawn_numbered_processes(5)

# Exercise 2 Solution
defmodule Exercise2 do
  def create_tree do
    IO.puts("\nExercise 2: Creating process tree")
    parent_pid = self()

    root_pid = spawn(fn ->
      IO.puts("  Root process: #{inspect(self())}, spawned by #{inspect(parent_pid)}")
      root = self()

      children = Enum.map(1..3, fn i ->
        spawn_link(fn ->
          IO.puts("    Child ##{i}: #{inspect(self())}, parent: #{inspect(root)}")
          Process.sleep(100)
        end)
      end)

      # Wait for children
      Process.sleep(150)
    end)

    Process.sleep(200)
    IO.puts("Tree completed, root alive? #{Process.alive?(root_pid)}")
  end
end

Exercise2.create_tree()

# Exercise 3 Solution
defmodule Exercise3 do
  def explore_process_info do
    IO.puts("\nExercise 3: Process Info Explorer")

    pid = spawn(fn ->
      # Do some work to have interesting stats
      _list = Enum.map(1..1000, &(&1 * 2))
      Process.sleep(500)
    end)

    Process.sleep(50)  # Let it start

    info = Process.info(pid)
    IO.puts("Process #{inspect(pid)} info:")
    IO.puts("  Memory: #{info[:memory]} bytes")
    IO.puts("  Current function: #{inspect(info[:current_function])}")
    IO.puts("  Status: #{info[:status]}")
    IO.puts("  Message queue length: #{info[:message_queue_len]}")
    IO.puts("  Heap size: #{info[:heap_size]} words")
    IO.puts("  Stack size: #{info[:stack_size]} words")
    IO.puts("  Reductions: #{info[:reductions]}")
  end
end

Exercise3.explore_process_info()

# Exercise 5 Solution
defmodule Exercise5 do
  def observe_lifecycle do
    IO.puts("\nExercise 5: Process Lifecycle Observer")

    pid = spawn(fn ->
      IO.puts("  Process started, doing work...")
      Process.sleep(100)
      IO.puts("  Process completing...")
    end)

    IO.puts("Immediately after spawn - alive? #{Process.alive?(pid)}")
    Process.sleep(50)
    IO.puts("After 50ms - alive? #{Process.alive?(pid)}")
    Process.sleep(100)
    IO.puts("After 150ms total - alive? #{Process.alive?(pid)}")
  end
end

Exercise5.observe_lifecycle()

# Exercise 6 Solution
defmodule Exercise6 do
  def start_named(name) do
    case Process.whereis(name) do
      nil ->
        pid = spawn(fn -> loop() end)
        Process.register(pid, name)
        {:ok, pid}
      _pid ->
        {:error, :already_registered}
    end
  end

  def exists?(name) do
    case Process.whereis(name) do
      nil -> false
      pid -> Process.alive?(pid)
    end
  end

  def stop_named(name) do
    case Process.whereis(name) do
      nil ->
        {:error, :not_found}
      pid ->
        Process.unregister(name)
        Process.exit(pid, :normal)
        :ok
    end
  end

  defp loop do
    receive do
      :stop -> :ok
      _ -> loop()
    end
  end

  def demo do
    IO.puts("\nExercise 6: Named Process Manager")

    IO.puts("Starting :my_worker...")
    {:ok, pid} = start_named(:my_worker)
    IO.puts("Started with PID: #{inspect(pid)}")

    IO.puts("Exists? #{exists?(:my_worker)}")

    IO.puts("Trying to start again...")
    result = start_named(:my_worker)
    IO.puts("Result: #{inspect(result)}")

    IO.puts("Stopping :my_worker...")
    stop_named(:my_worker)
    Process.sleep(50)
    IO.puts("Exists after stop? #{exists?(:my_worker)}")
  end
end

Exercise6.demo()

IO.puts("""

================================================================================
                    End of Lesson 01: Spawn Basics
================================================================================
Next: 02_message_passing.exs - Learn how processes communicate!
""")
