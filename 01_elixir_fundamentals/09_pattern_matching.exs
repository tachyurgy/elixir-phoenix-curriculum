# ============================================================================
# Lesson 09: Pattern Matching
# ============================================================================
#
# Pattern matching is one of Elixir's most powerful features. The = operator
# doesn't just assign values - it matches patterns and binds variables.
# This enables elegant, declarative code.
#
# Learning Objectives:
# - Understand the match operator (=)
# - Destructure data structures
# - Use the pin operator (^)
# - Apply pattern matching in various contexts
# - Handle match failures gracefully
#
# Prerequisites:
# - Lessons 01-08 completed
#
# ============================================================================

IO.puts("=" |> String.duplicate(60))
IO.puts("Lesson 09: Pattern Matching")
IO.puts("=" |> String.duplicate(60))

# -----------------------------------------------------------------------------
# Section 1: The Match Operator (=)
# -----------------------------------------------------------------------------

IO.puts("\n--- The Match Operator (=) ---")

# In Elixir, = is the MATCH operator, not just assignment
# The left side is a pattern, the right side is the value

# Simple "assignment" is actually matching
x = 1
IO.inspect(x, label: "x = 1")

# But we can also match in the other direction!
1 = x  # This works because x is 1
IO.puts("1 = x works!")

# This would fail:
# 2 = x  # MatchError! 2 doesn't match 1

# The match operator checks if both sides can be made equal
# If the left has unbound variables, it binds them

y = 2
2 = y  # Works - both sides equal 2
IO.puts("2 = y works!")

# Multiple bindings
a = b = c = 10
IO.inspect({a, b, c}, label: "a = b = c = 10")

# -----------------------------------------------------------------------------
# Section 2: Matching Tuples
# -----------------------------------------------------------------------------

IO.puts("\n--- Matching Tuples ---")

# Destructure tuples
{a, b, c} = {1, 2, 3}
IO.inspect({a, b, c}, label: "Destructured tuple")

# Match with literals
{:ok, result} = {:ok, 42}
IO.inspect(result, label: "Extracted result from :ok tuple")

# Common pattern: function returns
{:ok, value} = {:ok, "success"}
IO.inspect(value, label: "Success value")

# This would fail:
# {:ok, _} = {:error, "failed"}  # MatchError!

# Ignore elements with underscore
{first, _, third} = {1, 2, 3}
IO.inspect({first, third}, label: "Ignored middle element")

# Nested matching
{{a, b}, {c, d}} = {{1, 2}, {3, 4}}
IO.inspect({a, b, c, d}, label: "Nested tuple match")

# Match size must match
# {a, b} = {1, 2, 3}  # MatchError! Different sizes

# -----------------------------------------------------------------------------
# Section 3: Matching Lists
# -----------------------------------------------------------------------------

IO.puts("\n--- Matching Lists ---")

# Exact matching
[a, b, c] = [1, 2, 3]
IO.inspect({a, b, c}, label: "Exact list match")

# Head and tail matching
[head | tail] = [1, 2, 3, 4, 5]
IO.inspect(head, label: "head")
IO.inspect(tail, label: "tail")

# Multiple heads
[first, second | rest] = [1, 2, 3, 4, 5]
IO.inspect({first, second}, label: "First two elements")
IO.inspect(rest, label: "Rest")

# Single element list
[only] = [42]
IO.inspect(only, label: "Single element")

# Match with empty tail
[x | []] = [1]
IO.inspect(x, label: "Element before empty tail")

# Match specific values
[1, x, 3] = [1, 2, 3]
IO.inspect(x, label: "x from [1, x, 3]")

# Nested lists
[[a, b], [c, d]] = [[1, 2], [3, 4]]
IO.inspect({a, b, c, d}, label: "Nested list match")

# -----------------------------------------------------------------------------
# Section 4: Matching Maps
# -----------------------------------------------------------------------------

IO.puts("\n--- Matching Maps ---")

# Maps match if pattern is a SUBSET
%{name: name} = %{name: "Alice", age: 30, city: "NYC"}
IO.inspect(name, label: "Extracted name")

# Empty map matches any map
%{} = %{a: 1, b: 2, c: 3}
IO.puts("Empty pattern matches any map")

# Match multiple keys
%{name: n, age: a} = %{name: "Bob", age: 25, city: "LA"}
IO.inspect({n, a}, label: "Extracted name and age")

