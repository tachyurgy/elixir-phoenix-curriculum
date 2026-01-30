# ============================================================================
# Lesson 03: Process State - Maintaining State Through Recursive Loops
# ============================================================================
#
# Since Elixir is a functional language with immutable data, processes maintain
# state through recursive function calls where each iteration passes the new
# state to the next. This pattern is fundamental to understanding how GenServer
# and other OTP behaviors work under the hood.
#
# Key concepts covered:
# - Stateful recursive loops
# - State transformation patterns
# - Building stateful servers
# - State as process identity
# - Common state management patterns
#
# Run this file with: elixir 03_process_state.exs
# ============================================================================

IO.puts("""
================================================================================
                    PROCESS STATE - STATEFUL RECURSIVE LOOPS
================================================================================
""")

# ============================================================================
# Section 1: The Basic Stateful Loop Pattern
# ============================================================================

IO.puts("""
--------------------------------------------------------------------------------
Section 1: The Basic Stateful Loop Pattern
--------------------------------------------------------------------------------

A stateful process works by:
1. Starting with an initial state
2. Receiving a message
3. Computing a new state based on the message and current state
4. Recursively calling itself with the new state
5. Repeat from step 2

This is how ALL stateful processes work in Erlang/Elixir, including GenServer!
""")

defmodule SimpleCounter do
  def start(initial \\ 0) do
    spawn(fn -> loop(initial) end)
  end

  defp loop(count) do
    receive do
      :increment ->
        IO.puts("  Counter: #{count} -> #{count + 1}")
        loop(count + 1)  # Pass NEW state to next iteration

      :decrement ->
        IO.puts("  Counter: #{count} -> #{count - 1}")
        loop(count - 1)

      {:get, sender} ->
        send(sender, {:count, count})
        loop(count)  # State unchanged

      :stop ->
        IO.puts("  Counter stopped at #{count}")
        :ok  # Don't recurse - process ends
    end
  end
end

IO.puts("Creating a simple counter process:")
counter = SimpleCounter.start(0)

send(counter, :increment)
send(counter, :increment)
send(counter, :increment)
send(counter, :decrement)

send(counter, {:get, self()})
receive do
  {:count, n} -> IO.puts("  Current count: #{n}")
end

send(counter, :stop)
Process.sleep(50)

# ============================================================================
# Section 2: Complex State Structures
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 2: Complex State Structures
--------------------------------------------------------------------------------

State can be any Elixir term - maps, structs, lists, or nested combinations.
Using maps with well-defined keys is a common pattern.
""")

defmodule UserRegistry do
  # State structure: %{users: %{id => user}, next_id: integer}

  def start do
    spawn(fn -> loop(%{users: %{}, next_id: 1}) end)
  end

  defp loop(state) do
    receive do
      {:add_user, name, email, sender} ->
        id = state.next_id
        user = %{id: id, name: name, email: email, created_at: DateTime.utc_now()}
        new_users = Map.put(state.users, id, user)
        new_state = %{state | users: new_users, next_id: id + 1}

        send(sender, {:ok, id})
        IO.puts("  Added user #{id}: #{name}")
        loop(new_state)

      {:get_user, id, sender} ->
        result = Map.get(state.users, id)
        send(sender, {:user, result})
        loop(state)

      {:delete_user, id, sender} ->
        if Map.has_key?(state.users, id) do
          new_users = Map.delete(state.users, id)
          send(sender, :ok)
          IO.puts("  Deleted user #{id}")
          loop(%{state | users: new_users})
        else
          send(sender, {:error, :not_found})
          loop(state)
        end

      {:list_users, sender} ->
        users = Map.values(state.users)
        send(sender, {:users, users})
        loop(state)

      {:get_state, sender} ->
        send(sender, {:state, state})
        loop(state)

      :stop ->
        IO.puts("  Registry stopped with #{map_size(state.users)} users")
    end
  end
end

IO.puts("User Registry Demo:")
registry = UserRegistry.start()

# Add some users
send(registry, {:add_user, "Alice", "alice@example.com", self()})
receive do: ({:ok, id} -> IO.puts("  Created user with ID: #{id}"))

send(registry, {:add_user, "Bob", "bob@example.com", self()})
receive do: ({:ok, id} -> IO.puts("  Created user with ID: #{id}"))

send(registry, {:add_user, "Charlie", "charlie@example.com", self()})
receive do: ({:ok, id} -> IO.puts("  Created user with ID: #{id}"))

# List users
send(registry, {:list_users, self()})
receive do
  {:users, users} ->
    IO.puts("  All users: #{inspect(Enum.map(users, & &1.name))}")
end

# Get specific user
send(registry, {:get_user, 2, self()})
receive do
  {:user, user} -> IO.puts("  User 2: #{inspect(user)}")
end

# Delete user
send(registry, {:delete_user, 2, self()})
receive do: (:ok -> IO.puts("  User deleted"))

send(registry, {:get_state, self()})
receive do
  {:state, state} ->
    IO.puts("  Final state: #{inspect(state, pretty: true)}")
end

send(registry, :stop)
Process.sleep(50)

# ============================================================================
# Section 3: State with Validation
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 3: State with Validation
--------------------------------------------------------------------------------

Real servers need to validate state transitions and handle errors gracefully.
""")

