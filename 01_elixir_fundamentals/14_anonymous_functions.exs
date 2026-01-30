# ============================================================================
# Lesson 14: Anonymous Functions
# ============================================================================
#
# Anonymous functions are first-class citizens in Elixir. They enable
# functional programming patterns and are essential for working with
# the Enum module and other higher-order functions.
#
# Learning Objectives:
# - Create anonymous functions using fn syntax
# - Use the & capture operator for shorthand
# - Understand closures and variable capture
# - Pass functions as arguments to other functions
# - Use anonymous functions with Enum operations
#
# Prerequisites:
# - Basic types (Lesson 02)
# - Lists and Enumerables (Lessons 04, 08)
#
# ============================================================================

IO.puts("=" |> String.duplicate(60))
IO.puts("Lesson 14: Anonymous Functions")
IO.puts("=" |> String.duplicate(60))

# -----------------------------------------------------------------------------
# Section 1: Creating Anonymous Functions with fn
# -----------------------------------------------------------------------------

IO.puts("\n--- Creating Anonymous Functions ---")

# Anonymous functions are created with fn ... end
# They are also called lambdas or closures

# A simple function that adds two numbers
add = fn a, b -> a + b end

# Calling anonymous functions requires a dot (.)
result = add.(3, 5)
IO.inspect(result, label: "add.(3, 5)")

# A function with no arguments
greet = fn -> "Hello, World!" end
IO.inspect(greet.(), label: "greet.()")

# A function with one argument
double = fn x -> x * 2 end
IO.inspect(double.(21), label: "double.(21)")

# Functions can have multiple expressions in the body
calculate = fn a, b ->
  sum = a + b
  product = a * b
  {sum, product}
end
IO.inspect(calculate.(4, 5), label: "calculate.(4, 5)")

# The dot is required to distinguish function variables from named functions
IO.puts("\nRemember: Anonymous functions require a dot to call: func.(args)")

# -----------------------------------------------------------------------------
# Section 2: Pattern Matching in Anonymous Functions
# -----------------------------------------------------------------------------

IO.puts("\n--- Pattern Matching in Anonymous Functions ---")

# Anonymous functions can have multiple clauses with pattern matching
# This is like having multiple function heads

describe_number = fn
  0 -> "zero"
  1 -> "one"
  n when n > 0 -> "positive"
  n when n < 0 -> "negative"
end

IO.inspect(describe_number.(0), label: "describe_number.(0)")
IO.inspect(describe_number.(1), label: "describe_number.(1)")
IO.inspect(describe_number.(42), label: "describe_number.(42)")
IO.inspect(describe_number.(-5), label: "describe_number.(-5)")

# Pattern matching on data structures
handle_result = fn
  {:ok, value} -> "Success: #{value}"
  {:error, reason} -> "Error: #{reason}"
  _ -> "Unknown result"
end

IO.inspect(handle_result.({:ok, "data loaded"}), label: "handle_result.({:ok, ...})")
IO.inspect(handle_result.({:error, "not found"}), label: "handle_result.({:error, ...})")

# Destructuring in function arguments
get_name = fn %{name: name} -> name end
IO.inspect(get_name.(%{name: "Alice", age: 30}), label: "get_name from map")

# Pattern matching on lists
first_element = fn
  [] -> "empty list"
  [head | _tail] -> "first: #{head}"
end

IO.inspect(first_element.([1, 2, 3]), label: "first_element.([1,2,3])")
IO.inspect(first_element.([]), label: "first_element.([])")

# -----------------------------------------------------------------------------
# Section 3: The Capture Operator (&)
# -----------------------------------------------------------------------------

IO.puts("\n--- The Capture Operator (&) ---")

# The & operator provides a shorthand for creating anonymous functions
# &1, &2, etc. refer to the first, second, etc. arguments

# Long form:
add_long = fn a, b -> a + b end
# Short form with capture:
add_short = &(&1 + &2)

IO.inspect(add_long.(10, 5), label: "add_long.(10, 5)")
IO.inspect(add_short.(10, 5), label: "add_short.(10, 5)")

