# ============================================================================
# LESSON: Enum Basics - Working with Collections in Elixir
# ============================================================================
#
# The Enum module is one of the most frequently used modules in Elixir.
# It provides a rich set of functions for working with enumerables -
# data structures that can be iterated over, such as lists, maps, and ranges.
#
# ============================================================================

# ============================================================================
# LEARNING OBJECTIVES
# ============================================================================
#
# By the end of this lesson, you will be able to:
#
# 1. Transform collections using Enum.map/2
# 2. Filter elements with Enum.filter/2
# 3. Reduce collections to single values with Enum.reduce/2,3
# 4. Iterate with side effects using Enum.each/2
# 5. Search collections with Enum.find/2,3
# 6. Combine these functions to solve real-world problems
#
# ============================================================================

# ============================================================================
# PREREQUISITES
# ============================================================================
#
# Before starting this lesson, you should understand:
#
# - Basic Elixir data types (lists, maps, tuples)
# - Anonymous functions and the capture operator (&)
# - Pattern matching basics
# - Pipe operator (|>)
#
# ============================================================================

IO.puts("""
============================================================================
SECTION 1: Introduction to Enumerables
============================================================================
""")

# An enumerable is any data structure that implements the Enumerable protocol.
# The most common enumerables in Elixir are:

list = [1, 2, 3, 4, 5]
range = 1..5
map = %{a: 1, b: 2, c: 3}

IO.puts("Common enumerable types:")
IO.inspect(list, label: "List")
IO.inspect(range, label: "Range")
IO.inspect(map, label: "Map")

# All of these can be used with Enum functions!
IO.puts("\nCounting elements in each:")
IO.puts("List count: #{Enum.count(list)}")
IO.puts("Range count: #{Enum.count(range)}")
IO.puts("Map count: #{Enum.count(map)}")

IO.puts("""

============================================================================
SECTION 2: Enum.map/2 - Transforming Collections
============================================================================
""")

# Enum.map/2 applies a function to each element and returns a new list
# with the transformed values.
#
# Syntax: Enum.map(enumerable, function)

numbers = [1, 2, 3, 4, 5]

# Double each number
doubled = Enum.map(numbers, fn x -> x * 2 end)
IO.inspect(doubled, label: "Doubled")

# Using the capture operator for shorter syntax
squared = Enum.map(numbers, &(&1 * &1))
IO.inspect(squared, label: "Squared")

# Transform strings
names = ["alice", "bob", "charlie"]
capitalized = Enum.map(names, &String.capitalize/1)
IO.inspect(capitalized, label: "Capitalized names")

# Working with maps - map returns a list of transformed key-value tuples
prices = %{apple: 1.50, banana: 0.75, orange: 2.00}
with_tax = Enum.map(prices, fn {fruit, price} -> {fruit, price * 1.08} end)
IO.inspect(with_tax, label: "Prices with 8% tax")

# Chaining transformations with the pipe operator
result = [1, 2, 3, 4, 5]
         |> Enum.map(&(&1 * 2))      # [2, 4, 6, 8, 10]
         |> Enum.map(&(&1 + 1))      # [3, 5, 7, 9, 11]

IO.inspect(result, label: "Chained transformations")

# Practical example: Processing user data
users = [
  %{name: "Alice", age: 30},
  %{name: "Bob", age: 25},
  %{name: "Charlie", age: 35}
]

user_summaries = Enum.map(users, fn user ->
  "#{user.name} is #{user.age} years old"
end)
IO.inspect(user_summaries, label: "User summaries")

IO.puts("""

============================================================================
SECTION 3: Enum.filter/2 - Selecting Elements
============================================================================
""")

# Enum.filter/2 returns elements for which the function returns a truthy value.
#
# Syntax: Enum.filter(enumerable, function)

numbers = 1..10

# Filter even numbers
evens = Enum.filter(numbers, fn x -> rem(x, 2) == 0 end)
IO.inspect(evens, label: "Even numbers")

# Filter with capture operator
odds = Enum.filter(numbers, &(rem(&1, 2) == 1))
IO.inspect(odds, label: "Odd numbers")

# Filter strings by length
words = ["cat", "elephant", "dog", "hippopotamus", "ant"]
long_words = Enum.filter(words, fn word -> String.length(word) > 3 end)
IO.inspect(long_words, label: "Words longer than 3 characters")

# Enum.reject/2 is the opposite of filter - removes matching elements
short_words = Enum.reject(words, fn word -> String.length(word) > 3 end)
IO.inspect(short_words, label: "Words 3 characters or less")