defmodule BankAccount do
  def start(initial_balance) when initial_balance >= 0 do
    spawn(fn -> loop(%{balance: initial_balance, transactions: []}) end)
  end

  defp loop(state) do
    receive do
      {:deposit, amount, sender} when amount > 0 ->
        new_balance = state.balance + amount
        transaction = {:deposit, amount, DateTime.utc_now()}
        new_state = %{
          balance: new_balance,
          transactions: [transaction | state.transactions]
        }
        send(sender, {:ok, new_balance})
        IO.puts("  Deposited #{amount}, new balance: #{new_balance}")
        loop(new_state)

      {:deposit, amount, sender} ->
        send(sender, {:error, :invalid_amount})
        IO.puts("  Invalid deposit amount: #{amount}")
        loop(state)

      {:withdraw, amount, sender} when amount > 0 ->
        if amount <= state.balance do
          new_balance = state.balance - amount
          transaction = {:withdraw, amount, DateTime.utc_now()}
          new_state = %{
            balance: new_balance,
            transactions: [transaction | state.transactions]
          }
          send(sender, {:ok, new_balance})
          IO.puts("  Withdrew #{amount}, new balance: #{new_balance}")
          loop(new_state)
        else
          send(sender, {:error, :insufficient_funds})
          IO.puts("  Insufficient funds for withdrawal of #{amount}")
          loop(state)
        end

      {:withdraw, _, sender} ->
        send(sender, {:error, :invalid_amount})
        loop(state)

      {:balance, sender} ->
        send(sender, {:balance, state.balance})
        loop(state)

      {:history, sender} ->
        send(sender, {:history, Enum.reverse(state.transactions)})
        loop(state)

      :stop ->
        IO.puts("  Account closed with balance: #{state.balance}")
    end
  end
end

IO.puts("Bank Account Demo:")
account = BankAccount.start(100)

send(account, {:deposit, 50, self()})
receive do: ({:ok, bal} -> IO.puts("  Balance after deposit: #{bal}"))

send(account, {:withdraw, 30, self()})
receive do: ({:ok, bal} -> IO.puts("  Balance after withdrawal: #{bal}"))

send(account, {:withdraw, 200, self()})
receive do: ({:error, reason} -> IO.puts("  Withdrawal failed: #{reason}"))

send(account, {:history, self()})
receive do
  {:history, txns} ->
    IO.puts("  Transaction history: #{inspect(txns)}")
end

send(account, :stop)
Process.sleep(50)

# ============================================================================
# Section 4: State Machine Pattern
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 4: State Machine Pattern
--------------------------------------------------------------------------------

