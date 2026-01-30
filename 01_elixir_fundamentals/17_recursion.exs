# ============================================================================
# Lesson 17: Recursion
# ============================================================================
#
# Recursion is fundamental in functional programming. Since Elixir doesn't
# have traditional loops (for, while), recursion is how we iterate.
# Elixir optimizes tail recursion, making it as efficient as loops.
#
# Learning Objectives:
# - Understand recursive thinking patterns
# - Write recursive functions with base and recursive cases
# - Implement tail recursion with accumulators
# - Know when to use recursion vs Enum functions
# - Avoid common recursion pitfalls
#
# Prerequisites:
# - Function clauses (Lesson 16)
# - Pattern matching (Lesson 06)
# - Lists (Lesson 04)
#
# ============================================================================

IO.puts("=" |> String.duplicate(60))
IO.puts("Lesson 17: Recursion")
IO.puts("=" |> String.duplicate(60))

# -----------------------------------------------------------------------------
# Section 1: Basic Recursion Concepts
# -----------------------------------------------------------------------------

IO.puts("\n--- Basic Recursion Concepts ---")

# A recursive function calls itself
# Every recursive function needs:
# 1. Base case(s) - when to stop
# 2. Recursive case(s) - how to break down the problem

defmodule BasicRecursion do
  # Countdown: print numbers from n to 1
  def countdown(0) do
    IO.puts("Blastoff!")
  end

  def countdown(n) when n > 0 do
    IO.puts(n)
    countdown(n - 1)  # Recursive call with smaller value
  end

  # Count up: print numbers from 1 to n
  def count_up(n), do: do_count_up(1, n)

  defp do_count_up(current, max) when current > max do
    IO.puts("Done!")
  end

  defp do_count_up(current, max) do
    IO.puts(current)
    do_count_up(current + 1, max)
  end
end

IO.puts("Countdown from 5:")
BasicRecursion.countdown(5)

IO.puts("\nCount up to 5:")
BasicRecursion.count_up(5)

# The key insight: we're reducing the problem size with each call
# countdown(5) -> countdown(4) -> countdown(3) -> ... -> countdown(0)

# -----------------------------------------------------------------------------
# Section 2: Recursion on Lists
# -----------------------------------------------------------------------------

IO.puts("\n--- Recursion on Lists ---")

# Lists are the perfect data structure for recursion
# Pattern: [head | tail] naturally breaks down a list

defmodule ListRecursion do
  # Sum all elements
  def sum([]), do: 0                           # Base case: empty list
  def sum([head | tail]), do: head + sum(tail)  # Recursive case

  # Count elements
  def length_of([]), do: 0
  def length_of([_head | tail]), do: 1 + length_of(tail)

  # Find maximum (requires non-empty list)
  def max([x]), do: x  # Base: single element
  def max([head | tail]) do
    tail_max = max(tail)
    if head > tail_max, do: head, else: tail_max
  end

  # Double each element
  def double([]), do: []
  def double([head | tail]), do: [head * 2 | double(tail)]

  # Filter elements (keep only positive)
  def keep_positive([]), do: []
  def keep_positive([head | tail]) when head > 0 do
    [head | keep_positive(tail)]
  end
  def keep_positive([_head | tail]), do: keep_positive(tail)
end

numbers = [1, 2, 3, 4, 5]

IO.inspect(ListRecursion.sum(numbers), label: "sum")
IO.inspect(ListRecursion.length_of(numbers), label: "length")
IO.inspect(ListRecursion.max(numbers), label: "max")
IO.inspect(ListRecursion.double(numbers), label: "double")
IO.inspect(ListRecursion.keep_positive([1, -2, 3, -4, 5]), label: "keep_positive")

# Trace of sum([1, 2, 3]):
#   sum([1, 2, 3])
#   = 1 + sum([2, 3])
#   = 1 + (2 + sum([3]))
#   = 1 + (2 + (3 + sum([])))
#   = 1 + (2 + (3 + 0))
#   = 1 + (2 + 3)
#   = 1 + 5
#   = 6

# -----------------------------------------------------------------------------
# Section 3: Tail Recursion
# -----------------------------------------------------------------------------

IO.puts("\n--- Tail Recursion ---")

# Tail recursion: the recursive call is the LAST operation
# Elixir optimizes tail calls - no stack growth!

# NOT tail recursive (head + sum(tail) does addition AFTER the recursive call)
defmodule NotTailRecursive do
  def sum([]), do: 0
  def sum([head | tail]), do: head + sum(tail)  # Addition happens after return
end

