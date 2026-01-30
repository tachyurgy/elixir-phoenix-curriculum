# ============================================================================
# LESSON: Streams - Lazy Evaluation and Infinite Sequences
# ============================================================================
#
# Streams are lazy, composable enumerables. Unlike Enum functions which
# process the entire collection immediately (eager evaluation), Streams
# build up a series of computations that are only executed when needed.
#
# This enables working with large or infinite data sources efficiently.
#
# ============================================================================

# ============================================================================
# LEARNING OBJECTIVES
# ============================================================================
#
# By the end of this lesson, you will be able to:
#
# 1. Understand the difference between eager and lazy evaluation
# 2. Create and compose Stream operations
# 3. Generate infinite sequences with Stream.cycle and Stream.iterate
# 4. Use Stream.unfold for custom sequence generation
# 5. Process large files and datasets efficiently with Streams
# 6. Know when to use Streams vs Enum
#
# ============================================================================

# ============================================================================
# PREREQUISITES
# ============================================================================
#
# Before starting this lesson, you should understand:
#
# - Enum module functions (map, filter, reduce, take)
# - Anonymous functions and the capture operator
# - Pipe operator for chaining operations
# - Basic understanding of memory and performance concepts
#
# ============================================================================

IO.puts("""
============================================================================
SECTION 1: Eager vs Lazy Evaluation
============================================================================
""")

# Enum is EAGER - it processes the entire collection immediately
# and creates intermediate collections at each step.

IO.puts("EAGER evaluation with Enum:")
IO.puts("-" |> String.duplicate(40))

result = 1..10
         |> Enum.map(fn x ->
           IO.puts("  Enum.map: processing #{x}")
           x * 2
         end)
         |> Enum.filter(fn x ->
           IO.puts("  Enum.filter: checking #{x}")
           x > 10
         end)
         |> Enum.take(3)

IO.inspect(result, label: "Enum result")

IO.puts("\nNotice: Enum processed ALL elements at each step!")
IO.puts("  - map processed 10 elements")
IO.puts("  - filter checked 10 elements")
IO.puts("  - take selected 3 from the filtered result")

IO.puts("\n" <> "=" |> String.duplicate(60))
IO.puts("\nLAZY evaluation with Stream:")
IO.puts("-" |> String.duplicate(40))

# Stream is LAZY - it builds up computations but doesn't execute
# until we force evaluation (with Enum.to_list, Enum.take, etc.)

result = 1..10
         |> Stream.map(fn x ->
           IO.puts("  Stream.map: processing #{x}")
           x * 2
         end)
         |> Stream.filter(fn x ->
           IO.puts("  Stream.filter: checking #{x}")
           x > 10
         end)
         |> Enum.take(3)

IO.inspect(result, label: "Stream result")

IO.puts("\nNotice: Stream only processed what was needed!")
IO.puts("  - Processing happened element by element")
IO.puts("  - Stopped as soon as we had 3 matching elements")
IO.puts("  - No intermediate lists were created")

IO.puts("""

============================================================================
SECTION 2: Creating and Composing Streams
============================================================================
""")

# Streams are composable - you can chain operations without immediate execution

IO.puts("Building a stream pipeline (no execution yet):")
stream = 1..1_000_000
         |> Stream.map(&(&1 * 2))
         |> Stream.filter(&(rem(&1, 3) == 0))
         |> Stream.map(&(&1 + 1))

IO.inspect(stream, label: "Stream (not executed)")

IO.puts("\nThe stream is just a recipe - a description of operations.")
IO.puts("Memory usage is minimal because no data is computed yet.")

# Force execution by converting to list or using Enum
IO.puts("\nExecuting the stream to get first 5 elements:")
result = Enum.take(stream, 5)
IO.inspect(result, label: "First 5 elements")

# Multiple consumers can use the same stream
IO.puts("\nSame stream, different operations:")
IO.puts("Sum of first 10: #{stream |> Enum.take(10) |> Enum.sum()}")
IO.puts("Count of first 100: #{stream |> Enum.take(100) |> Enum.count()}")

