# ============================================================================
# Lesson 12: If and Unless
# ============================================================================
#
# If and unless are Elixir's simplest conditional constructs. They're best
# for simple true/false decisions. For more complex conditionals, prefer
# case or cond.
#
# Learning Objectives:
# - Use if and unless effectively
# - Understand truthy and falsy values
# - Use inline and block forms
# - Know when to use if vs case vs cond
#
# Prerequisites:
# - Lesson 11 (Cond) completed
#
# ============================================================================

IO.puts("=" |> String.duplicate(60))
IO.puts("Lesson 12: If and Unless")
IO.puts("=" |> String.duplicate(60))

# -----------------------------------------------------------------------------
# Section 1: Basic If Syntax
# -----------------------------------------------------------------------------

IO.puts("\n--- Basic If Syntax ---")

# Block form
age = 20

if age >= 18 do
  IO.puts("You are an adult")
end

# With else
is_raining = false

if is_raining do
  IO.puts("Bring an umbrella")
else
  IO.puts("Enjoy the sunshine")
end

# If returns a value (it's an expression!)
status = if age >= 21, do: "Can drink", else: "Cannot drink"
IO.inspect(status, label: "Status")

# Inline form (for short expressions)
message = if true, do: "yes", else: "no"
IO.inspect(message, label: "Inline if")

# If without else returns nil when condition is false
result = if false do
  "This won't be returned"
end
IO.inspect(result, label: "If without else (false)")

# -----------------------------------------------------------------------------
# Section 2: Unless - The Opposite of If
# -----------------------------------------------------------------------------

IO.puts("\n--- Unless ---")

# Unless executes when condition is FALSY
logged_in = false

unless logged_in do
  IO.puts("Please log in to continue")
end

# Unless with else (less common, consider using if instead)
active = true

unless active do
  IO.puts("Account is inactive")
else
  IO.puts("Account is active")
end

# Inline unless
warning = unless active, do: "Inactive!", else: "All good"
IO.inspect(warning, label: "Unless result")

# Unless is best for "guard clauses" - early returns
# Prefer if/else for complex logic

# -----------------------------------------------------------------------------
# Section 3: Truthy and Falsy Values
# -----------------------------------------------------------------------------

IO.puts("\n--- Truthy and Falsy Values ---")

# In Elixir, only two values are "falsy":
# - nil
# - false

# EVERYTHING else is truthy!

IO.puts("Falsy values:")
IO.inspect(if(nil, do: "truthy", else: "falsy"), label: "nil")
IO.inspect(if(false, do: "truthy", else: "falsy"), label: "false")

IO.puts("\nTruthy values (everything else!):")
IO.inspect(if(true, do: "truthy", else: "falsy"), label: "true")
IO.inspect(if(0, do: "truthy", else: "falsy"), label: "0 (zero)")
IO.inspect(if("", do: "truthy", else: "falsy"), label: "\"\" (empty string)")
IO.inspect(if([], do: "truthy", else: "falsy"), label: "[] (empty list)")
IO.inspect(if(%{}, do: "truthy", else: "falsy"), label: "%{} (empty map)")
IO.inspect(if(:false, do: "truthy", else: "falsy"), label: ":false (atom)")

# Common gotcha: empty collections ARE truthy!
list = []
if list do
  IO.puts("Empty list is truthy!")
end

# To check for empty, use functions:
if list == [] do
  IO.puts("List is empty (explicit check)")
end

if Enum.empty?(list) do
  IO.puts("List is empty (using Enum.empty?)")
end

# -----------------------------------------------------------------------------
# Section 4: If Returns Values
# -----------------------------------------------------------------------------

IO.puts("\n--- If Returns Values ---")

# If is an expression - it always returns a value
score = 85

# Capture the result
grade = if score >= 60 do
  "Pass"
else
  "Fail"
end
IO.inspect(grade, label: "Grade")

# Use in function calls
IO.puts(if(score >= 90, do: "Excellent!", else: "Good job!"))

