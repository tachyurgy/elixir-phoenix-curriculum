# ============================================================================
# Lesson 15: Named Functions
# ============================================================================
#
# Named functions are defined inside modules using def and defp.
# They are the building blocks of Elixir applications, providing
# organization, documentation, and reusability.
#
# Learning Objectives:
# - Define public functions with def
# - Define private functions with defp
# - Use default argument values
# - Understand function arity
# - Use the do: shorthand syntax
# - Document functions with @doc
#
# Prerequisites:
# - Anonymous functions (Lesson 14)
# - Basic types and pattern matching
#
# ============================================================================

IO.puts("=" |> String.duplicate(60))
IO.puts("Lesson 15: Named Functions")
IO.puts("=" |> String.duplicate(60))

# -----------------------------------------------------------------------------
# Section 1: Defining Functions with def
# -----------------------------------------------------------------------------

IO.puts("\n--- Defining Functions with def ---")

# Named functions must be defined inside a module
defmodule Greeter do
  # A simple function that returns a greeting
  def hello do
    "Hello, World!"
  end

  # A function with one argument
  def hello(name) do
    "Hello, #{name}!"
  end

  # A function with multiple arguments
  def greet(greeting, name) do
    "#{greeting}, #{name}!"
  end
end

# Calling named functions (no dot required!)
IO.inspect(Greeter.hello(), label: "Greeter.hello()")
IO.inspect(Greeter.hello("Alice"), label: "Greeter.hello(\"Alice\")")
IO.inspect(Greeter.greet("Good morning", "Bob"), label: "Greeter.greet")

# Notice: Greeter.hello/0 and Greeter.hello/1 are DIFFERENT functions
# They have different arities (number of arguments)

# -----------------------------------------------------------------------------
# Section 2: The do: Shorthand Syntax
# -----------------------------------------------------------------------------

IO.puts("\n--- do: Shorthand Syntax ---")

# For single-expression functions, use the do: shorthand
defmodule MathShort do
  # Long form
  def add_long(a, b) do
    a + b
  end

  # Short form (preferred for simple functions)
  def add(a, b), do: a + b

  def subtract(a, b), do: a - b

  def multiply(a, b), do: a * b

  def divide(a, b), do: a / b

  # Even works with guards
  def absolute(n) when n >= 0, do: n
  def absolute(n) when n < 0, do: -n
end

IO.inspect(MathShort.add(5, 3), label: "add")
IO.inspect(MathShort.subtract(10, 4), label: "subtract")
IO.inspect(MathShort.multiply(6, 7), label: "multiply")
IO.inspect(MathShort.divide(20, 4), label: "divide")
IO.inspect(MathShort.absolute(-42), label: "absolute(-42)")

# Use the shorthand when:
# - The function body is a single expression
# - It fits comfortably on one line
# Use the full do...end when:
# - The function body has multiple expressions
# - Readability is improved by multiple lines

# -----------------------------------------------------------------------------
# Section 3: Private Functions with defp
# -----------------------------------------------------------------------------

IO.puts("\n--- Private Functions with defp ---")

# Private functions can only be called from within the same module
# They are defined with defp instead of def

defmodule Calculator do
  # Public function - can be called from outside
  def calculate(a, b, operation) do
    case operation do
      :add -> do_add(a, b)
      :subtract -> do_subtract(a, b)
      :multiply -> do_multiply(a, b)
      :divide -> do_divide(a, b)
      _ -> {:error, "Unknown operation"}
    end
  end

  # Private functions - only accessible within this module
  defp do_add(a, b), do: {:ok, a + b}
  defp do_subtract(a, b), do: {:ok, a - b}
  defp do_multiply(a, b), do: {:ok, a * b}

  defp do_divide(_a, 0), do: {:error, "Cannot divide by zero"}
  defp do_divide(a, b), do: {:ok, a / b}
end

IO.inspect(Calculator.calculate(10, 5, :add), label: "calculate add")
IO.inspect(Calculator.calculate(10, 5, :subtract), label: "calculate subtract")
IO.inspect(Calculator.calculate(10, 5, :multiply), label: "calculate multiply")
IO.inspect(Calculator.calculate(10, 5, :divide), label: "calculate divide")
IO.inspect(Calculator.calculate(10, 0, :divide), label: "calculate divide by 0")

# This would cause an error (uncomment to try):
# Calculator.do_add(1, 2)  # ** (UndefinedFunctionError)

IO.puts("\nPrivate functions hide implementation details")
IO.puts("Users of Calculator only see calculate/3, not the do_* functions")