# Stream.run/1 - execute stream for side effects, returns :ok
IO.puts("\nStream.run for side effects:")
1..5
|> Stream.each(fn x -> IO.puts("  Processing #{x}") end)
|> Stream.run()

IO.puts("""

============================================================================
SECTION 3: Stream.cycle - Repeating Sequences
============================================================================
""")

# Stream.cycle/1 creates an infinite stream that repeats the given enumerable

colors = [:red, :green, :blue]
color_stream = Stream.cycle(colors)

IO.puts("Cycling through colors:")
first_10_colors = Enum.take(color_stream, 10)
IO.inspect(first_10_colors, label: "First 10 colors")

# Practical: Assign colors to items
items = ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape"]
colored_items = items
                |> Enum.zip(Stream.cycle([:red, :green, :blue]))
                |> Enum.map(fn {item, color} -> {item, color} end)
IO.inspect(colored_items, label: "Items with cycled colors")

# Practical: Round-robin assignment
tasks = ["Task A", "Task B", "Task C", "Task D", "Task E"]
workers = ["Alice", "Bob", "Charlie"]

assignments = tasks
              |> Enum.zip(Stream.cycle(workers))
              |> Enum.map(fn {task, worker} -> "#{task} -> #{worker}" end)
IO.inspect(assignments, label: "Task assignments (round-robin)")

# Alternating pattern
alternating = Stream.cycle([true, false]) |> Enum.take(10)
IO.inspect(alternating, label: "Alternating booleans")

# Create striped rows for a table
rows = 1..8
striped = rows
          |> Enum.zip(Stream.cycle([:odd, :even]))
          |> Enum.map(fn {row, stripe} -> {row, stripe} end)
IO.inspect(striped, label: "Striped rows")

IO.puts("""

============================================================================
SECTION 4: Stream.iterate - Building Sequences from Rules
============================================================================
""")

# Stream.iterate/2 generates an infinite stream where each element
# is computed from the previous one.
#
# Syntax: Stream.iterate(start_value, next_function)

# Simple incrementing sequence
naturals = Stream.iterate(1, &(&1 + 1))
IO.inspect(Enum.take(naturals, 10), label: "Natural numbers")

# Powers of 2
powers_of_2 = Stream.iterate(1, &(&1 * 2))
IO.inspect(Enum.take(powers_of_2, 10), label: "Powers of 2")

# Fibonacci sequence (with tuples for state)
fibonacci = Stream.iterate({0, 1}, fn {a, b} -> {b, a + b} end)
            |> Stream.map(fn {a, _} -> a end)
IO.inspect(Enum.take(fibonacci, 15), label: "Fibonacci sequence")

# Geometric sequence
geometric = Stream.iterate(1.0, &(&1 * 1.5))
            |> Stream.map(&Float.round(&1, 2))
IO.inspect(Enum.take(geometric, 8), label: "Geometric sequence (x1.5)")

# Practical: Date sequence
today = Date.utc_today()
dates = Stream.iterate(today, &Date.add(&1, 1))
IO.inspect(Enum.take(dates, 7), label: "Next 7 days")

# Practical: Exponential backoff for retries
backoff = Stream.iterate(100, &min(&1 * 2, 30_000))
IO.inspect(Enum.take(backoff, 10), label: "Backoff delays (ms, max 30s)")

# Practical: Compound interest growth
principal = 1000.0
interest_rate = 0.05
growth = Stream.iterate(principal, fn amount ->
  Float.round(amount * (1 + interest_rate), 2)
end)
IO.puts("\nInvestment growth at 5% annual interest:")
growth
|> Enum.take(11)
|> Enum.with_index()
|> Enum.each(fn {amount, year} ->
  IO.puts("  Year #{year}: $#{amount}")
end)

