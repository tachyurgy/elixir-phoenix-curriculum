# ============================================================================
# Lesson 05: Tuples
# ============================================================================
#
# Tuples are fixed-size collections stored contiguously in memory.
# They're perfect for grouping a small, fixed number of related values.
#
# Learning Objectives:
# - Understand tuple structure and use cases
# - Know when to use tuples vs lists
# - Use tuple pattern matching
# - Work with the :ok/:error tuple convention
#
# Prerequisites:
# - Lesson 04 (Lists) completed
#
# ============================================================================

IO.puts("=" |> String.duplicate(60))
IO.puts("Lesson 05: Tuples")
IO.puts("=" |> String.duplicate(60))

# -----------------------------------------------------------------------------
# Section 1: Creating Tuples
# -----------------------------------------------------------------------------

IO.puts("\n--- Creating Tuples ---")

# Tuples use curly braces
empty = {}
pair = {1, 2}
triple = {:ok, "Success", 42}
mixed = {"string", 123, :atom, [1, 2, 3]}

IO.inspect(empty, label: "Empty tuple")
IO.inspect(pair, label: "Pair")
IO.inspect(triple, label: "Triple")
IO.inspect(mixed, label: "Mixed types")

# Tuples can be nested
nested = {{1, 2}, {3, 4}}
IO.inspect(nested, label: "Nested tuples")

# Common conventions:
# - 2-tuples: coordinates, key-value pairs
# - 3-tuples: tagged data, results with metadata
# - :ok/:error tuples for function returns

# -----------------------------------------------------------------------------
# Section 2: Tuples vs Lists
# -----------------------------------------------------------------------------

IO.puts("\n--- Tuples vs Lists ---")

# TUPLES:
# - Fixed size (known at compile time)
# - Stored contiguously in memory
# - Fast random access O(1)
# - Slow to modify (must copy entire tuple)
# - Use for: small, fixed collections

# LISTS:
# - Variable size
# - Linked list structure
# - Slow random access O(n)
# - Fast prepend O(1)
# - Use for: dynamic collections, iteration

IO.puts("""
Tuples:
  - Fixed size, known at compile time
  - Fast random access: elem(tuple, 0) is O(1)
  - Expensive to update (copies entire tuple)
  - Use for: coordinates, tagged values, returns

Lists:
  - Variable size
  - Slow random access: Enum.at(list, 0) is O(n)
  - Fast prepend: [new | list] is O(1)
  - Use for: collections, sequences, iteration
""")

# Example comparison
point_tuple = {10, 20}
point_list = [10, 20]

# Accessing elements
IO.inspect(elem(point_tuple, 0), label: "Tuple access (fast)")
IO.inspect(Enum.at(point_list, 0), label: "List access (slower)")

# -----------------------------------------------------------------------------
# Section 3: Accessing Tuple Elements
# -----------------------------------------------------------------------------

IO.puts("\n--- Accessing Elements ---")

tuple = {:a, :b, :c, :d, :e}

# elem/2 - get element at index (0-based)
IO.inspect(elem(tuple, 0), label: "elem(tuple, 0)")
IO.inspect(elem(tuple, 2), label: "elem(tuple, 2)")
IO.inspect(elem(tuple, 4), label: "elem(tuple, 4)")

# tuple_size/1 - get number of elements
IO.inspect(tuple_size(tuple), label: "tuple_size")

# Pattern matching (preferred for small tuples)
{first, second, _, _, last} = tuple
IO.inspect({first, second, last}, label: "Pattern matched")

# -----------------------------------------------------------------------------
# Section 4: Modifying Tuples
# -----------------------------------------------------------------------------

IO.puts("\n--- Modifying Tuples ---")

# Tuples are immutable!
# put_elem returns a NEW tuple

original = {:a, :b, :c}
IO.inspect(original, label: "Original")

# put_elem/3 - replace element at index
modified = put_elem(original, 1, :B)
IO.inspect(modified, label: "After put_elem(_, 1, :B)")
IO.inspect(original, label: "Original unchanged")

# Tuple.append/2 - add element to end
appended = Tuple.append(original, :d)
IO.inspect(appended, label: "After Tuple.append")

# Tuple.delete_at/2 - remove element
deleted = Tuple.delete_at(original, 1)
IO.inspect(deleted, label: "After Tuple.delete_at(_, 1)")

# Tuple.insert_at/3 - insert element
inserted = Tuple.insert_at(original, 1, :inserted)
IO.inspect(inserted, label: "After Tuple.insert_at(_, 1, :inserted)")

# Note: All these operations copy the tuple!
# This is why tuples should be small

# -----------------------------------------------------------------------------
# Section 5: The :ok/:error Convention
# -----------------------------------------------------------------------------

