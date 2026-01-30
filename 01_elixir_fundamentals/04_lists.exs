# ============================================================================
# Lesson 04: Lists
# ============================================================================
#
# Lists are Elixir's primary collection type. They're implemented as linked
# lists, which affects their performance characteristics.
#
# Learning Objectives:
# - Create and manipulate lists
# - Understand head/tail structure
# - Know performance implications of linked lists
# - Use common List functions
#
# Prerequisites:
# - Lesson 03 (Operators) completed
#
# ============================================================================

IO.puts("=" |> String.duplicate(60))
IO.puts("Lesson 04: Lists")
IO.puts("=" |> String.duplicate(60))

# -----------------------------------------------------------------------------
# Section 1: Creating Lists
# -----------------------------------------------------------------------------

IO.puts("\n--- Creating Lists ---")

# Lists use square brackets
empty = []
numbers = [1, 2, 3, 4, 5]
mixed = [1, "two", :three, 4.0]  # Can mix types
nested = [[1, 2], [3, 4], [5, 6]]

IO.inspect(empty, label: "Empty list")
IO.inspect(numbers, label: "Number list")
IO.inspect(mixed, label: "Mixed types")
IO.inspect(nested, label: "Nested lists")

# Lists can contain any type, including other lists
complex = [1, [2, 3], %{key: "value"}, fn x -> x end]
IO.inspect(complex, label: "Complex list")

# Charlists are lists of integers (character codes)
# IEx shows them differently:
IO.inspect([104, 101, 108, 108, 111], label: "List of char codes")
# This might display as 'hello' in IEx!

# -----------------------------------------------------------------------------
# Section 2: Head and Tail
# -----------------------------------------------------------------------------

IO.puts("\n--- Head and Tail ---")

# Lists are linked lists: [head | tail]
# head = first element
# tail = rest of the list (also a list)

list = [1, 2, 3, 4, 5]

IO.inspect(hd(list), label: "hd([1,2,3,4,5])")
IO.inspect(tl(list), label: "tl([1,2,3,4,5])")

# Pattern matching to extract head and tail
[head | tail] = list
IO.inspect(head, label: "head via pattern match")
IO.inspect(tail, label: "tail via pattern match")

# The tail of a single-element list is empty
[x | rest] = [42]
IO.inspect(x, label: "head of [42]")
IO.inspect(rest, label: "tail of [42]")

# Multiple elements from the front
[first, second | rest] = [1, 2, 3, 4, 5]
IO.inspect(first, label: "first")
IO.inspect(second, label: "second")
IO.inspect(rest, label: "rest")

# Empty list has no head or tail
# hd([]) would raise an error!

# -----------------------------------------------------------------------------
# Section 3: Performance Characteristics
# -----------------------------------------------------------------------------

IO.puts("\n--- Performance Characteristics ---")

# Lists are LINKED LISTS, not arrays!
# This affects performance:

# FAST (O(1)):
# - Getting head: hd(list)
# - Getting tail: tl(list)
# - Prepending: [new | list]

# SLOW (O(n)):
# - Getting length: length(list)
# - Accessing by index: Enum.at(list, i)
# - Appending: list ++ [new]

IO.puts("Fast operations (O(1)):")
IO.puts("  - hd(list) - get first element")
IO.puts("  - tl(list) - get rest of list")
IO.puts("  - [elem | list] - prepend element")

IO.puts("\nSlow operations (O(n)):")
IO.puts("  - length(list) - count elements")
IO.puts("  - Enum.at(list, i) - access by index")
IO.puts("  - list ++ [elem] - append element")
IO.puts("  - Enum.reverse(list) - reverse")

# Example: prepend vs append
list = [1, 2, 3]

# Fast: prepend
new_list = [0 | list]
IO.inspect(new_list, label: "Prepend (fast)")

# Slow: append (creates new list)
new_list = list ++ [4]
IO.inspect(new_list, label: "Append (slow)")

# -----------------------------------------------------------------------------
# Section 4: List Operators
# -----------------------------------------------------------------------------

IO.puts("\n--- List Operators ---")

# Concatenation with ++
a = [1, 2, 3]
b = [4, 5, 6]
IO.inspect(a ++ b, label: "[1,2,3] ++ [4,5,6]")

# Subtraction with --
IO.inspect([1, 2, 3, 2, 1] -- [1, 2], label: "[1,2,3,2,1] -- [1,2]")
# Removes first occurrence of each element

