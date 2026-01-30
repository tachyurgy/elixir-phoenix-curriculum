# ============================================================================
# LESSON: Advanced Enum Functions - Powerful Collection Operations
# ============================================================================
#
# Building on the basics, this lesson covers advanced Enum functions that
# enable sophisticated data transformations. These functions are essential
# for real-world data processing tasks.
#
# ============================================================================

# ============================================================================
# LEARNING OBJECTIVES
# ============================================================================
#
# By the end of this lesson, you will be able to:
#
# 1. Group data by keys using Enum.group_by/2,3
# 2. Count occurrences with Enum.frequencies/1,2
# 3. Combine collections with Enum.zip/1,2 and Enum.zip_with/2,3
# 4. Partition data into chunks with Enum.chunk_every/2,3,4
# 5. Flatten nested transformations with Enum.flat_map/2
# 6. Apply these functions to solve complex data problems
#
# ============================================================================

# ============================================================================
# PREREQUISITES
# ============================================================================
#
# Before starting this lesson, you should understand:
#
# - Basic Enum functions (map, filter, reduce)
# - Anonymous functions and the capture operator
# - Pattern matching with maps and lists
# - Pipe operator for chaining operations
#
# ============================================================================

IO.puts("""
============================================================================
SECTION 1: Enum.group_by/2,3 - Categorizing Data
============================================================================
""")

# Enum.group_by/2 groups elements into a map based on a key function.
# Each key maps to a list of elements that produced that key.
#
# Syntax: Enum.group_by(enumerable, key_fun)
# Syntax: Enum.group_by(enumerable, key_fun, value_fun)

# Basic grouping by value
numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
by_parity = Enum.group_by(numbers, fn x -> if rem(x, 2) == 0, do: :even, else: :odd end)
IO.inspect(by_parity, label: "Numbers grouped by parity")

# Group words by first letter
words = ["apple", "apricot", "banana", "blueberry", "cherry", "coconut"]
by_letter = Enum.group_by(words, &String.first/1)
IO.inspect(by_letter, label: "Words by first letter")

# Group with value transformation (3-arity version)
# Transform values while grouping
by_letter_upper = Enum.group_by(words, &String.first/1, &String.upcase/1)
IO.inspect(by_letter_upper, label: "Words by first letter (uppercased)")

# Practical example: Group employees by department
employees = [
  %{name: "Alice", department: "Engineering", salary: 95000},
  %{name: "Bob", department: "Marketing", salary: 65000},
  %{name: "Charlie", department: "Engineering", salary: 85000},
  %{name: "Diana", department: "HR", salary: 55000},
  %{name: "Eve", department: "Marketing", salary: 70000},
  %{name: "Frank", department: "Engineering", salary: 105000}
]

by_department = Enum.group_by(employees, & &1.department)
IO.inspect(by_department, label: "Employees by department")

# Group and extract just names
names_by_dept = Enum.group_by(employees, & &1.department, & &1.name)
IO.inspect(names_by_dept, label: "Employee names by department")

# Group by salary range
by_salary_range = Enum.group_by(employees, fn emp ->
  cond do
    emp.salary < 60000 -> :entry
    emp.salary < 90000 -> :mid
    true -> :senior
  end
end)
IO.inspect(by_salary_range, label: "Employees by salary range")

# Group orders by date (using date part as key)
orders = [
  %{id: 1, date: ~D[2024-01-15], total: 99.99},
  %{id: 2, date: ~D[2024-01-15], total: 149.50},
  %{id: 3, date: ~D[2024-01-16], total: 75.00},
  %{id: 4, date: ~D[2024-01-16], total: 200.00},
  %{id: 5, date: ~D[2024-01-17], total: 50.00}
]

orders_by_date = Enum.group_by(orders, & &1.date, & &1.total)
IO.inspect(orders_by_date, label: "Order totals by date")

# Calculate totals per date
daily_totals = orders_by_date
               |> Enum.map(fn {date, totals} -> {date, Enum.sum(totals)} end)
               |> Map.new()
IO.inspect(daily_totals, label: "Daily revenue")

IO.puts("""

============================================================================
SECTION 2: Enum.frequencies/1,2 - Counting Occurrences
============================================================================
""")

# Enum.frequencies/1 counts how many times each element appears.
# Returns a map of element => count.
#
# Enum.frequencies_by/2 allows grouping by a custom key function.

