# ============================================================================
# Lesson 16: Function Clauses
# ============================================================================
#
# Elixir allows you to define multiple clauses of the same function.
# Combined with pattern matching and guards, this creates elegant and
# readable code that handles different cases explicitly.
#
# Learning Objectives:
# - Define multiple function clauses (heads)
# - Use pattern matching in function definitions
# - Apply guards for additional constraints
# - Understand clause ordering and matching
# - Combine clauses with guards effectively
#
# Prerequisites:
# - Pattern matching (Lesson 06)
# - Named functions (Lesson 15)
# - Guards basics
#
# ============================================================================

IO.puts("=" |> String.duplicate(60))
IO.puts("Lesson 16: Function Clauses")
IO.puts("=" |> String.duplicate(60))

# -----------------------------------------------------------------------------
# Section 1: Multiple Function Clauses
# -----------------------------------------------------------------------------

IO.puts("\n--- Multiple Function Clauses ---")

# Instead of using if/case inside a function, you can define
# multiple clauses that pattern match on the arguments

defmodule Factorial do
  # Base case: factorial of 0 is 1
  def calculate(0), do: 1

  # Recursive case: factorial of n is n * factorial(n-1)
  def calculate(n), do: n * calculate(n - 1)
end

IO.inspect(Factorial.calculate(0), label: "factorial(0)")
IO.inspect(Factorial.calculate(5), label: "factorial(5)")
IO.inspect(Factorial.calculate(10), label: "factorial(10)")

# The clauses are tried in order from top to bottom
# First matching clause wins

defmodule Greeting do
  def say_hello(:morning), do: "Good morning!"
  def say_hello(:afternoon), do: "Good afternoon!"
  def say_hello(:evening), do: "Good evening!"
  def say_hello(_other), do: "Hello!"  # Catch-all clause
end

IO.inspect(Greeting.say_hello(:morning), label: "morning")
IO.inspect(Greeting.say_hello(:afternoon), label: "afternoon")
IO.inspect(Greeting.say_hello(:evening), label: "evening")
IO.inspect(Greeting.say_hello(:night), label: "night (catch-all)")

# -----------------------------------------------------------------------------
# Section 2: Pattern Matching in Function Clauses
# -----------------------------------------------------------------------------

IO.puts("\n--- Pattern Matching in Function Clauses ---")

defmodule ListOperations do
  # Empty list
  def first([]), do: nil

  # Non-empty list - extract head
  def first([head | _tail]), do: head

  # Exactly one element
  def describe([_]), do: "single element"

  # Exactly two elements
  def describe([_, _]), do: "two elements"

  # Three or more elements
  def describe([_, _, _ | _rest]), do: "three or more elements"

  # Empty list
  def describe([]), do: "empty list"
end

IO.inspect(ListOperations.first([1, 2, 3]), label: "first of [1,2,3]")
IO.inspect(ListOperations.first([]), label: "first of []")

IO.inspect(ListOperations.describe([]), label: "describe []")
IO.inspect(ListOperations.describe([1]), label: "describe [1]")
IO.inspect(ListOperations.describe([1, 2]), label: "describe [1,2]")
IO.inspect(ListOperations.describe([1, 2, 3, 4]), label: "describe [1,2,3,4]")

# Pattern matching on tuples
defmodule ResultHandler do
  def handle({:ok, value}), do: "Success: #{inspect(value)}"
  def handle({:error, reason}), do: "Error: #{reason}"
  def handle({:warning, message}), do: "Warning: #{message}"
  def handle(other), do: "Unknown: #{inspect(other)}"
end

IO.inspect(ResultHandler.handle({:ok, 42}), label: "handle :ok")
IO.inspect(ResultHandler.handle({:error, "not found"}), label: "handle :error")
IO.inspect(ResultHandler.handle({:warning, "deprecated"}), label: "handle :warning")
IO.inspect(ResultHandler.handle("something else"), label: "handle other")

# Pattern matching on maps
defmodule UserHandler do
  def greet(%{name: name, role: :admin}), do: "Welcome, Administrator #{name}!"
  def greet(%{name: name, role: :user}), do: "Hello, #{name}!"
  def greet(%{name: name}), do: "Hi, #{name}!"
  def greet(_), do: "Hello, stranger!"
end

