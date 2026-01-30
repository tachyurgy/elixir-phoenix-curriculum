# ============================================================================
# Lesson 18: The Pipe Operator
# ============================================================================
#
# The pipe operator |> is one of Elixir's most beloved features. It allows
# you to chain function calls in a readable, left-to-right manner,
# transforming data through a pipeline of operations.
#
# Learning Objectives:
# - Understand and use the pipe operator |>
# - Build data transformation pipelines
# - Know when to use (and not use) pipes
# - Combine pipes with Enum functions effectively
# - Write clean, readable pipeline code
#
# Prerequisites:
# - Functions (Lessons 14-16)
# - Enum basics (Lesson 08)
# - Pattern matching
#
# ============================================================================

IO.puts("=" |> String.duplicate(60))
IO.puts("Lesson 18: The Pipe Operator")
IO.puts("=" |> String.duplicate(60))

# -----------------------------------------------------------------------------
# Section 1: Introduction to the Pipe Operator
# -----------------------------------------------------------------------------

IO.puts("\n--- Introduction to the Pipe Operator ---")

# The pipe operator |> passes the result of the left expression
# as the FIRST argument to the function on the right

# Without pipes (nested calls - hard to read):
result_nested = String.split(String.upcase(String.trim("  hello world  ")))
IO.inspect(result_nested, label: "Nested calls")

# With pipes (left to right - easy to read):
result_piped = "  hello world  "
  |> String.trim()
  |> String.upcase()
  |> String.split()

IO.inspect(result_piped, label: "Piped calls")

# The pipe transforms:
# x |> f() becomes f(x)
# x |> f(y) becomes f(x, y)
# x |> f(y, z) becomes f(x, y, z)

# Simple example
5
|> Kernel.+(3)      # 5 + 3 = 8
|> Kernel.*(2)      # 8 * 2 = 16
|> IO.inspect(label: "Math with pipes")

# -----------------------------------------------------------------------------
# Section 2: Basic Pipe Patterns
# -----------------------------------------------------------------------------

IO.puts("\n--- Basic Pipe Patterns ---")

# String transformations
"  HELLO, World!  "
|> String.trim()
|> String.downcase()
|> String.replace(",", "")
|> String.split()
|> IO.inspect(label: "String pipeline")

# Number transformations
42
|> Integer.to_string()
|> String.pad_leading(5, "0")
|> IO.inspect(label: "Number to padded string")

# List transformations
[1, 2, 3, 4, 5]
|> Enum.map(fn x -> x * 2 end)
|> Enum.filter(fn x -> x > 4 end)
|> Enum.sum()
|> IO.inspect(label: "List pipeline")

# Map transformations
%{name: "alice", age: 30}
|> Map.put(:email, "alice@example.com")
|> Map.update!(:name, &String.capitalize/1)
|> IO.inspect(label: "Map pipeline")

# -----------------------------------------------------------------------------
# Section 3: Pipes with Enum Module
# -----------------------------------------------------------------------------

IO.puts("\n--- Pipes with Enum ---")

# Enum functions are designed to work beautifully with pipes

numbers = 1..10

# Find sum of squares of even numbers
numbers
|> Enum.filter(fn x -> rem(x, 2) == 0 end)  # Keep evens: [2, 4, 6, 8, 10]
|> Enum.map(fn x -> x * x end)               # Square them: [4, 16, 36, 64, 100]
|> Enum.sum()                                 # Sum: 220
|> IO.inspect(label: "Sum of squares of evens")

# Using capture operator for cleaner pipes
numbers
|> Enum.filter(&(rem(&1, 2) == 0))
|> Enum.map(&(&1 * &1))
|> Enum.sum()
|> IO.inspect(label: "Same with capture operator")

# Complex data processing
people = [
  %{name: "Alice", age: 30, department: "Engineering"},
  %{name: "Bob", age: 25, department: "Marketing"},
  %{name: "Charlie", age: 35, department: "Engineering"},
  %{name: "Diana", age: 28, department: "Engineering"},
  %{name: "Eve", age: 32, department: "Marketing"}
]

# Find average age of Engineering department
people
|> Enum.filter(fn person -> person.department == "Engineering" end)
|> Enum.map(fn person -> person.age end)
|> then(fn ages -> Enum.sum(ages) / length(ages) end)
|> IO.inspect(label: "Avg age in Engineering")

