# ============================================================================
# Lesson 02: Basic Types
# ============================================================================
#
# Elixir is a dynamically typed language with rich data types.
#
# Learning Objectives:
# - Understand Elixir's basic data types
# - Know when to use each type
# - Use type-checking functions
#
# Prerequisites:
# - Lesson 01 completed
#
# ============================================================================

IO.puts("=" |> String.duplicate(60))
IO.puts("Lesson 02: Basic Types")
IO.puts("=" |> String.duplicate(60))

# -----------------------------------------------------------------------------
# Section 1: Integers
# -----------------------------------------------------------------------------

IO.puts("\n--- Integers ---")

# Integers have arbitrary precision (no overflow!)
small = 42
big = 1_000_000_000_000_000_000_000  # Underscores improve readability
negative = -17

IO.inspect(small, label: "Small integer")
IO.inspect(big, label: "Big integer")
IO.inspect(negative, label: "Negative integer")

# Different bases
binary = 0b1010      # Binary: 10
octal = 0o777        # Octal: 511
hex = 0xFF           # Hexadecimal: 255

IO.inspect(binary, label: "Binary 0b1010")
IO.inspect(octal, label: "Octal 0o777")
IO.inspect(hex, label: "Hex 0xFF")

# Check if something is an integer
IO.inspect(is_integer(42), label: "is_integer(42)")
IO.inspect(is_integer(3.14), label: "is_integer(3.14)")

# -----------------------------------------------------------------------------
# Section 2: Floats
# -----------------------------------------------------------------------------

IO.puts("\n--- Floats ---")

# Floats are 64-bit double precision
pi = 3.14159
scientific = 1.0e-10  # Scientific notation

IO.inspect(pi, label: "Pi")
IO.inspect(scientific, label: "Scientific notation")

# Floats require a digit on both sides of the decimal
# valid = 1.0
# invalid = 1.   (this won't work)

# Float operations
IO.inspect(10 / 3, label: "10 / 3 (always float)")
IO.inspect(div(10, 3), label: "div(10, 3) (integer division)")
IO.inspect(rem(10, 3), label: "rem(10, 3) (remainder)")

# Check if something is a float
IO.inspect(is_float(3.14), label: "is_float(3.14)")
IO.inspect(is_float(42), label: "is_float(42)")

# is_number checks for either
IO.inspect(is_number(42), label: "is_number(42)")
IO.inspect(is_number(3.14), label: "is_number(3.14)")

# -----------------------------------------------------------------------------
# Section 3: Booleans
# -----------------------------------------------------------------------------

IO.puts("\n--- Booleans ---")

# Booleans are true and false
# They're actually atoms! (more on atoms below)

IO.inspect(true, label: "true")
IO.inspect(false, label: "false")

# Boolean operations
IO.inspect(true and false, label: "true and false")
IO.inspect(true or false, label: "true or false")
IO.inspect(not true, label: "not true")

# Comparison
IO.inspect(1 == 1, label: "1 == 1")
IO.inspect(1 != 2, label: "1 != 2")
IO.inspect(1 < 2, label: "1 < 2")

# true and false are atoms
IO.inspect(true == :true, label: "true == :true")
IO.inspect(is_boolean(true), label: "is_boolean(true)")
IO.inspect(is_atom(true), label: "is_atom(true)")

# -----------------------------------------------------------------------------
# Section 4: Atoms
# -----------------------------------------------------------------------------

IO.puts("\n--- Atoms ---")

# Atoms are constants whose name is their value
# They start with : (colon)

status = :ok
error = :error
my_atom = :hello_world

IO.inspect(status, label: "status")
IO.inspect(error, label: "error")
IO.inspect(my_atom, label: "my_atom")

# Atoms are used extensively in Elixir:
# - :ok and :error for function returns
# - Keys in keyword lists
# - Module names (Elixir modules are atoms)

IO.inspect(:ok == :ok, label: ":ok == :ok")
IO.inspect(:ok == :error, label: ":ok == :error")

# Module names are atoms too!
IO.inspect(is_atom(String), label: "is_atom(String)")
IO.inspect(String == :"Elixir.String", label: "String == :\"Elixir.String\"")

# Atoms with special characters need quotes
special = :"hello world"
IO.inspect(special, label: "Atom with space")

# Check if something is an atom
IO.inspect(is_atom(:hello), label: "is_atom(:hello)")
IO.inspect(is_atom("hello"), label: "is_atom(\"hello\")")

# -----------------------------------------------------------------------------
# Section 5: Strings
# -----------------------------------------------------------------------------

IO.puts("\n--- Strings ---")

# Strings are UTF-8 encoded binaries (double quotes)
greeting = "Hello, World!"
unicode = "Hello, 世界! 🎉"

IO.puts(greeting)
IO.puts(unicode)

# String length vs byte size
IO.inspect(String.length(unicode), label: "String length (characters)")
IO.inspect(byte_size(unicode), label: "Byte size")

# String operations
IO.inspect(String.upcase("hello"), label: "String.upcase")
IO.inspect(String.downcase("HELLO"), label: "String.downcase")
IO.inspect(String.trim("  hello  "), label: "String.trim")
IO.inspect(String.split("a,b,c", ","), label: "String.split")

# Concatenation
IO.inspect("Hello" <> " " <> "World", label: "Concatenation with <>")

