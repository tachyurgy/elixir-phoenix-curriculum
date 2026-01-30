# ============================================================================
# Lesson 18: ETS Basics
# ============================================================================
#
# ETS (Erlang Term Storage) provides in-memory storage for Elixir/Erlang terms.
# Unlike processes that hold state, ETS tables exist outside any single process
# and can be accessed by multiple processes concurrently.
#
# Learning Objectives:
# - Create ETS tables with :ets.new/2
# - Insert data with :ets.insert/2
# - Retrieve data with :ets.lookup/2
# - Understand the four table types: set, ordered_set, bag, duplicate_bag
# - Delete data and tables
# - Understand table ownership and visibility
#
# Prerequisites:
# - Understanding of processes and message passing
# - Basic OTP concepts (GenServer helpful but not required)
# - Pattern matching
#
# ============================================================================

IO.puts("=" |> String.duplicate(70))
IO.puts("Lesson 18: ETS Basics")
IO.puts("=" |> String.duplicate(70))

# -----------------------------------------------------------------------------
# Section 1: What is ETS?
# -----------------------------------------------------------------------------
#
# ETS (Erlang Term Storage) is a powerful in-memory database that comes built
# into the BEAM VM. Key characteristics:
#
# - Stores tuples with a key element
# - Extremely fast O(1) or O(log n) access depending on table type
# - Can be accessed by multiple processes
# - Data is NOT garbage collected when the owning process dies
#   (unless the table is destroyed)
# - No transactions or persistence (it's purely in-memory)
#
# Common use cases:
# - Caching
# - Shared configuration
# - Session storage
# - Fast lookups for large datasets
# - Pub/sub subscriber lists
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 1: What is ETS? ---\n")

IO.puts("""
ETS (Erlang Term Storage) is an in-memory database built into the BEAM.

Key characteristics:
- Stores Erlang/Elixir tuples
- Extremely fast access
- Can be shared between processes
- Data persists until table is deleted

Unlike GenServer state:
- ETS tables are not tied to a single process
- Multiple processes can read/write concurrently
- No message passing overhead for reads
""")

# -----------------------------------------------------------------------------
# Section 2: Creating ETS Tables with :ets.new/2
# -----------------------------------------------------------------------------
#
# :ets.new/2 creates a new ETS table.
# - First argument: table name (atom) or reference
# - Second argument: list of options
#
# Important options:
# - :set | :ordered_set | :bag | :duplicate_bag - table type
# - :public | :protected | :private - access level
# - :named_table - allows accessing by name instead of reference
# - {:keypos, N} - which element of the tuple is the key (default: 1)
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 2: Creating ETS Tables ---\n")

# Create a simple ETS table
# Returns a table reference (a special term)
table_ref = :ets.new(:my_table, [:set])
IO.puts("Created table with reference: #{inspect(table_ref)}")

# The reference is used for all subsequent operations
IO.puts("Table info: #{inspect(:ets.info(table_ref))}")

# Create a named table (can access by name)
:ets.new(:users_cache, [:set, :named_table])
IO.puts("\nCreated named table :users_cache")

# With named_table, we can use the atom name directly
IO.puts("Named table info: #{inspect(:ets.info(:users_cache, :size))}")

# Create a public table (any process can read/write)
:ets.new(:public_cache, [:set, :public, :named_table])
IO.puts("\nCreated public named table :public_cache")

# Access levels:
# - :private   - only the owner process can access
# - :protected - owner can read/write, others can only read (default)
# - :public    - any process can read/write

IO.puts("""

Access Levels:
- :private   - only owner process can access
- :protected - owner reads/writes, others read only (DEFAULT)
- :public    - any process can read and write
""")

# -----------------------------------------------------------------------------
# Section 3: Inserting Data with :ets.insert/2
# -----------------------------------------------------------------------------
#
# :ets.insert/2 adds tuples to the table.
# - First element of tuple is the key (by default)
# - Can insert single tuple or list of tuples
# - For :set and :ordered_set, overwrites existing key
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 3: Inserting Data ---\n")

