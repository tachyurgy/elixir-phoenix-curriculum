# ============================================================================
# Lesson 10: Case Statements
# ============================================================================
#
# Case is Elixir's primary control flow construct for pattern matching
# against multiple possible values. It combines the power of pattern
# matching with guards for elegant conditional logic.
#
# Learning Objectives:
# - Use case for multi-way branching
# - Combine patterns with guards
# - Handle default cases properly
# - Choose between case and function clauses
#
# Prerequisites:
# - Lesson 09 (Pattern Matching) completed
#
# ============================================================================

IO.puts("=" |> String.duplicate(60))
IO.puts("Lesson 10: Case Statements")
IO.puts("=" |> String.duplicate(60))

# -----------------------------------------------------------------------------
# Section 1: Basic Case Syntax
# -----------------------------------------------------------------------------

IO.puts("\n--- Basic Case Syntax ---")

# Case matches a value against multiple patterns
value = 2

result = case value do
  1 -> "one"
  2 -> "two"
  3 -> "three"
end

IO.inspect(result, label: "case 2")

# Each arrow clause is a pattern -> expression
# First matching pattern wins

day = :tuesday

message = case day do
  :monday -> "Start of the work week"
  :tuesday -> "Second day"
  :wednesday -> "Midweek"
  :thursday -> "Almost Friday"
  :friday -> "TGIF!"
  :saturday -> "Weekend!"
  :sunday -> "Weekend!"
end

IO.puts(message)

# -----------------------------------------------------------------------------
# Section 2: The Default Case
# -----------------------------------------------------------------------------

IO.puts("\n--- The Default Case ---")

# Always include a catch-all pattern to avoid MatchError!

value = 10

result = case value do
  1 -> "one"
  2 -> "two"
  3 -> "three"
  _ -> "something else"  # Catch-all
end

IO.inspect(result, label: "case 10 with default")

# Without default, unmatched values raise CaseClauseError
# case 10 do
#   1 -> "one"
# end
# ** (CaseClauseError) no case clause matching: 10

# Using a named variable captures the value
result = case 42 do
  0 -> "zero"
  n -> "got #{n}"  # Captures the value
end

IO.inspect(result, label: "Captured value")

# _ is preferred when you don't need the value
result = case "hello" do
  "world" -> "matched world"
  _ -> "didn't match"  # Don't care about the value
end

IO.inspect(result, label: "Using underscore")

# -----------------------------------------------------------------------------
# Section 3: Pattern Matching in Case
# -----------------------------------------------------------------------------

IO.puts("\n--- Pattern Matching in Case ---")

# Match tuples
response = {:ok, "Success!"}

result = case response do
  {:ok, message} -> "Success: #{message}"
  {:error, reason} -> "Error: #{reason}"
  _ -> "Unknown response"
end

IO.puts(result)

# Match lists
list = [1, 2, 3, 4, 5]

result = case list do
  [] -> "Empty list"
  [single] -> "Single element: #{single}"
  [first, second] -> "Two elements: #{first}, #{second}"
  [head | _tail] -> "List starting with #{head}"
end

IO.puts(result)

# Match maps
user = %{name: "Alice", role: :admin, active: true}

result = case user do
  %{role: :admin, active: true} -> "Active admin"
  %{role: :admin, active: false} -> "Inactive admin"
  %{role: :user} -> "Regular user"
  _ -> "Unknown role"
end

IO.puts(result)

# Match with literal values AND extraction
point = {3, 4}

result = case point do
  {0, 0} -> "Origin"
  {x, 0} -> "On X-axis at #{x}"
  {0, y} -> "On Y-axis at #{y}"
  {x, y} -> "Point at (#{x}, #{y})"
end

IO.puts(result)

# -----------------------------------------------------------------------------
# Section 4: Guards in Case
# -----------------------------------------------------------------------------

IO.puts("\n--- Guards in Case ---")

# Guards add conditions to patterns with 'when'

age = 25

result = case age do
  n when n < 0 -> "Invalid age"
  n when n < 13 -> "Child"
  n when n < 20 -> "Teenager"
  n when n < 65 -> "Adult"
  _ -> "Senior"
end

IO.puts("Age #{age}: #{result}")

# Multiple conditions with 'and'
number = -5

result = case number do
  n when is_integer(n) and n > 0 -> "Positive integer"
  n when is_integer(n) and n < 0 -> "Negative integer"
  n when is_integer(n) -> "Zero"
  n when is_float(n) -> "Float: #{n}"
  _ -> "Not a number"