# TAIL recursive (uses accumulator)
defmodule TailRecursive do
  def sum(list), do: sum(list, 0)  # Start with accumulator = 0

  defp sum([], acc), do: acc                    # Return accumulated value
  defp sum([head | tail], acc), do: sum(tail, acc + head)  # Add to accumulator
end

IO.inspect(NotTailRecursive.sum([1, 2, 3, 4, 5]), label: "Not tail recursive sum")
IO.inspect(TailRecursive.sum([1, 2, 3, 4, 5]), label: "Tail recursive sum")

# Trace of tail recursive sum([1, 2, 3], 0):
#   sum([1, 2, 3], 0)
#   sum([2, 3], 1)        <- accumulator builds up
#   sum([3], 3)
#   sum([], 6)
#   6                      <- no unwinding needed!

# More tail recursive examples
defmodule TailRecursiveExamples do
  # Length with accumulator
  def length_of(list), do: length_of(list, 0)
  defp length_of([], acc), do: acc
  defp length_of([_h | t], acc), do: length_of(t, acc + 1)

  # Reverse with accumulator
  def reverse(list), do: reverse(list, [])
  defp reverse([], acc), do: acc
  defp reverse([head | tail], acc), do: reverse(tail, [head | acc])

  # Map with accumulator (builds result in reverse, then reverses)
  def map(list, func), do: do_map(list, func, [])
  defp do_map([], _func, acc), do: reverse(acc)
  defp do_map([head | tail], func, acc) do
    do_map(tail, func, [func.(head) | acc])
  end

  # Factorial (classic example)
  def factorial(n), do: factorial(n, 1)
  defp factorial(0, acc), do: acc
  defp factorial(n, acc) when n > 0, do: factorial(n - 1, n * acc)
end

IO.inspect(TailRecursiveExamples.length_of([1, 2, 3, 4, 5]), label: "tail length")
IO.inspect(TailRecursiveExamples.reverse([1, 2, 3, 4, 5]), label: "tail reverse")
IO.inspect(TailRecursiveExamples.map([1, 2, 3], fn x -> x * 2 end), label: "tail map")
IO.inspect(TailRecursiveExamples.factorial(10), label: "tail factorial(10)")

# -----------------------------------------------------------------------------
# Section 4: Accumulator Patterns
# -----------------------------------------------------------------------------

IO.puts("\n--- Accumulator Patterns ---")

# Accumulators can be any data type!

defmodule AccumulatorPatterns do
  # Integer accumulator - sum
  def sum(list), do: sum(list, 0)
  defp sum([], acc), do: acc
  defp sum([h | t], acc), do: sum(t, acc + h)

  # List accumulator - collect results
  def filter(list, predicate), do: filter(list, predicate, [])
  defp filter([], _pred, acc), do: Enum.reverse(acc)
  defp filter([h | t], pred, acc) do
    if pred.(h) do
      filter(t, pred, [h | acc])
    else
      filter(t, pred, acc)
    end
  end

  # Tuple accumulator - multiple values
  def sum_and_count(list), do: sum_and_count(list, {0, 0})
  defp sum_and_count([], {sum, count}), do: {sum, count}
  defp sum_and_count([h | t], {sum, count}) do
    sum_and_count(t, {sum + h, count + 1})
  end

  # Map accumulator - grouping
  def group_by_sign(list), do: group_by_sign(list, %{positive: [], negative: [], zero: []})
  defp group_by_sign([], acc), do: acc
  defp group_by_sign([h | t], acc) when h > 0 do
    group_by_sign(t, %{acc | positive: [h | acc.positive]})
  end
  defp group_by_sign([h | t], acc) when h < 0 do
    group_by_sign(t, %{acc | negative: [h | acc.negative]})
  end
  defp group_by_sign([h | t], acc) do
    group_by_sign(t, %{acc | zero: [h | acc.zero]})
  end

  # String accumulator - building strings
  def join(list, separator), do: join(list, separator, "")
  defp join([], _sep, acc), do: acc
  defp join([h], _sep, ""), do: to_string(h)
  defp join([h], _sep, acc), do: acc <> to_string(h)
  defp join([h | t], sep, ""), do: join(t, sep, to_string(h))
  defp join([h | t], sep, acc), do: join(t, sep, acc <> sep <> to_string(h))
end

IO.inspect(AccumulatorPatterns.sum([1, 2, 3, 4, 5]), label: "sum")
IO.inspect(AccumulatorPatterns.filter([1, 2, 3, 4, 5, 6], fn x -> rem(x, 2) == 0 end),
  label: "filter evens")