# Get sorted names from Marketing
people
|> Enum.filter(&(&1.department == "Marketing"))
|> Enum.map(& &1.name)
|> Enum.sort()
|> IO.inspect(label: "Marketing names (sorted)")

# -----------------------------------------------------------------------------
# Section 4: The then/2 Function
# -----------------------------------------------------------------------------

IO.puts("\n--- The then/2 Function ---")

# Sometimes you need the piped value in a different position
# Use then/2 to access the value in a custom way

# then/2 passes the value to a function you provide
10
|> then(fn x -> "The number is #{x}" end)
|> IO.inspect(label: "then/2 example")

# Useful when the value should be second argument
# div(10, 2) = 5, but what if 10 comes from a pipe?
20
|> then(fn x -> div(x, 4) end)
|> IO.inspect(label: "Using then for div")

# Compare: building a message
name = "Alice"
age = 30

# With then/2
name
|> String.upcase()
|> then(fn upper_name -> "Hello, #{upper_name}! You are #{age}." end)
|> IO.inspect(label: "Message with then")

# Multiple uses of the value
[1, 2, 3, 4, 5]
|> then(fn list -> {Enum.sum(list), length(list)} end)
|> then(fn {sum, len} -> sum / len end)
|> IO.inspect(label: "Average using then")

# -----------------------------------------------------------------------------
# Section 5: Pipes with Pattern Matching
# -----------------------------------------------------------------------------

IO.puts("\n--- Pipes with Pattern Matching ---")

# Pipes work great with functions that return tuples

defmodule DataProcessor do
  def fetch_data(id) when id > 0, do: {:ok, "Data for #{id}"}
  def fetch_data(_id), do: {:error, "Invalid ID"}

  def transform({:ok, data}), do: {:ok, String.upcase(data)}
  def transform({:error, _} = error), do: error

  def validate({:ok, data}) when byte_size(data) > 5, do: {:ok, data}
  def validate({:ok, _data}), do: {:error, "Data too short"}
  def validate({:error, _} = error), do: error

  def format_result({:ok, data}), do: "SUCCESS: #{data}"
  def format_result({:error, reason}), do: "FAILURE: #{reason}"
end

# Success pipeline
5
|> DataProcessor.fetch_data()
|> DataProcessor.transform()
|> DataProcessor.validate()
|> DataProcessor.format_result()
|> IO.inspect(label: "Success pipeline")

# Failure pipeline (error propagates)
-1
|> DataProcessor.fetch_data()
|> DataProcessor.transform()
|> DataProcessor.validate()
|> DataProcessor.format_result()
|> IO.inspect(label: "Failure pipeline")

# This pattern is so common that Elixir has the `with` construct
# We'll cover that in a later lesson

# -----------------------------------------------------------------------------
# Section 6: Debugging Pipelines with IO.inspect
# -----------------------------------------------------------------------------

IO.puts("\n--- Debugging Pipelines ---")

# IO.inspect returns its first argument, making it perfect for debugging

[1, 2, 3, 4, 5]
|> IO.inspect(label: "Initial list")
|> Enum.map(&(&1 * 2))
|> IO.inspect(label: "After doubling")
|> Enum.filter(&(&1 > 4))
|> IO.inspect(label: "After filtering > 4")
|> Enum.sum()
|> IO.inspect(label: "Final sum")

# IO.inspect with options
%{name: "Alice", nested: %{deeply: %{value: 42}}}
|> IO.inspect(label: "Default")
|> IO.inspect(label: "With limit", limit: 2)
|> IO.inspect(label: "Pretty printed", pretty: true)
|> Map.get(:name)
|> IO.inspect(label: "Extracted name")

# Temporary debug - easy to add and remove
result = [1, 2, 3]
  |> Enum.map(&(&1 * 10))
  # |> IO.inspect(label: "DEBUG")  # Easy to comment out
  |> Enum.sum()

IO.inspect(result, label: "Debug example result")

# -----------------------------------------------------------------------------
# Section 7: Creating Pipe-Friendly Functions
# -----------------------------------------------------------------------------

IO.puts("\n--- Creating Pipe-Friendly Functions ---")

