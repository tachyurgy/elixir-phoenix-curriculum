# ============================================================================
# Lesson 02: Message Passing - Inter-Process Communication
# ============================================================================
#
# Processes in Elixir communicate exclusively through message passing. Each
# process has a mailbox that stores incoming messages. Messages are processed
# in the order they arrive using the `receive` construct.
#
# Key concepts covered:
# - send/2 for sending messages
# - receive blocks for receiving messages
# - Pattern matching in receive
# - Timeouts with `after`
# - Selective receive
# - Mailbox management
#
# Run this file with: elixir 02_message_passing.exs
# ============================================================================

IO.puts("""
================================================================================
                    MESSAGE PASSING - INTER-PROCESS COMMUNICATION
================================================================================
""")

# ============================================================================
# Section 1: Basic Message Sending with send/2
# ============================================================================

IO.puts("""
--------------------------------------------------------------------------------
Section 1: Basic Message Sending with send/2
--------------------------------------------------------------------------------

The send/2 function sends a message to a process. Messages can be any Elixir
term: atoms, tuples, maps, lists, etc. Messages are copied to the recipient's
mailbox (no shared memory).

Syntax: send(dest, message)
- dest: PID or registered name
- message: any Elixir term
""")

# Sending a message to ourselves
send(self(), :hello)
send(self(), {:greeting, "world"})
send(self(), %{type: :data, value: 42})

IO.puts("Sent 3 messages to self")
IO.puts("Mailbox length: #{Process.info(self())[:message_queue_len]}")

# ============================================================================
# Section 2: Receiving Messages with receive
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 2: Receiving Messages with receive
--------------------------------------------------------------------------------

The `receive` block waits for messages and pattern matches against them.
It processes ONE message at a time and removes it from the mailbox.
""")

# Basic receive - processes the first matching message
result1 = receive do
  :hello -> "Received :hello atom"
  {:greeting, name} -> "Received greeting for #{name}"
  _ -> "Received something else"
end
IO.puts("Result 1: #{result1}")

result2 = receive do
  {:greeting, name} -> "Greeting: #{name}"
  other -> "Other: #{inspect(other)}"
end
IO.puts("Result 2: #{result2}")

result3 = receive do
  %{type: type, value: val} -> "Map with type=#{type}, value=#{val}"
end
IO.puts("Result 3: #{result3}")

IO.puts("Mailbox now empty: #{Process.info(self())[:message_queue_len]} messages")

# ============================================================================
# Section 3: Receive with Timeout
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 3: Receive with Timeout
--------------------------------------------------------------------------------

Without a timeout, `receive` blocks forever waiting for a message. The `after`
clause specifies a timeout in milliseconds.
""")

# Receive with timeout
result = receive do
  :message -> "Got a message"
after
  100 -> "Timeout after 100ms - no message received"
end
IO.puts("Timeout demo: #{result}")

# Zero timeout - check mailbox without blocking
send(self(), :quick_check)
result = receive do
  msg -> "Found: #{inspect(msg)}"
after
  0 -> "Mailbox is empty"
end
IO.puts("Zero timeout (with message): #{result}")

result = receive do
  msg -> "Found: #{inspect(msg)}"
after
  0 -> "Mailbox is empty"
end
IO.puts("Zero timeout (empty mailbox): #{result}")

# ============================================================================
# Section 4: Pattern Matching in Receive
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 4: Pattern Matching in Receive
--------------------------------------------------------------------------------

Receive uses full pattern matching, including guards. This allows for
sophisticated message handling.
""")

# Send various messages
send(self(), {:add, 5, 3})
send(self(), {:multiply, 4, 7})
send(self(), {:divide, 10, 2})
send(self(), {:divide, 10, 0})
send(self(), {:unknown_op, 1, 2})

# Process messages with pattern matching and guards
defmodule Calculator do
  def process_all do
    process_one()
    process_one()
    process_one()
    process_one()
    process_one()
  end

  defp process_one do
    receive do
      {:add, a, b} ->
        IO.puts("  #{a} + #{b} = #{a + b}")

      {:multiply, a, b} ->
        IO.puts("  #{a} * #{b} = #{a * b}")

      {:divide, _, 0} ->
        IO.puts("  Cannot divide by zero!")

      {:divide, a, b} when b != 0 ->
        IO.puts("  #{a} / #{b} = #{a / b}")

      {op, _, _} ->
        IO.puts("  Unknown operation: #{op}")
    after
      0 -> IO.puts("  No more messages")
    end
  end
end

IO.puts("Processing calculator messages:")
Calculator.process_all()

# ============================================================================
# Section 5: Selective Receive
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 5: Selective Receive
--------------------------------------------------------------------------------

Messages don't have to be processed in order. The receive block scans the
mailbox for the FIRST message matching any of its patterns.
""")

