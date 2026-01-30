# ============================================================================
# Lesson 06: Keyword Lists
# ============================================================================
#
# Keyword lists are a special type of list where each element is a two-element
# tuple with an atom as the first element. They're commonly used for options
# and named arguments in Elixir.
#
# Learning Objectives:
# - Understand keyword list structure and syntax
# - Know when to use keyword lists vs maps
# - Use keyword lists for function options
# - Master the shorthand syntax for keyword lists
#
# Prerequisites:
# - Lesson 04 (Lists) completed
# - Lesson 05 (Tuples) completed
#
# ============================================================================

IO.puts("=" |> String.duplicate(60))
IO.puts("Lesson 06: Keyword Lists")
IO.puts("=" |> String.duplicate(60))

# -----------------------------------------------------------------------------
# Section 1: What is a Keyword List?
# -----------------------------------------------------------------------------

IO.puts("\n--- What is a Keyword List? ---")

# A keyword list is a list of 2-tuples where the first element is an atom
# These are equivalent:
full_syntax = [{:name, "Alice"}, {:age, 30}, {:city, "NYC"}]
shorthand = [name: "Alice", age: 30, city: "NYC"]

IO.inspect(full_syntax, label: "Full syntax")
IO.inspect(shorthand, label: "Shorthand syntax")
IO.inspect(full_syntax == shorthand, label: "Are they equal?")

# The shorthand [key: value] is just syntax sugar for [{:key, value}]
IO.inspect([a: 1] == [{:a, 1}], label: "[a: 1] == [{:a, 1}]")

# Keyword lists are LISTS, so they have list properties:
# - Ordered
# - Can have duplicate keys
# - O(n) lookup

# -----------------------------------------------------------------------------
# Section 2: Duplicate Keys
# -----------------------------------------------------------------------------

IO.puts("\n--- Duplicate Keys ---")

# Unlike maps, keyword lists CAN have duplicate keys
# This is actually useful for certain scenarios!

options = [sort: :asc, filter: :active, sort: :desc]
IO.inspect(options, label: "Duplicate :sort keys")

# Keyword.get returns the FIRST value for a key
IO.inspect(Keyword.get(options, :sort), label: "Keyword.get(:sort)")

# Keyword.get_values returns ALL values for a key
IO.inspect(Keyword.get_values(options, :sort), label: "Keyword.get_values(:sort)")

# This is useful for things like:
# HTML attributes: [class: "btn", class: "btn-primary"]
# Query parameters: [tag: "elixir", tag: "programming"]

html_classes = [class: "btn", class: "btn-primary", class: "large"]
IO.inspect(Keyword.get_values(html_classes, :class), label: "All classes")

# -----------------------------------------------------------------------------
# Section 3: Accessing Values
# -----------------------------------------------------------------------------

IO.puts("\n--- Accessing Values ---")

person = [name: "Bob", age: 25, city: "LA"]

# Using Keyword module
IO.inspect(Keyword.get(person, :name), label: "Keyword.get(:name)")
IO.inspect(Keyword.get(person, :country), label: "Keyword.get(:country) - missing")
IO.inspect(Keyword.get(person, :country, "Unknown"), label: "With default")

# Using bracket syntax (only for single values)
IO.inspect(person[:name], label: "person[:name]")
IO.inspect(person[:missing], label: "person[:missing]")

# Keyword.fetch returns {:ok, value} or :error
IO.inspect(Keyword.fetch(person, :name), label: "Keyword.fetch(:name)")
IO.inspect(Keyword.fetch(person, :missing), label: "Keyword.fetch(:missing)")

# Keyword.fetch! raises if key doesn't exist
IO.inspect(Keyword.fetch!(person, :name), label: "Keyword.fetch!(:name)")
# Keyword.fetch!(person, :missing)  # Would raise KeyError!

# Check if key exists
IO.inspect(Keyword.has_key?(person, :name), label: "has_key?(:name)")
IO.inspect(Keyword.has_key?(person, :missing), label: "has_key?(:missing)")