# Count letter frequencies
letters = ~w(a b a c b a d c a b)
letter_counts = Enum.frequencies(letters)
IO.inspect(letter_counts, label: "Letter frequencies")

# Count word frequencies in text
text = "the quick brown fox jumps over the lazy dog the fox"
word_freq = text
            |> String.split()
            |> Enum.frequencies()
IO.inspect(word_freq, label: "Word frequencies")

# Enum.frequencies_by/2 - count by a derived key
words = ["apple", "banana", "apricot", "blueberry", "cherry", "coconut", "avocado"]
by_first_letter = Enum.frequencies_by(words, &String.first/1)
IO.inspect(by_first_letter, label: "Words starting with each letter")

by_length = Enum.frequencies_by(words, &String.length/1)
IO.inspect(by_length, label: "Words by length")

# Practical example: Analyze survey responses
responses = [
  %{age_group: "18-25", satisfaction: :high},
  %{age_group: "26-35", satisfaction: :medium},
  %{age_group: "18-25", satisfaction: :high},
  %{age_group: "36-45", satisfaction: :low},
  %{age_group: "26-35", satisfaction: :high},
  %{age_group: "18-25", satisfaction: :medium},
  %{age_group: "36-45", satisfaction: :medium},
  %{age_group: "26-35", satisfaction: :high}
]

satisfaction_counts = Enum.frequencies_by(responses, & &1.satisfaction)
IO.inspect(satisfaction_counts, label: "Satisfaction distribution")

age_group_counts = Enum.frequencies_by(responses, & &1.age_group)
IO.inspect(age_group_counts, label: "Responses by age group")

# Find most common element using frequencies
numbers = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8, 9, 7, 9]
{most_common, count} = numbers
                        |> Enum.frequencies()
                        |> Enum.max_by(fn {_num, count} -> count end)
IO.puts("Most common number: #{most_common} (appears #{count} times)")

# Character frequency analysis
sentence = "Hello, World!"
char_freq = sentence
            |> String.downcase()
            |> String.graphemes()
            |> Enum.reject(&(&1 == " " or &1 == "," or &1 == "!"))
            |> Enum.frequencies()
            |> Enum.sort_by(fn {_char, count} -> count end, :desc)
IO.inspect(char_freq, label: "Character frequencies (sorted)")

IO.puts("""

============================================================================
SECTION 3: Enum.zip/1,2 and Enum.zip_with/2,3 - Combining Collections
============================================================================
""")

# Enum.zip/2 combines two lists element-wise into tuples.
# Enum.zip/1 combines multiple lists.
# Enum.zip_with/2,3 combines and transforms in one step.
#
# Note: zip stops at the shortest list!

names = ["Alice", "Bob", "Charlie"]
ages = [30, 25, 35]

# Basic zip
zipped = Enum.zip(names, ages)
IO.inspect(zipped, label: "Names and ages zipped")

# Zip multiple lists
scores = [95, 87, 92]
zipped_all = Enum.zip([names, ages, scores])
IO.inspect(zipped_all, label: "Three lists zipped")

# Enum.zip_with combines and transforms
name_age_strings = Enum.zip_with(names, ages, fn name, age ->
  "#{name} is #{age} years old"
end)
IO.inspect(name_age_strings, label: "Combined strings")

# Zip with unequal lengths (stops at shortest)
list1 = [1, 2, 3, 4, 5]
list2 = [10, 20, 30]
short_zip = Enum.zip(list1, list2)
IO.inspect(short_zip, label: "Unequal length zip (stops at shortest)")

# Enum.zip_longest alternative using Stream.zip_longest/2 (if needed)
# For now, let's pad manually if we need equal lengths

# Practical example: Create records from parallel lists
first_names = ["John", "Jane", "Jack"]
last_names = ["Doe", "Smith", "Wilson"]
emails = ["john@example.com", "jane@example.com", "jack@example.com"]

users = [first_names, last_names, emails]
        |> Enum.zip()
        |> Enum.map(fn {first, last, email} ->
          %{first_name: first, last_name: last, email: email}
        end)
IO.inspect(users, label: "User records from parallel lists")

# Mathematical operations with zip_with
xs = [1, 2, 3, 4, 5]
ys = [2, 4, 6, 8, 10]