# Use in data structures
user = %{
  name: "Alice",
  status: if(true, do: :active, else: :inactive),
  role: if(false, do: :admin, else: :user)
}
IO.inspect(user, label: "User map")

# Multiple lines in blocks
config = if Mix.env() == :prod do
  %{
    debug: false,
    log_level: :warn,
    cache: true
  }
else
  %{
    debug: true,
    log_level: :debug,
    cache: false
  }
end
IO.inspect(config, label: "Config")

# -----------------------------------------------------------------------------
# Section 5: Inline vs Block Forms
# -----------------------------------------------------------------------------

IO.puts("\n--- Inline vs Block Forms ---")

x = 5

# Inline form - use for short, simple expressions
result = if x > 0, do: "positive", else: "non-positive"
IO.inspect(result, label: "Inline")

# Block form - use for longer expressions or multiple statements
result = if x > 0 do
  # Can have multiple expressions
  value = x * 2
  "positive: #{value}"
else
  "non-positive"
end
IO.inspect(result, label: "Block")

# The inline form is actually keyword list syntax!
# These are equivalent:
result1 = if x > 0, do: "yes", else: "no"
result2 = if x > 0, [do: "yes", else: "no"]
result3 = if(x > 0, [{:do, "yes"}, {:else, "no"}])

IO.inspect(result1 == result2 and result2 == result3, label: "All equivalent")

# Guidelines:
# - Inline: single expression, short
# - Block: multiple lines, complex logic

# -----------------------------------------------------------------------------
# Section 6: Nested If Statements
# -----------------------------------------------------------------------------

IO.puts("\n--- Nested If Statements ---")

# Nested ifs work but can become hard to read
age = 25
has_license = true

message = if age >= 18 do
  if has_license do
    "Can drive"
  else
    "Adult but no license"
  end
else
  "Too young to drive"
end

IO.puts(message)

# Better: use cond for multiple conditions
message = cond do
  age < 18 -> "Too young to drive"
  not has_license -> "Adult but no license"
  true -> "Can drive"
end

IO.puts("Using cond: #{message}")

# Or use case with patterns when appropriate
# Or combine conditions with 'and'
message = if age >= 18 and has_license do
  "Can drive"
else
  "Cannot drive"
end

IO.puts("Using combined condition: #{message}")

# -----------------------------------------------------------------------------
# Section 7: If in Functions
# -----------------------------------------------------------------------------

IO.puts("\n--- If in Functions ---")

defmodule Greeter do
  # Simple conditional in function
  def greet(name, formal \\ false) do
    if formal do
      "Good day, #{name}."
    else
      "Hey, #{name}!"
    end
  end

  # Guard clauses are often better than if
  def process(value) when is_nil(value), do: {:error, :nil_value}
  def process(value) when value < 0, do: {:error, :negative}
  def process(value), do: {:ok, value * 2}

  # Using unless for early return
  def validate(data) do
    unless is_map(data) do
      {:error, :not_a_map}
    else
      if Map.has_key?(data, :required_field) do
        {:ok, data}
      else
        {:error, :missing_required_field}
      end
    end
  end
end

IO.puts(Greeter.greet("Alice"))
IO.puts(Greeter.greet("Bob", true))

IO.inspect(Greeter.process(nil))
IO.inspect(Greeter.process(-5))
IO.inspect(Greeter.process(10))

IO.inspect(Greeter.validate("not a map"))
IO.inspect(Greeter.validate(%{}))
IO.inspect(Greeter.validate(%{required_field: "value"}))

# -----------------------------------------------------------------------------
# Section 8: Boolean Operators with If
# -----------------------------------------------------------------------------

IO.puts("\n--- Boolean Operators with If ---")

# Elixir has two sets of boolean operators:

# Strict: and, or, not (require boolean arguments)
# Relaxed: &&, ||, ! (work with any truthy/falsy value)

a = true
b = false

IO.puts("Strict operators (require booleans):")
IO.inspect(a and b, label: "true and false")
IO.inspect(a or b, label: "true or false")
IO.inspect(not a, label: "not true")

