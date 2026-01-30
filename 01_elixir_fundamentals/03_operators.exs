# ============================================================================
# Lesson 03: Operators
# ============================================================================
#
# Elixir provides a rich set of operators for arithmetic, comparison,
# boolean logic, and more.
#
# Learning Objectives:
# - Use arithmetic operators
# - Understand comparison operators
# - Master boolean operators (and, or, not, &&, ||, !)
# - Learn about the match operator (=)
# - Use string and list operators
#
# Prerequisites:
# - Lesson 02 (Basic Types) completed
#
# ============================================================================

IO.puts("=" |> String.duplicate(60))
IO.puts("Lesson 03: Operators")
IO.puts("=" |> String.duplicate(60))

# -----------------------------------------------------------------------------
# Section 1: Arithmetic Operators
# -----------------------------------------------------------------------------

IO.puts("\n--- Arithmetic Operators ---")

# Basic arithmetic
IO.inspect(5 + 3, label: "5 + 3 (addition)")
IO.inspect(10 - 4, label: "10 - 4 (subtraction)")
IO.inspect(6 * 7, label: "6 * 7 (multiplication)")
IO.inspect(15 / 4, label: "15 / 4 (division - always returns float)")

# Integer division and remainder
IO.inspect(div(15, 4), label: "div(15, 4) (integer division)")
IO.inspect(rem(15, 4), label: "rem(15, 4) (remainder/modulo)")

# Negative remainder matches dividend sign
IO.inspect(rem(-15, 4), label: "rem(-15, 4)")
IO.inspect(rem(15, -4), label: "rem(15, -4)")

# Unary operators
IO.inspect(-5, label: "-5 (unary minus)")
IO.inspect(+5, label: "+5 (unary plus)")

# No exponentiation operator - use :math.pow or **
IO.inspect(:math.pow(2, 10), label: ":math.pow(2, 10)")
IO.inspect(2 ** 10, label: "2 ** 10 (Elixir 1.13+)")

# -----------------------------------------------------------------------------
# Section 2: Comparison Operators
# -----------------------------------------------------------------------------

IO.puts("\n--- Comparison Operators ---")

# Equality
IO.inspect(1 == 1, label: "1 == 1 (equal)")
IO.inspect(1 != 2, label: "1 != 2 (not equal)")

# Strict equality (no type coercion)
IO.inspect(1 == 1.0, label: "1 == 1.0 (loose equality)")
IO.inspect(1 === 1.0, label: "1 === 1.0 (strict equality)")
IO.inspect(1 !== 1.0, label: "1 !== 1.0 (strict not equal)")

# Ordering
IO.inspect(3 < 5, label: "3 < 5 (less than)")
IO.inspect(5 > 3, label: "5 > 3 (greater than)")
IO.inspect(3 <= 3, label: "3 <= 3 (less or equal)")
IO.inspect(3 >= 3, label: "3 >= 3 (greater or equal)")

# Comparing different types (uses type ordering)
IO.inspect(1 < :atom, label: "1 < :atom (number < atom)")
IO.inspect(:atom < "string", label: ":atom < \"string\" (atom < string)")

# Type ordering (smallest to largest):
# number < atom < reference < function < port < pid < tuple < map < list < bitstring

# Comparing strings (lexicographic)
IO.inspect("apple" < "banana", label: "\"apple\" < \"banana\"")
IO.inspect("Apple" < "apple", label: "\"Apple\" < \"apple\" (uppercase first)")

# -----------------------------------------------------------------------------
# Section 3: Boolean Operators (Strict)
# -----------------------------------------------------------------------------

IO.puts("\n--- Boolean Operators (Strict) ---")

# These REQUIRE boolean arguments (true/false)
# Using non-boolean will raise an error

IO.inspect(true and true, label: "true and true")
IO.inspect(true and false, label: "true and false")
IO.inspect(false or true, label: "false or true")
IO.inspect(false or false, label: "false or false")
IO.inspect(not true, label: "not true")
IO.inspect(not false, label: "not false")

# Short-circuit evaluation
IO.puts("\nShort-circuit (and):")
# Second argument only evaluated if first is true
result = false and IO.puts("This won't print")
IO.inspect(result, label: "false and ...")

IO.puts("\nShort-circuit (or):")
# Second argument only evaluated if first is false
result = true or IO.puts("This won't print")
IO.inspect(result, label: "true or ...")

# These would cause ArgumentError with non-boolean:
# true and 1    # Error!
# 1 and true    # Error!