# Element-wise addition
sums = Enum.zip_with(xs, ys, &(&1 + &2))
IO.inspect(sums, label: "Element-wise sums")

# Element-wise multiplication (dot product components)
products = Enum.zip_with(xs, ys, &(&1 * &2))
IO.inspect(products, label: "Element-wise products")

# Dot product
dot_product = products |> Enum.sum()
IO.puts("Dot product: #{dot_product}")

# Practical example: Compare two datasets
last_month = [1000, 1200, 950, 1100, 1300]
this_month = [1050, 1150, 1000, 1200, 1250]
days = ["Mon", "Tue", "Wed", "Thu", "Fri"]

comparison = [days, last_month, this_month]
             |> Enum.zip()
             |> Enum.map(fn {day, last, this} ->
               change = this - last
               percent = Float.round((change / last) * 100, 1)
               %{day: day, last: last, this: this, change: change, percent: percent}
             end)

IO.puts("\nSales Comparison:")
Enum.each(comparison, fn row ->
  sign = if row.change >= 0, do: "+", else: ""
  IO.puts("  #{row.day}: $#{row.last} -> $#{row.this} (#{sign}#{row.change}, #{sign}#{row.percent}%)")
end)

# Enum.unzip - reverse of zip
pairs = [{:a, 1}, {:b, 2}, {:c, 3}]
{letters, numbers} = Enum.unzip(pairs)
IO.inspect({letters, numbers}, label: "\nUnzipped pairs")

IO.puts("""

============================================================================
SECTION 4: Enum.chunk_every/2,3,4 - Partitioning into Chunks
============================================================================
""")

# Enum.chunk_every/2,3,4 splits a collection into fixed-size chunks.
#
# Syntax: Enum.chunk_every(enumerable, count)
# Syntax: Enum.chunk_every(enumerable, count, step)
# Syntax: Enum.chunk_every(enumerable, count, step, leftover)

numbers = 1..12 |> Enum.to_list()
IO.inspect(numbers, label: "Original list")

# Basic chunking
chunks = Enum.chunk_every(numbers, 3)
IO.inspect(chunks, label: "Chunks of 3")

# Chunking with incomplete final chunk
numbers_odd = 1..10 |> Enum.to_list()
chunks_odd = Enum.chunk_every(numbers_odd, 3)
IO.inspect(chunks_odd, label: "Chunks of 3 (with leftover)")

# Discard incomplete chunks
chunks_discard = Enum.chunk_every(numbers_odd, 3, 3, :discard)
IO.inspect(chunks_discard, label: "Chunks of 3 (discard incomplete)")

# Pad incomplete chunks
chunks_padded = Enum.chunk_every(numbers_odd, 3, 3, [0, 0])
IO.inspect(chunks_padded, label: "Chunks of 3 (padded with zeros)")

# Overlapping chunks (sliding window) - step < count
sliding = Enum.chunk_every(numbers, 3, 1, :discard)
IO.inspect(sliding, label: "Sliding window of 3")

# Moving average calculation
values = [10, 12, 15, 14, 18, 20, 19, 22, 25, 23]
moving_avg = values
             |> Enum.chunk_every(3, 1, :discard)
             |> Enum.map(fn window -> Enum.sum(window) / 3 end)
             |> Enum.map(&Float.round(&1, 2))
IO.inspect(moving_avg, label: "3-period moving average")

# Practical example: Pagination
items = Enum.map(1..23, fn i -> "Item #{i}" end)
page_size = 5
pages = Enum.chunk_every(items, page_size)

IO.puts("\nPaginated view:")
pages
|> Enum.with_index(1)
|> Enum.each(fn {page, num} ->
  IO.puts("  Page #{num}: #{inspect(page)}")
end)

# Practical example: Process data in batches
records = Enum.map(1..17, fn i -> %{id: i, data: "Record #{i}"} end)
batch_size = 5

IO.puts("\nBatch processing:")
records
|> Enum.chunk_every(batch_size)
|> Enum.with_index(1)
|> Enum.each(fn {batch, num} ->
  IO.puts("  Processing batch #{num} with #{length(batch)} records...")
  # In real code, this would process the batch
end)

# Enum.chunk_by - chunk by a condition change
mixed = [1, 1, 2, 2, 2, 3, 1, 1]
by_value = Enum.chunk_by(mixed, & &1)
IO.inspect(by_value, label: "\nChunked by consecutive value")