# Filtering maps
products = [
  %{name: "Laptop", price: 999, in_stock: true},
  %{name: "Mouse", price: 29, in_stock: false},
  %{name: "Keyboard", price: 79, in_stock: true},
  %{name: "Monitor", price: 399, in_stock: true}
]

# Find affordable, available products
affordable_available = Enum.filter(products, fn product ->
  product.price < 500 and product.in_stock
end)
IO.inspect(affordable_available, label: "Affordable & in stock")

# Combining map and filter
result = 1..20
         |> Enum.filter(&(rem(&1, 3) == 0))  # Divisible by 3: [3, 6, 9, 12, 15, 18]
         |> Enum.map(&(&1 * &1))              # Square them

IO.inspect(result, label: "Squares of numbers divisible by 3")

IO.puts("""

============================================================================
SECTION 4: Enum.reduce/2,3 - Accumulating Values
============================================================================
""")

# Enum.reduce/2,3 is the most powerful Enum function. It iterates through
# a collection, accumulating a result based on each element.
#
# Syntax: Enum.reduce(enumerable, initial_accumulator, function)
# The function receives (element, accumulator) and returns new accumulator

numbers = [1, 2, 3, 4, 5]

# Sum all numbers
sum = Enum.reduce(numbers, 0, fn x, acc -> x + acc end)
IO.puts("Sum of #{inspect(numbers)}: #{sum}")

# With capture operator
product = Enum.reduce(numbers, 1, &(&1 * &2))
IO.puts("Product of #{inspect(numbers)}: #{product}")

# Enum.reduce/2 uses the first element as initial accumulator
sum_no_init = Enum.reduce(numbers, &(&1 + &2))
IO.puts("Sum using reduce/2: #{sum_no_init}")

# Find maximum value manually
max = Enum.reduce(numbers, fn x, acc ->
  if x > acc, do: x, else: acc
end)
IO.puts("Maximum: #{max}")

# Build a string from a list
words = ["Elixir", "is", "awesome"]
sentence = Enum.reduce(words, "", fn word, acc ->
  if acc == "", do: word, else: "#{acc} #{word}"
end)
IO.puts("Sentence: #{sentence}")

# Count occurrences of each character
text = "hello world"
char_counts = text
              |> String.graphemes()
              |> Enum.reduce(%{}, fn char, acc ->
                Map.update(acc, char, 1, &(&1 + 1))
              end)
IO.inspect(char_counts, label: "Character frequencies")

# Practical example: Calculate shopping cart total
cart = [
  %{item: "Book", quantity: 2, price: 15.99},
  %{item: "Pen", quantity: 5, price: 1.50},
  %{item: "Notebook", quantity: 3, price: 4.99}
]

total = Enum.reduce(cart, 0, fn item, acc ->
  acc + (item.quantity * item.price)
end)
IO.puts("Shopping cart total: $#{:erlang.float_to_binary(total, decimals: 2)}")

# Building complex data structures
transactions = [
  %{type: :deposit, amount: 100},
  %{type: :withdrawal, amount: 30},
  %{type: :deposit, amount: 50},
  %{type: :withdrawal, amount: 20}
]

final_balance = Enum.reduce(transactions, 0, fn tx, balance ->
  case tx.type do
    :deposit -> balance + tx.amount
    :withdrawal -> balance - tx.amount
  end
end)
IO.puts("Final balance: $#{final_balance}")

IO.puts("""

============================================================================
SECTION 5: Enum.each/2 - Side Effects
============================================================================
""")

# Enum.each/2 iterates through each element for side effects (like printing).
# It always returns :ok, not the transformed collection.
#
# Use Enum.each when you want to DO something, not transform data.

IO.puts("Printing each number:")
Enum.each([1, 2, 3], fn x ->
  IO.puts("  Number: #{x}")
end)

# Enum.each returns :ok
result = Enum.each([1, 2, 3], &IO.inspect/1)
IO.puts("Return value of Enum.each: #{inspect(result)}")

# Practical use: Sending notifications
users = [
  %{name: "Alice", email: "alice@example.com"},
  %{name: "Bob", email: "bob@example.com"}
]

IO.puts("\nSending notifications:")
Enum.each(users, fn user ->
  # In real code, this would send an actual email
  IO.puts("  [MOCK] Sending email to #{user.email} for #{user.name}")
end)

# Enum.each with index using Enum.with_index
IO.puts("\nNumbered list:")
["First", "Second", "Third"]
|> Enum.with_index(1)
|> Enum.each(fn {item, index} ->
  IO.puts("  #{index}. #{item}")
end)