State machines are processes where behavior changes based on current state.
Different messages are valid in different states.
""")

defmodule TrafficLight do
  # States: :red, :yellow, :green
  # Transitions: red -> green -> yellow -> red

  def start do
    spawn(fn -> red() end)
  end

  # Each state is a separate function
  defp red do
    IO.puts("  Light is RED")
    receive do
      :next ->
        green()

      {:get_state, sender} ->
        send(sender, :red)
        red()

      :stop ->
        IO.puts("  Traffic light turned off")
    after
      5000 -> green()  # Auto-transition after 5 seconds
    end
  end

  defp green do
    IO.puts("  Light is GREEN")
    receive do
      :next ->
        yellow()

      {:get_state, sender} ->
        send(sender, :green)
        green()

      :stop ->
        IO.puts("  Traffic light turned off")
    after
      5000 -> yellow()
    end
  end

  defp yellow do
    IO.puts("  Light is YELLOW")
    receive do
      :next ->
        red()

      {:get_state, sender} ->
        send(sender, :yellow)
        yellow()

      :stop ->
        IO.puts("  Traffic light turned off")
    after
      2000 -> red()
    end
  end
end

IO.puts("Traffic Light Demo:")
light = TrafficLight.start()

Process.sleep(50)
send(light, :next)
Process.sleep(50)
send(light, :next)
Process.sleep(50)
send(light, :next)
Process.sleep(50)

send(light, {:get_state, self()})
receive do: (state -> IO.puts("  Current state: #{state}"))

send(light, :stop)
Process.sleep(50)

# ============================================================================
# Section 5: Accumulator Pattern
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 5: Accumulator Pattern
--------------------------------------------------------------------------------

A common pattern is accumulating data over time, then processing it all at once.
""")

defmodule EventCollector do
  def start(flush_after_ms) do
    parent = self()
    spawn(fn -> loop([], flush_after_ms, parent) end)
  end

  defp loop(events, timeout, parent) do
    receive do
      {:event, data} ->
        IO.puts("    Collected event: #{inspect(data)}")
        loop([data | events], timeout, parent)

      :flush ->
        send(parent, {:events, Enum.reverse(events)})
        loop([], timeout, parent)

      :stop ->
        send(parent, {:events, Enum.reverse(events)})
    after
      timeout ->
        if events != [] do
          IO.puts("    Auto-flushing #{length(events)} events")
          send(parent, {:events, Enum.reverse(events)})
          loop([], timeout, parent)
        else
          loop([], timeout, parent)
        end
    end
  end
end

IO.puts("Event Collector Demo:")
collector = EventCollector.start(500)

send(collector, {:event, %{type: :click, x: 100, y: 200}})
send(collector, {:event, %{type: :click, x: 150, y: 250}})
send(collector, {:event, %{type: :scroll, delta: -50}})

# Manual flush
send(collector, :flush)
receive do
  {:events, events} ->
    IO.puts("  Received #{length(events)} events: #{inspect(events)}")
end

# More events
send(collector, {:event, %{type: :keypress, key: "a"}})
send(collector, {:event, %{type: :keypress, key: "b"}})

# Wait for auto-flush
IO.puts("  Waiting for auto-flush...")
receive do
  {:events, events} ->
    IO.puts("  Auto-flushed #{length(events)} events: #{inspect(events)}")
after
  1000 -> IO.puts("  No events received")
end

send(collector, :stop)
Process.sleep(50)

# ============================================================================
# Section 6: Stack Data Structure as Process
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 6: Stack Data Structure as Process
--------------------------------------------------------------------------------

Traditional data structures can be implemented as processes with clear APIs.
""")

defmodule StackProcess do
  def start do
    spawn(fn -> loop([]) end)
  end

  def push(stack, value) do
    send(stack, {:push, value})
    :ok
  end

  def pop(stack) do
    ref = make_ref()
    send(stack, {:pop, ref, self()})
    receive do
      {:ok, ^ref, value} -> {:ok, value}
      {:error, ^ref, reason} -> {:error, reason}
    after
      1000 -> {:error, :timeout}
    end
  end

  def peek(stack) do
    ref = make_ref()
    send(stack, {:peek, ref, self()})
    receive do
      {:ok, ^ref, value} -> {:ok, value}
      {:error, ^ref, reason} -> {:error, reason}
    after
      1000 -> {:error, :timeout}
    end
  end

  def size(stack) do
    ref = make_ref()
    send(stack, {:size, ref, self()})
    receive do
      {:size, ^ref, size} -> size
    after
      1000 -> {:error, :timeout}
    end
  end

  defp loop(items) do
    receive do
      {:push, value} ->
        loop([value | items])

      {:pop, ref, sender} ->
        case items do
          [head | tail] ->
            send(sender, {:ok, ref, head})
            loop(tail)
          [] ->
            send(sender, {:error, ref, :empty})
            loop([])
        end

      {:peek, ref, sender} ->
        case items do
          [head | _] ->
            send(sender, {:ok, ref, head})
          [] ->
            send(sender, {:error, ref, :empty})
        end
        loop(items)

      {:size, ref, sender} ->
        send(sender, {:size, ref, length(items)})
        loop(items)

      :stop ->
        :ok
    end
  end
end

IO.puts("Stack Process Demo:")
stack = StackProcess.start()

StackProcess.push(stack, 1)
StackProcess.push(stack, 2)
StackProcess.push(stack, 3)

IO.puts("  Size: #{StackProcess.size(stack)}")
IO.puts("  Peek: #{inspect(StackProcess.peek(stack))}")
IO.puts("  Pop: #{inspect(StackProcess.pop(stack))}")
IO.puts("  Pop: #{inspect(StackProcess.pop(stack))}")
IO.puts("  Size: #{StackProcess.size(stack)}")
IO.puts("  Pop: #{inspect(StackProcess.pop(stack))}")
IO.puts("  Pop (empty): #{inspect(StackProcess.pop(stack))}")

send(stack, :stop)
Process.sleep(50)

# ============================================================================
# Section 7: Key-Value Store Pattern
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 7: Key-Value Store Pattern
--------------------------------------------------------------------------------

A complete key-value store with get, put, delete, and update operations.
""")