# Get all keys or values
IO.inspect(Keyword.keys(person), label: "Keyword.keys")
IO.inspect(Keyword.values(person), label: "Keyword.values")

# -----------------------------------------------------------------------------
# Section 4: Modifying Keyword Lists
# -----------------------------------------------------------------------------

IO.puts("\n--- Modifying Keyword Lists ---")

original = [a: 1, b: 2, c: 3]
IO.inspect(original, label: "Original")

# Keyword.put - adds or updates (replaces ALL occurrences)
IO.inspect(Keyword.put(original, :d, 4), label: "put(:d, 4)")
IO.inspect(Keyword.put(original, :b, 20), label: "put(:b, 20)")

# Keyword.put_new - only adds if key doesn't exist
IO.inspect(Keyword.put_new(original, :d, 4), label: "put_new(:d, 4)")
IO.inspect(Keyword.put_new(original, :b, 20), label: "put_new(:b, 20) - no change")

# Keyword.delete - removes ALL occurrences of key
IO.inspect(Keyword.delete(original, :b), label: "delete(:b)")

# Keyword.delete_first - removes only first occurrence
multi = [a: 1, a: 2, a: 3]
IO.inspect(Keyword.delete_first(multi, :a), label: "delete_first from [a: 1, a: 2, a: 3]")

# Keyword.pop - removes and returns value
{value, rest} = Keyword.pop(original, :b)
IO.inspect({value, rest}, label: "pop(:b)")

# Keyword.update - update existing value with function
IO.inspect(Keyword.update(original, :a, 0, &(&1 * 10)), label: "update(:a, fn)")

# Keyword.merge - combine keyword lists
other = [c: 30, d: 40]
IO.inspect(Keyword.merge(original, other), label: "merge")

# -----------------------------------------------------------------------------
# Section 5: The Options Pattern
# -----------------------------------------------------------------------------

IO.puts("\n--- The Options Pattern ---")

# Keyword lists are THE standard way to pass options to functions
# This is one of the most important uses of keyword lists!

defmodule Greeter do
  # Options with defaults using Keyword.get
  def greet(name, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "Hello")
    suffix = Keyword.get(opts, :suffix, "!")
    uppercase = Keyword.get(opts, :uppercase, false)

    message = "#{prefix}, #{name}#{suffix}"

    if uppercase do
      String.upcase(message)
    else
      message
    end
  end
end

IO.puts(Greeter.greet("Alice"))
IO.puts(Greeter.greet("Bob", prefix: "Hi"))
IO.puts(Greeter.greet("Charlie", prefix: "Hey", suffix: "!!!"))
IO.puts(Greeter.greet("Dave", uppercase: true))
IO.puts(Greeter.greet("Eve", prefix: "Greetings", suffix: ".", uppercase: true))

# When keyword list is the LAST argument, brackets are optional!
# These are equivalent:
IO.puts(Greeter.greet("Test", [prefix: "A", suffix: "B"]))
IO.puts(Greeter.greet("Test", prefix: "A", suffix: "B"))

# -----------------------------------------------------------------------------
# Section 6: Pattern Matching with Keyword Lists
# -----------------------------------------------------------------------------

IO.puts("\n--- Pattern Matching with Keyword Lists ---")

# Basic pattern matching (order matters!)
[a: x, b: y] = [a: 1, b: 2]
IO.inspect({x, y}, label: "[a: x, b: y] = [a: 1, b: 2]")

# Using the cons operator
[first | rest] = [a: 1, b: 2, c: 3]
IO.inspect(first, label: "First element")
IO.inspect(rest, label: "Rest")

# Matching specific keys at the start
[name: name | _rest] = [name: "Alice", age: 30, city: "NYC"]
IO.inspect(name, label: "Extracted name")

# This won't work because order matters:
# [age: age | _] = [name: "Alice", age: 30]  # No match!

# For flexible matching, use Keyword functions instead
opts = [name: "Alice", age: 30, city: "NYC"]
name = Keyword.fetch!(opts, :name)
IO.inspect(name, label: "Flexible extraction")

