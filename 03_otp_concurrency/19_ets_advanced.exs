# ============================================================================
# Lesson 19: ETS Advanced
# ============================================================================
#
# This lesson covers advanced ETS features including pattern matching with
# :ets.match and :ets.select, concurrent access patterns, table ownership
# transfer, and performance considerations.
#
# Learning Objectives:
# - Use :ets.match/2 for pattern-based retrieval
# - Use :ets.select/2 with match specifications for complex queries
# - Understand concurrent access patterns and race conditions
# - Transfer table ownership with :ets.give_away/3
# - Set heirs for automatic ownership transfer
# - Build safe concurrent data structures with ETS
#
# Prerequisites:
# - Lesson 18: ETS Basics
# - Understanding of pattern matching
# - Basic process concepts
#
# ============================================================================

IO.puts("=" |> String.duplicate(70))
IO.puts("Lesson 19: ETS Advanced")
IO.puts("=" |> String.duplicate(70))

# -----------------------------------------------------------------------------
# Section 1: Pattern Matching with :ets.match/2
# -----------------------------------------------------------------------------
#
# :ets.match/2 retrieves data using patterns with wildcards.
#
# Pattern variables:
# - :_ - matches anything, result is discarded
# - :"$1", :"$2", etc. - matches anything, result is captured
#
# The result is a list of lists containing captured values.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 1: Pattern Matching with :ets.match/2 ---\n")

# Create a sample table with user data
users = :ets.new(:users, [:set])
:ets.insert(users, [
  {1, "Alice", "Engineering", 75000, :active},
  {2, "Bob", "Sales", 65000, :active},
  {3, "Charlie", "Engineering", 80000, :inactive},
  {4, "Diana", "Marketing", 70000, :active},
  {5, "Eve", "Engineering", 72000, :active}
])

IO.puts("Sample data:")
:ets.tab2list(users) |> Enum.each(&IO.inspect/1)

# Match all records, capture all fields
IO.puts("\nMatch all, capture all fields:")
result = :ets.match(users, {:"$1", :"$2", :"$3", :"$4", :"$5"})
result |> Enum.take(2) |> Enum.each(&IO.inspect/1)
IO.puts("...")

# Match with specific value, capture name
IO.puts("\nMatch Engineering department, capture names:")
result = :ets.match(users, {:_, :"$1", "Engineering", :_, :_})
IO.inspect(result)

# Match active users, capture name and salary
IO.puts("\nMatch active users, capture name and salary:")
result = :ets.match(users, {:_, :"$1", :_, :"$2", :active})
IO.inspect(result)

# :ets.match_object/2 returns full tuples instead of captured values
IO.puts("\nMatch objects (full tuples) for Engineering:")
result = :ets.match_object(users, {:_, :_, "Engineering", :_, :_})
IO.inspect(result)

# :ets.match_delete/2 deletes matching entries
IO.puts("\nDeleting inactive users with match_delete:")
:ets.match_delete(users, {:_, :_, :_, :_, :inactive})
IO.puts("Remaining users:")
:ets.tab2list(users) |> Enum.each(&IO.inspect/1)

# -----------------------------------------------------------------------------
# Section 2: Match Specifications with :ets.select/2
# -----------------------------------------------------------------------------
#
# :ets.select/2 is more powerful than :ets.match/2.
# It uses "match specifications" which can include guards and result transforms.
#
# Match spec format: [{Pattern, Guards, Result}]
# - Pattern: What to match (like :ets.match)
# - Guards: List of guard expressions
# - Result: What to return (can transform matched values)
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 2: Match Specifications with :ets.select/2 ---\n")

# Recreate the table with more data
:ets.delete(users)
users = :ets.new(:users, [:set])
:ets.insert(users, [
  {1, "Alice", "Engineering", 75000, :active},
  {2, "Bob", "Sales", 65000, :active},
  {3, "Charlie", "Engineering", 80000, :active},
  {4, "Diana", "Marketing", 70000, :active},
  {5, "Eve", "Engineering", 72000, :inactive},
  {6, "Frank", "Sales", 55000, :active},
  {7, "Grace", "Engineering", 90000, :active}
])