IO.puts("\n--- The :ok/:error Convention ---")

# Elixir functions commonly return:
# {:ok, result} for success
# {:error, reason} for failure

# This is a powerful pattern for error handling!

defmodule FileReader do
  def read(filename) do
    case File.read(filename) do
      {:ok, content} -> {:ok, content}
      {:error, reason} -> {:error, reason}
    end
  end
end

# Simulating function results
success_result = {:ok, "file contents here"}
error_result = {:error, :enoent}

IO.inspect(success_result, label: "Success result")
IO.inspect(error_result, label: "Error result")

# Pattern matching on results
case success_result do
  {:ok, content} -> IO.puts("Got content: #{String.slice(content, 0, 20)}...")
  {:error, reason} -> IO.puts("Failed: #{reason}")
end

case error_result do
  {:ok, content} -> IO.puts("Got content: #{content}")
  {:error, reason} -> IO.puts("Failed: #{reason}")
end

# -----------------------------------------------------------------------------
# Section 6: Common Tuple Patterns
# -----------------------------------------------------------------------------

IO.puts("\n--- Common Tuple Patterns ---")

# Key-value pairs
kv = {:name, "Alice"}
{key, value} = kv
IO.inspect({key, value}, label: "Key-value")

# Coordinates
point = {10, 20}
{x, y} = point
IO.inspect({x, y}, label: "Coordinates")

# 3D point
point3d = {1.0, 2.0, 3.0}
{x, y, z} = point3d
IO.inspect({x, y, z}, label: "3D point")

# Tagged data (like tagged unions)
user = {:user, "alice", 30}
admin = {:admin, "bob", ["users", "posts"]}

case user do
  {:user, name, age} -> IO.puts("User #{name} is #{age} years old")
  {:admin, name, perms} -> IO.puts("Admin #{name} with #{length(perms)} permissions")
end

case admin do
  {:user, name, age} -> IO.puts("User #{name} is #{age} years old")
  {:admin, name, perms} -> IO.puts("Admin #{name} with #{length(perms)} permissions")
end

# Date/Time representations
date = {2024, 1, 15}
time = {14, 30, 0}
datetime = {{2024, 1, 15}, {14, 30, 0}}

IO.inspect(date, label: "Date tuple")
IO.inspect(time, label: "Time tuple")
IO.inspect(datetime, label: "DateTime tuple")

# -----------------------------------------------------------------------------
# Section 7: Pattern Matching with Tuples
# -----------------------------------------------------------------------------

IO.puts("\n--- Pattern Matching with Tuples ---")

# Match exact structure
{a, b, c} = {1, 2, 3}
IO.inspect({a, b, c}, label: "Simple match")

# Match with literals
{:ok, value} = {:ok, 42}
IO.inspect(value, label: "Matched value from :ok tuple")

# Ignore elements
{_, middle, _} = {1, 2, 3}
IO.inspect(middle, label: "Only middle element")

# Nested matching
{{a, b}, {c, d}} = {{1, 2}, {3, 4}}
IO.inspect({a, b, c, d}, label: "Nested match")

# Match in function heads (common pattern)
defmodule TuplePatterns do
  # Different implementations based on tuple structure
  def process({:ok, value}), do: "Success: #{value}"
  def process({:error, reason}), do: "Error: #{reason}"
  def process({:pending, id}), do: "Pending: #{id}"
  def process(other), do: "Unknown: #{inspect(other)}"
end

IO.inspect(TuplePatterns.process({:ok, 42}), label: "process(:ok)")
IO.inspect(TuplePatterns.process({:error, "oops"}), label: "process(:error)")
IO.inspect(TuplePatterns.process({:pending, 123}), label: "process(:pending)")
IO.inspect(TuplePatterns.process("string"), label: "process(other)")

# -----------------------------------------------------------------------------
# Section 8: Tuple Functions
# -----------------------------------------------------------------------------

IO.puts("\n--- Tuple Functions ---")

tuple = {1, 2, 3, 4, 5}

# tuple_size/1 - size of tuple
IO.inspect(tuple_size(tuple), label: "tuple_size")

# elem/2 - get element
IO.inspect(elem(tuple, 0), label: "elem(_, 0)")

# put_elem/3 - replace element
IO.inspect(put_elem(tuple, 0, :replaced), label: "put_elem(_, 0, :replaced)")

# Tuple module functions
IO.inspect(Tuple.append(tuple, 6), label: "Tuple.append")
IO.inspect(Tuple.delete_at(tuple, 2), label: "Tuple.delete_at(_, 2)")
IO.inspect(Tuple.duplicate(:x, 5), label: "Tuple.duplicate(:x, 5)")
IO.inspect(Tuple.insert_at(tuple, 0, 0), label: "Tuple.insert_at(_, 0, 0)")
IO.inspect(Tuple.to_list(tuple), label: "Tuple.to_list")
IO.inspect(List.to_tuple([1, 2, 3]), label: "List.to_tuple")