IO.puts("""

============================================================================
SECTION 6: Enum.find/2,3 - Searching Collections
============================================================================
""")

# Enum.find/2,3 returns the first element for which the function returns truthy.
# Returns nil (or default) if no element matches.
#
# Syntax: Enum.find(enumerable, default \\ nil, function)

numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# Find first even number
first_even = Enum.find(numbers, fn x -> rem(x, 2) == 0 end)
IO.puts("First even number: #{first_even}")

# Find with default value
first_negative = Enum.find(numbers, :not_found, fn x -> x < 0 end)
IO.puts("First negative (with default): #{inspect(first_negative)}")

# Find in a list of maps
users = [
  %{id: 1, name: "Alice", role: :user},
  %{id: 2, name: "Bob", role: :admin},
  %{id: 3, name: "Charlie", role: :user}
]

admin = Enum.find(users, fn user -> user.role == :admin end)
IO.inspect(admin, label: "First admin")

user_by_id = Enum.find(users, fn user -> user.id == 3 end)
IO.inspect(user_by_id, label: "User with ID 3")

# Enum.find_index/2 - returns the index instead of the element
index = Enum.find_index(numbers, fn x -> x > 5 end)
IO.puts("Index of first number > 5: #{index}")

# Enum.find_value/2,3 - returns the function's return value, not the element
# Useful when you want to transform while finding
result = Enum.find_value(users, fn user ->
  if user.name == "Bob", do: String.upcase(user.name)
end)
IO.puts("Found and transformed: #{result}")

# Practical example: Validate configuration
configs = [
  %{key: "DATABASE_URL", value: "postgres://localhost/mydb"},
  %{key: "SECRET_KEY", value: nil},
  %{key: "PORT", value: "4000"}
]

missing_config = Enum.find(configs, fn config -> is_nil(config.value) end)
if missing_config do
  IO.puts("WARNING: Missing value for #{missing_config.key}")
end

IO.puts("""

============================================================================
SECTION 7: Combining Enum Functions
============================================================================
""")

# Real-world problems often require combining multiple Enum functions

# Example 1: Process and summarize sales data
sales = [
  %{product: "Widget", quantity: 10, price: 5.99, region: "North"},
  %{product: "Gadget", quantity: 5, price: 15.99, region: "South"},
  %{product: "Widget", quantity: 8, price: 5.99, region: "South"},
  %{product: "Gizmo", quantity: 3, price: 25.99, region: "North"},
  %{product: "Gadget", quantity: 12, price: 15.99, region: "North"}
]

# Find total revenue for North region
north_revenue = sales
                |> Enum.filter(fn sale -> sale.region == "North" end)
                |> Enum.map(fn sale -> sale.quantity * sale.price end)
                |> Enum.reduce(0, &(&1 + &2))

IO.puts("North region revenue: $#{:erlang.float_to_binary(north_revenue, decimals: 2)}")

# Example 2: Process text data
text = "The quick brown fox jumps over the lazy dog"
word_lengths = text
               |> String.downcase()
               |> String.split()
               |> Enum.map(fn word -> {word, String.length(word)} end)
               |> Enum.filter(fn {_word, len} -> len > 3 end)

IO.inspect(word_lengths, label: "Words longer than 3 chars with lengths")

# Example 3: Data pipeline with early termination
# Enum.take_while/2 takes elements until condition fails
numbers = 1..100
result = numbers
         |> Enum.map(&(&1 * 2))
         |> Enum.take_while(&(&1 < 15))

IO.inspect(result, label: "Doubled numbers less than 15")

IO.puts("""

============================================================================
SECTION 8: Common Enum Helper Functions
============================================================================
""")

# These functions are built on the core functions but provide convenience

numbers = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5]

IO.puts("Working with: #{inspect(numbers)}")
IO.puts("Sum: #{Enum.sum(numbers)}")
IO.puts("Min: #{Enum.min(numbers)}")
IO.puts("Max: #{Enum.max(numbers)}")
IO.puts("Count: #{Enum.count(numbers)}")

# Enum.member?/2 - check if element exists
IO.puts("Contains 5? #{Enum.member?(numbers, 5)}")
IO.puts("Contains 7? #{Enum.member?(numbers, 7)}")

# Enum.any?/2 and Enum.all?/2
IO.puts("Any even? #{Enum.any?(numbers, &(rem(&1, 2) == 0))}")
IO.puts("All positive? #{Enum.all?(numbers, &(&1 > 0))}")

# Enum.empty?/1
IO.puts("Is empty? #{Enum.empty?(numbers)}")
IO.puts("Is [] empty? #{Enum.empty?([])}")

