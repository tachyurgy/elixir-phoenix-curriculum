# ============================================================================
# Lesson 07: Maps
# ============================================================================
#
# Maps are Elixir's primary key-value data structure. They provide efficient
# lookup and are the go-to choice for storing structured data.
#
# Learning Objectives:
# - Create and manipulate maps
# - Access values safely and efficiently
# - Update maps immutably
# - Work with nested maps
# - Understand maps vs keyword lists
#
# Prerequisites:
# - Lesson 06 (Keyword Lists) completed
#
# ============================================================================

IO.puts("=" |> String.duplicate(60))
IO.puts("Lesson 07: Maps")
IO.puts("=" |> String.duplicate(60))

# -----------------------------------------------------------------------------
# Section 1: Creating Maps
# -----------------------------------------------------------------------------

IO.puts("\n--- Creating Maps ---")

# Maps use %{} syntax
empty = %{}
IO.inspect(empty, label: "Empty map")

# Keys can be any type (but atoms are most common)
atom_keys = %{name: "Alice", age: 30}
string_keys = %{"name" => "Bob", "age" => 25}
mixed_keys = %{:atom => 1, "string" => 2, 42 => 3}
integer_keys = %{1 => "one", 2 => "two", 3 => "three"}

IO.inspect(atom_keys, label: "Atom keys")
IO.inspect(string_keys, label: "String keys")
IO.inspect(mixed_keys, label: "Mixed keys")
IO.inspect(integer_keys, label: "Integer keys")

# Shorthand syntax for atom keys
# %{name: "Alice"} is the same as %{:name => "Alice"}
shorthand = %{name: "Alice", age: 30}
longhand = %{:name => "Alice", :age => 30}
IO.inspect(shorthand == longhand, label: "Shorthand equals longhand")

# Maps with complex values
complex = %{
  name: "Alice",
  scores: [95, 87, 92],
  metadata: %{created: "2024-01-15", active: true}
}
IO.inspect(complex, label: "Complex map")

# -----------------------------------------------------------------------------
# Section 2: Accessing Values
# -----------------------------------------------------------------------------

IO.puts("\n--- Accessing Values ---")

person = %{name: "Charlie", age: 35, city: "Boston"}

# Bracket notation - works with any key type
IO.inspect(person[:name], label: "person[:name]")
IO.inspect(person[:missing], label: "person[:missing]")  # Returns nil

# Dot notation - ONLY for atom keys, raises if missing
IO.inspect(person.name, label: "person.name")
IO.inspect(person.age, label: "person.age")
# person.missing  # Would raise KeyError!

# Map.get with optional default
IO.inspect(Map.get(person, :name), label: "Map.get(:name)")
IO.inspect(Map.get(person, :missing), label: "Map.get(:missing)")
IO.inspect(Map.get(person, :missing, "default"), label: "Map.get with default")

# Map.fetch returns {:ok, value} or :error
IO.inspect(Map.fetch(person, :name), label: "Map.fetch(:name)")
IO.inspect(Map.fetch(person, :missing), label: "Map.fetch(:missing)")

# Map.fetch! raises if key doesn't exist
IO.inspect(Map.fetch!(person, :name), label: "Map.fetch!(:name)")
# Map.fetch!(person, :missing)  # Would raise KeyError!

# Check for key existence
IO.inspect(Map.has_key?(person, :name), label: "has_key?(:name)")
IO.inspect(Map.has_key?(person, :missing), label: "has_key?(:missing)")

# Get all keys or values
IO.inspect(Map.keys(person), label: "Map.keys")
IO.inspect(Map.values(person), label: "Map.values")

# -----------------------------------------------------------------------------
# Section 3: Updating Maps
# -----------------------------------------------------------------------------

IO.puts("\n--- Updating Maps ---")

# Maps are IMMUTABLE - all operations return new maps
original = %{a: 1, b: 2, c: 3}
IO.inspect(original, label: "Original")

# Map.put - add or update a key
IO.inspect(Map.put(original, :d, 4), label: "Map.put(:d, 4)")
IO.inspect(Map.put(original, :a, 100), label: "Map.put(:a, 100)")

# Map.put_new - only adds if key doesn't exist
IO.inspect(Map.put_new(original, :d, 4), label: "Map.put_new(:d, 4)")
IO.inspect(Map.put_new(original, :a, 100), label: "Map.put_new(:a, 100) - no change")