IO.inspect(UserHandler.greet(%{name: "Alice", role: :admin}), label: "admin")
IO.inspect(UserHandler.greet(%{name: "Bob", role: :user}), label: "user")
IO.inspect(UserHandler.greet(%{name: "Charlie"}), label: "no role")
IO.inspect(UserHandler.greet(%{id: 123}), label: "no name")

# -----------------------------------------------------------------------------
# Section 3: Guards in Function Clauses
# -----------------------------------------------------------------------------

IO.puts("\n--- Guards in Function Clauses ---")

# Guards add extra conditions beyond pattern matching
# Use `when` keyword followed by guard expressions

defmodule NumberChecker do
  def check(n) when is_integer(n) and n > 0, do: "positive integer"
  def check(n) when is_integer(n) and n < 0, do: "negative integer"
  def check(0), do: "zero"
  def check(n) when is_float(n), do: "float: #{n}"
  def check(_), do: "not a number"
end

IO.inspect(NumberChecker.check(42), label: "check 42")
IO.inspect(NumberChecker.check(-17), label: "check -17")
IO.inspect(NumberChecker.check(0), label: "check 0")
IO.inspect(NumberChecker.check(3.14), label: "check 3.14")
IO.inspect(NumberChecker.check("hello"), label: "check \"hello\"")

# Guards with ranges and comparisons
defmodule AgeClassifier do
  def classify(age) when age < 0, do: {:error, "Invalid age"}
  def classify(age) when age < 13, do: {:ok, :child}
  def classify(age) when age < 20, do: {:ok, :teenager}
  def classify(age) when age < 65, do: {:ok, :adult}
  def classify(_age), do: {:ok, :senior}
end

IO.inspect(AgeClassifier.classify(-5), label: "age -5")
IO.inspect(AgeClassifier.classify(8), label: "age 8")
IO.inspect(AgeClassifier.classify(16), label: "age 16")
IO.inspect(AgeClassifier.classify(35), label: "age 35")
IO.inspect(AgeClassifier.classify(70), label: "age 70")

# Multiple guards with `and` / `or`
defmodule StringChecker do
  def check(s) when is_binary(s) and byte_size(s) == 0 do
    "empty string"
  end

  def check(s) when is_binary(s) and byte_size(s) > 0 and byte_size(s) <= 10 do
    "short string (1-10 chars)"
  end

  def check(s) when is_binary(s) and byte_size(s) > 10 do
    "long string (> 10 chars)"
  end

  def check(_), do: "not a string"
end

IO.inspect(StringChecker.check(""), label: "empty string")
IO.inspect(StringChecker.check("hello"), label: "short string")
IO.inspect(StringChecker.check("hello, world!"), label: "long string")
IO.inspect(StringChecker.check(42), label: "not a string")

# -----------------------------------------------------------------------------
# Section 4: Available Guard Expressions
# -----------------------------------------------------------------------------

IO.puts("\n--- Available Guard Expressions ---")

IO.puts("""
Guards are limited to specific expressions for performance reasons.

Type checks:
  is_atom/1, is_binary/1, is_bitstring/1, is_boolean/1
  is_float/1, is_function/1, is_function/2, is_integer/1
  is_list/1, is_map/1, is_nil/1, is_number/1, is_pid/1
  is_port/1, is_reference/1, is_tuple/1

Comparison operators:
  ==, !=, ===, !==, <, <=, >, >=

Boolean operators (short-circuit):
  and, or, not

Arithmetic operators:
  +, -, *, /, div, rem

Other allowed functions:
  abs/1, ceil/1, floor/1, round/1, trunc/1
  bit_size/1, byte_size/1, tuple_size/1, map_size/1
  length/1, hd/1, tl/1, elem/2
  in (membership operator)
""")

# Examples of guard expressions
defmodule GuardExamples do
  # Type checking
  def process(x) when is_list(x), do: "it's a list"
  def process(x) when is_map(x), do: "it's a map"
  def process(x) when is_binary(x), do: "it's a string"
  def process(_), do: "something else"

  # Using `in` for membership
  def day_type(day) when day in [:saturday, :sunday], do: "weekend"
  def day_type(day) when day in [:monday, :tuesday, :wednesday, :thursday, :friday] do
    "weekday"
  end
  def day_type(_), do: "unknown"

  # Using tuple_size
  def tuple_desc(t) when tuple_size(t) == 2, do: "pair"
  def tuple_desc(t) when tuple_size(t) == 3, do: "triple"
  def tuple_desc(t) when is_tuple(t), do: "tuple with #{tuple_size(t)} elements"
  def tuple_desc(_), do: "not a tuple"

  # Combining multiple conditions
  def valid_score?(score) when is_number(score) and score >= 0 and score <= 100 do
    true
  end
  def valid_score?(_), do: false