# Collatz sequence (3n+1 problem)
collatz = fn n ->
  Stream.iterate(n, fn
    x when rem(x, 2) == 0 -> div(x, 2)
    x -> 3 * x + 1
  end)
  |> Stream.take_while(&(&1 != 1))
  |> Enum.to_list()
  |> Kernel.++([1])
end

IO.puts("\nCollatz sequence starting at 27:")
IO.inspect(collatz.(27))

IO.puts("""

============================================================================
SECTION 5: Stream.unfold - Custom Sequence Generation
============================================================================
""")

# Stream.unfold/2 is the most flexible way to generate streams.
# It takes an accumulator and a function that returns either:
#   - {element_to_emit, next_accumulator}
#   - nil (to end the stream)
#
# Syntax: Stream.unfold(initial_acc, fn acc -> {emit, next_acc} | nil end)

# Simple counter with unfold
counter = Stream.unfold(1, fn n -> {n, n + 1} end)
IO.inspect(Enum.take(counter, 5), label: "Counter via unfold")

# Finite sequence - countdown
countdown = Stream.unfold(5, fn
  0 -> nil
  n -> {n, n - 1}
end)
IO.inspect(Enum.to_list(countdown), label: "Countdown via unfold")

# Fibonacci with unfold (cleaner than iterate)
fib = Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)
IO.inspect(Enum.take(fib, 10), label: "Fibonacci via unfold")

# Generate unique IDs
id_generator = Stream.unfold(1000, fn id -> {id, id + 1} end)
new_ids = Enum.take(id_generator, 5)
IO.inspect(new_ids, label: "Generated IDs")

# Practical: Paginated API simulation
defmodule PaginatedData do
  def fetch_page(page) do
    # Simulate API returning data and total pages
    total_pages = 5
    if page <= total_pages do
      items = Enum.map(1..3, fn i -> "Item #{(page - 1) * 3 + i}" end)
      {:ok, items, page < total_pages}
    else
      {:done, [], false}
    end
  end
end

IO.puts("\nSimulating paginated API fetch:")
paginated = Stream.unfold(1, fn page ->
  case PaginatedData.fetch_page(page) do
    {:ok, items, has_more} ->
      if has_more, do: {items, page + 1}, else: {items, nil}
    {:done, _, _} ->
      nil
  end
end)
|> Stream.flat_map(& &1)

all_items = Enum.to_list(paginated)
IO.inspect(all_items, label: "All paginated items")

# Practical: Parse delimited string lazily
parse_csv_row = fn data ->
  Stream.unfold(data, fn
    "" -> nil
    str ->
      case String.split(str, ",", parts: 2) do
        [field] -> {String.trim(field), ""}
        [field, rest] -> {String.trim(field), rest}
      end
  end)
end

row = "Alice, 30, New York, Engineer"
fields = parse_csv_row.(row) |> Enum.to_list()
IO.inspect(fields, label: "Parsed CSV fields")

# Random sequence with state
random_stream = Stream.unfold(:rand.seed(:exsss), fn state ->
  {value, new_state} = :rand.uniform_s(state)
  {Float.round(value, 4), new_state}
end)
IO.inspect(Enum.take(random_stream, 5), label: "Random values")

IO.puts("""

============================================================================
SECTION 6: More Stream Functions
============================================================================
""")

# Stream.repeatedly/1 - call function repeatedly
IO.puts("Stream.repeatedly - call function each time:")
timestamps = Stream.repeatedly(fn -> :os.system_time(:millisecond) end)
             |> Enum.take(3)
IO.inspect(timestamps, label: "Timestamps")

# Stream.resource/3 - for resources requiring cleanup (files, connections)
IO.puts("\nStream.resource - for managed resources:")
IO.puts("(Used for files, database connections, etc.)")

# Stream.chunk_every, chunk_by, etc. - lazy versions of Enum counterparts
IO.puts("\nLazy chunking:")
chunked = 1..20
          |> Stream.chunk_every(5)
          |> Enum.take(2)
IO.inspect(chunked, label: "First 2 chunks of 5")

# Stream.take_every/2 - take every nth element
every_third = 1..30
              |> Stream.take_every(3)
              |> Enum.to_list()