# -----------------------------------------------------------------------------
# Section 9: Tuples in Practice
# -----------------------------------------------------------------------------

IO.puts("\n--- Tuples in Practice ---")

# Function returning multiple values
defmodule Stats do
  def min_max([]), do: {:error, :empty_list}
  def min_max(list) do
    {:ok, Enum.min(list), Enum.max(list)}
  end
end

case Stats.min_max([3, 1, 4, 1, 5, 9, 2, 6]) do
  {:ok, min, max} -> IO.puts("Min: #{min}, Max: #{max}")
  {:error, reason} -> IO.puts("Error: #{reason}")
end

# Using with for clean error handling
defmodule Calculator do
  def divide(_, 0), do: {:error, :division_by_zero}
  def divide(a, b), do: {:ok, a / b}
end

defmodule Pipeline do
  def calculate(a, b) do
    with {:ok, result} <- Calculator.divide(a, b),
         {:ok, doubled} <- {:ok, result * 2} do
      {:ok, doubled}
    end
  end
end

IO.inspect(Pipeline.calculate(10, 2), label: "10 / 2 * 2")
IO.inspect(Pipeline.calculate(10, 0), label: "10 / 0 * 2")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: Tuple Creation
# Difficulty: Easy
#
# Create tuples representing:
# 1. A RGB color (red=255, green=128, blue=0)
# 2. A person (name, age, email)
# 3. A result tuple for a successful operation returning 42
#
# Your code here:

IO.puts("\nExercise 1: Create various tuples")

# Exercise 2: Pattern Matching
# Difficulty: Easy
#
# Given the tuple: {:user, "Alice", 30, "alice@example.com"}
# Use pattern matching to extract:
# 1. Just the name
# 2. The name and age
# 3. Everything except the tag
#
# Your code here:

IO.puts("\nExercise 2: Pattern match extraction")

# Exercise 3: Safe Division
# Difficulty: Medium
#
# Implement a safe_divide/2 function that:
# - Returns {:ok, result} for valid division
# - Returns {:error, :division_by_zero} when dividing by zero
# - Returns {:error, :invalid_input} for non-numeric inputs
#
# defmodule SafeMath do
#   def safe_divide(a, b) do
#     # Your implementation
#   end
# end
#
# Your code here:

IO.puts("\nExercise 3: Safe division function")

# Exercise 4: Tuple Transformation
# Difficulty: Medium
#
# Write a function that takes a tuple of 3 numbers and returns
# a new tuple with each number squared.
# {:ok, {1, 2, 3}} -> {:ok, {1, 4, 9}}
#
# defmodule TupleTransform do
#   def square_tuple({a, b, c}) do
#     # Your implementation
#   end
# end
#
# Your code here:

IO.puts("\nExercise 4: Tuple transformation")

# Exercise 5: Result Pipeline
# Difficulty: Hard
#
# Implement a pipeline of operations that:
# 1. Takes a number
# 2. Validates it's positive (returns error if not)
# 3. Doubles it
# 4. Validates it's less than 100 (returns error if not)
# 5. Returns {:ok, final_result}
#
# Each step should return {:ok, value} or {:error, reason}
# Use `with` to chain them together
#
# Your code here:

IO.puts("\nExercise 5: Result pipeline")

# Exercise 6: Coordinate Operations
# Difficulty: Medium
#
# Create functions for 2D point operations:
# - add_points({x1, y1}, {x2, y2}) -> {x1+x2, y1+y2}
# - distance({x1, y1}, {x2, y2}) -> distance between points
# - scale({x, y}, factor) -> {x*factor, y*factor}
#
# Your code here:

IO.puts("\nExercise 6: Point operations")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

1. Tuples are fixed-size, contiguous memory structures
   - Fast random access: O(1)
   - Slow to modify: O(n) - copies entire tuple
   - Use for small, fixed collections

2. Creating and accessing:
   - Create: {1, 2, 3}
   - Access: elem(tuple, index)
   - Size: tuple_size(tuple)

3. The :ok/:error convention:
   - {:ok, value} for success
   - {:error, reason} for failure
   - Enables clean pattern matching

4. Pattern matching:
   - {a, b, c} = {1, 2, 3}
   - {:ok, value} = {:ok, 42}
   - Ignore with _

5. Common uses:
   - Function return values
   - Coordinates
   - Key-value pairs
   - Tagged data

6. When to use tuples vs lists:
   - Tuples: fixed size, fast access, small
   - Lists: variable size, iteration, dynamic

Next: 06_keyword_lists.exs - Keyword lists for options
""")