end

IO.inspect(GuardExamples.process([1, 2, 3]), label: "process list")
IO.inspect(GuardExamples.process(%{a: 1}), label: "process map")
IO.inspect(GuardExamples.day_type(:saturday), label: "day_type saturday")
IO.inspect(GuardExamples.day_type(:monday), label: "day_type monday")
IO.inspect(GuardExamples.tuple_desc({1, 2}), label: "tuple_desc pair")
IO.inspect(GuardExamples.tuple_desc({1, 2, 3, 4}), label: "tuple_desc 4")
IO.inspect(GuardExamples.valid_score?(85), label: "valid_score? 85")
IO.inspect(GuardExamples.valid_score?(150), label: "valid_score? 150")

# -----------------------------------------------------------------------------
# Section 5: Clause Ordering Matters
# -----------------------------------------------------------------------------

IO.puts("\n--- Clause Ordering Matters ---")

# Clauses are matched top to bottom
# More specific clauses should come before more general ones

defmodule OrderingDemo do
  # CORRECT ordering - specific to general
  def describe_correct(0), do: "zero"
  def describe_correct(1), do: "one"
  def describe_correct(n) when n > 0, do: "positive"
  def describe_correct(n) when n < 0, do: "negative"

  # What happens with wrong ordering? The compiler warns you!
  # This is commented out to avoid the warning:
  # def describe_wrong(n) when n > 0, do: "positive"  # This would match 1
  # def describe_wrong(1), do: "one"  # This would never match!
end

IO.inspect(OrderingDemo.describe_correct(0), label: "describe 0")
IO.inspect(OrderingDemo.describe_correct(1), label: "describe 1")
IO.inspect(OrderingDemo.describe_correct(5), label: "describe 5")

# Pattern specificity examples
defmodule PatternOrder do
  # Specific map pattern
  def handle(%{status: :error, code: 404}), do: "Not found"
  def handle(%{status: :error, code: 500}), do: "Server error"

  # Less specific - any error
  def handle(%{status: :error}), do: "Some error"

  # Even less specific - has status
  def handle(%{status: _}), do: "Has status"

  # Catch-all
  def handle(_), do: "Unknown"
end

IO.inspect(PatternOrder.handle(%{status: :error, code: 404}), label: "404")
IO.inspect(PatternOrder.handle(%{status: :error, code: 403}), label: "403")
IO.inspect(PatternOrder.handle(%{status: :ok}), label: "ok")
IO.inspect(PatternOrder.handle(%{other: :data}), label: "no status")

# -----------------------------------------------------------------------------
# Section 6: Combining Pattern Matching and Guards
# -----------------------------------------------------------------------------

IO.puts("\n--- Combining Pattern Matching and Guards ---")

defmodule Parser do
  # Parse integers with validation
  def parse({:integer, value}) when is_integer(value) and value >= 0 do
    {:ok, value}
  end

  def parse({:integer, value}) when is_integer(value) do
    {:error, "negative integers not allowed"}
  end

  # Parse strings with length check
  def parse({:string, value}) when is_binary(value) and byte_size(value) > 0 do
    {:ok, value}
  end

  def parse({:string, ""}) do
    {:error, "empty string not allowed"}
  end

  # Parse lists with minimum length
  def parse({:list, value}) when is_list(value) and length(value) >= 1 do
    {:ok, value}
  end

  def parse({:list, []}) do
    {:error, "empty list not allowed"}
  end

  # Catch-all for unknown types
  def parse({type, _value}) do
    {:error, "unknown type: #{type}"}
  end

  def parse(_) do
    {:error, "invalid format"}
  end
end

IO.inspect(Parser.parse({:integer, 42}), label: "parse positive int")
IO.inspect(Parser.parse({:integer, -5}), label: "parse negative int")
IO.inspect(Parser.parse({:string, "hello"}), label: "parse string")
IO.inspect(Parser.parse({:string, ""}), label: "parse empty string")
IO.inspect(Parser.parse({:list, [1, 2]}), label: "parse list")
IO.inspect(Parser.parse({:list, []}), label: "parse empty list")
IO.inspect(Parser.parse({:unknown, nil}), label: "parse unknown")