end

IO.puts(result)

# Guards with complex patterns
data = {:user, "Alice", 30}

result = case data do
  {:user, name, age} when age >= 18 ->
    "Adult user: #{name}"

  {:user, name, age} when age < 18 ->
    "Minor user: #{name} (#{age} years old)"

  {:admin, name, _} ->
    "Admin: #{name}"

  _ ->
    "Unknown data type"
end

IO.puts(result)

# Multiple guard clauses (OR logic)
value = "hello"

result = case value do
  x when is_binary(x) or is_atom(x) -> "String or atom"
  x when is_number(x) -> "Number"
  _ -> "Other"
end

IO.puts(result)

# -----------------------------------------------------------------------------
# Section 5: Guard Functions
# -----------------------------------------------------------------------------

IO.puts("\n--- Guard Functions ---")

# Only certain functions are allowed in guards
# These are called "guard-safe" functions

IO.puts("""
Guard-safe functions include:
  Type checks: is_atom/1, is_binary/1, is_integer/1, is_float/1,
               is_list/1, is_map/1, is_tuple/1, is_nil/1, etc.
  Comparisons: ==, !=, <, >, <=, >=, ===, !==
  Boolean:     and, or, not
  Math:        +, -, *, /, abs/1, rem/2, div/2
  Size:        length/1, map_size/1, tuple_size/1, byte_size/1
  Element:     elem/2, hd/1, tl/1
  Membership:  in
""")

# Examples of guard-safe functions
list = [1, 2, 3, 4, 5]

result = case list do
  l when length(l) == 0 -> "Empty"
  l when length(l) < 3 -> "Short"
  l when length(l) < 10 -> "Medium"
  _ -> "Long"
end

IO.puts("List is: #{result}")

tuple = {:a, :b, :c}

result = case tuple do
  t when tuple_size(t) == 2 -> "Pair"
  t when tuple_size(t) == 3 -> "Triple"
  t when tuple_size(t) > 3 -> "Large tuple"
  _ -> "Other"
end

IO.puts("Tuple is: #{result}")

# Using 'in' guard
day = :saturday

result = case day do
  d when d in [:saturday, :sunday] -> "Weekend!"
  d when d in [:monday, :tuesday, :wednesday, :thursday, :friday] -> "Weekday"
  _ -> "Invalid day"
end

IO.puts(result)

# -----------------------------------------------------------------------------
# Section 6: Nested Case Expressions
# -----------------------------------------------------------------------------

IO.puts("\n--- Nested Case Expressions ---")

# Case expressions can be nested (but prefer other patterns when possible)

response = {:ok, {:user, "Alice", :admin}}

result = case response do
  {:ok, data} ->
    case data do
      {:user, name, :admin} -> "Admin: #{name}"
      {:user, name, _role} -> "User: #{name}"
      _ -> "Unknown data"
    end

  {:error, reason} ->
    "Error: #{reason}"
end

IO.puts(result)

# Better: flatten with more specific patterns
result = case response do
  {:ok, {:user, name, :admin}} -> "Admin: #{name}"
  {:ok, {:user, name, _role}} -> "User: #{name}"
  {:ok, _} -> "Unknown data"
  {:error, reason} -> "Error: #{reason}"
end

IO.puts("Flattened: #{result}")

# -----------------------------------------------------------------------------
# Section 7: Case vs Function Clauses
# -----------------------------------------------------------------------------

IO.puts("\n--- Case vs Function Clauses ---")

# Case: use for branching within a function
defmodule CaseExample do
  def process(value) do
    case value do
      {:ok, result} -> "Success: #{result}"
      {:error, reason} -> "Error: #{reason}"
      _ -> "Unknown"
    end
  end
end

# Function clauses: use when behavior differs significantly
defmodule ClausesExample do
  def process({:ok, result}) do
    # Could have more complex logic here
    "Success: #{result}"
  end

  def process({:error, reason}) do
    # Separate implementation
    "Error: #{reason}"
  end

  def process(_) do
    "Unknown"
  end
end

IO.puts(CaseExample.process({:ok, 42}))
IO.puts(ClausesExample.process({:ok, 42}))

# Guidelines:
# - Case: single function, branching on return values
# - Function clauses: polymorphic behavior, separate implementations
# - Function clauses: better for documentation and testing

# -----------------------------------------------------------------------------
# Section 8: Case with Structs
# -----------------------------------------------------------------------------

