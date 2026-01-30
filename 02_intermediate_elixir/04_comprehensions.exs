# ============================================================================
# LESSON: For Comprehensions - Elegant Collection Transformations
# ============================================================================
#
# Comprehensions provide a concise syntax for creating new collections
# from existing enumerables. They combine mapping, filtering, and nested
# iteration into a single, readable expression.
#
# The syntax: for pattern <- enumerable, do: expression
#
# ============================================================================

# ============================================================================
# LEARNING OBJECTIVES
# ============================================================================
#
# By the end of this lesson, you will be able to:
#
# 1. Use basic for comprehensions to transform collections
# 2. Apply filters to select specific elements
# 3. Work with multiple generators for nested iteration
# 4. Use the :into option to produce different collection types
# 5. Understand bitstring generators for binary manipulation
# 6. Choose between comprehensions, Enum, and Stream
#
# ============================================================================

# ============================================================================
# PREREQUISITES
# ============================================================================
#
# Before starting this lesson, you should understand:
#
# - Enum module basics (map, filter)
# - Pattern matching
# - Lists, maps, and other collection types
# - Anonymous functions
#
# ============================================================================

IO.puts("""
============================================================================
SECTION 1: Basic For Comprehensions
============================================================================
""")

# The simplest form of a comprehension transforms each element
# Syntax: for pattern <- enumerable, do: expression

# Basic mapping - double each number
numbers = [1, 2, 3, 4, 5]
doubled = for n <- numbers, do: n * 2
IO.inspect(doubled, label: "Doubled numbers")

# Equivalent Enum.map
doubled_enum = Enum.map(numbers, &(&1 * 2))
IO.inspect(doubled_enum, label: "Same with Enum.map")

# Transform strings
names = ["alice", "bob", "charlie"]
capitalized = for name <- names, do: String.capitalize(name)
IO.inspect(capitalized, label: "Capitalized names")

# Using pattern matching in the generator
tuples = [{:ok, 1}, {:ok, 2}, {:ok, 3}]
values = for {:ok, value} <- tuples, do: value
IO.inspect(values, label: "Extracted values from :ok tuples")

# Mixed tuples - pattern match filters out non-matching
mixed = [{:ok, 1}, {:error, "failed"}, {:ok, 2}, {:ok, 3}]
ok_values = for {:ok, value} <- mixed, do: value
IO.inspect(ok_values, label: "Only :ok values (others filtered)")

# Works with ranges
squares = for n <- 1..10, do: n * n
IO.inspect(squares, label: "Squares of 1-10")

# Pattern matching with maps
users = [
  %{name: "Alice", age: 30},
  %{name: "Bob", age: 25},
  %{name: "Charlie", age: 35}
]
names = for %{name: name} <- users, do: name
IO.inspect(names, label: "Extracted names from maps")

# Creating tuples from a list
indexed = for {item, i} <- Enum.with_index(["a", "b", "c"]), do: {i, item}
IO.inspect(indexed, label: "Indexed items")

IO.puts("""

============================================================================
SECTION 2: Filters in Comprehensions
============================================================================
""")

# Filters are conditions that select which elements to process
# Syntax: for pattern <- enumerable, filter_condition, do: expression

numbers = 1..20

# Filter even numbers
evens = for n <- numbers, rem(n, 2) == 0, do: n
IO.inspect(evens, label: "Even numbers")

# Multiple filters (all must be true)
multiples_6 = for n <- numbers, rem(n, 2) == 0, rem(n, 3) == 0, do: n
IO.inspect(multiples_6, label: "Divisible by both 2 and 3")

# Filter and transform
even_squares = for n <- numbers, rem(n, 2) == 0, do: n * n
IO.inspect(even_squares, label: "Squares of even numbers")

# Filter with string functions
words = ["apple", "apricot", "banana", "avocado", "blueberry"]
a_words = for word <- words, String.starts_with?(word, "a"), do: String.upcase(word)
IO.inspect(a_words, label: "Words starting with 'a' (uppercased)")