# -----------------------------------------------------------------------------
# Section 4: Boolean Operators (Relaxed)
# -----------------------------------------------------------------------------

IO.puts("\n--- Boolean Operators (Relaxed) ---")

# &&, ||, ! work with any type
# They treat nil and false as falsy, everything else as truthy

IO.inspect(1 && 2, label: "1 && 2")
IO.inspect(nil && 2, label: "nil && 2")
IO.inspect(false && 2, label: "false && 2")

IO.inspect(1 || 2, label: "1 || 2")
IO.inspect(nil || 2, label: "nil || 2")
IO.inspect(false || 2, label: "false || 2")

IO.inspect(!nil, label: "!nil")
IO.inspect(!1, label: "!1")
IO.inspect(!!1, label: "!!1 (convert to boolean)")

# Common pattern: default values
name = nil
IO.inspect(name || "Anonymous", label: "name || \"Anonymous\"")

config = nil
IO.inspect(config && config[:key], label: "config && config[:key]")

# -----------------------------------------------------------------------------
# Section 5: The Match Operator (=)
# -----------------------------------------------------------------------------

IO.puts("\n--- The Match Operator (=) ---")

# = is NOT assignment, it's pattern matching!
# We'll cover this in depth in lesson 09

# Basic "assignment" (really: binding)
x = 1
IO.inspect(x, label: "x after x = 1")

# But = actually matches left to right
# 1 = x  # This works if x is 1!
IO.inspect(1 = x, label: "1 = x (pattern match)")

# This would fail:
# 2 = x  # MatchError! 2 doesn't match 1

# Pattern matching with tuples
{a, b} = {1, 2}
IO.inspect({a, b}, label: "{a, b} from {1, 2}")

# Pattern matching with lists
[head | tail] = [1, 2, 3]
IO.inspect(head, label: "head")
IO.inspect(tail, label: "tail")

# -----------------------------------------------------------------------------
# Section 6: String Operators
# -----------------------------------------------------------------------------

IO.puts("\n--- String Operators ---")

# Concatenation with <>
IO.inspect("Hello" <> " " <> "World", label: "String concatenation")

# String interpolation
name = "Elixir"
IO.inspect("Hello, #{name}!", label: "Interpolation")

# Comparison (lexicographic)
IO.inspect("abc" < "abd", label: "\"abc\" < \"abd\"")
IO.inspect("abc" == "abc", label: "\"abc\" == \"abc\"")

# -----------------------------------------------------------------------------
# Section 7: List Operators
# -----------------------------------------------------------------------------

IO.puts("\n--- List Operators ---")

# List concatenation with ++
IO.inspect([1, 2] ++ [3, 4], label: "[1, 2] ++ [3, 4]")

# List subtraction with --
IO.inspect([1, 2, 3, 2, 1] -- [1, 2], label: "[1, 2, 3, 2, 1] -- [1, 2]")
# Note: removes first occurrence of each element

# Prepending with | (cons operator)
list = [2, 3, 4]
IO.inspect([1 | list], label: "[1 | [2, 3, 4]]")

# in operator (membership)
IO.inspect(2 in [1, 2, 3], label: "2 in [1, 2, 3]")
IO.inspect(4 in [1, 2, 3], label: "4 in [1, 2, 3]")
IO.inspect(:a in [:a, :b, :c], label: ":a in [:a, :b, :c]")

# not in
IO.inspect(4 not in [1, 2, 3], label: "4 not in [1, 2, 3]")

# -----------------------------------------------------------------------------
# Section 8: Range Operator
# -----------------------------------------------------------------------------

IO.puts("\n--- Range Operator ---")

# Create ranges with ..
range = 1..10
IO.inspect(range, label: "1..10")
IO.inspect(Enum.to_list(range), label: "Enum.to_list(1..10)")

# Descending ranges
IO.inspect(Enum.to_list(10..1), label: "10..1")