IO.puts("\n--- Case with Structs ---")

defmodule Shape do
  defmodule Circle do
    defstruct [:radius]
  end

  defmodule Rectangle do
    defstruct [:width, :height]
  end

  defmodule Triangle do
    defstruct [:base, :height]
  end
end

defmodule Geometry do
  alias Shape.{Circle, Rectangle, Triangle}

  def area(shape) do
    case shape do
      %Circle{radius: r} ->
        :math.pi() * r * r

      %Rectangle{width: w, height: h} ->
        w * h

      %Triangle{base: b, height: h} ->
        0.5 * b * h

      _ ->
        {:error, :unknown_shape}
    end
  end

  def describe(shape) do
    case shape do
      %Circle{radius: r} when r > 10 -> "Large circle"
      %Circle{} -> "Small circle"
      %Rectangle{width: w, height: h} when w == h -> "Square"
      %Rectangle{} -> "Rectangle"
      %Triangle{} -> "Triangle"
      _ -> "Unknown shape"
    end
  end
end

circle = %Shape.Circle{radius: 5}
rectangle = %Shape.Rectangle{width: 4, height: 6}
square = %Shape.Rectangle{width: 5, height: 5}
triangle = %Shape.Triangle{base: 3, height: 4}

IO.inspect(Geometry.area(circle), label: "Circle area")
IO.inspect(Geometry.area(rectangle), label: "Rectangle area")
IO.inspect(Geometry.area(triangle), label: "Triangle area")

IO.puts(Geometry.describe(circle))
IO.puts(Geometry.describe(square))
IO.puts(Geometry.describe(rectangle))

# -----------------------------------------------------------------------------
# Section 9: Common Case Patterns
# -----------------------------------------------------------------------------

IO.puts("\n--- Common Case Patterns ---")

# Pattern 1: Result handling
defmodule ResultHandler do
  def handle(result) do
    case result do
      :ok -> "Operation succeeded"
      {:ok, value} -> "Got: #{inspect(value)}"
      {:ok, value, metadata} -> "Got #{inspect(value)} with #{inspect(metadata)}"
      :error -> "Operation failed"
      {:error, reason} -> "Failed: #{inspect(reason)}"
    end
  end
end

IO.puts(ResultHandler.handle(:ok))
IO.puts(ResultHandler.handle({:ok, 42}))
IO.puts(ResultHandler.handle({:error, :timeout}))

# Pattern 2: Command dispatch
defmodule CommandProcessor do
  def execute(command) do
    case command do
      {:add, a, b} -> {:ok, a + b}
      {:subtract, a, b} -> {:ok, a - b}
      {:multiply, a, b} -> {:ok, a * b}
      {:divide, _, 0} -> {:error, :division_by_zero}
      {:divide, a, b} -> {:ok, a / b}
      _ -> {:error, :unknown_command}
    end
  end
end

IO.inspect(CommandProcessor.execute({:add, 5, 3}))
IO.inspect(CommandProcessor.execute({:divide, 10, 2}))
IO.inspect(CommandProcessor.execute({:divide, 10, 0}))
IO.inspect(CommandProcessor.execute({:unknown, 1, 2}))

# Pattern 3: State machine transitions
defmodule OrderState do
  def transition(current_state, event) do
    case {current_state, event} do
      {:pending, :confirm} -> {:ok, :confirmed}
      {:confirmed, :ship} -> {:ok, :shipped}
      {:shipped, :deliver} -> {:ok, :delivered}
      {:delivered, :return} -> {:ok, :returned}
      {:pending, :cancel} -> {:ok, :cancelled}
      {:confirmed, :cancel} -> {:ok, :cancelled}
      {state, _event} -> {:error, "Invalid transition from #{state}"}
    end
  end
end

IO.inspect(OrderState.transition(:pending, :confirm))
IO.inspect(OrderState.transition(:confirmed, :ship))
IO.inspect(OrderState.transition(:shipped, :cancel))

# Pattern 4: Validation
defmodule Validator do
  def validate_user(user) do
    case user do
      %{name: name} when byte_size(name) < 2 ->
        {:error, "Name too short"}

      %{name: name} when byte_size(name) > 50 ->
        {:error, "Name too long"}

      %{age: age} when not is_integer(age) ->
        {:error, "Age must be an integer"}

      %{age: age} when age < 0 or age > 150 ->
        {:error, "Invalid age"}

      %{name: _, age: _} = user ->
        {:ok, user}

      _ ->
        {:error, "Missing required fields"}
    end
  end