# Filter with complex conditions
products = [
  %{name: "Laptop", price: 999, category: :electronics},
  %{name: "Book", price: 20, category: :media},
  %{name: "Phone", price: 699, category: :electronics},
  %{name: "Headphones", price: 199, category: :electronics}
]

affordable_electronics = for p <- products,
                            p.category == :electronics,
                            p.price < 500,
                            do: p.name
IO.inspect(affordable_electronics, label: "Affordable electronics")

# Using variables defined in the generator in the filter
data = [{1, "odd"}, {2, "even"}, {3, "odd"}, {4, "even"}]
even_items = for {n, label} <- data, rem(n, 2) == 0, do: {n, label}
IO.inspect(even_items, label: "Even items from tuples")

# Filter can use pattern match results
events = [
  {:login, "user1", ~U[2024-01-15 10:00:00Z]},
  {:logout, "user1", ~U[2024-01-15 12:00:00Z]},
  {:login, "user2", ~U[2024-01-15 11:00:00Z]},
  {:purchase, "user1", ~U[2024-01-15 11:30:00Z]}
]

logins = for {:login, user, time} <- events, do: {user, time}
IO.inspect(logins, label: "Login events only")

IO.puts("""

============================================================================
SECTION 3: Multiple Generators - Nested Iteration
============================================================================
""")

# Multiple generators create a cartesian product (all combinations)
# Syntax: for x <- list1, y <- list2, do: {x, y}

letters = ["a", "b", "c"]
numbers = [1, 2, 3]

# All combinations
combinations = for l <- letters, n <- numbers, do: {l, n}
IO.inspect(combinations, label: "All letter-number combinations")

# Practical: Create coordinate pairs
rows = 1..3
cols = [:a, :b, :c]
grid = for r <- rows, c <- cols, do: {c, r}
IO.inspect(grid, label: "Grid coordinates")

# Multiplication table
mult_table = for x <- 1..3, y <- 1..3, do: {x, y, x * y}
IO.puts("\nMultiplication table:")
Enum.each(mult_table, fn {x, y, product} ->
  IO.puts("  #{x} x #{y} = #{product}")
end)

# Nested iteration with filter
# Find all pairs that sum to 10
pairs_sum_10 = for x <- 1..9, y <- 1..9, x + y == 10, x <= y, do: {x, y}
IO.inspect(pairs_sum_10, label: "\nPairs that sum to 10 (no duplicates)")

# Later generators can depend on earlier ones
triangular_pairs = for x <- 1..4, y <- 1..x, do: {x, y}
IO.inspect(triangular_pairs, label: "Triangular pairs (y <= x)")

# Practical: Team matchups (each team plays every other team once)
teams = [:alpha, :beta, :gamma, :delta]
matchups = for t1 <- teams, t2 <- teams, t1 < t2, do: {t1, t2}
IO.inspect(matchups, label: "Unique team matchups")

# Three generators - RGB color combinations
colors = for r <- [0, 128, 255],
             g <- [0, 128, 255],
             b <- [0, 128, 255],
             do: {r, g, b}
IO.puts("\nRGB combinations: #{length(colors)} total")
IO.inspect(Enum.take(colors, 5), label: "First 5 colors")

# Flatten nested structure
nested = [[1, 2], [3, 4], [5, 6]]
flattened = for list <- nested, item <- list, do: item
IO.inspect(flattened, label: "Flattened nested list")

IO.puts("""

============================================================================
SECTION 4: The :into Option - Different Output Types
============================================================================
""")

# By default, comprehensions return a list.
# The :into option lets you specify a different collectable.
# Syntax: for pattern <- enumerable, into: collectable, do: expression

# Into a map
names = ["alice", "bob", "charlie"]
name_lengths = for name <- names, into: %{}, do: {name, String.length(name)}
IO.inspect(name_lengths, label: "Name lengths as map")

# Transform map values
prices = %{apple: 1.50, banana: 0.75, cherry: 2.00}
with_tax = for {fruit, price} <- prices, into: %{}, do: {fruit, Float.round(price * 1.08, 2)}
IO.inspect(with_tax, label: "Prices with tax (map)")