# Match with literal values
%{status: :active} = %{status: :active, id: 1}
IO.puts("Matched active status")

# Nested map matching
user = %{name: "Charlie", address: %{city: "Boston", zip: "02101"}}
%{address: %{city: city}} = user
IO.inspect(city, label: "Nested city extraction")

# Match with string keys
%{"name" => name} = %{"name" => "Dave", "age" => 40}
IO.inspect(name, label: "String key extraction")

# -----------------------------------------------------------------------------
# Section 5: The Pin Operator (^)
# -----------------------------------------------------------------------------

IO.puts("\n--- The Pin Operator (^) ---")

# By default, variables on the left are bound
# Use ^ to match against existing value instead

x = 1
IO.inspect(x, label: "x starts as")

# This rebinds x:
x = 2
IO.inspect(x, label: "x after x = 2")

# Reset for demo
x = 1
IO.inspect(x, label: "x reset to")

# Pin operator: match, don't rebind
^x = 1  # Works! x is 1
IO.puts("^x = 1 works (x is 1)")

# This would fail:
# ^x = 2  # MatchError! x is 1, not 2

# Pin in patterns
expected = "hello"
{:ok, ^expected} = {:ok, "hello"}
IO.puts("Pinned match succeeded")

# Common use: verify a value
id = 42
# Later in code...
%{id: ^id, name: name} = %{id: 42, name: "Test"}
IO.inspect(name, label: "Found record with id #{id}")

# Pin in lists
first = 1
[^first, second, third] = [1, 2, 3]
IO.inspect({second, third}, label: "Pinned first element match")

# Pin is essential for preventing accidental rebinding!

# -----------------------------------------------------------------------------
# Section 6: Pattern Matching in Function Heads
# -----------------------------------------------------------------------------

IO.puts("\n--- Pattern Matching in Function Heads ---")

defmodule Calculator do
  # Match specific patterns
  def divide(_, 0), do: {:error, :division_by_zero}
  def divide(a, b), do: {:ok, a / b}

  # Match on tuple structure
  def process({:ok, value}), do: "Success: #{value}"
  def process({:error, reason}), do: "Error: #{reason}"

  # Match on list patterns
  def sum([]), do: 0
  def sum([head | tail]), do: head + sum(tail)

  # Match on map structure
  def greet(%{name: name, title: title}), do: "Hello, #{title} #{name}"
  def greet(%{name: name}), do: "Hello, #{name}"
  def greet(_), do: "Hello, stranger"
end

IO.inspect(Calculator.divide(10, 2), label: "10 / 2")
IO.inspect(Calculator.divide(10, 0), label: "10 / 0")

IO.puts(Calculator.process({:ok, 42}))
IO.puts(Calculator.process({:error, "failed"}))

IO.inspect(Calculator.sum([1, 2, 3, 4, 5]), label: "sum([1,2,3,4,5])")

IO.puts(Calculator.greet(%{name: "Alice", title: "Dr."}))
IO.puts(Calculator.greet(%{name: "Bob"}))
IO.puts(Calculator.greet("unknown"))

# -----------------------------------------------------------------------------
# Section 7: Guards in Pattern Matching
# -----------------------------------------------------------------------------

IO.puts("\n--- Guards in Pattern Matching ---")

defmodule Classifier do
  # Guards add conditions to patterns
  def classify(n) when is_integer(n) and n < 0, do: :negative
  def classify(0), do: :zero
  def classify(n) when is_integer(n) and n > 0, do: :positive
  def classify(n) when is_float(n), do: :float
  def classify(_), do: :other

  # Multiple guards with 'or' (comma) or 'and' (when ... when)
  def category(x) when x > 0 and x < 10, do: :single_digit
  def category(x) when x >= 10 and x < 100, do: :double_digit
  def category(x) when x >= 100, do: :triple_plus
  def category(_), do: :invalid

  # Guards with pattern matching
  def process_list([head | _]) when head > 0, do: "Starts positive"
  def process_list([head | _]) when head < 0, do: "Starts negative"
  def process_list([0 | _]), do: "Starts with zero"
  def process_list([]), do: "Empty list"
end

IO.inspect(Classifier.classify(-5), label: "classify(-5)")
IO.inspect(Classifier.classify(0), label: "classify(0)")
IO.inspect(Classifier.classify(10), label: "classify(10)")
IO.inspect(Classifier.classify(3.14), label: "classify(3.14)")