# Send messages in one order
send(self(), {:low_priority, "task 1"})
send(self(), {:low_priority, "task 2"})
send(self(), {:high_priority, "urgent!"})
send(self(), {:low_priority, "task 3"})

IO.puts("Messages sent: low, low, HIGH, low")
IO.puts("Processing high priority first:")

# Process high priority first (selective receive)
receive do
  {:high_priority, msg} -> IO.puts("  HIGH PRIORITY: #{msg}")
after
  0 -> IO.puts("  No high priority messages")
end

IO.puts("Now processing remaining in order:")
Enum.each(1..3, fn _ ->
  receive do
    {:low_priority, msg} -> IO.puts("  Low priority: #{msg}")
    {:high_priority, msg} -> IO.puts("  High priority: #{msg}")
  after
    0 -> :done
  end
end)

# ============================================================================
# Section 6: Request-Reply Pattern
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 6: Request-Reply Pattern
--------------------------------------------------------------------------------

A common pattern: send a message with your PID so the receiver can reply.
This creates a simple RPC-like communication pattern.
""")

defmodule EchoServer do
  def start do
    spawn(fn -> loop() end)
  end

  defp loop do
    receive do
      {:echo, message, sender} ->
        send(sender, {:reply, String.upcase(message)})
        loop()

      {:stop, sender} ->
        send(sender, {:stopped, self()})
        :ok
    end
  end
end

# Start the echo server
server = EchoServer.start()
IO.puts("Echo server started: #{inspect(server)}")

# Send a request and wait for reply
send(server, {:echo, "hello world", self()})
receive do
  {:reply, response} -> IO.puts("Server replied: #{response}")
after
  1000 -> IO.puts("Server didn't respond!")
end

# Send another
send(server, {:echo, "elixir is awesome", self()})
receive do
  {:reply, response} -> IO.puts("Server replied: #{response}")
after
  1000 -> IO.puts("Server didn't respond!")
end

# Stop the server
send(server, {:stop, self()})
receive do
  {:stopped, ^server} -> IO.puts("Server stopped")
after
  1000 -> IO.puts("Server didn't confirm stop!")
end

# ============================================================================
# Section 7: Reference-Tagged Messages
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 7: Reference-Tagged Messages
--------------------------------------------------------------------------------

When making multiple requests, use references to match replies to requests.
make_ref/0 creates a unique reference.
""")

defmodule MathServer do
  def start do
    spawn(fn -> loop() end)
  end

  defp loop do
    receive do
      {:compute, operation, ref, sender} ->
        result = compute(operation)
        send(sender, {:result, ref, result})
        loop()

      :stop ->
        :ok
    end
  end

  defp compute({:add, a, b}), do: a + b
  defp compute({:sub, a, b}), do: a - b
  defp compute({:mul, a, b}), do: a * b
  defp compute({:slow_add, a, b}) do
    Process.sleep(100)
    a + b
  end
end

server = MathServer.start()

# Make multiple requests
ref1 = make_ref()
ref2 = make_ref()
ref3 = make_ref()

send(server, {:compute, {:slow_add, 1, 2}, ref1, self()})  # Takes 100ms
send(server, {:compute, {:add, 10, 20}, ref2, self()})
send(server, {:compute, {:mul, 5, 5}, ref3, self()})

IO.puts("Sent 3 requests, waiting for specific replies...")

# We can receive in any order by matching on ref
receive do
  {:result, ^ref2, result} -> IO.puts("ref2 (add 10+20): #{result}")