# Enum.sort/1,2
IO.inspect(Enum.sort(numbers), label: "Sorted ascending")
IO.inspect(Enum.sort(numbers, :desc), label: "Sorted descending")

# Enum.uniq/1 - remove duplicates
IO.inspect(Enum.uniq(numbers), label: "Unique values")

# Enum.take/2 and Enum.drop/2
IO.inspect(Enum.take(numbers, 3), label: "First 3")
IO.inspect(Enum.drop(numbers, 3), label: "After dropping first 3")
IO.inspect(Enum.take(numbers, -3), label: "Last 3")

# Enum.reverse/1
IO.inspect(Enum.reverse(numbers), label: "Reversed")

# Enum.join/2
words = ["Hello", "Elixir", "World"]
IO.puts("Joined with space: #{Enum.join(words, " ")}")
IO.puts("Joined with comma: #{Enum.join(words, ", ")}")

# Enum.at/2,3 - get element at index
IO.puts("Element at index 2: #{Enum.at(numbers, 2)}")
IO.puts("Element at index 100 (with default): #{Enum.at(numbers, 100, :not_found)}")

IO.puts("""

============================================================================
SUMMARY
============================================================================

Key Enum functions covered:

1. Enum.map/2
   - Transforms each element
   - Returns a new list with transformed values
   - Does NOT modify the original collection

2. Enum.filter/2
   - Selects elements matching a condition
   - Returns elements where function returns truthy
   - Enum.reject/2 is the opposite

3. Enum.reduce/2,3
   - Most powerful function - accumulates values
   - Takes (element, accumulator) and returns new accumulator
   - Can build any data structure

4. Enum.each/2
   - For side effects (printing, sending messages, etc.)
   - Always returns :ok
   - Use when you don't need the transformed data

5. Enum.find/2,3
   - Returns first matching element
   - Returns nil or default if not found
   - Enum.find_index/2 returns the index instead

Best Practices:
- Use the pipe operator (|>) to chain operations
- Use capture operator (&) for simple functions
- Choose the right function for the job
- Enum functions are eager (process entire collection immediately)

============================================================================
EXERCISES
============================================================================
""")

IO.puts("""
Exercise 1 (Easy): Double and Sum
---------------------------------
Given a list of numbers, double each number and then sum them all.
Use Enum.map and Enum.reduce (or Enum.sum).

numbers = [1, 2, 3, 4, 5]
# Expected result: 30 (because 2+4+6+8+10 = 30)

# Your solution:
# result = numbers |> ...
""")

# Solution:
numbers = [1, 2, 3, 4, 5]
result = numbers |> Enum.map(&(&1 * 2)) |> Enum.sum()
IO.puts("Exercise 1 Solution: #{result}")

IO.puts("""

Exercise 2 (Easy): Filter and Count
-----------------------------------
Count how many strings in a list have more than 5 characters.

words = ["apple", "banana", "cherry", "date", "elderberry", "fig"]
# Expected result: 3 (banana, cherry, elderberry)

# Your solution:
# count = words |> ...
""")

# Solution:
words = ["apple", "banana", "cherry", "date", "elderberry", "fig"]
count = words |> Enum.filter(&(String.length(&1) > 5)) |> Enum.count()
IO.puts("Exercise 2 Solution: #{count}")

IO.puts("""

Exercise 3 (Medium): Word Frequency
-----------------------------------
Given a sentence, count the frequency of each word (case-insensitive).
Use String.split, String.downcase, and Enum.reduce.

sentence = "The cat and the dog and the bird"
# Expected result: %{"the" => 3, "cat" => 1, "and" => 2, "dog" => 1, "bird" => 1}

# Your solution:
# frequencies = sentence |> ...
""")

# Solution:
sentence = "The cat and the dog and the bird"
frequencies = sentence
              |> String.downcase()
              |> String.split()
              |> Enum.reduce(%{}, fn word, acc ->
                Map.update(acc, word, 1, &(&1 + 1))
              end)
IO.inspect(frequencies, label: "Exercise 3 Solution")

IO.puts("""

Exercise 4 (Medium): Find Expensive Items
-----------------------------------------
Find all products that cost more than $50 and are in stock,
then return their names in uppercase.

products = [
  %{name: "Laptop", price: 999.99, in_stock: true},
  %{name: "Mouse", price: 29.99, in_stock: true},
  %{name: "Keyboard", price: 79.99, in_stock: false},
  %{name: "Monitor", price: 299.99, in_stock: true},
  %{name: "USB Cable", price: 9.99, in_stock: true}
]
# Expected result: ["LAPTOP", "MONITOR"]

# Your solution:
# expensive_available = products |> ...
""")