# Group consecutive even/odd
numbers_mixed = [1, 3, 5, 2, 4, 7, 9, 8, 6]
by_parity = Enum.chunk_by(numbers_mixed, &(rem(&1, 2) == 0))
IO.inspect(by_parity, label: "Chunked by consecutive parity")

# Practical: Parse log entries by type
log_entries = [
  {:info, "Starting"},
  {:info, "Loading config"},
  {:error, "Config not found"},
  {:error, "Using defaults"},
  {:info, "Server started"},
  {:info, "Listening on port 4000"}
]

chunked_logs = Enum.chunk_by(log_entries, fn {level, _} -> level end)
IO.inspect(chunked_logs, label: "Logs chunked by consecutive level")

IO.puts("""

============================================================================
SECTION 5: Enum.flat_map/2 - Map and Flatten Combined
============================================================================
""")

# Enum.flat_map/2 applies a function that returns a list, then flattens results.
# Equivalent to map + flatten, but more efficient.
#
# Use when your mapping function returns a list and you want a flat result.

# Basic flat_map
nested = [[1, 2], [3, 4], [5, 6]]
# With map, we'd get [[2, 4], [6, 8], [10, 12]]
# With flat_map, we get [2, 4, 6, 8, 10, 12]
doubled_flat = Enum.flat_map(nested, fn list -> Enum.map(list, &(&1 * 2)) end)
IO.inspect(doubled_flat, label: "Flat mapped doubled")

# Generate multiple items from each input
numbers = [1, 2, 3]
expanded = Enum.flat_map(numbers, fn x -> [x, x * 10, x * 100] end)
IO.inspect(expanded, label: "Each number expanded to 3")

# Practical: Extract tags from posts
posts = [
  %{title: "Elixir Basics", tags: ["elixir", "programming", "beginner"]},
  %{title: "Phoenix Framework", tags: ["elixir", "phoenix", "web"]},
  %{title: "OTP Guide", tags: ["elixir", "otp", "advanced"]}
]

all_tags = Enum.flat_map(posts, & &1.tags)
IO.inspect(all_tags, label: "All tags")

unique_tags = all_tags |> Enum.uniq() |> Enum.sort()
IO.inspect(unique_tags, label: "Unique tags sorted")

# Practical: Flatten order items
orders = [
  %{id: 1, items: [%{name: "Book", qty: 2}, %{name: "Pen", qty: 5}]},
  %{id: 2, items: [%{name: "Notebook", qty: 1}]},
  %{id: 3, items: [%{name: "Pencil", qty: 10}, %{name: "Eraser", qty: 3}, %{name: "Ruler", qty: 1}]}
]

all_items = Enum.flat_map(orders, fn order ->
  Enum.map(order.items, fn item ->
    Map.put(item, :order_id, order.id)
  end)
end)
IO.inspect(all_items, label: "All items with order ID")

# Filter and flat_map combined
words = ["hello", "world", "elixir"]
vowels = Enum.flat_map(words, fn word ->
  word
  |> String.graphemes()
  |> Enum.filter(&(&1 in ~w(a e i o u)))
end)
IO.inspect(vowels, label: "All vowels from words")

# Practical: File path expansion (simulated)
directories = ["src", "test", "lib"]
# Simulate finding files in each directory
files = Enum.flat_map(directories, fn dir ->
  # In real code, this would use File.ls!
  ["#{dir}/file1.ex", "#{dir}/file2.ex"]
end)
IO.inspect(files, label: "Expanded file paths")

# Combination: flat_map with filter
users = [
  %{name: "Alice", orders: [100, 200, 50]},
  %{name: "Bob", orders: [75, 150]},
  %{name: "Charlie", orders: [300]}
]

large_orders = Enum.flat_map(users, fn user ->
  user.orders
  |> Enum.filter(&(&1 >= 100))
  |> Enum.map(&{user.name, &1})
end)
IO.inspect(large_orders, label: "Large orders with user names")

IO.puts("""

============================================================================
SECTION 6: Additional Advanced Functions
============================================================================
""")

# Enum.split_with/2 - partition into two lists based on condition
numbers = 1..10 |> Enum.to_list()
{evens, odds} = Enum.split_with(numbers, &(rem(&1, 2) == 0))
IO.inspect({evens, odds}, label: "Split into evens and odds")