# Common convention: prefix private helper functions with do_
# Examples: do_calculate, do_process, do_validate

# -----------------------------------------------------------------------------
# Section 4: Function Arity
# -----------------------------------------------------------------------------

IO.puts("\n--- Function Arity ---")

# Arity is the number of arguments a function takes
# Functions are identified by name AND arity
# name/arity is the full function identifier

defmodule ArityDemo do
  # These are THREE different functions!
  def greet, do: "Hello!"                     # greet/0
  def greet(name), do: "Hello, #{name}!"      # greet/1
  def greet(greeting, name), do: "#{greeting}, #{name}!"  # greet/2

  # Same with sum
  def sum(list) when is_list(list), do: Enum.sum(list)  # sum/1
  def sum(a, b), do: a + b                              # sum/2
  def sum(a, b, c), do: a + b + c                       # sum/3
end

IO.inspect(ArityDemo.greet(), label: "greet/0")
IO.inspect(ArityDemo.greet("Alice"), label: "greet/1")
IO.inspect(ArityDemo.greet("Hi", "Bob"), label: "greet/2")

IO.inspect(ArityDemo.sum([1, 2, 3]), label: "sum/1")
IO.inspect(ArityDemo.sum(1, 2), label: "sum/2")
IO.inspect(ArityDemo.sum(1, 2, 3), label: "sum/3")

# When capturing named functions, you must specify the arity
sum_list = &ArityDemo.sum/1
sum_pair = &ArityDemo.sum/2

IO.inspect(sum_list.([4, 5, 6]), label: "captured sum/1")
IO.inspect(sum_pair.(4, 5), label: "captured sum/2")

# You can check available arities in IEx with:
# h ArityDemo.sum

# -----------------------------------------------------------------------------
# Section 5: Default Argument Values
# -----------------------------------------------------------------------------

IO.puts("\n--- Default Argument Values ---")

# Use \\ to specify default values for arguments
defmodule Defaults do
  # Single default argument
  def greet(name \\ "World") do
    "Hello, #{name}!"
  end

  # Multiple default arguments
  def introduce(name \\ "Anonymous", role \\ "guest", company \\ "Unknown") do
    "#{name} is a #{role} at #{company}"
  end

  # Default with expression
  def timestamp(datetime \\ DateTime.utc_now()) do
    DateTime.to_string(datetime)
  end
end

IO.inspect(Defaults.greet(), label: "greet() - uses default")
IO.inspect(Defaults.greet("Alice"), label: "greet(\"Alice\")")

IO.inspect(Defaults.introduce(), label: "introduce() - all defaults")
IO.inspect(Defaults.introduce("Bob"), label: "introduce(\"Bob\")")
IO.inspect(Defaults.introduce("Bob", "developer"), label: "with 2 args")
IO.inspect(Defaults.introduce("Bob", "developer", "Acme"), label: "with 3 args")

# Defaults are filled left-to-right
# You can't skip a default in the middle

# Default arguments create multiple function clauses under the hood
# greet/0 and greet/1 are both created from def greet(name \\ "World")

# -----------------------------------------------------------------------------
# Section 6: Default Arguments with Multiple Clauses
# -----------------------------------------------------------------------------

IO.puts("\n--- Default Arguments with Multiple Clauses ---")

# When you have multiple function clauses, defaults need special handling
# Use a function head to declare defaults

defmodule MultiClause do
  # Function head declares defaults (no body!)
  def process(value, opts \\ [])

  # Individual clauses handle different patterns
  def process(value, opts) when is_list(value) do
    limit = Keyword.get(opts, :limit, 10)
    Enum.take(value, limit)
  end

  def process(value, opts) when is_binary(value) do
    upcase? = Keyword.get(opts, :upcase, false)
    if upcase?, do: String.upcase(value), else: value
  end

  def process(value, _opts) when is_number(value) do
    value * 2
  end
end

IO.inspect(MultiClause.process([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]),
  label: "process list (default limit)")
IO.inspect(MultiClause.process([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], limit: 3),
  label: "process list (limit: 3)")
IO.inspect(MultiClause.process("hello"), label: "process string")
IO.inspect(MultiClause.process("hello", upcase: true), label: "process string upcase")
IO.inspect(MultiClause.process(21), label: "process number")

# -----------------------------------------------------------------------------
# Section 7: Documenting Functions
# -----------------------------------------------------------------------------

IO.puts("\n--- Documenting Functions ---")