# Basic select - equivalent to match
IO.puts("Basic select (all Engineering):")
match_spec = [
  {{:_, :"$1", "Engineering", :_, :_}, [], [:"$1"]}
]
result = :ets.select(users, match_spec)
IO.inspect(result)

# Select with guards - salary > 70000
IO.puts("\nSelect with guard (salary > 70000):")
match_spec = [
  {{:"$1", :"$2", :_, :"$3", :_}, [{:>, :"$3", 70000}], [{{:"$1", :"$2", :"$3"}}]}
]
result = :ets.select(users, match_spec)
IO.inspect(result)

# Multiple guards combined with AND
IO.puts("\nEngineering AND salary > 75000:")
match_spec = [
  {{:"$1", :"$2", :"$3", :"$4", :"$5"},
   [{:==, :"$3", "Engineering"}, {:>, :"$4", 75000}],
   [{{:"$2", :"$4"}}]}
]
result = :ets.select(users, match_spec)
IO.inspect(result)

# Guards with OR - use multiple match specs
IO.puts("\nEngineering OR Sales (using multiple patterns):")
match_spec = [
  {{:_, :"$1", "Engineering", :_, :_}, [], [:"$1"]},
  {{:_, :"$1", "Sales", :_, :_}, [], [:"$1"]}
]
result = :ets.select(users, match_spec)
IO.inspect(result)

# Return full objects with :"$_"
IO.puts("\nReturn full objects for high earners:")
match_spec = [
  {{:_, :_, :_, :"$1", :_}, [{:>=, :"$1", 75000}], [:"$_"]}
]
result = :ets.select(users, match_spec)
IO.inspect(result)

# Using :ets.fun2ms/1 to build match specs (requires :stdlib)
# This is easier than writing match specs by hand!
IO.puts("\nUsing fun2ms for readable match specs:")
IO.puts("(Note: fun2ms only works in compiled code with :ets import)")

# Manual equivalent of what fun2ms would generate for:
# fn {id, name, dept, salary, status} when salary > 70000 -> {name, salary} end
match_spec = [
  {{:"$1", :"$2", :"$3", :"$4", :"$5"},
   [{:>, :"$4", 70000}],
   [{{:"$2", :"$4"}}]}
]
IO.puts("High earners: #{inspect(:ets.select(users, match_spec))}")

# :ets.select_count/2 - count matching entries
IO.puts("\nCount active users:")
match_spec = [{{:_, :_, :_, :_, :active}, [], [true]}]
count = :ets.select_count(users, match_spec)
IO.puts("Active users: #{count}")

# :ets.select_delete/2 - delete matching entries and return count
IO.puts("\nDelete users with salary < 60000:")
match_spec = [{{:_, :_, :_, :"$1", :_}, [{:<, :"$1", 60000}], [true]}]
deleted = :ets.select_delete(users, match_spec)
IO.puts("Deleted: #{deleted} user(s)")

# Match specification reference
IO.puts("""

Match Specification Quick Reference:
------------------------------------
Pattern Variables: :"$1", :"$2", :"$3", etc.
Wildcard (discard): :_

Guard Operators:
  Comparison: :==, :"/=", :<, :>, :<=, :>=
  Arithmetic: :+, :-, :*, :div, :rem
  Boolean: :and, :or, :not, :andalso, :orelse
  Type checks: :is_atom, :is_binary, :is_integer, etc.

Result Specials:
  :"$_" - return entire matched object
  :"$$" - return list of all bound variables
  [:"$1", :"$2"] - return specific variables as list
  {{:"$1", :"$2"}} - return as tuple
""")

# -----------------------------------------------------------------------------
# Section 3: Continuation-Based Iteration
# -----------------------------------------------------------------------------
#
# For large tables, iterating all at once can be problematic.
# Use :ets.select/3 and :ets.match/3 with limits for chunked processing.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 3: Continuation-Based Iteration ---\n")

# Create a larger table
large_table = :ets.new(:large, [:set])
1..100 |> Enum.each(fn i ->
  :ets.insert(large_table, {i, "item_#{i}", rem(i, 10)})
end)