# Single argument functions
double_long = fn x -> x * 2 end
double_short = &(&1 * 2)

IO.inspect(double_long.(7), label: "double_long.(7)")
IO.inspect(double_short.(7), label: "double_short.(7)")

# More examples of capture syntax
square = &(&1 * &1)
IO.inspect(square.(5), label: "square.(5)")

concat = &(&1 <> " " <> &2)
IO.inspect(concat.("Hello", "World"), label: "concat.(\"Hello\", \"World\")")

# Capture operator with tuple creation
make_tuple = &{&1, &2, &3}
IO.inspect(make_tuple.(1, 2, 3), label: "make_tuple.(1, 2, 3)")

# Capture operator with list creation
make_list = &[&1, &2]
IO.inspect(make_list.("a", "b"), label: "make_list.(\"a\", \"b\")")

# -----------------------------------------------------------------------------
# Section 4: Capturing Named Functions
# -----------------------------------------------------------------------------

IO.puts("\n--- Capturing Named Functions ---")

# The & operator can also capture named functions
# Syntax: &Module.function/arity

# Capture String.upcase/1
upcase_fn = &String.upcase/1
IO.inspect(upcase_fn.("hello"), label: "upcase_fn.(\"hello\")")

# Capture String.split/2
split_fn = &String.split/2
IO.inspect(split_fn.("a,b,c", ","), label: "split_fn.(\"a,b,c\", \",\")")

# Capture Enum.sum/1
sum_fn = &Enum.sum/1
IO.inspect(sum_fn.([1, 2, 3, 4, 5]), label: "sum_fn.([1,2,3,4,5])")

# This is especially useful when passing functions to Enum
numbers = [1, 2, 3, 4, 5]

# Using captured function with Enum.map
IO.inspect(Enum.map(numbers, &Integer.to_string/1), label: "Map to strings")

# Capture with Kernel functions
negate = &Kernel.-/1
IO.inspect(negate.(42), label: "negate.(42)")

abs_fn = &abs/1  # Kernel functions can omit the module
IO.inspect(abs_fn.(-42), label: "abs_fn.(-42)")

# You must specify the arity (number of arguments)
# &String.split/1 captures the 1-arity version (splits on whitespace)
# &String.split/2 captures the 2-arity version (splits on given pattern)

# -----------------------------------------------------------------------------
# Section 5: Closures - Capturing Variables
# -----------------------------------------------------------------------------

IO.puts("\n--- Closures ---")

# Anonymous functions can capture variables from their surrounding scope
# This creates a "closure" - the function "closes over" those variables

multiplier = 10
multiply_by_ten = fn x -> x * multiplier end

IO.inspect(multiply_by_ten.(5), label: "multiply_by_ten.(5)")

# The closure captures the VALUE at the time of creation
# Reassigning the variable doesn't affect existing closures
counter = 0
increment = fn -> counter + 1 end
IO.inspect(increment.(), label: "First call")

counter = 100  # This doesn't change what the closure captured
IO.inspect(increment.(), label: "After reassigning counter")
# Still returns 1, not 101!

# Practical example: creating configured functions
defmodule TaxCalculator do
  def create_calculator(tax_rate) do
    # This closure captures tax_rate
    fn price -> price * (1 + tax_rate) end
  end
end

california_tax = TaxCalculator.create_calculator(0.0725)
texas_tax = TaxCalculator.create_calculator(0.0625)

IO.inspect(california_tax.(100.00), label: "California tax on $100")
IO.inspect(texas_tax.(100.00), label: "Texas tax on $100")

# Closures with multiple captured variables
defmodule Greeter do
  def create_greeter(greeting, punctuation) do
    fn name -> "#{greeting}, #{name}#{punctuation}" end
  end
end

formal_greeter = Greeter.create_greeter("Good evening", ".")
casual_greeter = Greeter.create_greeter("Hey", "!")

IO.inspect(formal_greeter.("Dr. Smith"), label: "Formal")
IO.inspect(casual_greeter.("Bob"), label: "Casual")