# Solution:
products = [
  %{name: "Laptop", price: 999.99, in_stock: true},
  %{name: "Mouse", price: 29.99, in_stock: true},
  %{name: "Keyboard", price: 79.99, in_stock: false},
  %{name: "Monitor", price: 299.99, in_stock: true},
  %{name: "USB Cable", price: 9.99, in_stock: true}
]
expensive_available = products
                      |> Enum.filter(fn p -> p.price > 50 and p.in_stock end)
                      |> Enum.map(fn p -> String.upcase(p.name) end)
IO.inspect(expensive_available, label: "Exercise 4 Solution")

IO.puts("""

Exercise 5 (Hard): Grade Calculator
-----------------------------------
Calculate the average grade for each student and determine if they pass (avg >= 60).
Return a list of maps with student name, average, and pass/fail status.

students = [
  %{name: "Alice", grades: [85, 92, 78, 90]},
  %{name: "Bob", grades: [55, 62, 48, 70]},
  %{name: "Charlie", grades: [90, 95, 92, 88]}
]
# Expected result: [
#   %{name: "Alice", average: 86.25, status: :pass},
#   %{name: "Bob", average: 58.75, status: :fail},
#   %{name: "Charlie", average: 91.25, status: :pass}
# ]

# Your solution:
# results = students |> ...
""")

# Solution:
students = [
  %{name: "Alice", grades: [85, 92, 78, 90]},
  %{name: "Bob", grades: [55, 62, 48, 70]},
  %{name: "Charlie", grades: [90, 95, 92, 88]}
]
results = Enum.map(students, fn student ->
  average = Enum.sum(student.grades) / Enum.count(student.grades)
  status = if average >= 60, do: :pass, else: :fail
  %{name: student.name, average: average, status: status}
end)
IO.inspect(results, label: "Exercise 5 Solution")

IO.puts("""

Exercise 6 (Hard): Transaction Analyzer
---------------------------------------
Analyze a list of transactions to find:
1. Total deposits
2. Total withdrawals
3. Largest transaction
4. Final balance

transactions = [
  %{type: :deposit, amount: 1000, description: "Initial deposit"},
  %{type: :withdrawal, amount: 200, description: "ATM"},
  %{type: :deposit, amount: 500, description: "Paycheck"},
  %{type: :withdrawal, amount: 150, description: "Groceries"},
  %{type: :withdrawal, amount: 75, description: "Gas"},
  %{type: :deposit, amount: 250, description: "Refund"}
]

# Expected result: %{
#   total_deposits: 1750,
#   total_withdrawals: 425,
#   largest_transaction: %{type: :deposit, amount: 1000, description: "Initial deposit"},
#   final_balance: 1325
# }

# Your solution (hint: you might need multiple Enum calls or a complex reduce):
""")

# Solution:
transactions = [
  %{type: :deposit, amount: 1000, description: "Initial deposit"},
  %{type: :withdrawal, amount: 200, description: "ATM"},
  %{type: :deposit, amount: 500, description: "Paycheck"},
  %{type: :withdrawal, amount: 150, description: "Groceries"},
  %{type: :withdrawal, amount: 75, description: "Gas"},
  %{type: :deposit, amount: 250, description: "Refund"}
]

analysis = %{
  total_deposits: transactions
                  |> Enum.filter(&(&1.type == :deposit))
                  |> Enum.map(& &1.amount)
                  |> Enum.sum(),
  total_withdrawals: transactions
                     |> Enum.filter(&(&1.type == :withdrawal))
                     |> Enum.map(& &1.amount)
                     |> Enum.sum(),
  largest_transaction: Enum.max_by(transactions, & &1.amount),
  final_balance: Enum.reduce(transactions, 0, fn tx, balance ->
    case tx.type do
      :deposit -> balance + tx.amount
      :withdrawal -> balance - tx.amount
    end
  end)
}
IO.inspect(analysis, label: "Exercise 6 Solution")

IO.puts("""

============================================================================
CONGRATULATIONS!
============================================================================

You've completed the Enum Basics lesson! You now understand:

- How to transform data with Enum.map/2
- How to filter collections with Enum.filter/2
- How to accumulate values with Enum.reduce/2,3
- How to perform side effects with Enum.each/2
- How to search collections with Enum.find/2,3

Next up: Advanced Enum functions (Enum.group_by, Enum.zip, and more!)

============================================================================
""")