# -----------------------------------------------------------------------------
# Section 7: Keyword Lists in Practice
# -----------------------------------------------------------------------------

IO.puts("\n--- Keyword Lists in Practice ---")

# Example 1: Database query options
defmodule Query do
  def find(table, opts \\ []) do
    where = Keyword.get(opts, :where, [])
    order = Keyword.get(opts, :order, :asc)
    limit = Keyword.get(opts, :limit, 100)

    "SELECT * FROM #{table} " <>
    "WHERE #{inspect(where)} " <>
    "ORDER BY #{order} " <>
    "LIMIT #{limit}"
  end
end

IO.puts(Query.find("users"))
IO.puts(Query.find("users", where: [active: true], limit: 10))
IO.puts(Query.find("posts", order: :desc, where: [published: true]))

# Example 2: HTTP request options
defmodule HttpClient do
  def get(url, opts \\ []) do
    headers = Keyword.get(opts, :headers, [])
    timeout = Keyword.get(opts, :timeout, 5000)
    follow_redirects = Keyword.get(opts, :follow_redirects, true)

    %{
      url: url,
      headers: headers,
      timeout: timeout,
      follow_redirects: follow_redirects
    }
  end
end

IO.inspect(HttpClient.get("https://example.com"))
IO.inspect(HttpClient.get("https://api.com",
  headers: [authorization: "Bearer token"],
  timeout: 10000
))

# Example 3: Validation with Keyword.validate
# Available in Elixir 1.13+
valid_keys = [:name, :age, :email]
opts = [name: "Alice", age: 30]

case Keyword.validate(opts, valid_keys) do
  {:ok, validated} -> IO.inspect(validated, label: "Valid options")
  {:error, invalid} -> IO.inspect(invalid, label: "Invalid keys")
end

# Invalid options
bad_opts = [name: "Bob", invalid_key: true]
case Keyword.validate(bad_opts, valid_keys) do
  {:ok, validated} -> IO.inspect(validated, label: "Valid")
  {:error, invalid} -> IO.inspect(invalid, label: "Invalid keys found")
end

# -----------------------------------------------------------------------------
# Section 8: Keyword Lists vs Maps
# -----------------------------------------------------------------------------

IO.puts("\n--- Keyword Lists vs Maps ---")

IO.puts("""
When to use Keyword Lists:
  - Options/named arguments to functions
  - When you need duplicate keys
  - When order matters
  - Small number of elements (< 10-20)
  - DSL-like syntax (like Ecto queries)

When to use Maps:
  - Storing data/state
  - When you need fast lookup
  - Large number of elements
  - When keys are not atoms
  - When you need pattern matching on any key

Performance comparison:
  Keyword List: O(n) lookup (linear scan)
  Map: O(log n) for small maps, O(1) for large maps
""")

# Example: Keyword list for options
IO.inspect(String.split("hello world", " ", trim: true), label: "Options example")

# Example: Map for data
user = %{name: "Alice", age: 30}
IO.inspect(user, label: "Data example")

# -----------------------------------------------------------------------------
# Section 9: Special Syntax in Function Calls
# -----------------------------------------------------------------------------

IO.puts("\n--- Special Syntax in Function Calls ---")

# When keyword list is the LAST argument, you can omit brackets

defmodule Demo do
  def example(value, opts) do
    IO.inspect({value, opts}, label: "Received")
  end
end

# All these are equivalent:
Demo.example(42, [{:a, 1}, {:b, 2}])
Demo.example(42, [a: 1, b: 2])
Demo.example(42, a: 1, b: 2)  # Most common style

# Even in pipelines:
"hello"
|> String.split("", trim: true)
|> IO.inspect(label: "Split result")

# With do blocks (these use keyword lists under the hood!)
# if condition, do: true_value, else: false_value
result = if true, do: "yes", else: "no"
IO.inspect(result, label: "If with keyword syntax")