defmodule KVStore do
  def start do
    spawn(fn -> loop(%{}) end)
  end

  # Synchronous operations (wait for response)
  def get(store, key) do
    call(store, {:get, key})
  end

  def put(store, key, value) do
    call(store, {:put, key, value})
  end

  def delete(store, key) do
    call(store, {:delete, key})
  end

  def update(store, key, default, fun) do
    call(store, {:update, key, default, fun})
  end

  def keys(store) do
    call(store, :keys)
  end

  # Asynchronous cast (fire and forget)
  def put_async(store, key, value) do
    send(store, {:cast, {:put, key, value}})
    :ok
  end

  defp call(store, request) do
    ref = make_ref()
    send(store, {:call, request, ref, self()})
    receive do
      {:reply, ^ref, response} -> response
    after
      5000 -> {:error, :timeout}
    end
  end

  defp loop(data) do
    receive do
      {:call, {:get, key}, ref, sender} ->
        send(sender, {:reply, ref, Map.get(data, key)})
        loop(data)

      {:call, {:put, key, value}, ref, sender} ->
        send(sender, {:reply, ref, :ok})
        loop(Map.put(data, key, value))

      {:call, {:delete, key}, ref, sender} ->
        {value, new_data} = Map.pop(data, key)
        send(sender, {:reply, ref, value})
        loop(new_data)

      {:call, {:update, key, default, fun}, ref, sender} ->
        current = Map.get(data, key, default)
        new_value = fun.(current)
        send(sender, {:reply, ref, new_value})
        loop(Map.put(data, key, new_value))

      {:call, :keys, ref, sender} ->
        send(sender, {:reply, ref, Map.keys(data)})
        loop(data)

      {:cast, {:put, key, value}} ->
        loop(Map.put(data, key, value))

      :stop ->
        :ok
    end
  end
end

IO.puts("KV Store Demo:")
store = KVStore.start()

KVStore.put(store, :name, "Alice")
KVStore.put(store, :age, 30)
KVStore.put(store, :scores, [])

IO.puts("  Name: #{inspect(KVStore.get(store, :name))}")
IO.puts("  Age: #{inspect(KVStore.get(store, :age))}")
IO.puts("  Missing: #{inspect(KVStore.get(store, :missing))}")

# Update with function
KVStore.update(store, :age, 0, &(&1 + 1))
IO.puts("  Age after birthday: #{inspect(KVStore.get(store, :age))}")

KVStore.update(store, :scores, [], fn scores -> [95 | scores] end)
KVStore.update(store, :scores, [], fn scores -> [87 | scores] end)
IO.puts("  Scores: #{inspect(KVStore.get(store, :scores))}")

IO.puts("  All keys: #{inspect(KVStore.keys(store))}")

deleted = KVStore.delete(store, :age)
IO.puts("  Deleted age: #{inspect(deleted)}")
IO.puts("  Keys after delete: #{inspect(KVStore.keys(store))}")