# Create a fresh table for our examples
user_table = :ets.new(:user_db, [:set])

# Insert a single tuple
# The first element (1) is the key
:ets.insert(user_table, {1, "Alice", "alice@example.com", 25})
IO.puts("Inserted user 1: Alice")

# Insert another user
:ets.insert(user_table, {2, "Bob", "bob@example.com", 30})
IO.puts("Inserted user 2: Bob")

# Insert multiple tuples at once (more efficient)
:ets.insert(user_table, [
  {3, "Charlie", "charlie@example.com", 35},
  {4, "Diana", "diana@example.com", 28},
  {5, "Eve", "eve@example.com", 22}
])
IO.puts("Inserted users 3, 4, 5 in batch")

# Check table size
size = :ets.info(user_table, :size)
IO.puts("\nTable now has #{size} entries")

# Inserting with same key overwrites (in :set tables)
IO.puts("\nOverwriting user 1...")
:ets.insert(user_table, {1, "Alice Updated", "alice.new@example.com", 26})

# Verify the overwrite
IO.puts("After overwrite: #{inspect(:ets.lookup(user_table, 1))}")

# -----------------------------------------------------------------------------
# Section 4: Looking Up Data with :ets.lookup/2
# -----------------------------------------------------------------------------
#
# :ets.lookup/2 retrieves data by key.
# - Returns a list of matching tuples
# - For :set/:ordered_set, returns 0 or 1 element
# - For :bag/:duplicate_bag, can return multiple elements
# - Returns empty list [] if key not found
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 4: Looking Up Data ---\n")

# Lookup returns a list
result = :ets.lookup(user_table, 2)
IO.puts("Lookup user 2: #{inspect(result)}")

# For :set tables, result is always a single-element list or empty
[{id, name, email, age}] = :ets.lookup(user_table, 2)
IO.puts("User 2 details - ID: #{id}, Name: #{name}, Email: #{email}, Age: #{age}")

# Looking up non-existent key returns empty list
not_found = :ets.lookup(user_table, 999)
IO.puts("\nLookup non-existent key 999: #{inspect(not_found)}")

# Pattern match on lookup result
case :ets.lookup(user_table, 3) do
  [{_id, name, _email, _age}] ->
    IO.puts("Found user: #{name}")

  [] ->
    IO.puts("User not found")
end

# :ets.lookup_element/3 for direct access to specific element
name_only = :ets.lookup_element(user_table, 4, 2)  # Get 2nd element of tuple
IO.puts("\nUser 4 name (using lookup_element): #{name_only}")

# :ets.member/2 checks if key exists (returns boolean)
exists = :ets.member(user_table, 1)
IO.puts("Does user 1 exist? #{exists}")

# -----------------------------------------------------------------------------
# Section 5: Table Types - set, ordered_set, bag, duplicate_bag
# -----------------------------------------------------------------------------
#
# ETS supports four table types:
#
# :set - Each key can appear only once. O(1) access.
# :ordered_set - Like set, but keys are ordered. O(log n) access.
# :bag - Multiple tuples with same key allowed (but no exact duplicates).
# :duplicate_bag - Multiple tuples with same key, including exact duplicates.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 5: Table Types ---\n")

# ---- SET ----
# Default type. Each key unique. Hash-based, O(1) access.
set_table = :ets.new(:set_example, [:set])
:ets.insert(set_table, {1, "first"})
:ets.insert(set_table, {1, "second"})  # Overwrites!
IO.puts("SET - After inserting {1, 'first'} then {1, 'second'}:")
IO.puts("  Result: #{inspect(:ets.lookup(set_table, 1))}")
IO.puts("  (Second insert overwrote the first)")

# ---- ORDERED_SET ----
# Keys are ordered. Uses a tree structure, O(log n) access.
# Useful when you need to iterate in key order.
ordered_table = :ets.new(:ordered_example, [:ordered_set])
:ets.insert(ordered_table, [{3, "three"}, {1, "one"}, {2, "two"}])
IO.puts("\nORDERED_SET - Inserted in order 3, 1, 2:")
IO.puts("  All entries: #{inspect(:ets.tab2list(ordered_table))}")
IO.puts("  (Note: entries are ordered by key)")