IO.inspect(every_third, label: "Every 3rd element")

# Stream.drop/2 and Stream.take/2
IO.puts("\nStream.drop and Stream.take:")
middle = 1..100
         |> Stream.drop(40)
         |> Stream.take(20)
         |> Enum.to_list()
IO.inspect(middle, label: "Elements 41-60")

# Stream.drop_while and Stream.take_while
IO.puts("\nStream.take_while:")
small_nums = Stream.iterate(1, &(&1 + 1))
             |> Stream.take_while(&(&1 < 10))
             |> Enum.to_list()
IO.inspect(small_nums, label: "Numbers while < 10")

# Stream.dedup - remove consecutive duplicates lazily
with_dupes = [1, 1, 2, 2, 2, 3, 1, 1, 4]
deduped = with_dupes |> Stream.dedup() |> Enum.to_list()
IO.inspect(deduped, label: "Lazy dedup")

# Stream.uniq - remove all duplicates (requires memory for seen elements)
all_unique = [1, 2, 1, 3, 2, 4] |> Stream.uniq() |> Enum.to_list()
IO.inspect(all_unique, label: "Lazy unique")

# Stream.intersperse - insert element between each pair
interspersed = 1..5
               |> Stream.intersperse(:sep)
               |> Enum.to_list()
IO.inspect(interspersed, label: "Interspersed")

# Stream.transform/3 - stateful transformation
IO.puts("\nStream.transform - stateful processing:")
# Running sum with transform
running_sum = Stream.transform(1..5, 0, fn x, acc ->
  new_sum = acc + x
  {[new_sum], new_sum}
end)
|> Enum.to_list()
IO.inspect(running_sum, label: "Running sum")

IO.puts("""

============================================================================
SECTION 7: Working with Large Data and Files
============================================================================
""")

# Streams are essential for processing large files without loading
# everything into memory.

IO.puts("File processing with streams (simulated):")

# Simulate a large data source
large_data = Stream.iterate(1, &(&1 + 1)) |> Stream.take(1_000_000)

# Process in chunks without loading all into memory
IO.puts("\nProcessing 1 million records in chunks:")
chunk_sums = large_data
             |> Stream.chunk_every(100_000)
             |> Stream.map(fn chunk ->
               sum = Enum.sum(chunk)
               IO.puts("  Processed chunk, sum: #{sum}")
               sum
             end)
             |> Enum.to_list()

total = Enum.sum(chunk_sums)
IO.puts("Total sum: #{total}")

# Stream.resource for file reading (pattern)
IO.puts("\nPattern for file streaming (pseudo-code):")
IO.puts("""
  File.stream!("large_file.txt")
  |> Stream.map(&String.trim/1)
  |> Stream.filter(&(&1 != ""))
  |> Stream.map(&process_line/1)
  |> Enum.each(&save_result/1)
""")

# Example: Process log entries
IO.puts("\nSimulated log processing:")
log_entries = """
[INFO] Server started
[DEBUG] Loading config
[ERROR] Connection timeout
[INFO] Retrying connection
[ERROR] Connection failed
[INFO] Fallback activated
[DEBUG] Config loaded
[INFO] Server ready
"""

log_entries
|> String.split("\n", trim: true)
|> Stream.filter(&String.contains?(&1, "[ERROR]"))
|> Stream.map(fn line ->
  "[ALERT] " <> String.replace(line, "[ERROR]", "")
end)
|> Enum.each(&IO.puts/1)

# Memory comparison
IO.puts("\nMemory efficiency demonstration:")
IO.puts("Enum approach: Creates intermediate lists at each step")
IO.puts("Stream approach: Processes one element at a time")
IO.puts("")
IO.puts("For 1 million elements with 3 transformations:")
IO.puts("  Enum: ~24MB (3 intermediate lists of ~8MB each)")
IO.puts("  Stream: ~8KB (constant, just the current element)")

