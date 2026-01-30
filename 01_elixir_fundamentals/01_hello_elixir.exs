# ============================================================================
# Lesson 01: Hello, Elixir!
# ============================================================================
#
# Welcome to Elixir! This is your first Elixir program.
#
# Learning Objectives:
# - Run your first Elixir program
# - Understand the .exs file extension
# - Use IO.puts and IO.inspect for output
# - Get familiar with IEx (Interactive Elixir)
#
# Prerequisites:
# - Elixir installed (run `elixir --version` to verify)
#
# ============================================================================

# -----------------------------------------------------------------------------
# Section 1: Your First Output
# -----------------------------------------------------------------------------

# IO.puts prints a string followed by a newline
# It returns :ok (an atom) after printing

IO.puts("Hello, Elixir!")
IO.puts("Welcome to functional programming!")

# -----------------------------------------------------------------------------
# Section 2: .ex vs .exs Files
# -----------------------------------------------------------------------------

# Elixir has two file extensions:
#
# .ex  - Compiled files (used for production code)
#        These are compiled to bytecode before running
#
# .exs - Script files (used for scripts, tests, configuration)
#        These are interpreted at runtime
#
# For learning, we use .exs because:
# - No compilation step needed
# - Just run with: elixir filename.exs
# - Perfect for experimentation

IO.puts("\nThis file is a .exs script file")
IO.puts("Run it with: elixir 01_hello_elixir.exs")

# -----------------------------------------------------------------------------
# Section 3: IO.inspect - Your Debugging Friend
# -----------------------------------------------------------------------------

# IO.inspect is incredibly useful for debugging
# It prints the value AND returns it, so you can insert it anywhere

IO.puts("\n--- IO.inspect examples ---")

# Basic inspect
IO.inspect("Hello")

# inspect returns the value, so you can chain it
result = IO.inspect(1 + 2 + 3)
IO.puts("The result was: #{result}")

# inspect with labels (very useful for debugging!)
IO.inspect("some value", label: "Debug")

# You can inspect complex data structures
IO.inspect([1, 2, 3], label: "A list")
IO.inspect(%{name: "Alice", age: 30}, label: "A map")

# -----------------------------------------------------------------------------
# Section 4: String Interpolation
# -----------------------------------------------------------------------------

# Use #{} to embed expressions inside strings

name = "World"
IO.puts("\nHello, #{name}!")

# You can put any expression inside #{}
IO.puts("2 + 2 = #{2 + 2}")
IO.puts("Uppercase: #{String.upcase(name)}")

# -----------------------------------------------------------------------------
# Section 5: Comments
# -----------------------------------------------------------------------------

# This is a single-line comment

# Multi-line comments don't exist in Elixir
# Instead, we use multiple single-line comments
# like this

# For documentation, Elixir uses @doc and @moduledoc
# We'll cover those when we learn about modules

# -----------------------------------------------------------------------------
# Section 6: IEx - Interactive Elixir
# -----------------------------------------------------------------------------

IO.puts("\n--- IEx Tips ---")
IO.puts("""
IEx is the interactive Elixir shell. Start it with: iex

Useful IEx commands:
  h()          - Show help
  h(Enum)      - Show help for Enum module
  h(Enum.map)  - Show help for Enum.map function
  i(value)     - Show info about a value
  c("file.ex") - Compile a file
  r(Module)    - Recompile a module
  v()          - Show last value
  Ctrl+C twice - Exit IEx

Try running: iex 01_hello_elixir.exs
This loads this file into IEx so you can experiment!
""")

# -----------------------------------------------------------------------------
# Section 7: Everything is an Expression
# -----------------------------------------------------------------------------

# In Elixir, everything returns a value
# Even IO.puts returns something (:ok)

IO.puts("\n--- Everything is an expression ---")

return_value = IO.puts("This returns :ok")
IO.inspect(return_value, label: "IO.puts returned")

# if/else is also an expression that returns a value
message = if true do
  "This is the result"
else
  "This won't be reached"
end
IO.puts("if/else returned: #{message}")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: Hello, You!
# Difficulty: Easy
#
# Create a variable with your name and use string interpolation
# to print "Hello, [your name]!"
#
# Your code here:
# my_name = "..."
# IO.puts(...)

IO.puts("\nExercise 1: Create a greeting with your name")

# Exercise 2: Math Expression
# Difficulty: Easy
#
# Use IO.puts with string interpolation to print:
# "The answer to 7 * 8 is 56"
# (Calculate 7 * 8 inside the interpolation, don't hardcode 56)
#
# Your code here:

IO.puts("\nExercise 2: Print a math expression result")

# Exercise 3: Inspect Chain
# Difficulty: Medium
#
# IO.inspect returns its argument, so you can chain operations.
# Create a chain that:
# 1. Starts with the number 10
# 2. Inspects it with label "start"
# 3. Adds 5
# 4. Inspects it with label "after add"
# 5. Multiplies by 2
# 6. Inspects it with label "final"
#
# Hint: You can do this in one expression using |> (pipe operator)
# or as separate steps with variables
#
# Your code here:

IO.puts("\nExercise 3: Chain IO.inspect calls")

# Exercise 4: Multi-line String
# Difficulty: Easy
#
# Elixir supports multi-line strings with triple quotes (heredocs).
# Create a multi-line string that prints a small ASCII art or poem.
#
# Example:
# """
# Line 1
# Line 2
# """
#
# Your code here:

IO.puts("\nExercise 4: Create a multi-line string")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

1. Run Elixir scripts with: elixir filename.exs
2. Use IO.puts for printing strings
3. Use IO.inspect for debugging (it returns the value!)
4. String interpolation: "Hello, #{name}!"
5. Everything in Elixir is an expression
6. IEx is your interactive playground

Next: 02_basic_types.exs - Learn about Elixir's data types
""")