# Update syntax (ONLY for existing keys!)
IO.inspect(%{original | a: 10}, label: "%{original | a: 10}")
IO.inspect(%{original | a: 10, b: 20}, label: "%{original | a: 10, b: 20}")
# %{original | x: 1}  # Would raise KeyError - key must exist!

# Map.update - update with a function
IO.inspect(Map.update(original, :a, 0, &(&1 * 10)), label: "Map.update(:a)")

# Map.update! - raises if key doesn't exist
IO.inspect(Map.update!(original, :a, &(&1 * 10)), label: "Map.update!(:a)")

# Map.delete - remove a key
IO.inspect(Map.delete(original, :b), label: "Map.delete(:b)")
IO.inspect(Map.delete(original, :missing), label: "Map.delete(:missing) - no error")

# Map.pop - remove and return value
{value, rest} = Map.pop(original, :b)
IO.inspect({value, rest}, label: "Map.pop(:b)")

{value, rest} = Map.pop(original, :missing, "default")
IO.inspect({value, rest}, label: "Map.pop(:missing)")

# Map.merge - combine maps (second wins on conflicts)
map1 = %{a: 1, b: 2}
map2 = %{b: 20, c: 30}
IO.inspect(Map.merge(map1, map2), label: "Map.merge")

# Merge with conflict resolution function
merged = Map.merge(map1, map2, fn _key, v1, v2 -> v1 + v2 end)
IO.inspect(merged, label: "Merge with conflict fn")

# -----------------------------------------------------------------------------
# Section 4: Nested Maps
# -----------------------------------------------------------------------------

IO.puts("\n--- Nested Maps ---")

user = %{
  name: "Alice",
  profile: %{
    bio: "Elixir developer",
    social: %{
      twitter: "@alice",
      github: "alice"
    }
  },
  settings: %{
    theme: "dark",
    notifications: true
  }
}

IO.inspect(user, label: "Nested user map")

# Accessing nested values
IO.inspect(user.profile.bio, label: "user.profile.bio")
IO.inspect(user.profile.social.twitter, label: "Deeply nested")

# Safe nested access with get_in
IO.inspect(get_in(user, [:profile, :bio]), label: "get_in bio")
IO.inspect(get_in(user, [:profile, :social, :twitter]), label: "get_in twitter")
IO.inspect(get_in(user, [:profile, :missing, :key]), label: "get_in missing path")

# put_in - update nested value
updated = put_in(user, [:profile, :bio], "Senior Elixir developer")
IO.inspect(updated.profile.bio, label: "After put_in")

# update_in - update with function
updated = update_in(user, [:profile, :bio], &String.upcase/1)
IO.inspect(updated.profile.bio, label: "After update_in")

# pop_in - remove nested value
{value, updated} = pop_in(user, [:settings, :theme])
IO.inspect({value, updated.settings}, label: "After pop_in")

# Using Access for dynamic paths
path = [:profile, :social, :github]
IO.inspect(get_in(user, path), label: "Dynamic path access")

# -----------------------------------------------------------------------------
# Section 5: Pattern Matching with Maps
# -----------------------------------------------------------------------------

IO.puts("\n--- Pattern Matching with Maps ---")

# Maps match if pattern is a SUBSET of the value
user = %{name: "Bob", age: 30, city: "NYC"}

# Match specific keys
%{name: name} = user
IO.inspect(name, label: "Matched name")

# Match multiple keys
%{name: n, age: a} = user
IO.inspect({n, a}, label: "Matched name and age")

# Match with literal values
%{name: "Bob"} = user  # Works!
IO.puts("Pattern %{name: \"Bob\"} matched!")

# This would fail:
# %{name: "Alice"} = user  # MatchError!

# Match in function heads
defmodule UserMatcher do
  def greet(%{name: name, age: age}) when age >= 18 do
    "Hello, #{name}! You are an adult."
  end

  def greet(%{name: name}) do
    "Hi, #{name}!"
  end

  def greet(_) do
    "Hello, stranger!"
  end
end

IO.puts(UserMatcher.greet(%{name: "Alice", age: 25}))
IO.puts(UserMatcher.greet(%{name: "Bob", age: 15}))
IO.puts(UserMatcher.greet(%{name: "Charlie"}))
IO.puts(UserMatcher.greet("not a map"))

# Empty map matches ANY map
%{} = %{a: 1, b: 2}  # Works!
IO.puts("Empty pattern matches any map")

# Matching nested maps
nested = %{user: %{name: "Alice", role: :admin}}
%{user: %{role: role}} = nested
IO.inspect(role, label: "Matched nested role")