after 200 -> IO.puts("Timeout waiting for ref2")
end

receive do
  {:result, ^ref3, result} -> IO.puts("ref3 (mul 5*5): #{result}")
after 200 -> IO.puts("Timeout waiting for ref3")
end

receive do
  {:result, ^ref1, result} -> IO.puts("ref1 (slow_add 1+2): #{result}")
after 200 -> IO.puts("Timeout waiting for ref1")
end

send(server, :stop)

# ============================================================================
# Section 8: Flushing the Mailbox
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 8: Flushing the Mailbox
--------------------------------------------------------------------------------

Sometimes you need to clear all messages from the mailbox. Here's a common
pattern for that.
""")

defmodule Mailbox do
  def flush do
    receive do
      _ -> flush()
    after
      0 -> :ok
    end
  end

  def count do
    Process.info(self())[:message_queue_len]
  end

  def peek(n \\ 5) do
    # Warning: This is for debugging only!
    # Uses process_info which can be expensive
    {:messages, messages} = Process.info(self(), :messages)
    Enum.take(messages, n)
  end
end

# Add some messages
send(self(), :msg1)
send(self(), :msg2)
send(self(), :msg3)

IO.puts("Before flush: #{Mailbox.count()} messages")
IO.puts("Peeking: #{inspect(Mailbox.peek())}")

Mailbox.flush()
IO.puts("After flush: #{Mailbox.count()} messages")

# ============================================================================
# Section 9: Message Ordering Guarantees
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 9: Message Ordering Guarantees
--------------------------------------------------------------------------------

BEAM guarantees that messages from process A to process B arrive in the
order they were sent. But no guarantees exist between different senders.
""")

defmodule OrderingDemo do
  def receiver(expected_count, results \\ []) do
    if length(results) >= expected_count do
      Enum.reverse(results)
    else
      receive do
        {:msg, from, n} ->
          receiver(expected_count, [{from, n} | results])
      after
        500 -> Enum.reverse(results)
      end
    end
  end

  def demo do
    parent = self()

    # Spawn two senders
    spawn(fn ->
      Enum.each(1..5, fn n ->
        send(parent, {:msg, :sender_a, n})
      end)
    end)

    spawn(fn ->
      Enum.each(1..5, fn n ->
        send(parent, {:msg, :sender_b, n})
      end)
    end)

    # Receive all messages
    results = receiver(10)

    IO.puts("Received messages:")
    Enum.each(results, fn {sender, n} ->
      IO.puts("  #{sender}: #{n}")
    end)

    # Check ordering within each sender
    sender_a_msgs = results |> Enum.filter(fn {s, _} -> s == :sender_a end) |> Enum.map(&elem(&1, 1))
    sender_b_msgs = results |> Enum.filter(fn {s, _} -> s == :sender_b end) |> Enum.map(&elem(&1, 1))

    IO.puts("Sender A order: #{inspect(sender_a_msgs)} - in order? #{sender_a_msgs == Enum.sort(sender_a_msgs)}")
    IO.puts("Sender B order: #{inspect(sender_b_msgs)} - in order? #{sender_b_msgs == Enum.sort(sender_b_msgs)}")
  end
end

OrderingDemo.demo()

# ============================================================================
# Section 10: Receive Gotchas - Unmatched Messages
# ============================================================================

IO.puts("""

--------------------------------------------------------------------------------
Section 10: Receive Gotchas - Unmatched Messages
--------------------------------------------------------------------------------

IMPORTANT: Messages that don't match any pattern stay in the mailbox!
This can cause memory issues if you're not careful.
""")

defmodule MailboxGotcha do
  def demo do
    # Send messages of different types
    send(self(), {:type_a, 1})
    send(self(), {:type_b, 2})  # This won't be handled!
    send(self(), {:type_a, 3})
    send(self(), {:type_c, 4})  # This won't be handled!
    send(self(), {:type_a, 5})

    IO.puts("Mailbox before: #{Process.info(self())[:message_queue_len]} messages")

    # Only handle type_a
    handle_type_a()
    handle_type_a()
    handle_type_a()

    IO.puts("Mailbox after handling type_a: #{Process.info(self())[:message_queue_len]} messages")
    IO.puts("Remaining messages: #{inspect(Mailbox.peek(10))}")

    # Clean up
    Mailbox.flush()
  end

  defp handle_type_a do
    receive do
      {:type_a, n} -> IO.puts("  Handled type_a: #{n}")
    after
      0 -> IO.puts("  No type_a messages")
    end
  end