send(store, :stop)
Process.sleep(50)

# ============================================================================
# EXERCISES
# ============================================================================

IO.puts("""

================================================================================
                              EXERCISES
================================================================================

Exercise 1: Shopping Cart
-------------------------
Create a shopping cart process with state %{items: [], total: 0}:
- {:add_item, name, price, quantity} - add item to cart
- {:remove_item, name} - remove item by name
- :get_items - return list of items
- :get_total - return current total
- :clear - empty the cart
- :checkout - return final total and stop the process

Exercise 2: Rate Limiter
------------------------
Create a rate limiter process that allows only N requests per time window:
- State tracks: max_requests, window_ms, request_timestamps
- {:request, sender} -> replies {:ok, :allowed} or {:error, :rate_limited}
- Clean up old timestamps outside the current window

Exercise 3: Game Score Tracker
------------------------------
Create a multiplayer game score tracker:
- {:register_player, name} - add player with score 0
- {:add_points, name, points} - add points to player
- {:get_score, name} - get player's current score
- :leaderboard - return sorted list of {name, score} pairs
- {:remove_player, name} - remove player from game

Exercise 4: Todo List Manager
-----------------------------
Create a todo list process with items as maps:
  %{id: integer, title: string, completed: boolean, priority: :low|:medium|:high}
Operations:
- {:add, title, priority} - add new todo, return id
- {:complete, id} - mark as completed
- {:delete, id} - remove todo
- :pending - list all incomplete todos (sorted by priority)
- :stats - return %{total: n, completed: n, pending: n}

Exercise 5: Chat Room
---------------------
Create a chat room process that manages participants and messages:
- {:join, name, pid} - add participant
- {:leave, name} - remove participant
- {:message, from_name, text} - broadcast message to all participants
- :participants - list all participant names
- :history - return last 10 messages as [{from, text, timestamp}, ...]

Exercise 6: Cache with TTL
--------------------------
Create a cache process where entries expire after a TTL:
- {:put, key, value, ttl_ms} - store with expiration
- {:get, key} - return value if not expired, else nil
- :cleanup - remove all expired entries
- :stats - return %{total: n, expired: n, active: n}
Run cleanup periodically using `after` in receive.
""")

# ============================================================================
# Exercise Solutions
# ============================================================================

IO.puts("""
--------------------------------------------------------------------------------
Exercise Solutions
--------------------------------------------------------------------------------
""")

# Exercise 1 Solution
defmodule Exercise1 do
  def start do
    spawn(fn -> loop(%{items: [], total: 0}) end)
  end

  defp loop(state) do
    receive do
      {:add_item, name, price, quantity, sender} ->
        item = %{name: name, price: price, quantity: quantity}
        new_items = [item | state.items]
        new_total = state.total + (price * quantity)
        send(sender, {:ok, item})
        loop(%{items: new_items, total: new_total})

      {:remove_item, name, sender} ->
        case Enum.find(state.items, &(&1.name == name)) do
          nil ->
            send(sender, {:error, :not_found})
            loop(state)
          item ->
            new_items = Enum.reject(state.items, &(&1.name == name))
            new_total = state.total - (item.price * item.quantity)
            send(sender, {:ok, item})
            loop(%{items: new_items, total: new_total})
        end

      {:get_items, sender} ->
        send(sender, {:items, state.items})
        loop(state)

      {:get_total, sender} ->
        send(sender, {:total, state.total})
        loop(state)

      {:clear, sender} ->
        send(sender, :ok)
        loop(%{items: [], total: 0})

      {:checkout, sender} ->
        send(sender, {:checkout, state.total, state.items})
        # Don't loop - process ends
    end
  end

  def demo do
    IO.puts("Exercise 1: Shopping Cart")
    cart = start()

    send(cart, {:add_item, "Apple", 1.50, 3, self()})
    receive do: ({:ok, _} -> IO.puts("  Added Apples"))

    send(cart, {:add_item, "Bread", 2.50, 1, self()})
    receive do: ({:ok, _} -> IO.puts("  Added Bread"))

    send(cart, {:get_total, self()})
    receive do: ({:total, t} -> IO.puts("  Total: $#{t}"))

    send(cart, {:get_items, self()})
    receive do: ({:items, items} -> IO.puts("  Items: #{inspect(items)}"))

    send(cart, {:checkout, self()})
    receive do
      {:checkout, total, items} ->
        IO.puts("  Checkout: $#{total} for #{length(items)} item types")
    end
  end