IO.inspect(AccumulatorPatterns.sum_and_count([1, 2, 3, 4, 5]), label: "sum_and_count")
IO.inspect(AccumulatorPatterns.group_by_sign([1, -2, 0, 3, -4, 0, 5]), label: "group_by_sign")
IO.inspect(AccumulatorPatterns.join(["a", "b", "c"], ", "), label: "join")

# -----------------------------------------------------------------------------
# Section 5: Multiple Base Cases and Recursive Cases
# -----------------------------------------------------------------------------

IO.puts("\n--- Multiple Base Cases ---")

defmodule MultipleCases do
  # Fibonacci - two base cases
  def fib(0), do: 0
  def fib(1), do: 1
  def fib(n) when n > 1, do: fib(n - 1) + fib(n - 2)

  # Efficient fibonacci with accumulator (two accumulators!)
  def fib_fast(n), do: fib_fast(n, 0, 1)
  defp fib_fast(0, a, _b), do: a
  defp fib_fast(n, a, b), do: fib_fast(n - 1, b, a + b)

  # Processing two lists - multiple recursive cases
  def zip([], _), do: []
  def zip(_, []), do: []
  def zip([h1 | t1], [h2 | t2]), do: [{h1, h2} | zip(t1, t2)]

  # Merge two sorted lists
  def merge([], list2), do: list2
  def merge(list1, []), do: list1
  def merge([h1 | t1] = list1, [h2 | t2] = list2) do
    if h1 <= h2 do
      [h1 | merge(t1, list2)]
    else
      [h2 | merge(list1, t2)]
    end
  end
end

IO.puts("Fibonacci sequence:")
fibs = for n <- 0..10, do: MultipleCases.fib_fast(n)
IO.inspect(fibs, label: "fib(0..10)")

IO.inspect(MultipleCases.zip([1, 2, 3], [:a, :b, :c]), label: "zip")
IO.inspect(MultipleCases.zip([1, 2], [:a, :b, :c, :d]), label: "zip unequal")
IO.inspect(MultipleCases.merge([1, 3, 5], [2, 4, 6]), label: "merge sorted")

# -----------------------------------------------------------------------------
# Section 6: Tree Recursion
# -----------------------------------------------------------------------------

IO.puts("\n--- Tree Recursion ---")

# Recursion on tree-like structures
# Representation: {:node, value, left, right} or :empty

defmodule BinaryTree do
  # Create some helper functions
  def leaf(value), do: {:node, value, :empty, :empty}
  def node(value, left, right), do: {:node, value, left, right}

  # Sum all values in tree
  def sum(:empty), do: 0
  def sum({:node, value, left, right}) do
    value + sum(left) + sum(right)
  end

  # Count nodes
  def count(:empty), do: 0
  def count({:node, _value, left, right}) do
    1 + count(left) + count(right)
  end

  # Find height/depth of tree
  def height(:empty), do: 0
  def height({:node, _value, left, right}) do
    1 + max(height(left), height(right))
  end

  # Check if value exists in tree
  def member?(:empty, _value), do: false
  def member?({:node, value, _left, _right}, value), do: true
  def member?({:node, _value, left, right}, target) do
    member?(left, target) or member?(right, target)
  end

  # Convert tree to list (in-order traversal)
  def to_list(:empty), do: []
  def to_list({:node, value, left, right}) do
    to_list(left) ++ [value] ++ to_list(right)
  end

  # Map over tree values
  def map(:empty, _func), do: :empty
  def map({:node, value, left, right}, func) do
    {:node, func.(value), map(left, func), map(right, func)}
  end
end

# Build a sample tree:
#        5
#       / \
#      3   8
#     / \   \
#    1   4   10

tree = BinaryTree.node(5,
  BinaryTree.node(3, BinaryTree.leaf(1), BinaryTree.leaf(4)),
  BinaryTree.node(8, :empty, BinaryTree.leaf(10))
)

IO.inspect(tree, label: "Tree structure")
IO.inspect(BinaryTree.sum(tree), label: "Sum of tree")
IO.inspect(BinaryTree.count(tree), label: "Count of nodes")
IO.inspect(BinaryTree.height(tree), label: "Height of tree")
IO.inspect(BinaryTree.member?(tree, 4), label: "member?(4)")
IO.inspect(BinaryTree.member?(tree, 99), label: "member?(99)")
IO.inspect(BinaryTree.to_list(tree), label: "In-order traversal")
IO.inspect(BinaryTree.map(tree, fn x -> x * 2 end), label: "Map *2")

# -----------------------------------------------------------------------------
# Section 7: Recursion vs Enum
# -----------------------------------------------------------------------------