# Design your functions to work well with pipes:
# - Put the "main data" as the first argument
# - Return the transformed data

defmodule PipeFriendly do
  # Good: data is first argument
  def add_prefix(string, prefix), do: prefix <> string
  def add_suffix(string, suffix), do: string <> suffix
  def wrap(string, wrapper), do: wrapper <> string <> wrapper

  # Process a list: list is first, options second
  def process(list, opts \\ []) do
    multiplier = Keyword.get(opts, :multiplier, 1)
    filter_fn = Keyword.get(opts, :filter, fn _ -> true end)

    list
    |> Enum.map(&(&1 * multiplier))
    |> Enum.filter(filter_fn)
  end

  # Transform a map: map is first
  def normalize_keys(map) do
    Map.new(map, fn {k, v} -> {normalize_key(k), v} end)
  end

  defp normalize_key(key) when is_atom(key), do: key
  defp normalize_key(key) when is_binary(key) do
    key
    |> String.downcase()
    |> String.replace(" ", "_")
    |> String.to_atom()
  end
end

"world"
|> PipeFriendly.add_prefix("hello ")
|> PipeFriendly.add_suffix("!")
|> PipeFriendly.wrap("***")
|> IO.inspect(label: "String transformations")

[1, 2, 3, 4, 5]
|> PipeFriendly.process(multiplier: 10, filter: &(&1 > 20))
|> IO.inspect(label: "Processed list")

%{"First Name" => "Alice", "Last Name" => "Smith"}
|> PipeFriendly.normalize_keys()
|> IO.inspect(label: "Normalized keys")

# -----------------------------------------------------------------------------
# Section 8: When NOT to Use Pipes
# -----------------------------------------------------------------------------

IO.puts("\n--- When NOT to Use Pipes ---")

IO.puts("""
Avoid pipes when:

1. Single function call (no transformation chain)
   Bad:  value |> function()
   Good: function(value)

2. The value isn't the first argument
   Bad:  2 |> div(10)  # This is div(2, 10) = 0, not div(10, 2)!
   Good: div(10, 2)

3. Multiple unrelated operations
   Bad:  x |> foo() |> IO.puts()  # Side effect in middle of pipe
   Good: result = foo(x)
         IO.puts(result)

4. When it hurts readability
   Sometimes nested calls are clearer for simple operations
""")

# Example: Don't pipe single calls
list = [1, 2, 3]
# Bad
_ = list |> Enum.sum()
# Good
_ = Enum.sum(list)

# Example: Be careful with argument order
# This is div(2, 10) = 0, NOT div(10, 2) = 5
bad_result = 2 |> div(10)
IO.inspect(bad_result, label: "2 |> div(10) - probably not what you want")

# Use then/2 if you need the piped value in a different position
good_result = 2 |> then(&div(10, &1))
IO.inspect(good_result, label: "Using then for correct order")

# -----------------------------------------------------------------------------
# Section 9: Real-World Pipeline Examples
# -----------------------------------------------------------------------------

IO.puts("\n--- Real-World Pipeline Examples ---")

# Example 1: Processing CSV-like data
csv_data = """
name,age,city
Alice,30,New York
Bob,25,Boston
Charlie,35,Chicago
"""

csv_data
|> String.trim()
|> String.split("\n")
|> Enum.drop(1)  # Skip header
|> Enum.map(&String.split(&1, ","))
|> Enum.map(fn [name, age, city] ->
  %{name: name, age: String.to_integer(age), city: city}
end)
|> IO.inspect(label: "Parsed CSV")

# Example 2: URL slug generation
title = "  Hello World! This is Elixir Programming  "

title
|> String.trim()
|> String.downcase()
|> String.replace(~r/[^\w\s]/, "")  # Remove non-word chars
|> String.replace(~r/\s+/, "-")     # Replace spaces with dashes
|> IO.inspect(label: "URL slug")