# Ordered sets support efficient range operations
first_two = :ets.select(ordered_table, [{{:"$1", :"$2"}, [{:"<", :"$1", 3}], [:"$$"]}])
IO.puts("  Keys less than 3: #{inspect(first_two)}")

# ---- BAG ----
# Multiple tuples with same key allowed, but no exact duplicates.
bag_table = :ets.new(:bag_example, [:bag])
:ets.insert(bag_table, {1, "tag_a"})
:ets.insert(bag_table, {1, "tag_b"})
:ets.insert(bag_table, {1, "tag_a"})  # Duplicate - ignored!
:ets.insert(bag_table, {2, "other"})
IO.puts("\nBAG - After inserting {1, 'tag_a'}, {1, 'tag_b'}, {1, 'tag_a'} again:")
IO.puts("  Key 1 results: #{inspect(:ets.lookup(bag_table, 1))}")
IO.puts("  (Duplicate {1, 'tag_a'} was not added)")

# ---- DUPLICATE_BAG ----
# Like bag, but exact duplicates ARE allowed.
dup_bag_table = :ets.new(:dup_bag_example, [:duplicate_bag])
:ets.insert(dup_bag_table, {1, "event"})
:ets.insert(dup_bag_table, {1, "event"})  # Duplicate - allowed!
:ets.insert(dup_bag_table, {1, "event"})  # Another duplicate
:ets.insert(dup_bag_table, {1, "different_event"})
IO.puts("\nDUPLICATE_BAG - After inserting {1, 'event'} three times:")
IO.puts("  Key 1 results: #{inspect(:ets.lookup(dup_bag_table, 1))}")
IO.puts("  (All duplicates are stored)")

# Summary table
IO.puts("""

Table Type Summary:
+---------------+------------+------------------+--------------+
| Type          | Keys       | Duplicates       | Complexity   |
+---------------+------------+------------------+--------------+
| :set          | Unique     | Overwritten      | O(1)         |
| :ordered_set  | Unique     | Overwritten      | O(log n)     |
| :bag          | Duplicates | No exact dupes   | O(1)         |
| :duplicate_bag| Duplicates | Exact dupes OK   | O(1)         |
+---------------+------------+------------------+--------------+
""")

# -----------------------------------------------------------------------------
# Section 6: Deleting Data
# -----------------------------------------------------------------------------
#
# :ets.delete/2 - Delete all entries with given key
# :ets.delete_object/2 - Delete specific tuple
# :ets.delete_all_objects/1 - Clear the entire table
# :ets.delete/1 - Delete the table itself
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 6: Deleting Data ---\n")

# Create a table with some data
del_table = :ets.new(:delete_demo, [:bag])
:ets.insert(del_table, [
  {1, "item_a"},
  {1, "item_b"},
  {2, "item_c"},
  {3, "item_d"}
])
IO.puts("Initial table: #{inspect(:ets.tab2list(del_table))}")

# Delete by key (removes ALL entries with that key)
:ets.delete(del_table, 1)
IO.puts("After :ets.delete(table, 1): #{inspect(:ets.tab2list(del_table))}")

# Delete specific object
:ets.delete_object(del_table, {2, "item_c"})
IO.puts("After :ets.delete_object(table, {2, 'item_c'}): #{inspect(:ets.tab2list(del_table))}")

# Delete all objects (table remains)
:ets.delete_all_objects(del_table)
IO.puts("After :ets.delete_all_objects: #{inspect(:ets.tab2list(del_table))}")
IO.puts("Table still exists? #{:ets.info(del_table) != :undefined}")

# Delete the table itself
:ets.delete(del_table)
IO.puts("After :ets.delete(table): Table exists? #{:ets.info(del_table) != :undefined}")