# -----------------------------------------------------------------------------
# Section 6: Functions as First-Class Citizens
# -----------------------------------------------------------------------------

IO.puts("\n--- Functions as First-Class Citizens ---")

# Functions can be:
# 1. Assigned to variables (we've seen this)
# 2. Passed as arguments to other functions
# 3. Returned from other functions
# 4. Stored in data structures

# Passing functions as arguments
apply_twice = fn func, value ->
  func.(func.(value))
end

add_one = fn x -> x + 1 end
IO.inspect(apply_twice.(add_one, 5), label: "apply_twice add_one to 5")

double = fn x -> x * 2 end
IO.inspect(apply_twice.(double, 3), label: "apply_twice double to 3")

# Returning functions from functions
make_adder = fn n ->
  fn x -> x + n end
end

add_five = make_adder.(5)
add_ten = make_adder.(10)

IO.inspect(add_five.(3), label: "add_five.(3)")
IO.inspect(add_ten.(3), label: "add_ten.(3)")

# Storing functions in data structures
operations = %{
  add: fn a, b -> a + b end,
  subtract: fn a, b -> a - b end,
  multiply: fn a, b -> a * b end,
  divide: fn a, b -> a / b end
}

IO.inspect(operations.add.(10, 5), label: "operations.add")
IO.inspect(operations.subtract.(10, 5), label: "operations.subtract")
IO.inspect(operations.multiply.(10, 5), label: "operations.multiply")
IO.inspect(operations.divide.(10, 5), label: "operations.divide")

# Using with Enum (very common in Elixir)
numbers = [1, 2, 3, 4, 5]

IO.inspect(Enum.map(numbers, fn x -> x * 2 end), label: "Enum.map double")
IO.inspect(Enum.filter(numbers, fn x -> rem(x, 2) == 0 end), label: "Enum.filter even")
IO.inspect(Enum.reduce(numbers, 0, fn x, acc -> x + acc end), label: "Enum.reduce sum")

# Using capture shorthand with Enum
IO.inspect(Enum.map(numbers, &(&1 * 2)), label: "Enum.map with &")
IO.inspect(Enum.filter(numbers, &(rem(&1, 2) == 0)), label: "Enum.filter with &")
IO.inspect(Enum.reduce(numbers, 0, &(&1 + &2)), label: "Enum.reduce with &")

# -----------------------------------------------------------------------------
# Section 7: Anonymous Functions vs Named Functions
# -----------------------------------------------------------------------------

IO.puts("\n--- Anonymous vs Named Functions ---")

# Quick comparison:

# Anonymous function:
# - Created with fn ... end or & capture
# - Called with dot: func.()
# - Stored in variables
# - Can be passed around easily

# Named function:
# - Defined with def in a module
# - Called without dot: Module.func()
# - Must be captured to pass around: &Module.func/arity

# Example showing the difference
defmodule Comparison do
  # Named function
  def double(x), do: x * 2
end

# Anonymous function
double_anon = fn x -> x * 2 end

# Calling them
IO.inspect(Comparison.double(5), label: "Named function call")
IO.inspect(double_anon.(5), label: "Anonymous function call")

# Passing to Enum.map
IO.inspect(Enum.map([1, 2, 3], &Comparison.double/1), label: "Named (captured)")
IO.inspect(Enum.map([1, 2, 3], double_anon), label: "Anonymous (direct)")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: Basic Anonymous Functions
# Difficulty: Easy
#
# Create anonymous functions for the following:
# a) subtract - takes two numbers and returns their difference
# b) is_even - takes a number and returns true if even, false if odd
# c) format_name - takes first and last name, returns "Last, First"
#
# Test each function with IO.inspect
#
# Your code here:

IO.puts("\nExercise 1: Create basic anonymous functions")
# subtract = fn ...
# is_even = fn ...
# format_name = fn ...

# Exercise 2: Capture Operator
# Difficulty: Easy
#
# Rewrite these functions using the capture operator (&):
# a) fn x -> x * 3 end
# b) fn a, b -> a - b end
# c) fn str -> String.reverse(str) end
# d) fn a, b, c -> a + b + c end
#
# Your code here:

IO.puts("\nExercise 2: Use capture operator shorthand")
# triple = &...
# subtract = &...
# reverse = &...
# sum_three = &...

# Exercise 3: Pattern Matching Function
# Difficulty: Medium
#
# Create an anonymous function called `describe_list` that:
# - Returns "empty" for an empty list
# - Returns "single: X" for a list with one element X
# - Returns "pair: X, Y" for a list with two elements
# - Returns "many: X, Y, ..." for a list with more than two elements
#   (showing first two elements)
#
# Test with: [], [1], [1, 2], [1, 2, 3, 4, 5]
#
# Your code here:

IO.puts("\nExercise 3: Pattern matching in anonymous function")
# describe_list = fn
#   [] -> ...
#   [x] -> ...
#   [x, y] -> ...
#   [x, y | _rest] -> ...
# end

# Exercise 4: Closure Factory
# Difficulty: Medium
#
# Create a function `make_counter` that takes a starting value and step.
# It should return a function that, when called with a number n,
# returns what the counter value would be after n steps.
#
# Example:
# counter = make_counter(0, 5)   # start at 0, step by 5
# counter.(0)  # => 0
# counter.(1)  # => 5
# counter.(3)  # => 15
#
# Your code here:

IO.puts("\nExercise 4: Create a counter factory using closures")
# make_counter = fn start, step ->
#   fn n -> ... end
# end

# Exercise 5: Higher-Order Function
# Difficulty: Medium
#
# Create a function `compose` that takes two functions f and g
# and returns a new function that applies g first, then f.
# In other words: compose(f, g).(x) == f.(g.(x))
#
# Test with:
# add_one = fn x -> x + 1 end
# double = fn x -> x * 2 end
# add_then_double = compose(double, add_one)  # double(add_one(x))
# add_then_double.(5) should return 12 (5+1=6, 6*2=12)
#
# Your code here:

IO.puts("\nExercise 5: Create a compose function")
# compose = fn f, g ->
#   fn x -> ... end
# end

# Exercise 6: Working with Enum
# Difficulty: Hard
#
# Given the list of maps representing people:
# people = [
#   %{name: "Alice", age: 30, city: "New York"},
#   %{name: "Bob", age: 25, city: "Boston"},
#   %{name: "Charlie", age: 35, city: "New York"},
#   %{name: "Diana", age: 28, city: "Boston"}
# ]
#
# Use anonymous functions with Enum to:
# a) Get a list of all names (use Enum.map)
# b) Filter people over 27 years old (use Enum.filter)
# c) Group people by city (use Enum.group_by)
# d) Find the average age (use Enum.reduce or Enum.sum + length)
# e) Find the oldest person (use Enum.max_by)
#
# Your code here:

IO.puts("\nExercise 6: Use anonymous functions with Enum")
# people = [...]
# names = Enum.map(people, ...)
# over_27 = Enum.filter(people, ...)
# by_city = Enum.group_by(people, ...)
# avg_age = ...
# oldest = Enum.max_by(people, ...)

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

1. Anonymous Function Syntax:
   - Basic: fn args -> body end
   - Call with dot: func.(args)
   - Multiple clauses with pattern matching

2. Capture Operator (&):
   - Shorthand: &(&1 + &2) instead of fn a, b -> a + b end
   - &1, &2, etc. for positional arguments
   - Capture named functions: &Module.func/arity

3. Closures:
   - Functions capture variables from surrounding scope
   - The VALUE is captured at creation time
   - Great for creating configured/specialized functions

4. Functions as First-Class Citizens:
   - Assign to variables
   - Pass as arguments
   - Return from functions
   - Store in data structures

5. Common Patterns:
   - Enum.map(list, fn x -> ... end)
   - Enum.filter(list, &(condition(&1)))
   - Enum.reduce(list, acc, fn elem, acc -> ... end)

6. When to use what:
   - Anonymous functions: short, one-off operations
   - Captured named functions: reusing existing logic
   - Named functions: reusable, documented code

Next: 15_named_functions.exs - def/defp, default arguments, and arity
""")