end

MailboxGotcha.demo()

IO.puts("""

SOLUTION: Always include a catch-all clause or handle all message types:

receive do
  {:expected, data} -> handle(data)
  unexpected ->
    Logger.warning("Unexpected message: \#{inspect(unexpected)}")
    # Or just ignore: :ok
end
""")

# ============================================================================
# EXERCISES
# ============================================================================

IO.puts("""

================================================================================
                              EXERCISES
================================================================================

Exercise 1: Ping-Pong
---------------------
Create two processes that play ping-pong. Process A sends :ping to B,
B responds with :pong to A. Continue for N rounds and report the count.

Exercise 2: Calculator Server
-----------------------------
Create a calculator server process that handles these messages:
- {:add, a, b, sender} -> sends back {:result, a + b}
- {:sub, a, b, sender} -> sends back {:result, a - b}
- {:mul, a, b, sender} -> sends back {:result, a * b}
- {:div, a, b, sender} -> sends back {:result, a / b} or {:error, :div_by_zero}
Include proper error handling and test all operations.

Exercise 3: Message Aggregator
------------------------------
Create a process that collects messages for a specified duration, then
returns all collected messages as a list. Interface:
- start(duration_ms) -> spawns aggregator
- aggregator receives any messages during duration
- after duration, sends {:done, messages} to parent

Exercise 4: Priority Queue
--------------------------
Implement a process that handles messages with priorities:
- {:high, message} - processed first
- {:normal, message} - processed after all high priority
- {:low, message} - processed last
The process should batch messages for 100ms, then process in priority order.

Exercise 5: Request Timeout Handler
-----------------------------------
Create a function that sends a request to a server and waits for a reply
with a timeout. If timeout occurs, return {:error, :timeout}. If reply
received, return {:ok, reply}. Also handle the case where the server
process is dead ({:error, :server_down}).

Exercise 6: Broadcast Server
----------------------------
Create a broadcast server that:
- Accepts {:subscribe, pid} to add subscribers
- Accepts {:unsubscribe, pid} to remove subscribers
- Accepts {:broadcast, message} to send message to all subscribers
- Handles dead subscribers gracefully (remove them)
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
  def ping_pong(rounds) do
    IO.puts("Exercise 1: Ping-Pong (#{rounds} rounds)")
    parent = self()

    pong_pid = spawn(fn -> pong_loop(parent) end)
    ping_pid = spawn(fn -> ping_loop(pong_pid, rounds, parent) end)

    # Wait for completion
    receive do
      {:done, count} ->
        IO.puts("  Completed #{count} rounds of ping-pong!")
    after
      5000 -> IO.puts("  Timeout!")
    end
  end

  defp ping_loop(pong_pid, 0, parent) do
    send(pong_pid, :stop)
    send(parent, {:done, 0})
  end

  defp ping_loop(pong_pid, remaining, parent) do
    send(pong_pid, {:ping, self()})
    receive do
      :pong ->
        IO.puts("    Ping received pong, #{remaining - 1} remaining")
        ping_loop(pong_pid, remaining - 1, parent)
    after
      1000 -> send(parent, {:done, :timeout})
    end
  end

  def ping_loop_done(pong_pid, total, parent) do
    send(pong_pid, :stop)
    send(parent, {:done, total})
  end

  defp pong_loop(parent) do
    receive do
      {:ping, sender} ->
        IO.puts("    Pong received ping")
        send(sender, :pong)
        pong_loop(parent)
      :stop ->
        :ok
    end
  end
end

# Run with fewer rounds for demo
Exercise1.ping_pong(3)

# Exercise 2 Solution
defmodule Exercise2 do
  def start_calculator do
    spawn(fn -> calc_loop() end)
  end

  defp calc_loop do
    receive do
      {:add, a, b, sender} ->
        send(sender, {:result, a + b})
        calc_loop()

      {:sub, a, b, sender} ->
        send(sender, {:result, a - b})
        calc_loop()

      {:mul, a, b, sender} ->
        send(sender, {:result, a * b})
        calc_loop()

      {:div, _, 0, sender} ->
        send(sender, {:error, :div_by_zero})
        calc_loop()

      {:div, a, b, sender} ->
        send(sender, {:result, a / b})
        calc_loop()

      :stop ->
        :ok
    end
  end

  def demo do
    IO.puts("\nExercise 2: Calculator Server")
    calc = start_calculator()

    operations = [
      {:add, 10, 5},
      {:sub, 10, 5},
      {:mul, 10, 5},
      {:div, 10, 5},
      {:div, 10, 0}
    ]

    Enum.each(operations, fn {op, a, b} ->
      send(calc, {op, a, b, self()})
      receive do
        {:result, r} -> IO.puts("  #{op}(#{a}, #{b}) = #{r}")
        {:error, e} -> IO.puts("  #{op}(#{a}, #{b}) = ERROR: #{e}")
      after
        100 -> IO.puts("  Timeout!")
      end
    end)

    send(calc, :stop)
  end
end

Exercise2.demo()

# Exercise 3 Solution
defmodule Exercise3 do
  def start_aggregator(duration_ms, parent) do
    spawn(fn -> aggregate_loop([], duration_ms, parent) end)
  end

  defp aggregate_loop(messages, remaining, parent) when remaining <= 0 do
    send(parent, {:done, Enum.reverse(messages)})
  end

  defp aggregate_loop(messages, remaining, parent) do
    start = System.monotonic_time(:millisecond)

    receive do
      msg ->
        elapsed = System.monotonic_time(:millisecond) - start
        aggregate_loop([msg | messages], remaining - elapsed, parent)
    after
      remaining ->
        send(parent, {:done, Enum.reverse(messages)})
    end
  end

  def demo do
    IO.puts("\nExercise 3: Message Aggregator")

    aggregator = start_aggregator(200, self())

    # Send messages over time
    send(aggregator, {:msg, 1})
    Process.sleep(50)
    send(aggregator, {:msg, 2})
    Process.sleep(50)
    send(aggregator, {:msg, 3})

    receive do
      {:done, messages} ->
        IO.puts("  Aggregated #{length(messages)} messages: #{inspect(messages)}")
    after
      500 -> IO.puts("  Timeout!")
    end
  end
end

Exercise3.demo()

# Exercise 4 Solution
defmodule Exercise4 do
  def start_priority_queue do
    spawn(fn -> collect_loop([], [], [], 100) end)
  end

  defp collect_loop(high, normal, low, remaining) when remaining <= 0 do
    process_all(high, normal, low)
  end

  defp collect_loop(high, normal, low, remaining) do
    start = System.monotonic_time(:millisecond)

    receive do
      {:high, msg} ->
        elapsed = System.monotonic_time(:millisecond) - start
        collect_loop([msg | high], normal, low, remaining - elapsed)

      {:normal, msg} ->
        elapsed = System.monotonic_time(:millisecond) - start
        collect_loop(high, [msg | normal], low, remaining - elapsed)

      {:low, msg} ->
        elapsed = System.monotonic_time(:millisecond) - start
        collect_loop(high, normal, [msg | low], remaining - elapsed)
    after
      remaining ->
        process_all(high, normal, low)
    end
  end

  defp process_all(high, normal, low) do
    all = Enum.reverse(high) ++ Enum.reverse(normal) ++ Enum.reverse(low)
    Enum.each(all, fn msg ->
      IO.puts("    Processing: #{inspect(msg)}")
    end)
  end

  def demo do
    IO.puts("\nExercise 4: Priority Queue")

    pq = start_priority_queue()

    send(pq, {:low, "low 1"})
    send(pq, {:normal, "normal 1"})
    send(pq, {:high, "high 1"})
    send(pq, {:low, "low 2"})
    send(pq, {:high, "high 2"})
    send(pq, {:normal, "normal 2"})

    IO.puts("  Sent messages in order: low, normal, high, low, high, normal")
    IO.puts("  Processing order (after 100ms collection):")

    Process.sleep(200)
  end
end

Exercise4.demo()

# Exercise 5 Solution
defmodule Exercise5 do
  def request(server, message, timeout \\ 1000) do
    if Process.alive?(server) do
      ref = make_ref()
      send(server, {message, ref, self()})

      receive do
        {:reply, ^ref, response} -> {:ok, response}
      after
        timeout -> {:error, :timeout}
      end
    else
      {:error, :server_down}
    end
  end

  def start_slow_server do
    spawn(fn -> slow_server_loop() end)
  end

  defp slow_server_loop do
    receive do
      {:fast, ref, sender} ->
        send(sender, {:reply, ref, "fast response"})
        slow_server_loop()

      {:slow, ref, sender} ->
        Process.sleep(200)
        send(sender, {:reply, ref, "slow response"})
        slow_server_loop()

      :stop ->
        :ok
    end
  end

  def demo do
    IO.puts("\nExercise 5: Request Timeout Handler")

    server = start_slow_server()

    IO.puts("  Fast request: #{inspect(request(server, :fast, 100))}")
    IO.puts("  Slow request (will timeout): #{inspect(request(server, :slow, 100))}")
    IO.puts("  Slow request (enough time): #{inspect(request(server, :slow, 500))}")

    send(server, :stop)
    Process.sleep(50)

    IO.puts("  Dead server: #{inspect(request(server, :fast, 100))}")
  end
end

Exercise5.demo()

# Exercise 6 Solution
defmodule Exercise6 do
  def start_broadcast_server do
    spawn(fn -> broadcast_loop(MapSet.new()) end)
  end

  defp broadcast_loop(subscribers) do
    receive do
      {:subscribe, pid} ->
        IO.puts("    Subscriber added: #{inspect(pid)}")
        broadcast_loop(MapSet.put(subscribers, pid))

      {:unsubscribe, pid} ->
        IO.puts("    Subscriber removed: #{inspect(pid)}")
        broadcast_loop(MapSet.delete(subscribers, pid))

      {:broadcast, message} ->
        # Filter out dead processes while broadcasting
        alive_subscribers = Enum.filter(subscribers, &Process.alive?/1)

        Enum.each(alive_subscribers, fn pid ->
          send(pid, {:broadcast, message})
        end)

        IO.puts("    Broadcast '#{message}' to #{MapSet.size(MapSet.new(alive_subscribers))} subscribers")
        broadcast_loop(MapSet.new(alive_subscribers))

      :stop ->
        :ok
    end
  end

  def demo do
    IO.puts("\nExercise 6: Broadcast Server")

    server = start_broadcast_server()

    # Create some subscriber processes
    sub1 = spawn(fn -> subscriber_loop("Sub1") end)
    sub2 = spawn(fn -> subscriber_loop("Sub2") end)
    sub3 = spawn(fn -> subscriber_loop("Sub3") end)

    send(server, {:subscribe, sub1})
    send(server, {:subscribe, sub2})
    send(server, {:subscribe, sub3})

    Process.sleep(50)

    send(server, {:broadcast, "Hello everyone!"})
    Process.sleep(100)

    # Kill one subscriber
    Process.exit(sub2, :kill)
    Process.sleep(50)

    send(server, {:broadcast, "Sub2 is gone!"})
    Process.sleep(100)

    send(server, {:unsubscribe, sub1})
    send(server, {:broadcast, "Final message"})
    Process.sleep(100)

    # Cleanup
    Process.exit(sub1, :kill)
    Process.exit(sub3, :kill)
    send(server, :stop)
  end

  defp subscriber_loop(name) do
    receive do
      {:broadcast, message} ->
        IO.puts("      #{name} received: #{message}")
        subscriber_loop(name)
    end
  end
end

Exercise6.demo()

IO.puts("""

================================================================================
                    End of Lesson 02: Message Passing
================================================================================
Next: 03_process_state.exs - Learn how to maintain state in processes!
""")