IO.puts("\nRelaxed operators (any truthy/falsy):")
IO.inspect("hello" && "world", label: "\"hello\" && \"world\"")
IO.inspect(nil || "default", label: "nil || \"default\"")
IO.inspect(!nil, label: "!nil")

# Common pattern: default values with ||
name = nil
display_name = name || "Anonymous"
IO.inspect(display_name, label: "Default name")

# Common pattern: short-circuit with &&
user = %{name: "Alice", admin: true}
admin_greeting = user.admin && "Hello, admin #{user.name}!"
IO.inspect(admin_greeting, label: "Admin greeting")

# Using with if
value = nil
result = if value, do: value, else: "default"
# Same as:
result2 = value || "default"
IO.inspect(result == result2, label: "Equivalent")

# -----------------------------------------------------------------------------
# Section 9: When to Use If vs Other Constructs
# -----------------------------------------------------------------------------

IO.puts("\n--- When to Use If vs Others ---")

IO.puts("""
Use IF when:
  - Simple true/false condition
  - Two branches maximum (if/else)
  - No pattern matching needed
  - Condition is a boolean or simple comparison

Use UNLESS when:
  - Checking for absence/falsy values
  - Guard clauses (early returns)
  - Avoid: unless with else (use if instead)

Use CASE when:
  - Matching against patterns
  - Multiple possible values to match
  - Need to destructure data
  - Matching struct types

Use COND when:
  - Multiple boolean conditions
  - Range comparisons
  - Complex logical expressions
  - No specific value to match
""")

# Examples of each:

# If: simple boolean
is_admin = true
if is_admin, do: IO.puts("Admin access granted")

# Unless: guard clause style
value = nil
unless value, do: IO.puts("No value provided")

# Case: pattern matching
response = {:ok, 42}
case response do
  {:ok, value} -> IO.puts("Got: #{value}")
  {:error, _} -> IO.puts("Error!")
end

# Cond: multiple ranges
score = 75
IO.puts(cond do
  score >= 90 -> "A"
  score >= 80 -> "B"
  score >= 70 -> "C"
  true -> "Below C"
end)

# -----------------------------------------------------------------------------
# Section 10: Common Patterns
# -----------------------------------------------------------------------------

IO.puts("\n--- Common Patterns ---")

# Pattern 1: Default values
defmodule Defaults do
  def greet(opts \\ []) do
    name = opts[:name] || "Guest"
    formal = if opts[:formal], do: true, else: false

    if formal do
      "Good evening, #{name}."
    else
      "Hi #{name}!"
    end
  end
end

IO.puts(Defaults.greet())
IO.puts(Defaults.greet(name: "Alice"))
IO.puts(Defaults.greet(name: "Dr. Smith", formal: true))

# Pattern 2: Conditional transformation
defmodule Transformer do
  def maybe_upcase(string, upcase?) do
    if upcase? do
      String.upcase(string)
    else
      string
    end
  end

  # More idiomatic with pattern matching
  def maybe_reverse(string, true), do: String.reverse(string)
  def maybe_reverse(string, false), do: string
end

IO.puts(Transformer.maybe_upcase("hello", true))
IO.puts(Transformer.maybe_upcase("hello", false))
IO.puts(Transformer.maybe_reverse("hello", true))
IO.puts(Transformer.maybe_reverse("hello", false))

# Pattern 3: Feature flags
defmodule Features do
  def with_feature(enabled?, action) do
    if enabled? do
      action.()
    else
      {:disabled, :feature_off}
    end
  end
end

result = Features.with_feature(true, fn -> {:ok, "Feature executed"} end)
IO.inspect(result, label: "Feature enabled")

result = Features.with_feature(false, fn -> {:ok, "Feature executed"} end)
IO.inspect(result, label: "Feature disabled")