IO.puts("Table has #{:ets.info(large_table, :size)} entries")

# Select with limit - returns {Results, Continuation} or :"$end_of_table"
IO.puts("\nIterating with :ets.select/3 (10 at a time):")

match_spec = [{{:"$1", :_, :_}, [], [:"$1"]}]

# First batch
{results, continuation} = :ets.select(large_table, match_spec, 10)
IO.puts("Batch 1: #{length(results)} items - #{inspect(Enum.take(results, 3))}...")

# Next batch using continuation
{results, continuation} = :ets.select(continuation)
IO.puts("Batch 2: #{length(results)} items - #{inspect(Enum.take(results, 3))}...")

# Continue until end
defmodule TableIterator do
  def iterate_all(continuation, acc \\ [])
  def iterate_all(:"$end_of_table", acc), do: Enum.reverse(acc)
  def iterate_all({results, continuation}, acc) do
    iterate_all(:ets.select(continuation), [results | acc])
  end
end

# Get remaining batches
remaining = TableIterator.iterate_all(:ets.select(continuation))
IO.puts("Remaining batches: #{length(remaining)}")
IO.puts("Total items across remaining: #{remaining |> List.flatten() |> length()}")

# :ets.match/3 works similarly
IO.puts("\nUsing :ets.match/3 with limit:")
{results, _cont} = :ets.match(large_table, {:"$1", :_, :_}, 5)
IO.puts("First 5 IDs: #{inspect(results)}")

:ets.delete(large_table)

# -----------------------------------------------------------------------------
# Section 4: Concurrent Access Patterns
# -----------------------------------------------------------------------------
#
# ETS tables support concurrent access, but you need to understand the
# guarantees and limitations:
#
# - Single operations are atomic (insert, lookup, delete)
# - Multiple operations are NOT atomic together
# - Read-modify-write patterns need special handling
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 4: Concurrent Access Patterns ---\n")

# Demonstrate race condition potential
IO.puts("Demonstrating race condition with naive increment:")

race_table = :ets.new(:race_demo, [:set, :public])
:ets.insert(race_table, {:counter, 0})

# Naive increment (WRONG - race condition!)
naive_increment = fn ->
  [{:counter, value}] = :ets.lookup(race_table, :counter)
  # Another process could read the same value here!
  :ets.insert(race_table, {:counter, value + 1})
end

# Spawn 100 processes doing naive increment
1..100 |> Enum.each(fn _ ->
  spawn(fn -> naive_increment.() end)
end)

Process.sleep(100)
[{:counter, final}] = :ets.lookup(race_table, :counter)
IO.puts("Expected: 100, Got: #{final} (likely less due to race conditions)")

# Correct approach: use :ets.update_counter/3 for atomic updates
:ets.delete(race_table)
atomic_table = :ets.new(:atomic_demo, [:set, :public])
:ets.insert(atomic_table, {:counter, 0})

IO.puts("\nUsing atomic :ets.update_counter/3:")

1..100 |> Enum.each(fn _ ->
  spawn(fn -> :ets.update_counter(atomic_table, :counter, 1) end)
end)

Process.sleep(100)
[{:counter, final}] = :ets.lookup(atomic_table, :counter)
IO.puts("Expected: 100, Got: #{final} (correct!)")

# Complex atomic operations with update_counter
IO.puts("\nComplex update_counter operations:")
:ets.insert(atomic_table, {:stats, 0, 0, 0})  # {key, a, b, c}

# Update multiple positions at once
:ets.update_counter(atomic_table, :stats, [{2, 1}, {3, 5}, {4, -2}])
IO.puts("After update: #{inspect(:ets.lookup(atomic_table, :stats))}")

# Update with threshold (won't go below 0)
:ets.update_counter(atomic_table, :stats, {4, -10, 0, 0})
IO.puts("After bounded update: #{inspect(:ets.lookup(atomic_table, :stats))}")

# Pattern: Check-and-set with :ets.insert_new/2
IO.puts("\nAtomic check-and-set with insert_new:")
cas_table = :ets.new(:cas_demo, [:set, :public])