IO.puts("""

============================================================================
SECTION 8: When to Use Streams vs Enum
============================================================================
""")

IO.puts("""
USE STREAMS WHEN:
-----------------
1. Working with large datasets that don't fit in memory
2. Processing infinite or very long sequences
3. Reading files line by line
4. You only need a portion of the results (early termination)
5. Composing many operations before execution
6. Working with external data sources (files, network, databases)

USE ENUM WHEN:
--------------
1. Working with small to medium collections
2. You need all results immediately
3. Performance is critical (Enum can be faster for small data)
4. The collection is already in memory
5. You need random access to elements
6. Simplicity is more important than memory efficiency

HYBRID APPROACH:
----------------
Start with Enum for prototyping, switch to Stream for production
if memory or performance becomes an issue.
""")

IO.puts("Benchmark comparison (small data):")
small_data = 1..100

{enum_time, enum_result} = :timer.tc(fn ->
  small_data
  |> Enum.map(&(&1 * 2))
  |> Enum.filter(&(rem(&1, 3) == 0))
  |> Enum.take(10)
end)

{stream_time, stream_result} = :timer.tc(fn ->
  small_data
  |> Stream.map(&(&1 * 2))
  |> Stream.filter(&(rem(&1, 3) == 0))
  |> Enum.take(10)
end)

IO.puts("  Enum time: #{enum_time} microseconds")
IO.puts("  Stream time: #{stream_time} microseconds")
IO.puts("  Results match: #{enum_result == stream_result}")
IO.puts("  (For small data, Enum is often faster due to less overhead)")

IO.puts("""

============================================================================
SUMMARY
============================================================================

Key Stream concepts covered:

1. Lazy Evaluation
   - Computations deferred until needed
   - Processes elements one at a time
   - No intermediate collections created

2. Stream.cycle/1
   - Repeats enumerable infinitely
   - Great for round-robin assignment
   - Alternating patterns

3. Stream.iterate/2
   - Generates sequence from rule
   - Each element derived from previous
   - Perfect for mathematical sequences

4. Stream.unfold/2
   - Most flexible generator
   - Custom accumulator state
   - Can produce finite or infinite streams

5. Stream.resource/3
   - For resources needing cleanup
   - Files, database connections, etc.
   - Ensures proper resource management

6. Memory Efficiency
   - Constant memory usage
   - Enables processing of huge datasets
   - Essential for file processing

When to Use:
- Large data: Use Stream
- Infinite sequences: Use Stream
- Small data, need speed: Use Enum
- File processing: Use Stream

============================================================================
EXERCISES
============================================================================
""")

IO.puts("""
Exercise 1 (Easy): Infinite Alphabet
------------------------------------
Create a stream that cycles through the letters a-z infinitely.
Take the first 30 characters.

# Expected: ["a", "b", "c", ..., "z", "a", "b", "c", "d"]
# (26 letters + 4 more = 30 total)

# Your solution:
# alphabet_stream = Stream.cycle(...) |> ...
""")

# Solution:
alphabet = ?a..?z |> Enum.map(&<<&1>>)
alphabet_stream = Stream.cycle(alphabet) |> Enum.take(30)
IO.inspect(alphabet_stream, label: "Exercise 1 Solution")

IO.puts("""

Exercise 2 (Easy): Powers Stream
--------------------------------
Create a stream of powers of 3 (3^0, 3^1, 3^2, ...).
Take the first 8 powers.

# Expected: [1, 3, 9, 27, 81, 243, 729, 2187]

# Your solution:
# powers_of_3 = Stream.iterate(...) |> ...
""")

# Solution:
powers_of_3 = Stream.iterate(1, &(&1 * 3)) |> Enum.take(8)
IO.inspect(powers_of_3, label: "Exercise 2 Solution")

IO.puts("""

Exercise 3 (Medium): Triangular Numbers
---------------------------------------
Create a stream of triangular numbers (1, 3, 6, 10, 15, ...).
Triangular number T(n) = 1 + 2 + 3 + ... + n = n*(n+1)/2
Take the first 10 triangular numbers.

Hint: Use Stream.iterate with a tuple {current_value, next_increment}
or use Stream.unfold.

# Expected: [1, 3, 6, 10, 15, 21, 28, 36, 45, 55]

# Your solution:
""")