# Complex example: HTTP request handler
defmodule RequestHandler do
  def handle(%{method: :get, path: "/"}), do: "Home page"

  def handle(%{method: :get, path: "/users"}), do: "List users"

  def handle(%{method: :get, path: "/users/" <> id}) when byte_size(id) > 0 do
    "Get user #{id}"
  end

  def handle(%{method: :post, path: "/users", body: body}) when is_map(body) do
    "Create user with #{inspect(body)}"
  end

  def handle(%{method: :delete, path: "/users/" <> id}) when byte_size(id) > 0 do
    "Delete user #{id}"
  end

  def handle(%{method: method, path: path}) do
    "Unknown: #{method} #{path}"
  end
end

IO.inspect(RequestHandler.handle(%{method: :get, path: "/"}), label: "GET /")
IO.inspect(RequestHandler.handle(%{method: :get, path: "/users"}), label: "GET /users")
IO.inspect(RequestHandler.handle(%{method: :get, path: "/users/123"}), label: "GET /users/123")
IO.inspect(RequestHandler.handle(%{method: :post, path: "/users", body: %{name: "Alice"}}),
  label: "POST /users")
IO.inspect(RequestHandler.handle(%{method: :delete, path: "/users/456"}),
  label: "DELETE /users/456")
IO.inspect(RequestHandler.handle(%{method: :patch, path: "/unknown"}), label: "unknown")

# -----------------------------------------------------------------------------
# Section 7: The Catch-All Clause
# -----------------------------------------------------------------------------

IO.puts("\n--- The Catch-All Clause ---")

# Always consider having a catch-all clause to handle unexpected inputs
# This prevents crashes from unmatched function calls

defmodule SafeOperations do
  # With catch-all - always returns a result
  def safe_divide(_, 0), do: {:error, :division_by_zero}
  def safe_divide(a, b) when is_number(a) and is_number(b), do: {:ok, a / b}
  def safe_divide(_, _), do: {:error, :invalid_arguments}

  # Without catch-all - can crash
  # def unsafe_divide(a, b), do: a / b
end

IO.inspect(SafeOperations.safe_divide(10, 2), label: "10 / 2")
IO.inspect(SafeOperations.safe_divide(10, 0), label: "10 / 0")
IO.inspect(SafeOperations.safe_divide("10", 2), label: "\"10\" / 2")

# Using underscore variables for documentation
defmodule Documentation do
  # _name shows this is intentionally unused but documents the purpose
  def log_error({:error, reason}, _context) do
    IO.puts("Error: #{reason}")
  end

  def log_error({:ok, _result}, _context) do
    IO.puts("Success (no error to log)")
  end
end

Documentation.log_error({:error, "something went wrong"}, %{user: "alice"})
Documentation.log_error({:ok, 42}, %{user: "bob"})

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: FizzBuzz with Function Clauses
# Difficulty: Easy
#
# Create a module FizzBuzz with a function `of/1` that:
# - Returns "FizzBuzz" for numbers divisible by both 3 and 15
# - Returns "Fizz" for numbers divisible by 3
# - Returns "Buzz" for numbers divisible by 5
# - Returns the number as a string otherwise
#
# Use multiple function clauses with guards.
# Hint: rem(n, 3) == 0 checks divisibility by 3
#
# Your code here:

IO.puts("\nExercise 1: Implement FizzBuzz with function clauses")
# defmodule FizzBuzz do
#   def of(n) when rem(n, 15) == 0, do: ...
#   def of(n) when rem(n, 3) == 0, do: ...
#   def of(n) when rem(n, 5) == 0, do: ...
#   def of(n), do: ...
# end

# Exercise 2: Shape Area Calculator
# Difficulty: Easy
#
# Create a module Shape that calculates areas using pattern matching:
# - area({:circle, radius}) - returns pi * radius^2
# - area({:rectangle, width, height}) - returns width * height
# - area({:triangle, base, height}) - returns 0.5 * base * height
# - area({:square, side}) - returns side * side
#
# Add guards to ensure dimensions are positive.
#
# Your code here:

IO.puts("\nExercise 2: Create shape area calculator")
# defmodule Shape do
#   def area({:circle, r}) when r > 0, do: ...
#   def area({:rectangle, w, h}) when w > 0 and h > 0, do: ...
#   ...
# end