# Step ranges (Elixir 1.12+)
IO.inspect(Enum.to_list(1..10//2), label: "1..10//2 (step of 2)")
IO.inspect(Enum.to_list(10..1//-2), label: "10..1//-2")

# Check if value in range
IO.inspect(5 in 1..10, label: "5 in 1..10")
IO.inspect(15 in 1..10, label: "15 in 1..10")

# -----------------------------------------------------------------------------
# Section 9: Pipe Operator
# -----------------------------------------------------------------------------

IO.puts("\n--- Pipe Operator |> ---")

# The pipe operator passes the result as the first argument
# to the next function

# Without pipe:
result = String.trim(String.downcase(String.reverse("  HELLO  ")))
IO.inspect(result, label: "Nested calls")

# With pipe (much cleaner!):
result = "  HELLO  "
  |> String.reverse()
  |> String.downcase()
  |> String.trim()
IO.inspect(result, label: "With pipe")

# Pipe always passes to the FIRST argument
# If you need a different position, use an anonymous function

# -----------------------------------------------------------------------------
# Section 10: Other Useful Operators
# -----------------------------------------------------------------------------

IO.puts("\n--- Other Operators ---")

# Capture operator & (for anonymous functions)
double = &(&1 * 2)
IO.inspect(double.(5), label: "&(&1 * 2).(5)")

# Module attribute access @ (only in modules)
# @attribute_name

# Bitwise operators (in Bitwise module)
import Bitwise
IO.inspect(band(5, 3), label: "band(5, 3) (bitwise AND)")
IO.inspect(bor(5, 3), label: "bor(5, 3) (bitwise OR)")
IO.inspect(bxor(5, 3), label: "bxor(5, 3) (bitwise XOR)")
IO.inspect(bnot(5), label: "bnot(5) (bitwise NOT)")
IO.inspect(bsl(1, 3), label: "bsl(1, 3) (shift left)")
IO.inspect(bsr(8, 2), label: "bsr(8, 2) (shift right)")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: Calculator
# Difficulty: Easy
#
# Calculate and print the following:
# - The sum of 123 and 456
# - The product of 17 and 23
# - Integer division of 1000 by 7
# - The remainder of 1000 divided by 7
# - 2 to the power of 20
#
# Your code here:

IO.puts("\nExercise 1: Basic calculations")

# Exercise 2: Comparison Chain
# Difficulty: Easy
#
# Verify the type ordering by comparing:
# - A number, an atom, and a string
# - Print whether each comparison matches the expected order
#
# Your code here:

IO.puts("\nExercise 2: Type comparisons")

# Exercise 3: Boolean Logic
# Difficulty: Medium
#
# Write expressions that demonstrate the difference between:
# - and vs &&
# - or vs ||
# - not vs !
# Show a case where && works but and would fail
#
# Your code here:

IO.puts("\nExercise 3: Boolean operators comparison")

# Exercise 4: Default Values Pattern
# Difficulty: Medium
#
# Using || and &&, implement:
# 1. A default value pattern for a potentially nil variable
# 2. A safe navigation pattern that returns nil if the first value is nil
#
# Example:
# username = nil
# display_name = username || "Guest"
#
# Your code here:

IO.puts("\nExercise 4: Default value patterns")

# Exercise 5: List Operations
# Difficulty: Medium
#
# Given lists a = [1, 2, 3] and b = [3, 4, 5]:
# 1. Concatenate them
# 2. Find elements in a but not in b
# 3. Find common elements (hint: use --)
# 4. Prepend 0 to list a
#
# Your code here:

IO.puts("\nExercise 5: List operations")

# Exercise 6: Pipeline Challenge
# Difficulty: Hard
#
# Using only the pipe operator, transform the string:
# "  the QUICK brown FOX  "
# Into:
# "THE QUICK BROWN FOX"
# (trimmed and fully uppercase)
#
# Then extend it to:
# "THE-QUICK-BROWN-FOX"
# (replace spaces with hyphens)
#
# Hint: String.replace/3, String.trim/1, String.upcase/1
#
# Your code here:

IO.puts("\nExercise 6: Pipeline transformation")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

Arithmetic: +, -, *, /, div(), rem(), **
Comparison: ==, !=, ===, !==, <, >, <=, >=
Boolean (strict): and, or, not (require boolean args)
Boolean (relaxed): &&, ||, ! (work with any type)
Match: = (pattern matching, not assignment!)
String: <> (concatenation)
List: ++ (concat), -- (subtract), | (cons), in, not in
Range: .. (e.g., 1..10), ..// (with step)
Pipe: |> (data transformation pipelines)

Truthiness:
- Only nil and false are falsy
- Everything else is truthy

Operator precedence (highest to lowest):
1. Unary: +, -, !, ^, not
2. *, /
3. +, -
4. ++, --, .., <>
5. in, not in
6. <, >, <=, >=
7. ==, !=, ===, !==
8. &&, and
9. ||, or
10. =

Next: 04_lists.exs - Working with lists
""")