end

Exercise1.demo()

# Exercise 2 Solution
defmodule Exercise2 do
  def start(max_requests, window_ms) do
    spawn(fn -> loop(%{max: max_requests, window: window_ms, timestamps: []}) end)
  end

  defp loop(state) do
    receive do
      {:request, sender} ->
        now = System.monotonic_time(:millisecond)
        cutoff = now - state.window

        # Clean old timestamps
        valid_timestamps = Enum.filter(state.timestamps, &(&1 > cutoff))

        if length(valid_timestamps) < state.max do
          send(sender, {:ok, :allowed})
          loop(%{state | timestamps: [now | valid_timestamps]})
        else
          send(sender, {:error, :rate_limited})
          loop(%{state | timestamps: valid_timestamps})
        end

      :stop ->
        :ok
    end
  end

  def demo do
    IO.puts("\nExercise 2: Rate Limiter (3 requests per 100ms)")
    limiter = start(3, 100)

    results = Enum.map(1..5, fn i ->
      send(limiter, {:request, self()})
      receive do
        {:ok, :allowed} -> "Request #{i}: ALLOWED"
        {:error, :rate_limited} -> "Request #{i}: RATE LIMITED"
      end
    end)

    Enum.each(results, &IO.puts("  #{&1}"))

    Process.sleep(150)
    IO.puts("  After waiting 150ms...")

    send(limiter, {:request, self()})
    receive do
      {:ok, :allowed} -> IO.puts("  New request: ALLOWED")
      {:error, :rate_limited} -> IO.puts("  New request: RATE LIMITED")
    end

    send(limiter, :stop)
  end
end

Exercise2.demo()

# Exercise 3 Solution
defmodule Exercise3 do
  def start do
    spawn(fn -> loop(%{}) end)
  end

  defp loop(scores) do
    receive do
      {:register_player, name, sender} ->
        if Map.has_key?(scores, name) do
          send(sender, {:error, :already_registered})
          loop(scores)
        else
          send(sender, :ok)
          loop(Map.put(scores, name, 0))
        end

      {:add_points, name, points, sender} ->
        if Map.has_key?(scores, name) do
          new_score = scores[name] + points
          send(sender, {:ok, new_score})
          loop(Map.put(scores, name, new_score))
        else
          send(sender, {:error, :not_found})
          loop(scores)
        end

      {:get_score, name, sender} ->
        send(sender, {:score, Map.get(scores, name)})
        loop(scores)

      {:leaderboard, sender} ->
        sorted = scores
          |> Enum.sort_by(fn {_, score} -> score end, :desc)
        send(sender, {:leaderboard, sorted})
        loop(scores)

      {:remove_player, name, sender} ->
        send(sender, :ok)
        loop(Map.delete(scores, name))

      :stop ->
        :ok
    end
  end

  def demo do
    IO.puts("\nExercise 3: Game Score Tracker")
    game = start()

    Enum.each(["Alice", "Bob", "Charlie"], fn name ->
      send(game, {:register_player, name, self()})
      receive do: (:ok -> IO.puts("  Registered: #{name}"))
    end)

    send(game, {:add_points, "Alice", 100, self()})
    receive do: ({:ok, s} -> IO.puts("  Alice scored, now has #{s}"))

    send(game, {:add_points, "Bob", 150, self()})
    receive do: ({:ok, s} -> IO.puts("  Bob scored, now has #{s}"))

    send(game, {:add_points, "Alice", 75, self()})
    receive do: ({:ok, s} -> IO.puts("  Alice scored again, now has #{s}"))

    send(game, {:leaderboard, self()})
    receive do
      {:leaderboard, lb} ->
        IO.puts("  Leaderboard:")
        Enum.with_index(lb, 1)
        |> Enum.each(fn {{name, score}, rank} ->
          IO.puts("    #{rank}. #{name}: #{score}")
        end)
    end

    send(game, :stop)
  end
end

Exercise3.demo()