defmodule DocumentedModule do
  @moduledoc """
  A module demonstrating documentation.

  This module provides functions for working with numbers
  and strings, primarily for educational purposes.
  """

  @doc """
  Calculates the factorial of a non-negative integer.

  ## Parameters

    - n: A non-negative integer

  ## Returns

    The factorial of n (n!)

  ## Examples

      iex> DocumentedModule.factorial(5)
      120

      iex> DocumentedModule.factorial(0)
      1

  """
  def factorial(0), do: 1
  def factorial(n) when n > 0, do: n * factorial(n - 1)

  @doc """
  Reverses a string.

  ## Examples

      iex> DocumentedModule.reverse("hello")
      "olleh"

  """
  def reverse(str), do: String.reverse(str)

  @doc false  # This hides the function from documentation
  def internal_helper(x), do: x * 2
end

IO.inspect(DocumentedModule.factorial(5), label: "factorial(5)")
IO.inspect(DocumentedModule.reverse("Elixir"), label: "reverse(\"Elixir\")")

IO.puts("\nDocumentation tips:")
IO.puts("- @moduledoc for module documentation")
IO.puts("- @doc for function documentation")
IO.puts("- @doc false to hide internal functions")
IO.puts("- Use ## Examples with iex> for doctests")
IO.puts("- View docs in IEx with: h DocumentedModule.factorial")

# -----------------------------------------------------------------------------
# Section 8: Function Visibility Summary
# -----------------------------------------------------------------------------

IO.puts("\n--- Function Visibility Summary ---")

defmodule VisibilityDemo do
  @moduledoc """
  Demonstrates public vs private functions.
  """

  # Public: Part of the module's API
  def public_function do
    # Can call private functions
    result = private_helper()
    "Public function called private_helper: #{result}"
  end

  def another_public do
    # Can also call other public functions
    public_function()
  end

  # Private: Implementation detail
  defp private_helper do
    "I'm private!"
  end

  defp another_private do
    # Private functions can call other private functions
    private_helper()
  end

  # Making the private function testable via public wrapper
  def test_helper do
    another_private()
  end
end

IO.inspect(VisibilityDemo.public_function(), label: "public_function")
IO.inspect(VisibilityDemo.another_public(), label: "another_public")
IO.inspect(VisibilityDemo.test_helper(), label: "test_helper")

IO.puts("""

Visibility guidelines:
- def: Public API - functions users should call
- defp: Private - implementation details

When to use defp:
- Helper functions not meant for external use
- Functions that might change without notice
- Internal implementation that should be hidden

Benefits of defp:
- Clearer API (users see only what matters)
- Freedom to refactor internals
- Smaller public surface area
""")

# -----------------------------------------------------------------------------
# Section 9: Calling Functions - Various Ways
# -----------------------------------------------------------------------------

IO.puts("\n--- Calling Functions ---")

defmodule CallDemo do
  def add(a, b), do: a + b
  def greet(name), do: "Hello, #{name}!"
end

# Standard call
IO.inspect(CallDemo.add(1, 2), label: "Standard call")

# Using apply/3 - useful for dynamic function calls
IO.inspect(apply(CallDemo, :add, [3, 4]), label: "apply/3")
IO.inspect(apply(CallDemo, :greet, ["Alice"]), label: "apply/3 greet")

# Capturing and calling
add_fn = &CallDemo.add/2
IO.inspect(add_fn.(5, 6), label: "Captured function")

# Dynamic module and function names
module = CallDemo
function = :add
args = [7, 8]
IO.inspect(apply(module, function, args), label: "Fully dynamic call")

# Using Kernel.apply
IO.inspect(Kernel.apply(CallDemo, :add, [9, 10]), label: "Kernel.apply")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: Temperature Converter
# Difficulty: Easy
#
# Create a module TemperatureConverter with:
# - celsius_to_fahrenheit(c) - converts Celsius to Fahrenheit
# - fahrenheit_to_celsius(f) - converts Fahrenheit to Celsius
# Formula: F = C * 9/5 + 32
#
# Use the do: shorthand syntax
#
# Your code here:

IO.puts("\nExercise 1: Create temperature converter functions")
# defmodule TemperatureConverter do
#   def celsius_to_fahrenheit(c), do: ...
#   def fahrenheit_to_celsius(f), do: ...
# end

# Exercise 2: String Utilities with Defaults
# Difficulty: Easy
#
# Create a module StringUtils with:
# - wrap(str, wrapper \\ "*") - wraps a string with a character
#   wrap("hello") => "*hello*"
#   wrap("hello", "-") => "-hello-"
# - pad(str, length \\ 20, char \\ " ") - pads string to length
#   pad("hi", 5, "-") => "hi---"
#
# Your code here:

IO.puts("\nExercise 2: Create string utilities with defaults")
# defmodule StringUtils do
#   def wrap(str, wrapper \\ ...), do: ...
#   def pad(str, length \\ ..., char \\ ...), do: ...
# end

# Exercise 3: Public and Private Functions
# Difficulty: Medium
#
# Create a module Password with:
# - generate(length \\ 12) - public, generates a random password
# - validate(password) - public, returns {:ok, password} or {:error, reason}
#
# Private helpers:
# - random_char() - returns a random alphanumeric character
# - check_length(password) - checks if password is at least 8 chars
# - check_has_number(password) - checks if password has a digit
#
# Validation should check length and presence of number.
#
# Your code here:

IO.puts("\nExercise 3: Create password module with public/private functions")
# defmodule Password do
#   def generate(length \\ 12), do: ...
#   def validate(password), do: ...
#   defp random_char(), do: ...
#   defp check_length(password), do: ...
#   defp check_has_number(password), do: ...
# end

# Exercise 4: Multiple Arities
# Difficulty: Medium
#
# Create a module Logger with a log function that has multiple arities:
# - log() - logs "No message" with level :info
# - log(message) - logs message with level :info
# - log(message, level) - logs message with specified level
# - log(message, level, metadata) - logs with metadata map
#
# Output format: "[LEVEL] message (metadata)"
# Use IO.puts to print the log.
#
# Your code here:

IO.puts("\nExercise 4: Create logger with multiple arities")
# defmodule Logger do
#   def log, do: ...
#   def log(message), do: ...
#   def log(message, level), do: ...
#   def log(message, level, metadata), do: ...
# end

# Exercise 5: Documented Module
# Difficulty: Medium
#
# Create a module MathHelpers with full documentation:
# - @moduledoc describing the module
# - @doc for each function with examples
#
# Functions:
# - square(n) - returns n squared
# - cube(n) - returns n cubed
# - power(base, exp \\ 2) - returns base to the exp power
# - sum_of_squares(list) - returns sum of squares of all numbers
#
# Include @doc false for any private helpers.
#
# Your code here:

IO.puts("\nExercise 5: Create fully documented math module")
# defmodule MathHelpers do
#   @moduledoc """
#   ...
#   """
#
#   @doc """
#   ...
#   """
#   def square(n), do: ...
#   ...
# end

# Exercise 6: Function Composition Module
# Difficulty: Hard
#
# Create a module FunctionBuilder that returns functions:
# - multiplier(n) - returns a function that multiplies by n
# - adder(n) - returns a function that adds n
# - clamper(min, max) - returns a function that clamps values between min and max
# - pipeline(functions) - takes a list of functions and returns a function
#   that applies them in order
#
# Example usage:
# double = FunctionBuilder.multiplier(2)
# double.(5) => 10
#
# add_ten = FunctionBuilder.adder(10)
# add_ten.(5) => 15
#
# clamp = FunctionBuilder.clamper(0, 100)
# clamp.(150) => 100
#
# process = FunctionBuilder.pipeline([&(&1 + 1), &(&1 * 2)])
# process.(5) => 12  # (5 + 1) * 2
#
# Your code here:

IO.puts("\nExercise 6: Create function builder module")
# defmodule FunctionBuilder do
#   def multiplier(n), do: ...
#   def adder(n), do: ...
#   def clamper(min, max), do: ...
#   def pipeline(functions), do: ...
# end

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

1. Defining Functions:
   - def name(args) do ... end  (public)
   - defp name(args) do ... end (private)
   - def name(args), do: expr   (shorthand for single expressions)

2. Function Arity:
   - Functions are identified by name/arity
   - greet/0, greet/1, greet/2 are different functions
   - Capture with &Module.func/arity

3. Default Arguments:
   - Use \\\\ for defaults: def greet(name \\\\ "World")
   - Defaults are applied left-to-right
   - Use function heads with multiple clauses

4. Public vs Private:
   - def: Public API, callable from outside
   - defp: Private, internal implementation
   - Convention: prefix private helpers with do_

5. Documentation:
   - @moduledoc for module docs
   - @doc for function docs
   - @doc false to hide functions
   - Use ## Examples with iex> for doctests

6. Calling Functions:
   - Direct: Module.function(args)
   - Dynamic: apply(Module, :function, [args])
   - Captured: (&Module.function/arity).(args)

Best Practices:
- Keep functions small and focused
- Use meaningful names
- Document public functions
- Hide implementation with defp
- Use defaults to reduce boilerplate

Next: 16_function_clauses.exs - Multiple function heads and guards
""")