IO.inspect(Classifier.category(5), label: "category(5)")
IO.inspect(Classifier.category(50), label: "category(50)")
IO.inspect(Classifier.category(500), label: "category(500)")

IO.puts(Classifier.process_list([5, 1, 2]))
IO.puts(Classifier.process_list([-1, 2, 3]))
IO.puts(Classifier.process_list([0, 1, 2]))

# -----------------------------------------------------------------------------
# Section 8: Pattern Matching in Case Expressions
# -----------------------------------------------------------------------------

IO.puts("\n--- Pattern Matching in Case ---")

# case uses pattern matching
defmodule ResponseHandler do
  def handle(response) do
    case response do
      {:ok, data} when is_list(data) ->
        "Got list with #{length(data)} items"

      {:ok, data} when is_map(data) ->
        "Got map with #{map_size(data)} keys"

      {:ok, data} ->
        "Got: #{inspect(data)}"

      {:error, :not_found} ->
        "Resource not found"

      {:error, reason} when is_atom(reason) ->
        "Error: #{reason}"

      {:error, message} when is_binary(message) ->
        "Error message: #{message}"

      _ ->
        "Unknown response format"
    end
  end
end

IO.puts(ResponseHandler.handle({:ok, [1, 2, 3]}))
IO.puts(ResponseHandler.handle({:ok, %{a: 1, b: 2}}))
IO.puts(ResponseHandler.handle({:ok, "hello"}))
IO.puts(ResponseHandler.handle({:error, :not_found}))
IO.puts(ResponseHandler.handle({:error, :timeout}))
IO.puts(ResponseHandler.handle({:error, "Connection refused"}))
IO.puts(ResponseHandler.handle("unexpected"))

# -----------------------------------------------------------------------------
# Section 9: Advanced Pattern Matching
# -----------------------------------------------------------------------------

IO.puts("\n--- Advanced Pattern Matching ---")

# Binary/String matching
<<first::binary-size(1), rest::binary>> = "Hello"
IO.inspect({first, rest}, label: "Binary split")

# Match beginning of string
"Hello, " <> name = "Hello, World"
IO.inspect(name, label: "String match")

# Struct matching (already covered, but important!)
defmodule Point do
  defstruct [:x, :y]
end

point = %Point{x: 10, y: 20}
%Point{x: x, y: y} = point
IO.inspect({x, y}, label: "Struct match")

# Matching in anonymous functions
handler = fn
  {:ok, value} -> "Success: #{value}"
  {:error, _} -> "Failed"
end

IO.puts(handler.({:ok, 42}))
IO.puts(handler.({:error, "oops"}))

# Matching in for comprehensions
list = [{:ok, 1}, {:error, 2}, {:ok, 3}, {:error, 4}]
ok_values = for {:ok, v} <- list, do: v
IO.inspect(ok_values, label: "Filtered :ok values")

# Matching in with expressions
result = with {:ok, a} <- {:ok, 1},
              {:ok, b} <- {:ok, 2},
              {:ok, c} <- {:ok, 3} do
  {:ok, a + b + c}
end
IO.inspect(result, label: "With expression result")

# -----------------------------------------------------------------------------
# Section 10: Common Patterns and Idioms
# -----------------------------------------------------------------------------

IO.puts("\n--- Common Patterns and Idioms ---")

# Pattern 1: Extracting from nested structures
data = %{
  user: %{
    profile: %{
      name: "Alice",
      settings: %{theme: "dark"}
    }
  }
}

%{user: %{profile: %{name: name, settings: %{theme: theme}}}} = data
IO.inspect({name, theme}, label: "Deep extraction")

# Pattern 2: Function clause ordering (specific to general)
defmodule Matcher do
  # Most specific first
  def match([1, 2, 3]), do: "Exact [1,2,3]"
  def match([1, 2 | _]), do: "Starts with [1,2,...]"
  def match([1 | _]), do: "Starts with 1"
  def match([_ | _]), do: "Non-empty list"
  def match([]), do: "Empty list"
end

IO.puts(Matcher.match([1, 2, 3]))
IO.puts(Matcher.match([1, 2, 4, 5]))
IO.puts(Matcher.match([1, 9, 9]))
IO.puts(Matcher.match([5, 6, 7]))
IO.puts(Matcher.match([]))