IO.puts("\n--- Recursion vs Enum ---")

# In practice, use Enum for most list operations
# Enum functions are well-tested and optimized

defmodule CompareApproaches do
  # Recursive approach
  def sum_recursive([]), do: 0
  def sum_recursive([h | t]), do: h + sum_recursive(t)

  # Enum approach (preferred in most cases)
  def sum_enum(list), do: Enum.sum(list)

  # Recursive filter
  def filter_recursive([], _pred), do: []
  def filter_recursive([h | t], pred) do
    if pred.(h) do
      [h | filter_recursive(t, pred)]
    else
      filter_recursive(t, pred)
    end
  end

  # Enum filter (preferred)
  def filter_enum(list, pred), do: Enum.filter(list, pred)
end

numbers = Enum.to_list(1..100)

IO.inspect(CompareApproaches.sum_recursive(numbers), label: "Recursive sum")
IO.inspect(CompareApproaches.sum_enum(numbers), label: "Enum sum")

even? = fn x -> rem(x, 2) == 0 end
IO.inspect(length(CompareApproaches.filter_recursive(numbers, even?)), label: "Recursive filter evens")
IO.inspect(length(CompareApproaches.filter_enum(numbers, even?)), label: "Enum filter evens")

IO.puts("""

When to use explicit recursion:
- Learning and understanding how things work
- Custom traversal patterns
- When Enum doesn't have what you need
- Tree/graph structures
- Stateful recursion with complex accumulators

When to use Enum:
- Standard list operations (map, filter, reduce)
- Production code (well-tested, readable)
- When readability is important
- Simple transformations
""")

# -----------------------------------------------------------------------------
# Section 8: Common Recursion Patterns
# -----------------------------------------------------------------------------

IO.puts("\n--- Common Recursion Patterns ---")

defmodule RecursionPatterns do
  # Pattern 1: Process and transform each element
  def double_all([]), do: []
  def double_all([h | t]), do: [h * 2 | double_all(t)]

  # Pattern 2: Filter elements
  def only_evens([]), do: []
  def only_evens([h | t]) when rem(h, 2) == 0, do: [h | only_evens(t)]
  def only_evens([_ | t]), do: only_evens(t)

  # Pattern 3: Reduce to single value
  def product([]), do: 1
  def product([h | t]), do: h * product(t)

  # Pattern 4: Find specific element
  def find([], _target), do: nil
  def find([target | _t], target), do: target
  def find([_ | t], target), do: find(t, target)

  # Pattern 5: Take while condition is true
  def take_while([], _pred), do: []
  def take_while([h | t], pred) do
    if pred.(h) do
      [h | take_while(t, pred)]
    else
      []
    end
  end

  # Pattern 6: Drop while condition is true
  def drop_while([], _pred), do: []
  def drop_while([h | t] = list, pred) do
    if pred.(h) do
      drop_while(t, pred)
    else
      list
    end
  end

  # Pattern 7: Flatten nested lists
  def flatten([]), do: []
  def flatten([head | tail]) when is_list(head) do
    flatten(head) ++ flatten(tail)
  end
  def flatten([head | tail]), do: [head | flatten(tail)]
end

IO.inspect(RecursionPatterns.double_all([1, 2, 3]), label: "double_all")
IO.inspect(RecursionPatterns.only_evens([1, 2, 3, 4, 5, 6]), label: "only_evens")
IO.inspect(RecursionPatterns.product([1, 2, 3, 4, 5]), label: "product")
IO.inspect(RecursionPatterns.find([1, 2, 3, 4, 5], 3), label: "find 3")
IO.inspect(RecursionPatterns.find([1, 2, 3, 4, 5], 9), label: "find 9")
IO.inspect(RecursionPatterns.take_while([1, 2, 3, 4, 5], fn x -> x < 4 end), label: "take_while < 4")
IO.inspect(RecursionPatterns.drop_while([1, 2, 3, 4, 5], fn x -> x < 4 end), label: "drop_while < 4")
IO.inspect(RecursionPatterns.flatten([[1, 2], [3, [4, 5]], 6]), label: "flatten")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: Recursive List Length
# Difficulty: Easy
#
# Implement my_length/1 that returns the length of a list
# Use recursion (not Enum.count or length/1)
#
# my_length([]) => 0
# my_length([1, 2, 3]) => 3
#
# Your code here:

IO.puts("\nExercise 1: Implement recursive list length")
# defmodule Exercise1 do
#   def my_length([]), do: ...
#   def my_length([_ | tail]), do: ...
# end