# insert_new only inserts if key doesn't exist
result1 = :ets.insert_new(cas_table, {:lock, self()})
result2 = :ets.insert_new(cas_table, {:lock, self()})
IO.puts("First insert_new: #{result1}")
IO.puts("Second insert_new: #{result2} (key exists, not inserted)")

# Pattern: Optimistic locking with version numbers
IO.puts("\nOptimistic locking pattern:")

defmodule OptimisticUpdate do
  def update(table, key, update_fn) do
    case :ets.lookup(table, key) do
      [{^key, version, data}] ->
        new_data = update_fn.(data)
        # Try to update with version check
        # This is a simplification - real implementation would use CAS
        :ets.insert(table, {key, version + 1, new_data})
        {:ok, new_data}

      [] ->
        {:error, :not_found}
    end
  end
end

opt_table = :ets.new(:opt_demo, [:set])
:ets.insert(opt_table, {:user_1, 1, %{name: "Alice", balance: 100}})

{:ok, updated} = OptimisticUpdate.update(opt_table, :user_1, fn data ->
  %{data | balance: data.balance + 50}
end)
IO.puts("Updated data: #{inspect(updated)}")
IO.puts("Table entry: #{inspect(:ets.lookup(opt_table, :user_1))}")

# -----------------------------------------------------------------------------
# Section 5: Ownership Transfer with :ets.give_away/3
# -----------------------------------------------------------------------------
#
# ETS tables have a single owner process. When the owner dies, the table
# is deleted. :ets.give_away/3 transfers ownership to another process.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 5: Ownership Transfer ---\n")

parent = self()

# Create a process that will receive ownership
receiver = spawn(fn ->
  receive do
    {:"ETS-TRANSFER", table, from_pid, gift_data} ->
      IO.puts("Received table from #{inspect(from_pid)}")
      IO.puts("Gift data: #{inspect(gift_data)}")
      IO.puts("Table contents: #{inspect(:ets.tab2list(table))}")
      send(parent, {:received, table})

      # Keep alive to maintain ownership
      receive do
        :done -> :ok
      end
  end
end)

# Create a table and transfer it
gift_table = :ets.new(:gift, [:set])
:ets.insert(gift_table, {:key, "valuable data"})

IO.puts("Original owner: #{inspect(:ets.info(gift_table, :owner))}")
IO.puts("Giving away table to #{inspect(receiver)}...")

:ets.give_away(gift_table, receiver, %{reason: "process migration"})

# Wait for transfer
receive do
  {:received, _table} ->
    IO.puts("New owner: #{inspect(:ets.info(gift_table, :owner))}")
after
  1000 -> IO.puts("Transfer timed out")
end

# Clean up
send(receiver, :done)
Process.sleep(50)

# -----------------------------------------------------------------------------
# Section 6: Setting Heirs
# -----------------------------------------------------------------------------
#
# An heir is a backup owner. If the current owner dies, ownership
# transfers to the heir automatically (if the heir is still alive).
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 6: Setting Heirs ---\n")

parent = self()

# Create an heir process
heir = spawn(fn ->
  receive do
    {:"ETS-TRANSFER", table, from_pid, heir_data} ->
      IO.puts("Heir received table! Previous owner: #{inspect(from_pid)}")
      IO.puts("Heir data: #{inspect(heir_data)}")
      send(parent, {:heir_activated, table})
      receive do: (:done -> :ok)
  end
end)

# Create a process that owns a table with an heir
original_owner = spawn(fn ->
  table = :ets.new(:heir_demo, [:set, {:heir, heir, %{transferred: true}}])
  :ets.insert(table, {:data, "important"})
  send(parent, {:table_created, table})
  # Die immediately
end)

# Wait for table creation
table_ref = receive do
  {:table_created, ref} -> ref
end

IO.puts("Table created with heir set")
Process.sleep(50)  # Wait for original owner to die

# Check if heir received the table
receive do
  {:heir_activated, _table} ->
    IO.puts("Heir successfully took over!")
    IO.puts("Current owner: #{inspect(:ets.info(table_ref, :owner))}")