# -----------------------------------------------------------------------------
# Section 7: Table Ownership and Process Lifecycle
# -----------------------------------------------------------------------------
#
# Every ETS table has an owner process. When the owner dies:
# - By default, the table is automatically deleted
# - You can transfer ownership with :ets.give_away/3
# - You can set an heir with :ets.setopts/2
#
# This is crucial for long-running applications!
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 7: Table Ownership ---\n")

# Demonstrate table destruction when owner dies
parent = self()

child = spawn(fn ->
  # Create table in child process
  table = :ets.new(:child_table, [:set, :public, :named_table])
  :ets.insert(table, {1, "data from child"})

  # Notify parent
  send(parent, {:table_created, table})

  # Keep process alive briefly
  receive do
    :done -> :ok
  after
    100 -> :ok
  end
end)

# Wait for table creation
table_ref = receive do
  {:table_created, ref} -> ref
end

IO.puts("Table created by child process")
IO.puts("Can access table: #{inspect(:ets.lookup(:child_table, 1))}")

# Wait for child to die
Process.sleep(150)

IO.puts("After child process died:")
IO.puts("Table info: #{inspect(:ets.info(:child_table))}")
IO.puts("(Table was automatically deleted when owner died)")

# Solution: Create tables in a long-lived process (like a GenServer or Application)
IO.puts("""

Best Practice: Create ETS tables in your application's supervision tree,
typically in a GenServer or in your Application.start/2 callback.
This ensures tables survive individual process crashes.
""")

# -----------------------------------------------------------------------------
# Section 8: Useful ETS Functions
# -----------------------------------------------------------------------------
#
# Beyond basic CRUD, ETS provides many utility functions.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 8: Useful ETS Functions ---\n")

# Create a sample table
util_table = :ets.new(:utilities, [:set])
:ets.insert(util_table, [
  {:alice, 100, :active},
  {:bob, 200, :inactive},
  {:charlie, 150, :active}
])

# :ets.tab2list/1 - Get all entries as a list
all_entries = :ets.tab2list(util_table)
IO.puts("All entries: #{inspect(all_entries)}")

# :ets.first/1 and :ets.next/2 - Iterate through keys
first_key = :ets.first(util_table)
IO.puts("\nFirst key: #{inspect(first_key)}")
second_key = :ets.next(util_table, first_key)
IO.puts("Next key: #{inspect(second_key)}")

# For ordered_set, first/next go in order
ord_table = :ets.new(:ordered_util, [:ordered_set])
:ets.insert(ord_table, [{3, "c"}, {1, "a"}, {2, "b"}])
IO.puts("\nOrdered set iteration:")
key = :ets.first(ord_table)
IO.puts("  First: #{inspect(key)}")
key = :ets.next(ord_table, key)
IO.puts("  Next: #{inspect(key)}")
key = :ets.next(ord_table, key)
IO.puts("  Next: #{inspect(key)}")
IO.puts("  Next: #{inspect(:ets.next(ord_table, key))}")  # :"$end_of_table"

# :ets.info/1 and :ets.info/2 - Table metadata
IO.puts("\nTable info:")
IO.puts("  Size: #{:ets.info(util_table, :size)}")
IO.puts("  Type: #{:ets.info(util_table, :type)}")
IO.puts("  Memory (words): #{:ets.info(util_table, :memory)}")
IO.puts("  Owner: #{inspect(:ets.info(util_table, :owner))}")

# :ets.update_counter/3 - Atomic counter updates
counter_table = :ets.new(:counters, [:set])
:ets.insert(counter_table, {:page_views, 0})

IO.puts("\nAtomic counter updates:")
IO.puts("Initial: #{:ets.lookup_element(counter_table, :page_views, 2)}")
:ets.update_counter(counter_table, :page_views, 1)
IO.puts("After +1: #{:ets.lookup_element(counter_table, :page_views, 2)}")
:ets.update_counter(counter_table, :page_views, 5)
IO.puts("After +5: #{:ets.lookup_element(counter_table, :page_views, 2)}")
:ets.update_counter(counter_table, :page_views, -3)
IO.puts("After -3: #{:ets.lookup_element(counter_table, :page_views, 2)}")