# Example 3: Data validation pipeline
defmodule UserValidator do
  def validate(user) do
    user
    |> validate_name()
    |> validate_email()
    |> validate_age()
  end

  defp validate_name(%{name: name} = user) when byte_size(name) >= 2, do: {:ok, user}
  defp validate_name(_), do: {:error, "Name must be at least 2 characters"}

  defp validate_email({:error, _} = error), do: error
  defp validate_email({:ok, %{email: email} = user}) do
    if String.contains?(email, "@"), do: {:ok, user}, else: {:error, "Invalid email"}
  end

  defp validate_age({:error, _} = error), do: error
  defp validate_age({:ok, %{age: age} = user}) when age >= 0 and age <= 150 do
    {:ok, user}
  end
  defp validate_age({:ok, _}), do: {:error, "Invalid age"}
end

%{name: "Alice", email: "alice@example.com", age: 30}
|> UserValidator.validate()
|> IO.inspect(label: "Valid user")

%{name: "A", email: "invalid", age: 30}
|> UserValidator.validate()
|> IO.inspect(label: "Invalid user")

# Example 4: Statistics calculation
scores = [85, 90, 78, 92, 88, 76, 95, 89, 91, 84]

stats = scores
|> Enum.sort()
|> then(fn sorted ->
  %{
    min: List.first(sorted),
    max: List.last(sorted),
    median: Enum.at(sorted, div(length(sorted), 2)),
    mean: Enum.sum(sorted) / length(sorted),
    count: length(sorted)
  }
end)

IO.inspect(stats, label: "Statistics")

# Example 5: Building a query-like structure
defmodule QueryBuilder do
  def new(), do: %{select: "*", from: nil, where: [], order_by: nil}

  def select(query, fields), do: %{query | select: fields}
  def from(query, table), do: %{query | from: table}
  def where(query, condition), do: %{query | where: [condition | query.where]}
  def order_by(query, field), do: %{query | order_by: field}

  def to_sql(query) do
    conditions = query.where |> Enum.reverse() |> Enum.join(" AND ")
    where_clause = if conditions != "", do: " WHERE #{conditions}", else: ""
    order_clause = if query.order_by, do: " ORDER BY #{query.order_by}", else: ""

    "SELECT #{query.select} FROM #{query.from}#{where_clause}#{order_clause}"
  end
end

QueryBuilder.new()
|> QueryBuilder.select("name, age")
|> QueryBuilder.from("users")
|> QueryBuilder.where("age > 18")
|> QueryBuilder.where("active = true")
|> QueryBuilder.order_by("name")
|> QueryBuilder.to_sql()
|> IO.inspect(label: "Generated SQL")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: String Pipeline
# Difficulty: Easy
#
# Create a pipeline that takes the string "  hELLo, wORLD!  " and:
# 1. Trims whitespace
# 2. Converts to lowercase
# 3. Removes the comma
# 4. Capitalizes each word
#
# Expected result: "Hello World!"
#
# Hint: Use String.trim/1, String.downcase/1, String.replace/3,
# and look up how to capitalize words (or do it with split + map + join)
#
# Your code here:

IO.puts("\nExercise 1: String transformation pipeline")
# result = "  hELLo, wORLD!  "
#   |> ...
#   |> ...

# Exercise 2: Number Statistics
# Difficulty: Easy
#
# Given a list of numbers [4, 8, 15, 16, 23, 42], create a pipeline that:
# 1. Filters to keep only numbers > 10
# 2. Multiplies each by 2
# 3. Returns the sum
#
# Your code here:

IO.puts("\nExercise 2: Number processing pipeline")
# result = [4, 8, 15, 16, 23, 42]
#   |> ...

# Exercise 3: Data Extraction
# Difficulty: Medium
#
# Given this list of products:
# products = [
#   %{name: "Laptop", price: 999, in_stock: true},
#   %{name: "Phone", price: 699, in_stock: false},
#   %{name: "Tablet", price: 499, in_stock: true},
#   %{name: "Watch", price: 299, in_stock: true}
# ]
#
# Create a pipeline that:
# 1. Filters only in-stock products
# 2. Gets only products under $500
# 3. Extracts just the names
# 4. Joins them with ", "
#
# Expected: "Tablet, Watch"
#
# Your code here:

IO.puts("\nExercise 3: Product data extraction")
# products = [...]
# result = products
#   |> ...