# -----------------------------------------------------------------------------
# Section 6: Map Functions
# -----------------------------------------------------------------------------

IO.puts("\n--- Map Functions ---")

map = %{a: 1, b: 2, c: 3, d: 4, e: 5}

# Size
IO.inspect(map_size(map), label: "map_size")
IO.inspect(Map.keys(map) |> length(), label: "Alternative: keys + length")

# Take/drop keys
IO.inspect(Map.take(map, [:a, :c]), label: "Map.take([:a, :c])")
IO.inspect(Map.drop(map, [:a, :c]), label: "Map.drop([:a, :c])")

# Filter/reject
IO.inspect(Map.filter(map, fn {_k, v} -> v > 2 end), label: "Filter v > 2")
IO.inspect(Map.reject(map, fn {_k, v} -> v > 2 end), label: "Reject v > 2")

# Split
{taken, rest} = Map.split(map, [:a, :b])
IO.inspect({taken, rest}, label: "Map.split([:a, :b])")

# Replace (only updates existing keys)
IO.inspect(Map.replace(map, :a, 100), label: "Map.replace(:a, 100)")
IO.inspect(Map.replace(map, :z, 100), label: "Map.replace(:z, 100) - no change")

# From/to list conversions
IO.inspect(Map.to_list(map), label: "Map.to_list")
IO.inspect(Map.new([{:x, 1}, {:y, 2}]), label: "Map.new from list")

# Map.new with transformation
IO.inspect(Map.new(1..3, fn x -> {x, x * x} end), label: "Map.new with fn")

# Equal maps (order doesn't matter)
IO.inspect(%{a: 1, b: 2} == %{b: 2, a: 1}, label: "Order independence")

# -----------------------------------------------------------------------------
# Section 7: Transforming Maps
# -----------------------------------------------------------------------------

IO.puts("\n--- Transforming Maps ---")

scores = %{alice: 85, bob: 92, charlie: 78}

# Using Enum with maps (iterates as {key, value} tuples)
doubled = Enum.map(scores, fn {name, score} -> {name, score * 2} end) |> Map.new()
IO.inspect(doubled, label: "Doubled scores")

# Map.map - transform values (keeps keys)
# Note: Map.map returns a map, not a list!
graded = Map.new(scores, fn {name, score} ->
  grade = cond do
    score >= 90 -> :A
    score >= 80 -> :B
    score >= 70 -> :C
    true -> :F
  end
  {name, grade}
end)
IO.inspect(graded, label: "Grades")

# For comprehension with maps
increased = for {name, score} <- scores, into: %{} do
  {name, score + 5}
end
IO.inspect(increased, label: "Increased by 5")

# Filter with for comprehension
passing = for {name, score} <- scores, score >= 80, into: %{} do
  {name, score}
end
IO.inspect(passing, label: "Passing scores")

# Reduce with maps
total = Enum.reduce(scores, 0, fn {_name, score}, acc -> acc + score end)
IO.inspect(total, label: "Total of all scores")

# -----------------------------------------------------------------------------
# Section 8: Structs Preview
# -----------------------------------------------------------------------------

IO.puts("\n--- Structs Preview ---")

# Structs are specialized maps with compile-time guarantees
# (Covered in detail in the next lesson)

defmodule Person do
  defstruct [:name, :age, email: "unknown@example.com"]
end

alice = %Person{name: "Alice", age: 30}
IO.inspect(alice, label: "Struct (is a map)")
IO.inspect(is_map(alice), label: "is_map(struct)")
IO.inspect(alice.__struct__, label: "struct module")

# Structs are maps with a __struct__ key
IO.inspect(Map.keys(alice), label: "Struct keys")

# -----------------------------------------------------------------------------
# Section 9: Common Patterns
# -----------------------------------------------------------------------------

IO.puts("\n--- Common Patterns ---")

# Pattern 1: Config with defaults
defmodule Config do
  @defaults %{
    timeout: 5000,
    retries: 3,
    verbose: false
  }

  def new(overrides \\ %{}) do
    Map.merge(@defaults, overrides)
  end
end

IO.inspect(Config.new(), label: "Default config")
IO.inspect(Config.new(%{timeout: 10000}), label: "Custom timeout")

# Pattern 2: Building maps incrementally
defmodule Builder do
  def build_user(name, opts \\ []) do
    %{name: name}
    |> maybe_add(:age, Keyword.get(opts, :age))
    |> maybe_add(:email, Keyword.get(opts, :email))
  end

  defp maybe_add(map, _key, nil), do: map
  defp maybe_add(map, key, value), do: Map.put(map, key, value)