# Exercise 4 Solution
defmodule Exercise4 do
  def start do
    spawn(fn -> loop(%{todos: %{}, next_id: 1}) end)
  end

  defp loop(state) do
    receive do
      {:add, title, priority, sender} ->
        id = state.next_id
        todo = %{id: id, title: title, completed: false, priority: priority}
        new_todos = Map.put(state.todos, id, todo)
        send(sender, {:ok, id})
        loop(%{state | todos: new_todos, next_id: id + 1})

      {:complete, id, sender} ->
        if Map.has_key?(state.todos, id) do
          new_todos = update_in(state.todos, [id, :completed], fn _ -> true end)
          send(sender, :ok)
          loop(%{state | todos: new_todos})
        else
          send(sender, {:error, :not_found})
          loop(state)
        end

      {:delete, id, sender} ->
        send(sender, :ok)
        loop(%{state | todos: Map.delete(state.todos, id)})

      {:pending, sender} ->
        priority_order = %{high: 0, medium: 1, low: 2}
        pending = state.todos
          |> Map.values()
          |> Enum.filter(&(!&1.completed))
          |> Enum.sort_by(&priority_order[&1.priority])
        send(sender, {:pending, pending})
        loop(state)

      {:stats, sender} ->
        todos = Map.values(state.todos)
        completed = Enum.count(todos, & &1.completed)
        stats = %{
          total: length(todos),
          completed: completed,
          pending: length(todos) - completed
        }
        send(sender, {:stats, stats})
        loop(state)

      :stop ->
        :ok
    end
  end

  def demo do
    IO.puts("\nExercise 4: Todo List Manager")
    todos = start()

    send(todos, {:add, "Buy groceries", :high, self()})
    receive do: ({:ok, id} -> IO.puts("  Added todo #{id}"))

    send(todos, {:add, "Clean room", :low, self()})
    receive do: ({:ok, id} -> IO.puts("  Added todo #{id}"))

    send(todos, {:add, "Finish project", :high, self()})
    receive do: ({:ok, id} -> IO.puts("  Added todo #{id}"))

    send(todos, {:pending, self()})
    receive do
      {:pending, pending} ->
        IO.puts("  Pending todos (by priority):")
        Enum.each(pending, fn t ->
          IO.puts("    [#{t.priority}] #{t.title}")
        end)
    end

    send(todos, {:complete, 1, self()})
    receive do: (:ok -> IO.puts("  Completed todo 1"))

    send(todos, {:stats, self()})
    receive do: ({:stats, s} -> IO.puts("  Stats: #{inspect(s)}"))

    send(todos, :stop)
  end
end

Exercise4.demo()

# Exercise 5 Solution
defmodule Exercise5 do
  def start do
    spawn(fn -> loop(%{participants: %{}, messages: []}) end)
  end

  defp loop(state) do
    receive do
      {:join, name, pid, sender} ->
        new_participants = Map.put(state.participants, name, pid)
        send(sender, :ok)
        broadcast(new_participants, {:system, "#{name} joined the chat"})
        loop(%{state | participants: new_participants})

      {:leave, name, sender} ->
        {_pid, new_participants} = Map.pop(state.participants, name)
        send(sender, :ok)
        broadcast(new_participants, {:system, "#{name} left the chat"})
        loop(%{state | participants: new_participants})

      {:message, from_name, text} ->
        msg = {from_name, text, DateTime.utc_now()}
        new_messages = Enum.take([msg | state.messages], 10)
        broadcast(state.participants, {:chat, from_name, text})
        loop(%{state | messages: new_messages})

      {:participants, sender} ->
        send(sender, {:participants, Map.keys(state.participants)})
        loop(state)

      {:history, sender} ->
        send(sender, {:history, Enum.reverse(state.messages)})
        loop(state)

      :stop ->
        :ok
    end
  end

  defp broadcast(participants, message) do
    Enum.each(participants, fn {_name, pid} ->
      send(pid, {:broadcast, message})
    end)
  end

  def demo do
    IO.puts("\nExercise 5: Chat Room")
    room = start()

    # Create participant processes
    alice = spawn(fn -> participant_loop("Alice") end)
    bob = spawn(fn -> participant_loop("Bob") end)

    send(room, {:join, "Alice", alice, self()})
    receive do: (:ok -> IO.puts("  Alice joined"))
    Process.sleep(50)

    send(room, {:join, "Bob", bob, self()})
    receive do: (:ok -> IO.puts("  Bob joined"))
    Process.sleep(50)

    send(room, {:message, "Alice", "Hello everyone!"})
    Process.sleep(50)

    send(room, {:message, "Bob", "Hi Alice!"})
    Process.sleep(50)

    send(room, {:participants, self()})
    receive do: ({:participants, p} -> IO.puts("  Participants: #{inspect(p)}"))

    send(room, {:history, self()})
    receive do
      {:history, msgs} ->
        IO.puts("  Message history:")
        Enum.each(msgs, fn {from, text, _} ->
          IO.puts("    #{from}: #{text}")
        end)
    end

    # Cleanup
    Process.exit(alice, :kill)
    Process.exit(bob, :kill)
    send(room, :stop)
  end

  defp participant_loop(name) do
    receive do
      {:broadcast, {:system, msg}} ->
        IO.puts("    [#{name} sees] SYSTEM: #{msg}")
        participant_loop(name)
      {:broadcast, {:chat, from, text}} ->
        IO.puts("    [#{name} sees] #{from}: #{text}")
        participant_loop(name)
    end
  end