# Enum.map_reduce/3 - map and reduce in one pass
# Returns {mapped_list, final_accumulator}
{squared, sum} = Enum.map_reduce(1..5, 0, fn x, acc ->
  {x * x, acc + x}
end)
IO.puts("\nMap reduce result:")
IO.inspect(squared, label: "Mapped (squared)")
IO.puts("Accumulated sum: #{sum}")

# Enum.scan/2,3 - like reduce, but keeps intermediate results
running_total = Enum.scan(1..5, &(&1 + &2))
IO.inspect(running_total, label: "Running totals (scan)")

# Enum.reduce_while/3 - reduce with early termination
numbers = 1..100
result = Enum.reduce_while(numbers, 0, fn x, acc ->
  if acc + x > 50 do
    {:halt, acc}
  else
    {:cont, acc + x}
  end
end)
IO.puts("Sum until exceeding 50: #{result}")

# Enum.dedup/1 - remove consecutive duplicates
with_dupes = [1, 1, 2, 2, 2, 3, 1, 1, 4]
deduped = Enum.dedup(with_dupes)
IO.inspect(deduped, label: "After removing consecutive duplicates")

# Enum.intersperse/2 - insert element between each pair
items = ["a", "b", "c", "d"]
interspersed = Enum.intersperse(items, "-")
IO.inspect(interspersed, label: "Interspersed with -")

# Enum.slide/3 - move element(s) to a new position
list = [:a, :b, :c, :d, :e]
slid = Enum.slide(list, 1, 3)  # Move element at index 1 to index 3
IO.inspect(slid, label: "After sliding :b to position 3")

# Enum.concat/1,2 - concatenate enumerables
lists = [[1, 2], [3, 4], [5, 6]]
concatenated = Enum.concat(lists)
IO.inspect(concatenated, label: "Concatenated lists")

IO.puts("""

============================================================================
SECTION 7: Combining Advanced Functions
============================================================================
""")

# Real-world example: Sales analytics pipeline
sales_data = [
  %{date: ~D[2024-01-01], product: "Widget", region: "North", amount: 150},
  %{date: ~D[2024-01-01], product: "Gadget", region: "South", amount: 200},
  %{date: ~D[2024-01-02], product: "Widget", region: "South", amount: 175},
  %{date: ~D[2024-01-02], product: "Widget", region: "North", amount: 125},
  %{date: ~D[2024-01-03], product: "Gadget", region: "North", amount: 300},
  %{date: ~D[2024-01-03], product: "Gizmo", region: "South", amount: 100},
  %{date: ~D[2024-01-03], product: "Widget", region: "North", amount: 200}
]

IO.puts("Sales Analytics Report")
IO.puts("=" |> String.duplicate(50))

# Sales by product
IO.puts("\nSales by Product:")
sales_data
|> Enum.group_by(& &1.product, & &1.amount)
|> Enum.map(fn {product, amounts} -> {product, Enum.sum(amounts)} end)
|> Enum.sort_by(fn {_, total} -> total end, :desc)
|> Enum.each(fn {product, total} ->
  IO.puts("  #{String.pad_trailing(product, 10)} $#{total}")
end)

# Sales by region
IO.puts("\nSales by Region:")
sales_data
|> Enum.group_by(& &1.region, & &1.amount)
|> Enum.map(fn {region, amounts} -> {region, Enum.sum(amounts)} end)
|> Enum.each(fn {region, total} ->
  IO.puts("  #{String.pad_trailing(region, 10)} $#{total}")
end)

# Daily totals
IO.puts("\nDaily Totals:")
sales_data
|> Enum.group_by(& &1.date, & &1.amount)
|> Enum.sort_by(fn {date, _} -> date end)
|> Enum.each(fn {date, amounts} ->
  IO.puts("  #{date}: $#{Enum.sum(amounts)}")
end)

# Top selling product per region
IO.puts("\nTop Product by Region:")
sales_data
|> Enum.group_by(& &1.region)
|> Enum.map(fn {region, sales} ->
  top = sales
        |> Enum.group_by(& &1.product, & &1.amount)
        |> Enum.map(fn {prod, amounts} -> {prod, Enum.sum(amounts)} end)
        |> Enum.max_by(fn {_, total} -> total end)
  {region, top}
end)
|> Enum.each(fn {region, {product, total}} ->
  IO.puts("  #{region}: #{product} ($#{total})")
end)