# Pattern 4: Validation helpers
defmodule Validation do
  def validate_length(string, min, max) do
    len = String.length(string)

    if len < min do
      {:error, "Too short (min: #{min})"}
    else
      if len > max do
        {:error, "Too long (max: #{max})"}
      else
        {:ok, string}
      end
    end
  end

  # Better with cond:
  def validate_length_v2(string, min, max) do
    len = String.length(string)

    cond do
      len < min -> {:error, "Too short (min: #{min})"}
      len > max -> {:error, "Too long (max: #{max})"}
      true -> {:ok, string}
    end
  end
end

IO.inspect(Validation.validate_length("hi", 3, 10))
IO.inspect(Validation.validate_length("hello", 3, 10))
IO.inspect(Validation.validate_length("hello world!", 3, 10))

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: Simple Conditions
# Difficulty: Easy
#
# Write a function is_even?/1 that returns true if a number is even.
# Write a function is_positive?/1 that returns true if a number is > 0.
# Write a function sign/1 that returns :positive, :negative, or :zero.
#
# Your code here:

IO.puts("\nExercise 1: Number checks")

# Exercise 2: String Validation
# Difficulty: Easy
#
# Write a function blank?/1 that returns true if:
# - The value is nil
# - The value is an empty string ""
# - The value is a string with only whitespace
#
# Use String.trim/1 to check for whitespace-only strings.
#
# Your code here:

IO.puts("\nExercise 2: Blank string checker")

# Exercise 3: Default Values
# Difficulty: Easy
#
# Write a function with_defaults/1 that takes a map and ensures it has:
# - :name (default: "Unknown")
# - :age (default: 0)
# - :active (default: true)
#
# Return the map with all keys present.
#
# Your code here:

IO.puts("\nExercise 3: Map with defaults")

# Exercise 4: Access Control
# Difficulty: Medium
#
# Write a function can_access?/2 that takes a user map and a resource.
# Users have :role (:admin, :moderator, :user, :guest)
# Resources have :level (:public, :members, :moderators, :admin)
#
# Access rules:
# - :admin can access everything
# - :moderator can access :public, :members, :moderators
# - :user can access :public, :members
# - :guest can access :public only
#
# Your code here:

IO.puts("\nExercise 4: Access control")

# Exercise 5: Fizz Buzz with If
# Difficulty: Medium
#
# Implement FizzBuzz using only if/else (no case or cond):
# - Divisible by 15: "FizzBuzz"
# - Divisible by 3: "Fizz"
# - Divisible by 5: "Buzz"
# - Otherwise: the number as string
#
# Your code here:

IO.puts("\nExercise 5: FizzBuzz with if")

# Exercise 6: Retry Logic
# Difficulty: Hard
#
# Write a function retry/3 that takes:
# - A function to execute
# - Maximum retries
# - A condition function that checks if result should retry
#
# The function should:
# - Execute the function
# - If condition returns true, retry (up to max times)
# - Return {:ok, result} or {:error, :max_retries}
#
# Example:
# retry(fn -> :rand.uniform(10) end, 5, fn x -> x < 5 end)
# Keep trying until we get >= 5 or run out of retries
#
# Your code here:

IO.puts("\nExercise 6: Retry logic")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

1. If syntax:
   if condition do
     true_branch
   else
     false_branch
   end

   Inline: if condition, do: true_value, else: false_value

2. Unless is opposite of if:
   unless condition do
     # Runs when condition is falsy
   end

3. Truthy and falsy:
   - Only nil and false are falsy
   - Everything else is truthy
   - Empty collections ARE truthy!

4. If returns a value:
   - Can be assigned to variables
   - Can be used in expressions
   - Returns nil if no else and condition is false

5. Boolean operators:
   - Strict: and, or, not (require booleans)
   - Relaxed: &&, ||, ! (any truthy/falsy)
   - Use || for defaults: value || "default"

6. When to use if:
   - Simple true/false decisions
   - Two branches maximum
   - No pattern matching needed

7. Consider alternatives:
   - case for pattern matching
   - cond for multiple conditions
   - Function clauses for polymorphism

Next: 13_with.exs - Happy path chaining with 'with'
""")