after
  1000 -> IO.puts("Heir did not receive table")
end

send(heir, :done)
Process.sleep(50)

# You can also set heir after table creation
demo_table = :ets.new(:setopts_demo, [:set])
new_heir = spawn(fn -> receive do: (:done -> :ok) end)
:ets.setopts(demo_table, {:heir, new_heir, "backup"})
IO.puts("\nSet heir after creation: #{inspect(:ets.info(demo_table, :heir))}")
send(new_heir, :done)
:ets.delete(demo_table)

# -----------------------------------------------------------------------------
# Section 7: ETS with GenServer
# -----------------------------------------------------------------------------
#
# Common pattern: Wrap ETS table in a GenServer for:
# - Guaranteed table ownership (survives crashes via supervisor)
# - Encapsulated access logic
# - Combined ETS speed with process isolation
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 7: ETS with GenServer ---\n")

defmodule CacheServer do
  use GenServer

  # Client API

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def get(key, server \\ __MODULE__) do
    # Read directly from ETS (no GenServer call needed!)
    case :ets.lookup(table_name(server), key) do
      [{^key, value, expires_at}] ->
        if expires_at > System.system_time(:second) do
          {:ok, value}
        else
          # Expired - could trigger async cleanup
          :expired
        end
      [] ->
        :not_found
    end
  end

  def put(key, value, ttl_seconds \\ 300, server \\ __MODULE__) do
    GenServer.call(server, {:put, key, value, ttl_seconds})
  end

  def delete(key, server \\ __MODULE__) do
    GenServer.call(server, {:delete, key})
  end

  def clear(server \\ __MODULE__) do
    GenServer.call(server, :clear)
  end

  def stats(server \\ __MODULE__) do
    table = table_name(server)
    %{
      size: :ets.info(table, :size),
      memory: :ets.info(table, :memory)
    }
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    table_name = Keyword.get(opts, :table_name, :cache_table)
    table = :ets.new(table_name, [:set, :public, :named_table, {:read_concurrency, true}])
    {:ok, %{table: table}}
  end

  @impl true
  def handle_call({:put, key, value, ttl_seconds}, _from, state) do
    expires_at = System.system_time(:second) + ttl_seconds
    :ets.insert(state.table, {key, value, expires_at})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:delete, key}, _from, state) do
    :ets.delete(state.table, key)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:clear, _from, state) do
    :ets.delete_all_objects(state.table)
    {:reply, :ok, state}
  end

  defp table_name(server) when is_atom(server) do
    # In production, you'd want a proper registry lookup
    :cache_table
  end
end

# Start the cache server
{:ok, _pid} = CacheServer.start_link(table_name: :cache_table)

# Use the cache
CacheServer.put(:user_1, %{name: "Alice"}, 60)
CacheServer.put(:user_2, %{name: "Bob"}, 60)

IO.puts("Get :user_1: #{inspect(CacheServer.get(:user_1))}")
IO.puts("Get :user_2: #{inspect(CacheServer.get(:user_2))}")
IO.puts("Get :user_3: #{inspect(CacheServer.get(:user_3))}")
IO.puts("Stats: #{inspect(CacheServer.stats())}")

CacheServer.delete(:user_1)
IO.puts("After delete :user_1: #{inspect(CacheServer.get(:user_1))}")

IO.puts("""

Key benefits of ETS + GenServer pattern:
1. Reads bypass GenServer (fast, concurrent)
2. Writes go through GenServer (serialized, safe)
3. Table survives if GenServer is supervised
4. Clean encapsulation of cache logic
""")

# -----------------------------------------------------------------------------
# Section 8: Performance Tuning
# -----------------------------------------------------------------------------
#
# ETS has several options for performance optimization.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 8: Performance Tuning ---\n")

# :read_concurrency - optimizes for concurrent reads
IO.puts("Read concurrency optimization:")
IO.puts("  Use {:read_concurrency, true} when reads >> writes")
IO.puts("  Adds overhead for writes, but speeds up concurrent reads")