# Into a string (binary)
chars = for c <- ?a..?e, into: "", do: <<c>>
IO.inspect(chars, label: "Characters as string")

# Into an existing map (merge/update)
base_config = %{debug: false, timeout: 30}
overrides = [debug: true, port: 4000]
final_config = for {key, value} <- overrides, into: base_config, do: {key, value}
IO.inspect(final_config, label: "Merged config")

# Into a MapSet
numbers = [1, 2, 2, 3, 3, 3, 4, 4, 4, 4]
unique_doubled = for n <- numbers, into: MapSet.new(), do: n * 2
IO.inspect(unique_doubled, label: "Unique doubled as MapSet")

# Practical: Create lookup map from list
users = [
  %{id: 1, name: "Alice"},
  %{id: 2, name: "Bob"},
  %{id: 3, name: "Charlie"}
]
users_by_id = for user <- users, into: %{}, do: {user.id, user}
IO.inspect(users_by_id, label: "Users indexed by ID")

# Into keyword list (note: creates list of tuples)
items = ["apple", "banana", "cherry"]
keyword = for item <- items, do: {String.to_atom(item), String.length(item)}
IO.inspect(keyword, label: "As keyword-like list")

# Practical: Invert a map
original = %{a: 1, b: 2, c: 3}
inverted = for {k, v} <- original, into: %{}, do: {v, k}
IO.inspect(inverted, label: "Inverted map")

# Filter and transform into map
scores = [
  {"Alice", 95},
  {"Bob", 42},
  {"Charlie", 88},
  {"Diana", 35}
]
passing = for {name, score} <- scores, score >= 60, into: %{}, do: {name, score}
IO.inspect(passing, label: "Passing scores as map")

IO.puts("""

============================================================================
SECTION 5: Bitstring Generators
============================================================================
""")

# Comprehensions can iterate over binaries using bitstring generators
# Syntax: for <<pattern <- binary>>, do: expression

# Extract bytes from a binary
binary = <<72, 101, 108, 108, 111>>  # "Hello"
bytes = for <<byte <- binary>>, do: byte
IO.inspect(bytes, label: "Bytes from binary")

# Convert bytes to characters
chars = for <<byte <- binary>>, do: <<byte>>
IO.inspect(chars, label: "Bytes as characters")

# Extract specific bit patterns
# Get each nibble (4 bits) from bytes
nibbles = for <<nibble::4 <- <<0xAB, 0xCD>>>>, do: nibble
IO.inspect(nibbles, label: "Nibbles (4-bit values)")

# Parse fixed-width records
# Imagine binary data with 2-byte records
data = <<1, 100, 2, 150, 3, 75>>
records = for <<id::8, value::8 <- data>>, do: %{id: id, value: value}
IO.inspect(records, label: "Parsed binary records")

# Filter bytes
ascii_binary = "Hello, World! 123"
letters_only = for <<c <- ascii_binary>>, c in ?a..?z or c in ?A..?Z, into: "", do: <<c>>
IO.inspect(letters_only, label: "Letters only from string")

# Extract 16-bit integers from binary (big-endian)
int_data = <<0, 1, 0, 2, 1, 0>>  # [1, 2, 256]
integers = for <<n::16-big <- int_data>>, do: n
IO.inspect(integers, label: "16-bit big-endian integers")

# Create binary from list
byte_list = [72, 101, 108, 108, 111]
binary_result = for b <- byte_list, into: <<>>, do: <<b>>
IO.inspect(binary_result, label: "List to binary")

# Practical: Simple XOR encryption
key = 42
message = "Secret"
encrypted = for <<byte <- message>>, into: <<>>, do: <<bxor(byte, key)>>
decrypted = for <<byte <- encrypted>>, into: <<>>, do: <<bxor(byte, key)>>
IO.inspect(encrypted, label: "Encrypted (binary)")
IO.inspect(decrypted, label: "Decrypted")