# This is actually:
result = if(true, [do: "yes", else: "no"])
IO.inspect(result, label: "Explicit keyword list")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: Create Keyword Lists
# Difficulty: Easy
#
# Create keyword lists for:
# 1. A person with name, age, and occupation
# 2. HTTP headers with content_type and authorization
# 3. Database config with host, port, and database name
#
# Use the shorthand syntax [key: value]
#
# Your code here:

IO.puts("\nExercise 1: Create keyword lists")

# Exercise 2: Access and Default Values
# Difficulty: Easy
#
# Given the keyword list: config = [host: "localhost", port: 5432]
# 1. Get the host value
# 2. Get the port value
# 3. Get a database value with default "postgres"
# 4. Check if :timeout key exists
#
# Your code here:

IO.puts("\nExercise 2: Access values with defaults")

# Exercise 3: Options Function
# Difficulty: Medium
#
# Create a function format_name/2 that takes a name and options:
# - :style - :full, :first_only, or :initials (default: :full)
# - :uppercase - boolean (default: false)
#
# Examples:
# format_name("John Doe") -> "John Doe"
# format_name("John Doe", style: :first_only) -> "John"
# format_name("John Doe", style: :initials) -> "J.D."
# format_name("John Doe", uppercase: true) -> "JOHN DOE"
#
# defmodule NameFormatter do
#   def format_name(name, opts \\ []) do
#     # Your implementation
#   end
# end
#
# Your code here:

IO.puts("\nExercise 3: Function with options")

# Exercise 4: Merge Configurations
# Difficulty: Medium
#
# Create a function merge_config/2 that merges user config with defaults.
# User config should override defaults.
#
# defaults = [timeout: 5000, retries: 3, verbose: false]
# user_config = [timeout: 10000, verbose: true]
# Result: [timeout: 10000, retries: 3, verbose: true]
#
# Your code here:

IO.puts("\nExercise 4: Merge configurations")

# Exercise 5: Validate Options
# Difficulty: Medium
#
# Create a function that validates options for a hypothetical
# send_email/2 function. Valid options are: :to, :subject, :body, :cc, :bcc
#
# Return {:ok, opts} if all keys are valid
# Return {:error, invalid_keys} if any invalid keys are present
#
# defmodule EmailValidator do
#   @valid_keys [:to, :subject, :body, :cc, :bcc]
#
#   def validate(opts) do
#     # Your implementation
#   end
# end
#
# Your code here:

IO.puts("\nExercise 5: Validate options")

# Exercise 6: Query Builder
# Difficulty: Hard
#
# Create a simple query builder that accepts options:
# - :select - list of fields (default: [:*])
# - :from - table name (required)
# - :where - keyword list of conditions (default: [])
# - :order_by - field to order by (optional)
# - :limit - number of records (optional)
#
# It should return a string like:
# "SELECT id, name FROM users WHERE active = true ORDER BY name LIMIT 10"
#
# defmodule QueryBuilder do
#   def build(opts) do
#     # Your implementation
#   end
# end
#
# Your code here:

IO.puts("\nExercise 6: Query builder")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

1. Keyword lists are lists of {atom, value} tuples:
   - [name: "Alice"] == [{:name, "Alice"}]
   - Ordered and can have duplicate keys
   - O(n) lookup time

2. Accessing values:
   - list[:key] or Keyword.get(list, :key)
   - Keyword.get(list, :key, default)
   - Keyword.fetch(list, :key) -> {:ok, value} | :error

3. The Options Pattern:
   - def func(arg, opts \\\\ [])
   - Brackets optional when last argument
   - Use Keyword.get with defaults

4. When to use keyword lists vs maps:
   - Keyword lists: options, small size, duplicate keys
   - Maps: data storage, fast lookup, large size

5. Common functions:
   - Keyword.get/2,3, Keyword.put/3, Keyword.merge/2
   - Keyword.keys/1, Keyword.values/1
   - Keyword.validate/2 (Elixir 1.13+)

6. Special syntax:
   - Last argument brackets optional
   - do/end blocks use keyword lists

Next: 07_maps.exs - The primary key-value data structure
""")