read_heavy = :ets.new(:read_heavy, [:set, {:read_concurrency, true}])
:ets.insert(read_heavy, {:key, "value"})
IO.puts("  Table with read_concurrency: #{inspect(:ets.info(read_heavy, :read_concurrency))}")

# :write_concurrency - optimizes for concurrent writes
IO.puts("\nWrite concurrency optimization:")
IO.puts("  Use {:write_concurrency, true} when many processes write")
IO.puts("  Allows concurrent writes to different keys")

write_heavy = :ets.new(:write_heavy, [:set, {:write_concurrency, true}])
IO.puts("  Table with write_concurrency: #{inspect(:ets.info(write_heavy, :write_concurrency))}")

# Both together
balanced = :ets.new(:balanced, [:set, {:read_concurrency, true}, {:write_concurrency, true}])
IO.puts("\nBoth optimizations: read=#{:ets.info(balanced, :read_concurrency)}, write=#{:ets.info(balanced, :write_concurrency)}")

# :compressed - reduces memory at cost of CPU
IO.puts("\nCompression:")
IO.puts("  Use :compressed for large data with memory constraints")
IO.puts("  Trades CPU time for memory savings")

compressed = :ets.new(:compressed_demo, [:set, :compressed])
:ets.insert(compressed, {:large_data, String.duplicate("x", 10000)})
IO.puts("  Compressed table memory: #{:ets.info(compressed, :memory)} words")

uncompressed = :ets.new(:uncompressed_demo, [:set])
:ets.insert(uncompressed, {:large_data, String.duplicate("x", 10000)})
IO.puts("  Uncompressed table memory: #{:ets.info(uncompressed, :memory)} words")

# Cleanup
:ets.delete(read_heavy)
:ets.delete(write_heavy)
:ets.delete(balanced)
:ets.delete(compressed)
:ets.delete(uncompressed)

IO.puts("""

Performance Guidelines:
-----------------------
1. Use :set for O(1) lookups (default)
2. Use :ordered_set only when ordering needed
3. Enable :read_concurrency for read-heavy workloads
4. Enable :write_concurrency for write-heavy workloads
5. Use :compressed for large, infrequently accessed data
6. Batch inserts when possible (insert list vs multiple calls)
7. Use match specs instead of tab2list + filter
""")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Exercise 1: Query Builder
Difficulty: Medium

Create a module that builds match specifications from a simpler query format.

Implement:
- where(field, op, value) - creates a condition
- query(table, conditions, select_fields) - executes query

Example usage:
  UserQuery.query(:users_table,
    [UserQuery.where(:age, :>, 25), UserQuery.where(:status, :==, :active)],
    [:name, :email]
  )

The table structure is: {id, name, email, age, status}

Your code here:
""")

# defmodule QueryBuilder do
#   # Field positions in tuple
#   @fields %{id: 1, name: 2, email: 3, age: 4, status: 5}
#
#   def where(field, operator, value) do
#     ...
#   end
#
#   def query(table, conditions, select_fields) do
#     ...
#   end
# end

IO.puts("""

Exercise 2: Concurrent Counter Set
Difficulty: Medium

Create a module for managing multiple named counters with guaranteed atomicity.

Implement:
- create() - creates the counter table
- increment(name, amount \\\\ 1) - atomically increments, creates if needed
- decrement(name, amount \\\\ 1) - atomically decrements (min 0)
- get(name) - gets current value (0 if not exists)
- get_all() - returns map of all counters
- reset(name) - resets counter to 0
- delete(name) - removes counter

Your code here:
""")

# defmodule CounterSet do
#   ...
# end

IO.puts("""

Exercise 3: LRU Cache with ETS
Difficulty: Hard

Implement a Least Recently Used (LRU) cache using ETS.
Use two tables:
1. Data table: {key, value}
2. Access table: {key, last_access_timestamp}

Implement:
- create(max_size) - creates cache with maximum entry limit
- get(key) - retrieves value, updates access time
- put(key, value) - stores value, evicts oldest if at capacity
- delete(key) - removes entry
- size() - returns current size
- clear() - removes all entries

When put() would exceed max_size, evict the least recently accessed entry.