# String interpolation (from lesson 01)
name = "Elixir"
IO.inspect("Hello, #{name}!", label: "Interpolation")

# Multi-line strings (heredocs)
multi = """
This is a
multi-line
string
"""
IO.puts("Multi-line string:")
IO.puts(multi)

# Check if something is a binary (string)
IO.inspect(is_binary("hello"), label: "is_binary(\"hello\")")

# -----------------------------------------------------------------------------
# Section 6: Charlists
# -----------------------------------------------------------------------------

IO.puts("\n--- Charlists ---")

# Charlists are lists of character codes (single quotes)
# They're mainly for Erlang interop

charlist = 'hello'
IO.inspect(charlist, label: "Charlist")

# Charlists are actually lists of integers
IO.inspect('ABC', label: "'ABC' (list of code points)")

# Convert between strings and charlists
IO.inspect(to_string('hello'), label: "to_string('hello')")
IO.inspect(to_charlist("hello"), label: "to_charlist(\"hello\")")

# IMPORTANT: Use double-quoted strings in Elixir
# Single-quoted charlists are mainly for Erlang compatibility

# Check if something is a list
IO.inspect(is_list('hello'), label: "is_list('hello')")
IO.inspect(is_list("hello"), label: "is_list(\"hello\")")

# -----------------------------------------------------------------------------
# Section 7: nil
# -----------------------------------------------------------------------------

IO.puts("\n--- nil ---")

# nil represents absence of value
# It's actually the atom :nil

IO.inspect(nil, label: "nil")
IO.inspect(nil == :nil, label: "nil == :nil")
IO.inspect(is_nil(nil), label: "is_nil(nil)")
IO.inspect(is_atom(nil), label: "is_atom(nil)")

# nil and false are the only "falsy" values
# Everything else is "truthy"

IO.inspect(!nil, label: "!nil (nil is falsy)")
IO.inspect(!false, label: "!false (false is falsy)")
IO.inspect(!0, label: "!0 (0 is truthy)")
IO.inspect(!"", label: "!\"\" (empty string is truthy)")

# -----------------------------------------------------------------------------
# Section 8: Type Comparison
# -----------------------------------------------------------------------------

IO.puts("\n--- Type Comparison ---")

# Elixir can compare values of different types
# Types have a sorting order:
# number < atom < reference < function < port < pid < tuple < map < list < bitstring

IO.inspect(1 < :atom, label: "1 < :atom")
IO.inspect(:atom < "string", label: ":atom < \"string\"")

# Strict vs loose equality
IO.inspect(1 == 1.0, label: "1 == 1.0 (loose)")
IO.inspect(1 === 1.0, label: "1 === 1.0 (strict)")

IO.inspect(1 != 1.0, label: "1 != 1.0")
IO.inspect(1 !== 1.0, label: "1 !== 1.0")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: Type Detective
# Difficulty: Easy
#
# For each value below, predict its type, then verify using is_* functions
# Print your findings with IO.puts
#
# Values to investigate:
# - 42
# - 42.0
# - :hello
# - "hello"
# - 'hello'
# - true
# - nil
#
# Your code here:

IO.puts("\nExercise 1: Investigate types")

# Exercise 2: Number Manipulation
# Difficulty: Easy
#
# Given the number 1234567890, use underscores to make it readable
# Then print it in different bases (binary, hex)
# Hint: Use Integer.to_string/2 for base conversion
#
# Your code here:

IO.puts("\nExercise 2: Number bases")

# Exercise 3: String Operations
# Difficulty: Medium
#
# Given the string "  Hello, Elixir World!  "
# 1. Trim the whitespace
# 2. Convert to uppercase
# 3. Replace "ELIXIR" with "FUNCTIONAL"
# 4. Split into words
# Print each step using IO.inspect with labels
#
# Your code here:

IO.puts("\nExercise 3: String transformation")

# Exercise 4: Truth Table
# Difficulty: Easy
#
# Create and print a truth table for `and` and `or` operations
# Format it nicely with IO.puts
#
# Your code here:

IO.puts("\nExercise 4: Boolean truth table")

# Exercise 5: Type Checking Function
# Difficulty: Medium
#
# Create a string that describes a value's type
# Use cond with is_* functions
# Example: describe(42) should return "integer"
#
# defmodule Exercise do
#   def describe(value) do
#     cond do
#       is_integer(value) -> "integer"
#       # ... add more
#     end
#   end
# end
#
# Your code here:

IO.puts("\nExercise 5: Type description")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

1. Integers: Arbitrary precision, support multiple bases
2. Floats: 64-bit double precision
3. Booleans: true and false (which are atoms!)
4. Atoms: Constants whose name is their value (:ok, :error)
5. Strings: UTF-8 binaries in double quotes
6. Charlists: Lists of code points in single quotes (for Erlang)
7. nil: Represents absence (also an atom)

Type checking functions:
- is_integer/1, is_float/1, is_number/1
- is_atom/1, is_boolean/1, is_nil/1
- is_binary/1 (for strings), is_list/1

Remember:
- Use double quotes for strings ("hello")
- Single quotes are charlists ('hello')
- nil and false are falsy, everything else is truthy

Next: 03_operators.exs - Arithmetic and logical operators
""")