# Exercise 2: Tail-Recursive Sum with Accumulator
# Difficulty: Easy
#
# Implement sum/1 as a tail-recursive function using an accumulator.
# Create a public function sum/1 and a private sum/2 with accumulator.
#
# sum([1, 2, 3, 4, 5]) => 15
#
# Your code here:

IO.puts("\nExercise 2: Implement tail-recursive sum")
# defmodule Exercise2 do
#   def sum(list), do: sum(list, 0)
#   defp sum([], acc), do: ...
#   defp sum([head | tail], acc), do: ...
# end

# Exercise 3: Implement map/2
# Difficulty: Medium
#
# Implement my_map/2 that applies a function to each element.
# Use tail recursion with an accumulator.
# Remember to reverse the result at the end!
#
# my_map([1, 2, 3], fn x -> x * 2 end) => [2, 4, 6]
#
# Your code here:

IO.puts("\nExercise 3: Implement recursive map")
# defmodule Exercise3 do
#   def my_map(list, func), do: do_map(list, func, [])
#   defp do_map([], _func, acc), do: ...
#   defp do_map([head | tail], func, acc), do: ...
# end

# Exercise 4: Implement reduce/3
# Difficulty: Medium
#
# Implement my_reduce/3 that reduces a list to a single value.
# reduce(list, initial_acc, reducer_function)
#
# my_reduce([1, 2, 3], 0, fn x, acc -> x + acc end) => 6
# my_reduce([1, 2, 3], 1, fn x, acc -> x * acc end) => 6
#
# Your code here:

IO.puts("\nExercise 4: Implement recursive reduce")
# defmodule Exercise4 do
#   def my_reduce([], acc, _func), do: ...
#   def my_reduce([head | tail], acc, func), do: ...
# end

# Exercise 5: Implement take/2 and drop/2
# Difficulty: Medium
#
# take/2 returns the first n elements
# drop/2 removes the first n elements
#
# take([1, 2, 3, 4, 5], 3) => [1, 2, 3]
# drop([1, 2, 3, 4, 5], 3) => [4, 5]
#
# Handle edge cases: n = 0, n > length of list
#
# Your code here:

IO.puts("\nExercise 5: Implement take and drop")
# defmodule Exercise5 do
#   def take([], _n), do: ...
#   def take(_list, 0), do: ...
#   def take([head | tail], n), do: ...
#
#   def drop(list, 0), do: ...
#   def drop([], _n), do: ...
#   def drop([_ | tail], n), do: ...
# end

# Exercise 6: Quick Sort
# Difficulty: Hard
#
# Implement quicksort/1 using recursion.
# Algorithm:
# 1. Base case: empty list or single element is already sorted
# 2. Pick a pivot (first element)
# 3. Partition into elements < pivot, elements >= pivot
# 4. Recursively sort both partitions
# 5. Combine: sorted_less ++ [pivot] ++ sorted_greater
#
# quicksort([3, 1, 4, 1, 5, 9, 2, 6]) => [1, 1, 2, 3, 4, 5, 6, 9]
#
# Your code here:

IO.puts("\nExercise 6: Implement quicksort")
# defmodule Exercise6 do
#   def quicksort([]), do: []
#   def quicksort([pivot | rest]) do
#     lesser = ... # filter elements < pivot
#     greater = ... # filter elements >= pivot
#     quicksort(lesser) ++ [pivot] ++ quicksort(greater)
#   end
# end

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

1. Recursion Basics:
   - Every recursive function needs base case(s) and recursive case(s)
   - Base case: when to stop (empty list, 0, etc.)
   - Recursive case: break down the problem

2. List Recursion Pattern:
   def func([]), do: base_result
   def func([head | tail]), do: process(head, func(tail))

3. Tail Recursion:
   - Recursive call is the LAST operation
   - Elixir optimizes tail calls (no stack overflow)
   - Use accumulators to achieve tail recursion

4. Accumulator Pattern:
   def func(list), do: func(list, initial_acc)
   defp func([], acc), do: acc
   defp func([h | t], acc), do: func(t, update_acc(acc, h))

5. When to Use Recursion:
   - Tree/graph structures
   - Custom traversal patterns
   - Learning how things work

6. When to Use Enum:
   - Standard list operations
   - Production code
   - Readability matters

7. Common Patterns:
   - Transform each element (map)
   - Filter elements
   - Reduce to single value
   - Find/search
   - Take/drop while condition

Remember: Tail recursion with accumulators is the efficient way!

Next: 18_pipe_operator.exs - The pipe operator and data transformation
""")