# Can also update multiple positions at once
:ets.insert(counter_table, {:stats, 0, 0, 0})  # {key, hits, misses, errors}
:ets.update_counter(counter_table, :stats, [{2, 1}, {3, 2}])  # Increment positions 2 and 3
IO.puts("Stats after update: #{inspect(:ets.lookup(counter_table, :stats))}")

# -----------------------------------------------------------------------------
# Section 9: Common Patterns
# -----------------------------------------------------------------------------
#
# Let's look at some common real-world patterns for using ETS.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 9: Common Patterns ---\n")

# Pattern 1: Simple Cache
IO.puts("Pattern 1: Simple Cache")

defmodule SimpleCache do
  def start do
    :ets.new(:simple_cache, [:set, :public, :named_table])
  end

  def get(key) do
    case :ets.lookup(:simple_cache, key) do
      [{^key, value}] -> {:ok, value}
      [] -> :not_found
    end
  end

  def put(key, value) do
    :ets.insert(:simple_cache, {key, value})
    :ok
  end

  def delete(key) do
    :ets.delete(:simple_cache, key)
    :ok
  end
end

SimpleCache.start()
SimpleCache.put(:user_1, %{name: "Alice", role: "admin"})
IO.puts("Cache get :user_1: #{inspect(SimpleCache.get(:user_1))}")
IO.puts("Cache get :user_2: #{inspect(SimpleCache.get(:user_2))}")

# Pattern 2: Tags/Categories (using bag)
IO.puts("\nPattern 2: Tags/Categories")

tags_table = :ets.new(:tags, [:bag])

# Tag some items
:ets.insert(tags_table, [
  {:elixir, "article_1"},
  {:elixir, "article_2"},
  {:phoenix, "article_1"},
  {:phoenix, "article_3"},
  {:otp, "article_2"}
])

# Find all items with a tag
elixir_articles = :ets.lookup(tags_table, :elixir)
IO.puts("Articles tagged 'elixir': #{inspect(elixir_articles)}")

# Pattern 3: Counters with default
IO.puts("\nPattern 3: Counters with default")

defmodule Counter do
  def start do
    :ets.new(:counters_table, [:set, :public, :named_table])
  end

  def increment(key, amount \\ 1) do
    try do
      :ets.update_counter(:counters_table, key, amount)
    rescue
      ArgumentError ->
        # Key doesn't exist, create it
        :ets.insert(:counters_table, {key, amount})
        amount
    end
  end

  def get(key) do
    case :ets.lookup(:counters_table, key) do
      [{^key, value}] -> value
      [] -> 0
    end
  end
end

Counter.start()
IO.puts("Initial count: #{Counter.get(:visits)}")
Counter.increment(:visits)
Counter.increment(:visits)
Counter.increment(:visits, 10)
IO.puts("After increments: #{Counter.get(:visits)}")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Exercise 1: Product Inventory
Difficulty: Easy

Create an ETS table to store product inventory with the following structure:
{product_id, name, price, quantity}

Implement these functions:
- create_inventory() - creates the table
- add_product(id, name, price, quantity) - adds a product
- get_product(id) - returns the product tuple or nil
- update_quantity(id, new_quantity) - updates the quantity
- list_products() - returns all products

Your code here:
""")

# defmodule Inventory do
#   def create_inventory do
#     ...
#   end
#
#   def add_product(id, name, price, quantity) do
#     ...
#   end
#
#   def get_product(id) do
#     ...
#   end
#
#   def update_quantity(id, new_quantity) do
#     ...
#   end
#
#   def list_products do
#     ...
#   end
# end

IO.puts("""

Exercise 2: Session Store
Difficulty: Easy

Create an ETS-based session store with expiration tracking:
{session_id, user_id, created_at, data}

Implement:
- create_session(session_id, user_id, data) - creates a new session
- get_session(session_id) - retrieves session data
- update_session_data(session_id, new_data) - updates the data field
- delete_session(session_id) - removes a session
- list_user_sessions(user_id) - finds all sessions for a user (hint: use a bag table)

Your code here:
""")

# defmodule SessionStore do
#   ...
# end

IO.puts("""