IO.puts("""

============================================================================
SUMMARY
============================================================================

Advanced Enum functions covered:

1. Enum.group_by/2,3
   - Groups elements by a key function
   - Returns map of key => list of elements
   - 3-arity version transforms values while grouping

2. Enum.frequencies/1 and Enum.frequencies_by/2
   - Counts occurrences of each element
   - Returns map of element => count
   - frequencies_by counts by a derived key

3. Enum.zip/1,2 and Enum.zip_with/2,3
   - Combines lists element-wise
   - Stops at shortest list length
   - zip_with combines and transforms

4. Enum.chunk_every/2,3,4
   - Splits into fixed-size chunks
   - Supports overlapping (sliding window)
   - Options for handling incomplete final chunk

5. Enum.flat_map/2
   - Maps function that returns list, then flattens
   - Essential for nested data extraction
   - More efficient than map + flatten

Additional functions:
- Enum.split_with/2: Partition by condition
- Enum.map_reduce/3: Map and reduce in one pass
- Enum.scan/2,3: Reduce keeping intermediate results
- Enum.reduce_while/3: Reduce with early termination

============================================================================
EXERCISES
============================================================================
""")

IO.puts("""
Exercise 1 (Easy): Group by Length
----------------------------------
Group a list of words by their length.

words = ["cat", "dog", "elephant", "bee", "ant", "tiger", "lion"]
# Expected: %{3 => ["cat", "dog", "bee", "ant"], 4 => ["lion"], 5 => ["tiger"], 8 => ["elephant"]}

# Your solution:
# grouped = Enum.group_by(words, ...)
""")

# Solution:
words = ["cat", "dog", "elephant", "bee", "ant", "tiger", "lion"]
grouped = Enum.group_by(words, &String.length/1)
IO.inspect(grouped, label: "Exercise 1 Solution")

IO.puts("""

Exercise 2 (Easy): Most Frequent Element
----------------------------------------
Find the most frequently occurring element in a list.

items = [:apple, :banana, :apple, :cherry, :banana, :apple, :date]
# Expected: {:apple, 3}

# Your solution:
# most_frequent = items |> Enum.frequencies() |> ...
""")

# Solution:
items = [:apple, :banana, :apple, :cherry, :banana, :apple, :date]
most_frequent = items |> Enum.frequencies() |> Enum.max_by(fn {_, count} -> count end)
IO.inspect(most_frequent, label: "Exercise 2 Solution")

IO.puts("""

Exercise 3 (Medium): Create Records from CSV-style Data
-------------------------------------------------------
Given parallel lists representing CSV columns, create a list of maps.

headers = [:name, :age, :city]
row1 = ["Alice", 30, "NYC"]
row2 = ["Bob", 25, "LA"]
row3 = ["Charlie", 35, "Chicago"]

# Expected: [
#   %{name: "Alice", age: 30, city: "NYC"},
#   %{name: "Bob", age: 25, city: "LA"},
#   %{name: "Charlie", age: 35, city: "Chicago"}
# ]

# Your solution:
# records = [row1, row2, row3] |> Enum.map(fn row -> ... end)
""")

# Solution:
headers = [:name, :age, :city]
row1 = ["Alice", 30, "NYC"]
row2 = ["Bob", 25, "LA"]
row3 = ["Charlie", 35, "Chicago"]

records = [row1, row2, row3]
          |> Enum.map(fn row ->
            Enum.zip(headers, row) |> Map.new()
          end)
IO.inspect(records, label: "Exercise 3 Solution")

IO.puts("""

Exercise 4 (Medium): Moving Average
-----------------------------------
Calculate a 3-period moving average for a list of values.
Round each average to 2 decimal places.

values = [10, 15, 20, 18, 22, 25, 30, 28, 32]
# Expected: [15.0, 17.67, 20.0, 21.67, 25.67, 27.67, 30.0]

# Your solution:
# moving_avg = values |> Enum.chunk_every(...) |> ...
""")

# Solution:
values = [10, 15, 20, 18, 22, 25, 30, 28, 32]
moving_avg = values
             |> Enum.chunk_every(3, 1, :discard)
             |> Enum.map(fn window -> Float.round(Enum.sum(window) / 3, 2) end)