Your code here:
""")

# defmodule LRUCache do
#   ...
# end

IO.puts("""

Exercise 4: Pub/Sub Registry with ETS
Difficulty: Hard

Create a pub/sub system using ETS bags for topic subscriptions.

Structure:
- Subscribers table (bag): {topic, subscriber_pid, metadata}
- Topics table (set): {topic, message_count, created_at}

Implement:
- create() - creates the registry tables
- subscribe(topic, metadata \\\\ %{}) - subscribes current process to topic
- unsubscribe(topic) - unsubscribes current process from topic
- publish(topic, message) - sends message to all subscribers
- subscribers(topic) - returns list of subscriber pids
- topics() - returns list of all topics with stats
- cleanup_dead() - removes subscriptions for dead processes

Remember to handle process deaths (subscribers might crash).

Your code here:
""")

# defmodule PubSubRegistry do
#   ...
# end

IO.puts("""

Exercise 5: Distributed Lock Manager
Difficulty: Hard

Create a lock manager for distributed locking across processes.

Features:
- Acquire lock with timeout
- Release lock
- Lock expiration (auto-release after TTL)
- Lock owner tracking

Implement:
- create() - creates lock table
- acquire(resource, timeout_ms \\\\ 5000, ttl_ms \\\\ 30000) - tries to acquire lock
  Returns {:ok, lock_id} or {:error, :timeout}
- release(resource, lock_id) - releases lock if owner
- force_release(resource) - admin release
- status(resource) - returns lock status
- cleanup_expired() - removes expired locks

Use :ets.insert_new for atomic lock acquisition.
Store: {resource, lock_id, owner_pid, expires_at}

Your code here:
""")

# defmodule LockManager do
#   ...
# end

IO.puts("""

Exercise 6: ETS Table Manager GenServer
Difficulty: Hard

Create a GenServer that manages multiple ETS tables with:
- Automatic heir setup for fault tolerance
- Table statistics collection
- Periodic cleanup of expired data

Implement:
- start_link(opts) - starts the manager
- create_table(name, opts) - creates managed table
- delete_table(name) - deletes managed table
- list_tables() - lists all managed tables with stats
- get_table(name) - returns table reference
- set_expiry_callback(name, callback) - sets function to check if entry expired

The manager should:
1. Set itself as heir for all created tables
2. Periodically scan tables for expired entries (if callback set)
3. Track table statistics (size, memory, access patterns)

Your code here:
""")

# defmodule TableManager do
#   use GenServer
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

1. Pattern Matching with :ets.match/2:
   - Use :"$1", :"$2" etc. to capture values
   - Use :_ to match and discard
   - Returns list of captured value lists
   - :ets.match_object/2 returns full tuples

2. Match Specifications with :ets.select/2:
   - Format: [{Pattern, Guards, Result}]
   - Supports complex guards (comparison, arithmetic, type checks)
   - Use :"$_" to return full object
   - :ets.select_count/2 for counting
   - :ets.select_delete/2 for conditional deletion

3. Continuation-Based Iteration:
   - Use :ets.select/3 with limit for large tables
   - Returns {Results, Continuation} for chunked processing
   - Prevents memory issues with large datasets

4. Concurrent Access:
   - Single operations are atomic
   - Use :ets.update_counter/3 for atomic counter updates
   - Use :ets.insert_new/2 for atomic check-and-insert
   - Avoid read-modify-write without proper synchronization

5. Ownership Transfer:
   - :ets.give_away/3 transfers ownership to another process
   - {:heir, pid, data} option sets automatic backup owner
   - Critical for table survival across process crashes

6. Performance Tuning:
   - {:read_concurrency, true} for read-heavy workloads
   - {:write_concurrency, true} for write-heavy workloads
   - :compressed for memory savings at CPU cost

7. ETS + GenServer Pattern:
   - GenServer owns the table (supervision = survival)
   - Reads directly from ETS (fast, no message passing)
   - Writes through GenServer (serialized, safe)

Next: 20_distributed_basics.exs - Learn about connecting nodes and
distributed Elixir
""")

# Clean up
:ets.delete(:cache_table)