Exercise 3: Leaderboard
Difficulty: Medium

Create a leaderboard system using an ordered_set table.
The table should store {score, player_name} where score is the key.

Note: Since ordered_set orders by key, putting score first lets us iterate
by score order.

Implement:
- create_leaderboard() - creates the table
- add_score(player, score) - adds/updates a player's score
- get_top_n(n) - returns top N scores with players
- get_rank(player) - returns the rank of a player
- clear_leaderboard() - removes all entries

Hint: For get_rank, you may need to iterate through the ordered entries.

Your code here:
""")

# defmodule Leaderboard do
#   ...
# end

IO.puts("""

Exercise 4: Event Logger with Bags
Difficulty: Medium

Create an event logging system using a duplicate_bag table.
This allows multiple events with the same key (event type).

Structure: {event_type, timestamp, details}

Implement:
- create_logger() - creates the table
- log_event(type, details) - logs an event with current timestamp
- get_events_by_type(type) - returns all events of a type
- get_all_events() - returns all events sorted by timestamp
- count_events_by_type(type) - counts events of a type
- clear_events() - removes all events

Your code here:
""")

# defmodule EventLogger do
#   ...
# end

IO.puts("""

Exercise 5: Rate Limiter
Difficulty: Medium

Create a rate limiter using ETS that limits requests per time window.
Use :ets.update_counter for atomic operations.

Structure: {client_id, request_count, window_start}

Implement:
- create_limiter(max_requests, window_seconds) - creates limiter with config
- check_rate(client_id) - returns :ok or {:error, :rate_limited}
- get_stats(client_id) - returns current count and time remaining in window
- reset_client(client_id) - resets a client's counter

Hint: Store config in a separate ETS entry or module attribute.
Compare timestamps to determine if window has expired.

Your code here:
""")

# defmodule RateLimiter do
#   ...
# end

IO.puts("""

Exercise 6: Multi-Index Store
Difficulty: Hard

Create a store that supports lookups by multiple fields using multiple ETS tables.
Store users with: {id, email, username, created_at}

Use three tables:
- Primary table (set): id -> full record
- Email index (set): email -> id
- Username index (set): username -> id

Implement:
- create_store() - creates all three tables
- add_user(id, email, username) - adds user to all tables
- find_by_id(id) - looks up by id
- find_by_email(email) - looks up by email
- find_by_username(username) - looks up by username
- delete_user(id) - removes from all tables
- update_email(id, new_email) - updates email (must update index!)

Your code here:
""")

# defmodule MultiIndexStore do
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

1. ETS Tables are created with :ets.new/2
   - Returns a reference (or use :named_table for name access)
   - Tables are owned by the creating process
   - Tables are deleted when owner dies (unless transferred)

2. Four Table Types:
   - :set - unique keys, O(1), most common
   - :ordered_set - unique keys, O(log n), sorted iteration
   - :bag - duplicate keys, no exact duplicates
   - :duplicate_bag - duplicate keys, exact duplicates allowed

3. Access Levels:
   - :private - only owner can access
   - :protected - owner writes, others read (default)
   - :public - any process can read/write

4. Basic Operations:
   - :ets.insert/2 - add data
   - :ets.lookup/2 - retrieve by key (returns list)
   - :ets.delete/2 - delete by key
   - :ets.delete/1 - delete table

5. Useful Functions:
   - :ets.update_counter/3 - atomic counter updates
   - :ets.tab2list/1 - get all entries
   - :ets.first/1, :ets.next/2 - iterate keys
   - :ets.info/1, :ets.info/2 - table metadata

6. Best Practices:
   - Create tables in supervised processes
   - Use named tables for application-wide access
   - Consider memory usage for large datasets
   - Use :public only when necessary

Next: 19_ets_advanced.exs - Learn about :ets.match, :ets.select, and
concurrent access patterns
""")

# Clean up tables created during this lesson
:ets.delete(:users_cache)
:ets.delete(:public_cache)
:ets.delete(:simple_cache)
:ets.delete(:counters_table)