end

IO.inspect(Builder.build_user("Alice"), label: "Basic user")
IO.inspect(Builder.build_user("Bob", age: 30), label: "User with age")
IO.inspect(Builder.build_user("Charlie", age: 25, email: "c@test.com"), label: "Full user")

# Pattern 3: Counting occurrences
words = ~w(apple banana apple cherry banana apple)
counts = Enum.reduce(words, %{}, fn word, acc ->
  Map.update(acc, word, 1, &(&1 + 1))
end)
IO.inspect(counts, label: "Word counts")

# Pattern 4: Grouping
people = [
  %{name: "Alice", dept: :eng},
  %{name: "Bob", dept: :sales},
  %{name: "Charlie", dept: :eng}
]
by_dept = Enum.group_by(people, & &1.dept)
IO.inspect(by_dept, label: "Grouped by department")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: Create and Access
# Difficulty: Easy
#
# Create a map representing a book with:
# - title, author, year, pages, genres (list)
#
# Then access:
# 1. The title using dot notation
# 2. The year using bracket notation
# 3. A non-existent :isbn key with default "N/A"
#
# Your code here:

IO.puts("\nExercise 1: Create and access a book map")

# Exercise 2: Update Operations
# Difficulty: Easy
#
# Given: product = %{name: "Widget", price: 100, stock: 50}
#
# Create new maps that:
# 1. Update the price to 120
# 2. Add a :category key with value "Electronics"
# 3. Remove the :stock key
# 4. Double the price using Map.update
#
# Your code here:

IO.puts("\nExercise 2: Update a product map")

# Exercise 3: Nested Access
# Difficulty: Medium
#
# Given:
# company = %{
#   name: "TechCorp",
#   address: %{
#     street: "123 Main St",
#     city: "San Francisco",
#     country: %{name: "USA", code: "US"}
#   },
#   employees: [%{name: "Alice"}, %{name: "Bob"}]
# }
#
# Use get_in, put_in, and update_in to:
# 1. Get the country code
# 2. Change the city to "Oakland"
# 3. Uppercase the company name
#
# Your code here:

IO.puts("\nExercise 3: Nested map operations")

# Exercise 4: Pattern Matching
# Difficulty: Medium
#
# Create a function describe_user/1 that pattern matches maps:
# - %{role: :admin, name: name} -> "Admin: {name}"
# - %{role: :user, name: name, verified: true} -> "Verified user: {name}"
# - %{role: :user, name: name} -> "User: {name}"
# - %{name: name} -> "Guest: {name}"
# - _ -> "Unknown"
#
# Your code here:

IO.puts("\nExercise 4: Pattern matching function")

# Exercise 5: Transform Maps
# Difficulty: Medium
#
# Given: inventory = %{apples: 50, bananas: 30, oranges: 45, grapes: 20}
#
# 1. Create a new map with all quantities doubled
# 2. Filter to only items with quantity > 35
# 3. Calculate the total quantity of all items
# 4. Find the item with the highest quantity
#
# Your code here:

IO.puts("\nExercise 5: Transform inventory map")

# Exercise 6: Word Frequency
# Difficulty: Hard
#
# Create a function word_frequency/1 that:
# - Takes a string of text
# - Returns a map of word => count
# - Words should be lowercase
# - Ignore punctuation
#
# Example:
# word_frequency("Hello world! Hello Elixir.")
# => %{"hello" => 2, "world" => 1, "elixir" => 1}
#
# Your code here:

IO.puts("\nExercise 6: Word frequency counter")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

1. Maps are key-value stores with fast lookup:
   - %{key: value} for atom keys
   - %{"key" => value} for other key types

2. Accessing values:
   - map.key (atom keys only, raises if missing)
   - map[:key] (returns nil if missing)
   - Map.get(map, :key, default)

3. Updating maps (immutable):
   - Map.put/3 - add or update
   - %{map | key: value} - update existing only
   - Map.merge/2 - combine maps

4. Nested access:
   - get_in(map, [:path, :to, :value])
   - put_in(map, [:path], value)
   - update_in(map, [:path], fn)

5. Pattern matching:
   - %{key: value} = map - extract values
   - Pattern matches subsets
   - Great in function heads

6. Common operations:
   - Map.keys/1, Map.values/1
   - Map.take/2, Map.drop/2
   - Map.filter/2, Map.reject/2

Next: 08_structs.exs - Structured maps with compile-time guarantees
""")