# Extract Unicode codepoints
string = "Hello"
codepoints = for <<cp::utf8 <- string>>, do: cp
IO.inspect(codepoints, label: "Unicode codepoints")

IO.puts("""

============================================================================
SECTION 6: Practical Examples
============================================================================
""")

# Example 1: Generate HTML options
IO.puts("Example 1: HTML option tags")
options = [
  {1, "Option One"},
  {2, "Option Two"},
  {3, "Option Three"}
]
html = for {value, label} <- options, into: "" do
  ~s(<option value="#{value}">#{label}</option>\n)
end
IO.puts(html)

# Example 2: Matrix operations
IO.puts("Example 2: Matrix transpose")
matrix = [
  [1, 2, 3],
  [4, 5, 6],
  [7, 8, 9]
]
# Transpose by creating new rows from columns
transposed = for col <- 0..2 do
  for row <- matrix, do: Enum.at(row, col)
end
IO.inspect(matrix, label: "Original")
IO.inspect(transposed, label: "Transposed")

# Example 3: Parse query string
IO.puts("\nExample 3: Query string parsing")
query = "name=Alice&age=30&city=NYC"
params = for pair <- String.split(query, "&"),
             [key, value] = String.split(pair, "="),
             into: %{} do
  {key, value}
end
IO.inspect(params, label: "Parsed params")

# Example 4: Generate test data
IO.puts("\nExample 4: Test data generation")
test_users = for id <- 1..3,
                 status <- [:active, :inactive],
                 do: %{
                   id: id,
                   name: "User#{id}",
                   email: "user#{id}@example.com",
                   status: status
                 }
IO.inspect(test_users, label: "Generated test users")

# Example 5: Validate and transform data
IO.puts("\nExample 5: Data validation pipeline")
raw_data = [
  %{name: "Alice", email: "alice@example.com", age: 30},
  %{name: "", email: "bob@example.com", age: 25},        # Invalid: empty name
  %{name: "Charlie", email: "invalid-email", age: 35},   # Invalid: bad email
  %{name: "Diana", email: "diana@example.com", age: 28}
]

valid_records = for record <- raw_data,
                    String.length(record.name) > 0,
                    String.contains?(record.email, "@"),
                    do: %{
                      name: String.upcase(record.name),
                      email: String.downcase(record.email),
                      age: record.age
                    }
IO.inspect(valid_records, label: "Validated and transformed")

# Example 6: Pythagorean triples
IO.puts("\nExample 6: Pythagorean triples up to 20")
triples = for a <- 1..20,
              b <- a..20,
              c <- b..20,
              a*a + b*b == c*c,
              do: {a, b, c}
IO.inspect(triples, label: "Pythagorean triples")

IO.puts("""

============================================================================
SECTION 7: Comprehensions vs Enum vs Stream
============================================================================
""")

IO.puts("""
WHEN TO USE COMPREHENSIONS:
---------------------------
1. Simple mappings and filters
2. Nested iteration (cartesian products)
3. Creating maps or other collectables
4. Pattern matching during iteration
5. Readable, declarative code

WHEN TO USE ENUM:
-----------------
1. Complex transformations requiring multiple steps
2. Reductions (folding to single value)
3. When you need specific Enum functions (group_by, frequencies)
4. Chaining with pipe operator

WHEN TO USE STREAM:
-------------------
1. Large or infinite data
2. Memory efficiency is critical
3. Early termination is needed
4. Composing many operations before execution
""")

# Comparison examples
numbers = 1..10

# Comprehension: Filter and transform
comp_result = for n <- numbers, rem(n, 2) == 0, do: n * n
IO.inspect(comp_result, label: "Comprehension")

# Enum: Same operation
enum_result = numbers |> Enum.filter(&(rem(&1, 2) == 0)) |> Enum.map(&(&1 * &1))
IO.inspect(enum_result, label: "Enum")

# Stream: Same operation (lazy)
stream_result = numbers
                |> Stream.filter(&(rem(&1, 2) == 0))
                |> Stream.map(&(&1 * &1))
                |> Enum.to_list()
IO.inspect(stream_result, label: "Stream")

IO.puts("\nAll produce the same result!")

# When comprehensions shine: multiple generators
IO.puts("\nComprehensions excel at cartesian products:")
comp_pairs = for x <- 1..3, y <- 1..3, do: {x, y}
# Enum equivalent is much more verbose:
enum_pairs = Enum.flat_map(1..3, fn x ->
  Enum.map(1..3, fn y -> {x, y} end)
end)
IO.puts("Comprehension: for x <- 1..3, y <- 1..3, do: {x, y}")
IO.puts("Enum: Enum.flat_map(1..3, fn x -> Enum.map(1..3, fn y -> {x, y} end) end)")
IO.puts("Results match: #{comp_pairs == enum_pairs}")

IO.puts("""

============================================================================
SUMMARY
============================================================================

For Comprehensions - Key Concepts:

1. Basic Syntax
   for pattern <- enumerable, do: expression
   - Iterates and transforms each element
   - Returns a list by default

2. Filters
   for pattern <- enumerable, condition, do: expression
   - Multiple filters act as AND conditions
   - Pattern matching in generator acts as filter

3. Multiple Generators
   for x <- list1, y <- list2, do: {x, y}
   - Creates cartesian product (all combinations)
   - Later generators can depend on earlier values
   - Filters can reference any generator variable

4. The :into Option
   for pattern <- enumerable, into: collectable, do: expression
   - Output to maps, strings, MapSets, etc.
   - Collect results into existing structures

5. Bitstring Generators
   for <<pattern <- binary>>, do: expression
   - Iterate over binary data
   - Extract specific bit patterns
   - Build binaries with into: <<>>

Best Practices:
- Use comprehensions for simple, readable transformations
- Choose Enum for complex pipelines
- Use Stream for large data
- Prefer pattern matching in generators for filtering

============================================================================
EXERCISES
============================================================================
""")

IO.puts("""
Exercise 1 (Easy): Square Even Numbers
--------------------------------------
Using a comprehension, square all even numbers from 1 to 10.

# Expected: [4, 16, 36, 64, 100]

# Your solution:
# result = for n <- 1..10, ..., do: ...
""")

# Solution:
result = for n <- 1..10, rem(n, 2) == 0, do: n * n
IO.inspect(result, label: "Exercise 1 Solution")

IO.puts("""

Exercise 2 (Easy): Create a Lookup Map
--------------------------------------
Given a list of tuples, create a map using a comprehension.

data = [{"a", 1}, {"b", 2}, {"c", 3}]
# Expected: %{"a" => 1, "b" => 2, "c" => 3}

# Your solution:
# result = for ... , into: %{}, do: ...
""")

# Solution:
data = [{"a", 1}, {"b", 2}, {"c", 3}]
result = for {k, v} <- data, into: %{}, do: {k, v}
IO.inspect(result, label: "Exercise 2 Solution")

IO.puts("""

Exercise 3 (Medium): Coordinate Grid with Labels
-------------------------------------------------
Create a list of coordinate maps for a 3x3 grid.
Each coordinate should have row (1-3), column (A-C), and a label.

# Expected: [
#   %{row: 1, col: "A", label: "A1"},
#   %{row: 1, col: "B", label: "B1"},
#   ...
#   %{row: 3, col: "C", label: "C3"}
# ]

# Your solution:
# grid = for r <- 1..3, c <- ["A", "B", "C"], do: ...
""")

# Solution:
grid = for r <- 1..3, c <- ["A", "B", "C"] do
  %{row: r, col: c, label: "#{c}#{r}"}
end
IO.inspect(grid, label: "Exercise 3 Solution")

IO.puts("""

Exercise 4 (Medium): Filter and Group
-------------------------------------
Given a list of products, use a comprehension to create a map
where the key is the category and the value is a list of
product names in that category (only products priced under $50).

products = [
  %{name: "Laptop", price: 999, category: :electronics},
  %{name: "Mouse", price: 29, category: :electronics},
  %{name: "Book", price: 15, category: :media},
  %{name: "Headphones", price: 199, category: :electronics},
  %{name: "Movie", price: 20, category: :media},
  %{name: "USB Cable", price: 10, category: :electronics}
]

# Expected: %{electronics: ["Mouse", "USB Cable"], media: ["Book", "Movie"]}

Hint: You might need Enum.group_by in combination with a comprehension,
or use multiple comprehension steps.

# Your solution:
""")

# Solution:
products = [
  %{name: "Laptop", price: 999, category: :electronics},
  %{name: "Mouse", price: 29, category: :electronics},
  %{name: "Book", price: 15, category: :media},
  %{name: "Headphones", price: 199, category: :electronics},
  %{name: "Movie", price: 20, category: :media},
  %{name: "USB Cable", price: 10, category: :electronics}
]

# Filter first, then group
affordable = for p <- products, p.price < 50, do: p
grouped = Enum.group_by(affordable, & &1.category, & &1.name)
IO.inspect(grouped, label: "Exercise 4 Solution")

IO.puts("""

Exercise 5 (Hard): All Possible Dice Rolls
------------------------------------------
Generate all possible outcomes when rolling two six-sided dice.
For each outcome, include the two dice values and their sum.
Then filter to only show outcomes where the sum is 7 or 11 (winning rolls in craps).

# Expected: [
#   %{die1: 1, die2: 6, sum: 7},
#   %{die1: 2, die2: 5, sum: 7},
#   ...
#   %{die1: 5, die2: 6, sum: 11},
#   %{die1: 6, die2: 5, sum: 11}
# ]

# Your solution:
""")

# Solution:
dice = 1..6
winning_rolls = for d1 <- dice, d2 <- dice,
                    sum = d1 + d2,
                    sum == 7 or sum == 11,
                    do: %{die1: d1, die2: d2, sum: sum}
IO.inspect(winning_rolls, label: "Exercise 5 Solution")

IO.puts("""

Exercise 6 (Hard): Binary Protocol Parser
-----------------------------------------
Parse a binary message format where each record is 5 bytes:
- 1 byte: message type (1=text, 2=number, 3=status)
- 2 bytes: message ID (16-bit big-endian)
- 2 bytes: value (16-bit big-endian for numbers, ignored for others)

Binary data (hex): 01 00 01 00 00,  02 00 02 00 64,  03 00 03 00 00
Which represents:
- Type 1 (text), ID 1, value ignored
- Type 2 (number), ID 2, value 100
- Type 3 (status), ID 3, value ignored

Parse this into a list of maps with type, id, and value (for type 2 only).

binary_data = <<1, 0, 1, 0, 0, 2, 0, 2, 0, 100, 3, 0, 3, 0, 0>>

# Expected: [
#   %{type: :text, id: 1},
#   %{type: :number, id: 2, value: 100},
#   %{type: :status, id: 3}
# ]

# Your solution:
""")

# Solution:
binary_data = <<1, 0, 1, 0, 0, 2, 0, 2, 0, 100, 3, 0, 3, 0, 0>>

records = for <<type::8, id::16-big, value::16-big <- binary_data>> do
  type_atom = case type do
    1 -> :text
    2 -> :number
    3 -> :status
  end

  base = %{type: type_atom, id: id}
  if type == 2, do: Map.put(base, :value, value), else: base
end

IO.inspect(records, label: "Exercise 6 Solution")

IO.puts("""

============================================================================
CONGRATULATIONS!
============================================================================

You've mastered Elixir for comprehensions! You now can:

- Transform collections with elegant syntax
- Filter elements using conditions
- Create cartesian products with multiple generators
- Output to different collection types with :into
- Parse binary data with bitstring generators

Comprehensions are a powerful tool in your Elixir toolkit,
enabling readable and declarative data transformations.

You've completed Section 2: Intermediate Elixir!
Topics covered:
- Enum Basics (map, filter, reduce, each, find)
- Advanced Enum (group_by, frequencies, zip, chunk_every, flat_map)
- Streams (lazy evaluation, infinite sequences)
- For Comprehensions (generators, filters, :into)

============================================================================
""")