end

IO.inspect(Validator.validate_user(%{name: "Alice", age: 30}))
IO.inspect(Validator.validate_user(%{name: "A", age: 30}))
IO.inspect(Validator.validate_user(%{name: "Bob", age: -5}))
IO.inspect(Validator.validate_user(%{name: "Charlie"}))

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: Basic Case
# Difficulty: Easy
#
# Write a function grade/1 that takes a numeric score (0-100)
# and returns a letter grade:
# - 90-100: "A"
# - 80-89: "B"
# - 70-79: "C"
# - 60-69: "D"
# - Below 60: "F"
# - Invalid scores: "Invalid"
#
# Use case with guards.
#
# Your code here:

IO.puts("\nExercise 1: Letter grades")

# Exercise 2: Response Handler
# Difficulty: Easy
#
# Create a function that handles HTTP-like responses:
# - {:ok, 200, body} -> "Success: {body}"
# - {:ok, 201, _} -> "Created"
# - {:ok, 204, _} -> "No Content"
# - {:redirect, code, url} when code in [301, 302] -> "Redirect to {url}"
# - {:error, 404, _} -> "Not Found"
# - {:error, 500, _} -> "Server Error"
# - {:error, code, _} -> "Error: {code}"
#
# Your code here:

IO.puts("\nExercise 2: HTTP response handler")

# Exercise 3: List Processor
# Difficulty: Medium
#
# Create a function that processes lists differently based on content:
# - Empty list -> "Empty"
# - All positive numbers -> "All positive, sum: {sum}"
# - All negative numbers -> "All negative, sum: {sum}"
# - Mixed -> "Mixed, count: {count}"
# - Contains non-numbers -> "Invalid list"
#
# Hint: You might need helper functions
#
# Your code here:

IO.puts("\nExercise 3: List content processor")

# Exercise 4: Config Parser
# Difficulty: Medium
#
# Create a function that parses configuration maps:
# - %{mode: :production, debug: false} -> production settings
# - %{mode: :development, debug: true} -> dev settings with debug
# - %{mode: :test} -> test settings
# - Missing mode -> error
#
# Return appropriate configuration structs or maps.
#
# Your code here:

IO.puts("\nExercise 4: Configuration parser")

# Exercise 5: Expression Evaluator
# Difficulty: Hard
#
# Create a simple expression evaluator that handles:
# - {:num, n} -> n
# - {:add, left, right} -> evaluate(left) + evaluate(right)
# - {:sub, left, right} -> evaluate(left) - evaluate(right)
# - {:mul, left, right} -> evaluate(left) * evaluate(right)
# - {:div, left, right} -> handle division (with zero check)
# - {:neg, expr} -> -evaluate(expr)
#
# Example: {:add, {:num, 5}, {:mul, {:num, 2}, {:num, 3}}} = 11
#
# Your code here:

IO.puts("\nExercise 5: Expression evaluator")

# Exercise 6: Packet Router
# Difficulty: Hard
#
# Create a packet routing function that handles network packets:
# - %{type: :tcp, dest: port} when port < 1024 -> "Privileged TCP to {port}"
# - %{type: :tcp, dest: port} -> "TCP to {port}"
# - %{type: :udp, dest: port, size: s} when s > 65535 -> "UDP too large"
# - %{type: :udp, dest: port} -> "UDP to {port}"
# - %{type: :icmp, code: code} -> "ICMP type {code}"
# - Invalid packets -> "Unknown packet"
#
# Your code here:

IO.puts("\nExercise 6: Network packet router")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

1. Case syntax:
   case value do
     pattern1 -> expression1
     pattern2 -> expression2
     _ -> default
   end

2. Pattern matching in case:
   - Tuples, lists, maps, structs
   - Literal values and variables
   - First match wins

3. Guards enhance patterns:
   - when condition
   - Type checks, comparisons, math
   - Guard-safe functions only

4. Always include defaults:
   - _ catches unmatched values
   - Prevents CaseClauseError
   - Named var captures value

5. Case vs function clauses:
   - Case: branching within a function
   - Clauses: polymorphic behavior
   - Clauses: better for complex logic

6. Common patterns:
   - Result/error handling
   - Command dispatch
   - State machines
   - Validation

7. Best practices:
   - Most specific patterns first
   - Use guards for conditions
   - Flatten nested cases when possible

Next: 11_cond.exs - Multiple conditions without pattern matching
""")