# Multiple subtractions
IO.inspect([1, 1, 1, 2, 2, 3] -- [1] -- [1], label: "[1,1,1,2,2,3] -- [1] -- [1]")

# Membership with in
IO.inspect(2 in [1, 2, 3], label: "2 in [1,2,3]")
IO.inspect(4 in [1, 2, 3], label: "4 in [1,2,3]")

# Cons operator | for prepending
IO.inspect([0 | [1, 2, 3]], label: "[0 | [1,2,3]]")

# Multiple prepends
IO.inspect([0 | [1 | [2 | [3 | []]]]], label: "Building [0,1,2,3] with |")

# -----------------------------------------------------------------------------
# Section 5: Common List Functions
# -----------------------------------------------------------------------------

IO.puts("\n--- Common List Functions ---")

list = [1, 2, 3, 4, 5]

# Length
IO.inspect(length(list), label: "length")

# First and last
IO.inspect(List.first(list), label: "List.first")
IO.inspect(List.last(list), label: "List.last")

# With default for empty list
IO.inspect(List.first([], :default), label: "List.first([], :default)")

# Flatten nested lists
nested = [[1, 2], [3, [4, 5]]]
IO.inspect(List.flatten(nested), label: "List.flatten")

# Flatten one level
IO.inspect(List.flatten(nested, []), label: "List.flatten one level")

# Delete element (first occurrence)
IO.inspect(List.delete([1, 2, 3, 2, 1], 2), label: "List.delete (first 2)")

# Delete at index
IO.inspect(List.delete_at([1, 2, 3, 4], 2), label: "List.delete_at index 2")

# Insert at index
IO.inspect(List.insert_at([1, 2, 4], 2, 3), label: "List.insert_at index 2")

# Replace at index
IO.inspect(List.replace_at([1, 2, 3], 1, :two), label: "List.replace_at index 1")

# Update at index with function
IO.inspect(List.update_at([1, 2, 3], 1, &(&1 * 10)), label: "List.update_at")

# Wrap a value in a list (useful for APIs)
IO.inspect(List.wrap(1), label: "List.wrap(1)")
IO.inspect(List.wrap([1, 2]), label: "List.wrap([1,2])")
IO.inspect(List.wrap(nil), label: "List.wrap(nil)")

# -----------------------------------------------------------------------------
# Section 6: List Comprehensions (Preview)
# -----------------------------------------------------------------------------

IO.puts("\n--- List Comprehensions (Preview) ---")

# A powerful way to transform lists (covered in depth later)

# Double each element
IO.inspect(for x <- [1, 2, 3], do: x * 2, label: "for x <- [1,2,3], do: x * 2")

# Filter and transform
IO.inspect(for x <- 1..10, rem(x, 2) == 0, do: x, label: "Even numbers 1-10")

# Cartesian product
IO.inspect(for x <- [1, 2], y <- [:a, :b], do: {x, y}, label: "Cartesian product")

# -----------------------------------------------------------------------------
# Section 7: Working with Charlists
# -----------------------------------------------------------------------------

IO.puts("\n--- Charlists ---")

# Single quotes create charlists (lists of character codes)
charlist = 'hello'
IO.inspect(charlist, label: "Charlist 'hello'")
IO.inspect(charlist, label: "As integers", charlists: :as_lists)

# Converting between strings and charlists
IO.inspect(to_string('hello'), label: "to_string('hello')")
IO.inspect(to_charlist("hello"), label: "to_charlist(\"hello\")")

# Charlist operations (they're just lists!)
IO.inspect('hello' ++ ' world', label: "'hello' ++ ' world'")

# Check type
IO.inspect(is_list('hello'), label: "is_list('hello')")
IO.inspect(is_list("hello"), label: "is_list(\"hello\")")

# IMPORTANT: Use double-quoted strings in Elixir!
# Charlists are mainly for Erlang interoperability

# -----------------------------------------------------------------------------
# Section 8: Pattern Matching with Lists
# -----------------------------------------------------------------------------

IO.puts("\n--- Pattern Matching with Lists ---")

# Match exact list
[a, b, c] = [1, 2, 3]
IO.inspect({a, b, c}, label: "[a, b, c] = [1, 2, 3]")

# Match with head and tail
[head | tail] = [1, 2, 3, 4]
IO.inspect({head, tail}, label: "[head | tail]")

# Match multiple heads
[first, second | rest] = [1, 2, 3, 4, 5]
IO.inspect({first, second, rest}, label: "[first, second | rest]")