# Exercise 3: List Processing with Clauses
# Difficulty: Medium
#
# Create a module ListProcessor with these functions using multiple clauses:
# - sum([]) returns 0
# - sum([head | tail]) returns head + sum(tail)
#
# - length_of([]) returns 0
# - length_of([_ | tail]) returns 1 + length_of(tail)
#
# - last([x]) returns x (single element)
# - last([_ | tail]) returns last(tail)
# - last([]) returns nil
#
# Your code here:

IO.puts("\nExercise 3: Create list processing functions")
# defmodule ListProcessor do
#   def sum([]), do: ...
#   def sum([head | tail]), do: ...
#   ...
# end

# Exercise 4: Validate User Input
# Difficulty: Medium
#
# Create a module Validator that validates user input:
# validate_email(email) - must be a string containing "@"
# validate_age(age) - must be integer between 0 and 150
# validate_username(name) - must be string, 3-20 chars, only alphanumeric
#
# Each function should return {:ok, value} or {:error, reason}
# Use guards and String functions (String.contains?, String.length, etc.)
#
# Your code here:

IO.puts("\nExercise 4: Create input validators")
# defmodule Validator do
#   def validate_email(email) when is_binary(email) do
#     if String.contains?(email, "@") do
#       {:ok, email}
#     else
#       {:error, "email must contain @"}
#     end
#   end
#   def validate_email(_), do: {:error, "email must be a string"}
#   ...
# end

# Exercise 5: Command Parser
# Difficulty: Hard
#
# Create a module CommandParser that parses command tuples:
#
# {:move, direction} where direction is :up, :down, :left, :right
#   Returns "Moving {direction}"
#
# {:move, direction, steps} where steps is a positive integer
#   Returns "Moving {direction} {steps} steps"
#
# {:attack, target} where target is a non-empty string
#   Returns "Attacking {target}"
#
# {:heal, amount} where amount is between 1 and 100
#   Returns "Healing for {amount} HP"
#
# {:use_item, item_name, count} where count is positive
#   Returns "Using {count}x {item_name}"
#
# Any other command returns {:error, "Unknown command"}
#
# Your code here:

IO.puts("\nExercise 5: Create command parser")
# defmodule CommandParser do
#   def parse({:move, dir}) when dir in [:up, :down, :left, :right] do
#     ...
#   end
#   ...
# end

# Exercise 6: Recursive Tree Operations
# Difficulty: Hard
#
# Trees can be represented as: {:node, value, left, right} or :empty
#
# Create a module BinaryTree with:
# - sum(tree) - returns sum of all values in tree
# - count(tree) - returns number of nodes
# - height(tree) - returns height of tree (empty = 0, single node = 1)
# - member?(tree, value) - returns true if value is in tree
#
# Example tree:
# tree = {:node, 5,
#          {:node, 3, :empty, :empty},
#          {:node, 8, {:node, 7, :empty, :empty}, :empty}}
#
# Your code here:

IO.puts("\nExercise 6: Create binary tree operations")
# defmodule BinaryTree do
#   def sum(:empty), do: 0
#   def sum({:node, value, left, right}), do: value + sum(left) + sum(right)
#   ...
# end

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

1. Multiple Function Clauses:
   - Define the same function multiple times with different patterns
   - Clauses are matched top to bottom
   - First match wins

2. Pattern Matching in Clauses:
   - Match on literals: def f(0), def f(:ok)
   - Destructure data: def f([h|t]), def f({:ok, v})
   - Match maps: def f(%{key: value})

3. Guards:
   - Add conditions with `when`: def f(n) when n > 0
   - Use type checks: is_integer/1, is_binary/1, etc.
   - Combine with `and`, `or`: when n > 0 and n < 100
   - Use `in` for membership: when x in [:a, :b, :c]

4. Clause Ordering:
   - More specific clauses first
   - General catch-all clauses last
   - Compiler warns about unreachable clauses

5. Guard Expressions (allowed):
   - Type checks: is_*/1 functions
   - Comparisons: ==, <, >, etc.
   - Math: +, -, *, /, div, rem
   - List/tuple: length, elem, tuple_size
   - Membership: in

6. Best Practices:
   - Use pattern matching for structure
   - Use guards for value constraints
   - Always have a catch-all for safety
   - Order from specific to general

Pattern matching + guards = powerful, readable code!

Next: 17_recursion.exs - Recursive thinking and tail recursion
""")