# Pattern 3: Handling optional fields
defmodule Parser do
  def parse_options(opts) do
    # Use \\ for defaults, but pattern matching for extraction
    %{
      name: opts[:name] || "unnamed",
      count: opts[:count] || 1,
      verbose: opts[:verbose] || false
    }
  end

  # Or with function clauses
  def get_name(%{name: name}), do: name
  def get_name(_), do: "unnamed"
end

IO.inspect(Parser.parse_options(%{name: "test"}))
IO.inspect(Parser.get_name(%{name: "Alice"}))
IO.inspect(Parser.get_name(%{}))

# Pattern 4: Recursive data processing
defmodule TreeProcessor do
  def sum_tree(nil), do: 0
  def sum_tree({value, left, right}) do
    value + sum_tree(left) + sum_tree(right)
  end
end

tree = {1, {2, nil, nil}, {3, {4, nil, nil}, nil}}
IO.inspect(TreeProcessor.sum_tree(tree), label: "Tree sum")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: Basic Matching
# Difficulty: Easy
#
# Use pattern matching to extract values:
# 1. From tuple {:user, "Alice", 30} - get name and age
# 2. From list [1, 2, 3, 4, 5] - get first, second, and rest
# 3. From map %{a: 1, b: 2, c: 3} - get value of :b
#
# Your code here:

IO.puts("\nExercise 1: Basic pattern matching")

# Exercise 2: Pin Operator
# Difficulty: Easy
#
# Given expected_status = :active
# Write a pattern match that succeeds only when a user map
# has that exact status value.
#
# user1 = %{name: "Alice", status: :active}  # Should match
# user2 = %{name: "Bob", status: :inactive}  # Should not match
#
# Your code here:

IO.puts("\nExercise 2: Using the pin operator")

# Exercise 3: Function Clauses
# Difficulty: Medium
#
# Create a function describe/1 that uses pattern matching to return:
# - "Empty list" for []
# - "Single element: X" for [x]
# - "Pair: X and Y" for [x, y]
# - "List starting with X" for longer lists
#
# Your code here:

IO.puts("\nExercise 3: Multi-clause function")

# Exercise 4: Nested Extraction
# Difficulty: Medium
#
# Given this data structure:
# order = %{
#   id: 123,
#   customer: %{name: "Alice", email: "alice@test.com"},
#   items: [%{name: "Widget", qty: 2}, %{name: "Gadget", qty: 1}]
# }
#
# Use ONE pattern match to extract:
# - The customer name
# - The first item's name
#
# Your code here:

IO.puts("\nExercise 4: Nested data extraction")

# Exercise 5: Error Handling
# Difficulty: Medium
#
# Create a function safe_divide/2 that:
# - Returns {:ok, result} for valid division
# - Returns {:error, :division_by_zero} for division by zero
#
# Then create a function that uses pattern matching to process
# the result and return a formatted string.
#
# Your code here:

IO.puts("\nExercise 5: Error handling with patterns")

# Exercise 6: List Processing
# Difficulty: Hard
#
# Create a function that takes a list of {:ok, value} and {:error, reason}
# tuples and returns:
# - {:ok, [values]} if all are :ok
# - {:error, first_error} if any is :error
#
# Example:
# [{:ok, 1}, {:ok, 2}, {:ok, 3}] -> {:ok, [1, 2, 3]}
# [{:ok, 1}, {:error, "fail"}, {:ok, 3}] -> {:error, "fail"}
#
# Your code here:

IO.puts("\nExercise 6: Aggregate results")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

1. The = operator is the MATCH operator:
   - Left side is a pattern
   - Right side is the value
   - Unbound variables get bound

2. Destructuring data:
   - Tuples: {a, b, c} = {1, 2, 3}
   - Lists: [head | tail] = [1, 2, 3]
   - Maps: %{key: value} = map

3. The pin operator (^):
   - Match against existing value
   - Prevents rebinding
   - Essential for verification

4. Pattern matching contexts:
   - Variable binding
   - Function heads
   - Case expressions
   - With expressions
   - For comprehensions

5. Guards enhance patterns:
   - when is_integer(x)
   - when x > 0
   - Combined with and/or

6. Best practices:
   - Order clauses specific to general
   - Use _ to ignore values
   - Pin when verifying values
   - Extract only what you need

7. Common idioms:
   - {:ok, value} / {:error, reason}
   - [head | tail] recursion
   - Deep nested extraction

Next: 10_case.exs - Case statements and control flow
""")