end

Exercise5.demo()

# Exercise 6 Solution
defmodule Exercise6 do
  def start(cleanup_interval_ms \\ 1000) do
    spawn(fn -> loop(%{}, cleanup_interval_ms) end)
  end

  defp loop(cache, cleanup_interval) do
    receive do
      {:put, key, value, ttl_ms, sender} ->
        expires_at = System.monotonic_time(:millisecond) + ttl_ms
        entry = %{value: value, expires_at: expires_at}
        send(sender, :ok)
        loop(Map.put(cache, key, entry), cleanup_interval)

      {:get, key, sender} ->
        now = System.monotonic_time(:millisecond)
        result = case Map.get(cache, key) do
          nil -> nil
          %{expires_at: exp} when exp < now -> nil
          %{value: v} -> v
        end
        send(sender, {:value, result})
        loop(cache, cleanup_interval)

      {:cleanup, sender} ->
        now = System.monotonic_time(:millisecond)
        {expired, active} = cache
          |> Enum.split_with(fn {_, %{expires_at: exp}} -> exp < now end)
        send(sender, {:cleaned, length(expired)})
        loop(Map.new(active), cleanup_interval)

      {:stats, sender} ->
        now = System.monotonic_time(:millisecond)
        {expired, active} = cache
          |> Map.values()
          |> Enum.split_with(fn %{expires_at: exp} -> exp < now end)
        stats = %{
          total: map_size(cache),
          expired: length(expired),
          active: length(active)
        }
        send(sender, {:stats, stats})
        loop(cache, cleanup_interval)

      :stop ->
        :ok
    after
      cleanup_interval ->
        now = System.monotonic_time(:millisecond)
        cleaned = cache
          |> Enum.reject(fn {_, %{expires_at: exp}} -> exp < now end)
          |> Map.new()
        loop(cleaned, cleanup_interval)
    end
  end

  def demo do
    IO.puts("\nExercise 6: Cache with TTL")
    cache = start(500)  # Auto-cleanup every 500ms

    send(cache, {:put, :short, "expires quickly", 100, self()})
    receive do: (:ok -> IO.puts("  Added :short with 100ms TTL"))

    send(cache, {:put, :long, "expires slowly", 2000, self()})
    receive do: (:ok -> IO.puts("  Added :long with 2000ms TTL"))

    send(cache, {:get, :short, self()})
    receive do: ({:value, v} -> IO.puts("  :short value: #{inspect(v)}"))

    IO.puts("  Waiting 150ms...")
    Process.sleep(150)

    send(cache, {:get, :short, self()})
    receive do: ({:value, v} -> IO.puts("  :short value (after expiry): #{inspect(v)}"))

    send(cache, {:get, :long, self()})
    receive do: ({:value, v} -> IO.puts("  :long value: #{inspect(v)}"))

    send(cache, {:stats, self()})
    receive do: ({:stats, s} -> IO.puts("  Stats: #{inspect(s)}"))

    send(cache, :stop)
  end
end

Exercise6.demo()

IO.puts("""

================================================================================
                    End of Lesson 03: Process State
================================================================================
Next: 04_process_links.exs - Learn about process links and monitors!
""")