# Exercise 4: Create Pipe-Friendly Functions
# Difficulty: Medium
#
# Create a module TextProcessor with these pipe-friendly functions:
# - remove_punctuation(text) - removes !?.,;:
# - normalize_whitespace(text) - replaces multiple spaces with single space
# - truncate(text, max_length) - truncates to max_length, adds "..." if truncated
# - word_count(text) - returns number of words
#
# Then create a pipeline that uses all of them on:
# "Hello!!!   World...   This is   a test!!!"
#
# Your code here:

IO.puts("\nExercise 4: Create and use pipe-friendly functions")
# defmodule TextProcessor do
#   def remove_punctuation(text), do: ...
#   def normalize_whitespace(text), do: ...
#   def truncate(text, max_length), do: ...
#   def word_count(text), do: ...
# end

# Exercise 5: Pipeline with Error Handling
# Difficulty: Hard
#
# Create a module SafeMath with functions that handle errors:
# - parse(string) - returns {:ok, number} or {:error, "Invalid number"}
# - divide(result, divisor) - handles {:ok, n}/{:error, e}, division by zero
# - multiply(result, multiplier) - handles {:ok, n}/{:error, e}
# - format(result) - converts {:ok, n} to "Result: n" or {:error, e} to "Error: e"
#
# Create a pipeline: "10" |> parse |> divide(2) |> multiply(3) |> format
# Should return "Result: 15.0"
#
# Also test: "abc" |> parse |> divide(2) |> multiply(3) |> format
# Should return "Error: Invalid number"
#
# Your code here:

IO.puts("\nExercise 5: Pipeline with error handling")
# defmodule SafeMath do
#   def parse(string), do: ...
#   def divide({:ok, n}, divisor) when divisor != 0, do: ...
#   def divide({:ok, _}, 0), do: ...
#   def divide({:error, _} = error, _), do: ...
#   ...
# end

# Exercise 6: Complex Data Transformation
# Difficulty: Hard
#
# Given this data:
# orders = [
#   %{id: 1, customer: "Alice", items: [%{name: "Book", qty: 2, price: 15.0}], status: :completed},
#   %{id: 2, customer: "Bob", items: [%{name: "Pen", qty: 5, price: 2.0}, %{name: "Notebook", qty: 1, price: 8.0}], status: :pending},
#   %{id: 3, customer: "Alice", items: [%{name: "Laptop", qty: 1, price: 999.0}], status: :completed},
#   %{id: 4, customer: "Charlie", items: [%{name: "Mouse", qty: 2, price: 25.0}], status: :completed}
# ]
#
# Create a pipeline that:
# 1. Filters only completed orders
# 2. Calculates total for each order (sum of qty * price for each item)
# 3. Groups by customer
# 4. Calculates total spent per customer
#
# Expected result: %{"Alice" => 1029.0, "Charlie" => 50.0}
#
# Your code here:

IO.puts("\nExercise 6: Complex order data transformation")
# orders = [...]
# result = orders
#   |> Enum.filter(...)
#   |> Enum.map(fn order -> ... end)  # Add :total to each order
#   |> Enum.group_by(...)
#   |> Enum.map(fn {customer, orders} -> ... end)
#   |> Map.new()

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

1. Pipe Operator Basics:
   x |> f() becomes f(x)
   x |> f(y) becomes f(x, y)
   - Left-to-right data flow
   - More readable than nested calls

2. Common Pipe Patterns:
   data
   |> transform1()
   |> transform2()
   |> transform3()
   |> final_operation()

3. Debugging with IO.inspect:
   - IO.inspect returns its argument
   - Insert anywhere in pipeline
   - Use label: option for clarity

4. The then/2 Function:
   - When value needs to go in different position
   - For custom transformations
   x |> then(fn val -> use(val) end)

5. Pipe-Friendly Function Design:
   - Main data as first argument
   - Return transformed data
   - Options as second argument (keyword list)

6. When NOT to Use Pipes:
   - Single function calls
   - When value needs to be non-first argument
   - When it hurts readability

7. Error Handling Pattern:
   - Functions accept/return {:ok, value} or {:error, reason}
   - Errors propagate through pipeline
   - (See `with` construct in later lessons)

Best Practices:
- Keep pipelines focused on one transformation flow
- Use IO.inspect for debugging
- Break very long pipelines into named variables
- Make your own functions pipe-friendly

The pipe operator is idiomatic Elixir - use it often!

Congratulations! You've completed the functions section of Elixir Fundamentals!
""")