# Match empty tail
[only | []] = [42]
IO.inspect(only, label: "Single element")

# Ignore elements with _
[_, second, _] = [1, 2, 3]
IO.inspect(second, label: "Only second element")

# Match specific values
[1, x, 3] = [1, 2, 3]
IO.inspect(x, label: "x from [1, x, 3] = [1, 2, 3]")

# This would fail: [1, x, 3] = [1, 2, 4]  # No match!

# -----------------------------------------------------------------------------
# Section 9: Recursion with Lists (Preview)
# -----------------------------------------------------------------------------

IO.puts("\n--- Recursion with Lists (Preview) ---")

# Lists and recursion go hand-in-hand
# Here's a simple example (covered in depth in lesson 17)

defmodule ListExamples do
  # Sum all elements in a list
  def sum([]), do: 0
  def sum([head | tail]), do: head + sum(tail)

  # Count elements
  def count([]), do: 0
  def count([_ | tail]), do: 1 + count(tail)

  # Double each element
  def double([]), do: []
  def double([head | tail]), do: [head * 2 | double(tail)]
end

IO.inspect(ListExamples.sum([1, 2, 3, 4, 5]), label: "sum([1,2,3,4,5])")
IO.inspect(ListExamples.count([1, 2, 3, 4, 5]), label: "count([1,2,3,4,5])")
IO.inspect(ListExamples.double([1, 2, 3]), label: "double([1,2,3])")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: List Construction
# Difficulty: Easy
#
# Using only the | (cons) operator and [], build the list [1, 2, 3, 4]
# Start from [] and prepend each element
#
# Your code here:

IO.puts("\nExercise 1: Build [1,2,3,4] with cons operator")

# Exercise 2: Pattern Extraction
# Difficulty: Easy
#
# Given the list ["Elixir", "Phoenix", "LiveView", "Ecto", "OTP"]
# Use pattern matching to extract:
# 1. The first element
# 2. The second element
# 3. All elements except the first two
#
# Your code here:

IO.puts("\nExercise 2: Extract from list")

# Exercise 3: List Operations
# Difficulty: Medium
#
# Given lists: a = [1, 2, 3, 4, 5] and b = [4, 5, 6, 7, 8]
# Find:
# 1. Elements in both lists (intersection)
# 2. Elements in a but not in b
# 3. Elements in either list but not both (symmetric difference)
#
# Hint: Use -- operator creatively
#
# Your code here:

IO.puts("\nExercise 3: Set operations with lists")

# Exercise 4: Recursive Length
# Difficulty: Medium
#
# Implement your own length function using recursion.
# Don't use the built-in length/1!
#
# defmodule MyList do
#   def my_length([]), do: ???
#   def my_length([_ | tail]), do: ???
# end
#
# Your code here:

IO.puts("\nExercise 4: Recursive length")

# Exercise 5: List Transformation
# Difficulty: Hard
#
# Implement a function that reverses a list using only
# recursion and the | operator.
# Don't use Enum.reverse or List.foldl!
#
# Hint: You'll need an accumulator
#
# defmodule MyList do
#   def reverse(list), do: reverse(list, [])
#   defp reverse([], acc), do: ???
#   defp reverse([head | tail], acc), do: ???
# end
#
# Your code here:

IO.puts("\nExercise 5: Recursive reverse")

# Exercise 6: Flatten One Level
# Difficulty: Hard
#
# Implement a function that flattens a list by one level only.
# [[1, 2], [3, [4, 5]]] should become [1, 2, 3, [4, 5]]
#
# Your code here:

IO.puts("\nExercise 6: Flatten one level")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

1. Lists are LINKED LISTS (not arrays!)
   - Prepend is O(1): [elem | list]
   - Append is O(n): list ++ [elem]
   - Length is O(n): length(list)

2. Head and Tail:
   - hd(list) - first element
   - tl(list) - rest of list
   - [head | tail] = list - pattern match

3. Operators:
   - ++ concatenation
   - -- subtraction
   - | cons (prepend)
   - in membership

4. Common Functions:
   - length/1, List.first/1, List.last/1
   - List.flatten/1, List.delete/2
   - List.insert_at/3, List.update_at/3

5. Pattern Matching:
   - [a, b, c] = [1, 2, 3]
   - [head | tail] = [1, 2, 3]
   - [first, second | rest] = [1, 2, 3, 4, 5]

6. Prefer Enum module for transformations (coming soon!)

Next: 05_tuples.exs - Fixed-size collections with tuples
""")