# Solution:
triangular = Stream.unfold({1, 1}, fn {value, n} ->
  {value, {value + n + 1, n + 1}}
end)
|> Enum.take(10)
IO.inspect(triangular, label: "Exercise 3 Solution")

IO.puts("""

Exercise 4 (Medium): Lazy Text Processing
-----------------------------------------
Given a list of sentences, create a lazy pipeline that:
1. Splits each sentence into words
2. Converts to lowercase
3. Filters words longer than 4 characters
4. Takes the first 10 such words

sentences = [
  "The Quick Brown Fox Jumps",
  "Over The Lazy Dog In The",
  "Beautiful Sunny Garden Today"
]

# Expected: ["quick", "brown", "jumps", "garden", "today", ...]
# (first 10 words longer than 4 chars)

# Your solution (use Stream functions):
""")

# Solution:
sentences = [
  "The Quick Brown Fox Jumps",
  "Over The Lazy Dog In The",
  "Beautiful Sunny Garden Today"
]

long_words = sentences
             |> Stream.flat_map(&String.split/1)
             |> Stream.map(&String.downcase/1)
             |> Stream.filter(&(String.length(&1) > 4))
             |> Enum.take(10)
IO.inspect(long_words, label: "Exercise 4 Solution")

IO.puts("""

Exercise 5 (Hard): Prime Number Generator
-----------------------------------------
Create an infinite stream of prime numbers using Stream.unfold.
Take the first 20 primes.

Hint: You'll need a helper function to check if a number is prime,
and unfold with an accumulator tracking candidates to check.

# Expected: [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71]

# Your solution:
""")

# Solution:
is_prime? = fn n ->
  if n < 2 do
    false
  else
    2..trunc(:math.sqrt(n))
    |> Enum.all?(fn x -> rem(n, x) != 0 end)
  end
end

primes = Stream.unfold(2, fn n ->
  next_prime = Stream.iterate(n, &(&1 + 1))
               |> Enum.find(is_prime?)
  {next_prime, next_prime + 1}
end)
|> Enum.take(20)
IO.inspect(primes, label: "Exercise 5 Solution")

IO.puts("""

Exercise 6 (Hard): Batched Processing Simulation
------------------------------------------------
Simulate processing a large dataset in batches.
Create a stream of 1000 "records" (just numbers 1-1000).
Process them in batches of 100, where processing means:
- Calculate the sum of the batch
- Calculate the average of the batch
- Return a summary map for each batch

Use Stream.chunk_every for batching.

# Expected output: List of 10 batch summaries
# [%{batch: 1, sum: 5050, avg: 50.5}, %{batch: 2, sum: 15050, avg: 150.5}, ...]

# Your solution:
""")

# Solution:
batch_summaries = 1..1000
                  |> Stream.chunk_every(100)
                  |> Stream.with_index(1)
                  |> Stream.map(fn {batch, index} ->
                    sum = Enum.sum(batch)
                    avg = sum / length(batch)
                    %{batch: index, sum: sum, avg: Float.round(avg, 1)}
                  end)
                  |> Enum.to_list()

IO.puts("Exercise 6 Solution:")
Enum.each(batch_summaries, fn summary ->
  IO.inspect(summary)
end)

IO.puts("""

============================================================================
CONGRATULATIONS!
============================================================================

You've mastered Elixir Streams! You now understand:

- The difference between eager (Enum) and lazy (Stream) evaluation
- How to create infinite sequences with cycle and iterate
- Using unfold for custom sequence generation
- Processing large datasets efficiently
- When to choose Streams over Enum

Streams are a powerful tool for building efficient data pipelines
that can handle datasets of any size.

Next up: For Comprehensions - a concise syntax for transformations!

============================================================================
""")