IO.inspect(moving_avg, label: "Exercise 4 Solution")

IO.puts("""

Exercise 5 (Hard): Extract Unique Skills from Team
--------------------------------------------------
Given a list of team members with their skills, extract all unique skills
and count how many team members have each skill.

team = [
  %{name: "Alice", skills: ["Elixir", "Python", "SQL"]},
  %{name: "Bob", skills: ["JavaScript", "Python", "React"]},
  %{name: "Charlie", skills: ["Elixir", "JavaScript", "SQL"]},
  %{name: "Diana", skills: ["Python", "SQL", "Machine Learning"]}
]

# Expected: %{
#   "Elixir" => 2,
#   "JavaScript" => 2,
#   "Machine Learning" => 1,
#   "Python" => 3,
#   "React" => 1,
#   "SQL" => 3
# }

# Your solution (hint: use flat_map and frequencies):
""")

# Solution:
team = [
  %{name: "Alice", skills: ["Elixir", "Python", "SQL"]},
  %{name: "Bob", skills: ["JavaScript", "Python", "React"]},
  %{name: "Charlie", skills: ["Elixir", "JavaScript", "SQL"]},
  %{name: "Diana", skills: ["Python", "SQL", "Machine Learning"]}
]

skill_counts = team
               |> Enum.flat_map(& &1.skills)
               |> Enum.frequencies()
               |> Enum.sort_by(fn {skill, _} -> skill end)
               |> Map.new()
IO.inspect(skill_counts, label: "Exercise 5 Solution")

IO.puts("""

Exercise 6 (Hard): Sales Report Generator
-----------------------------------------
Generate a comprehensive sales report from the following data.
Calculate: total revenue, best selling product, sales by category,
and average transaction amount.

transactions = [
  %{product: "Widget", category: "Electronics", amount: 29.99},
  %{product: "Gadget", category: "Electronics", amount: 49.99},
  %{product: "Book", category: "Media", amount: 14.99},
  %{product: "Widget", category: "Electronics", amount: 29.99},
  %{product: "Movie", category: "Media", amount: 19.99},
  %{product: "Gadget", category: "Electronics", amount: 49.99},
  %{product: "Book", category: "Media", amount: 14.99},
  %{product: "Widget", category: "Electronics", amount: 29.99}
]

# Expected output structure:
# %{
#   total_revenue: 239.92,
#   best_seller: {"Widget", 3},
#   by_category: %{"Electronics" => 189.95, "Media" => 49.97},
#   avg_transaction: 29.99
# }

# Your solution:
""")

# Solution:
transactions = [
  %{product: "Widget", category: "Electronics", amount: 29.99},
  %{product: "Gadget", category: "Electronics", amount: 49.99},
  %{product: "Book", category: "Media", amount: 14.99},
  %{product: "Widget", category: "Electronics", amount: 29.99},
  %{product: "Movie", category: "Media", amount: 19.99},
  %{product: "Gadget", category: "Electronics", amount: 49.99},
  %{product: "Book", category: "Media", amount: 14.99},
  %{product: "Widget", category: "Electronics", amount: 29.99}
]

report = %{
  total_revenue: transactions |> Enum.map(& &1.amount) |> Enum.sum() |> Float.round(2),
  best_seller: transactions |> Enum.frequencies_by(& &1.product) |> Enum.max_by(fn {_, c} -> c end),
  by_category: transactions
               |> Enum.group_by(& &1.category, & &1.amount)
               |> Enum.map(fn {cat, amounts} -> {cat, Float.round(Enum.sum(amounts), 2)} end)
               |> Map.new(),
  avg_transaction: Float.round(
    Enum.sum(Enum.map(transactions, & &1.amount)) / length(transactions),
    2
  )
}
IO.inspect(report, label: "Exercise 6 Solution")

IO.puts("""

============================================================================
CONGRATULATIONS!
============================================================================

You've mastered advanced Enum functions! You now can:

- Group and categorize data efficiently
- Count frequencies and find patterns
- Combine multiple data sources with zip
- Partition data into manageable chunks
- Flatten complex nested transformations

These tools are essential for building data pipelines
and processing real-world datasets in Elixir.

Next up: Streams for lazy evaluation and infinite sequences!

============================================================================
""")
