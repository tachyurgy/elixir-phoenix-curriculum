# ============================================================================
# Lesson 08: Structs
# ============================================================================
#
# Structs are extensions built on top of maps that provide compile-time
# checks and default values. They're perfect for defining data structures
# with known fields.
#
# Learning Objectives:
# - Define and create structs
# - Understand struct default values
# - Use pattern matching with structs
# - Know when to use structs vs maps
# - Work with struct updates and enforcement
#
# Prerequisites:
# - Lesson 07 (Maps) completed
#
# ============================================================================

IO.puts("=" |> String.duplicate(60))
IO.puts("Lesson 08: Structs")
IO.puts("=" |> String.duplicate(60))

# -----------------------------------------------------------------------------
# Section 1: Defining Structs
# -----------------------------------------------------------------------------

IO.puts("\n--- Defining Structs ---")

# Structs are defined inside modules using defstruct
defmodule User do
  defstruct [:name, :email, :age]
end

# Create a struct instance
user = %User{name: "Alice", email: "alice@example.com", age: 30}
IO.inspect(user, label: "User struct")

# Structs have a __struct__ field that identifies the module
IO.inspect(user.__struct__, label: "__struct__ field")

# Structs ARE maps!
IO.inspect(is_map(user), label: "is_map(user)")

# But with a special __struct__ key
IO.inspect(Map.keys(user), label: "Struct keys")

# -----------------------------------------------------------------------------
# Section 2: Default Values
# -----------------------------------------------------------------------------

IO.puts("\n--- Default Values ---")

defmodule Article do
  defstruct [
    :title,                      # nil by default
    :author,                     # nil by default
    published: false,            # default value
    views: 0,                    # default value
    tags: []                     # default value (empty list)
  ]
end

# Create with defaults
article1 = %Article{title: "Elixir Basics", author: "Alice"}
IO.inspect(article1, label: "With defaults")

# Override defaults
article2 = %Article{title: "Advanced Elixir", author: "Bob", published: true, views: 100}
IO.inspect(article2, label: "Custom values")

# All fields are optional when creating
empty_article = %Article{}
IO.inspect(empty_article, label: "Empty article")

# -----------------------------------------------------------------------------
# Section 3: Enforcing Required Fields
# -----------------------------------------------------------------------------

IO.puts("\n--- Enforcing Required Fields ---")

defmodule Product do
  # @enforce_keys requires these fields when creating
  @enforce_keys [:name, :price]
  defstruct [:name, :price, stock: 0, active: true]
end

# This works - required fields provided
product = %Product{name: "Widget", price: 29.99}
IO.inspect(product, label: "Valid product")

# This would raise ArgumentError:
# %Product{stock: 100}  # Missing :name and :price!

IO.puts("@enforce_keys ensures required fields are provided")
IO.puts("Trying to create %Product{} without :name and :price would raise!")

# -----------------------------------------------------------------------------
# Section 4: Accessing Struct Fields
# -----------------------------------------------------------------------------

IO.puts("\n--- Accessing Struct Fields ---")

defmodule Book do
  defstruct [:title, :author, :isbn, pages: 0, rating: nil]
end

book = %Book{title: "Programming Elixir", author: "Dave Thomas", pages: 400}

# Dot notation (recommended for structs)
IO.inspect(book.title, label: "book.title")
IO.inspect(book.author, label: "book.author")
IO.inspect(book.pages, label: "book.pages")

# Bracket notation also works
IO.inspect(book[:title], label: "book[:title]")

# Map functions work too
IO.inspect(Map.get(book, :author), label: "Map.get(:author)")
IO.inspect(Map.get(book, :missing, "N/A"), label: "Map.get(:missing)")

# But dot notation for missing keys raises!
# book.missing  # Would raise KeyError

# Check struct type
IO.inspect(book.__struct__ == Book, label: "Is a Book struct?")

# -----------------------------------------------------------------------------
# Section 5: Updating Structs
# -----------------------------------------------------------------------------

IO.puts("\n--- Updating Structs ---")

defmodule Task do
  defstruct [:title, :description, status: :pending, priority: :normal]
end

task = %Task{title: "Learn Elixir", description: "Complete the tutorial"}
IO.inspect(task, label: "Original task")

# Update syntax (only for existing fields!)
updated = %{task | status: :in_progress}
IO.inspect(updated, label: "Status updated")

# Multiple updates at once
updated = %{task | status: :completed, priority: :high}
IO.inspect(updated, label: "Multiple updates")

# This would raise - field doesn't exist:
# %{task | invalid_field: "oops"}

# The original is unchanged (immutability!)
IO.inspect(task, label: "Original unchanged")

# Using Map functions (less common with structs)
updated = Map.put(task, :status, :done)
IO.inspect(updated, label: "Using Map.put")

# struct/2 and struct!/2 for updates
updated = struct(task, status: :completed, priority: :low)
IO.inspect(updated, label: "Using struct/2")

# struct/2 ignores unknown keys
updated = struct(task, status: :done, unknown: "ignored")
IO.inspect(updated, label: "struct/2 ignores unknown")

# struct!/2 raises on unknown keys
# struct!(task, unknown: "error")  # Would raise!

# -----------------------------------------------------------------------------
# Section 6: Pattern Matching with Structs
# -----------------------------------------------------------------------------

IO.puts("\n--- Pattern Matching with Structs ---")

defmodule Order do
  defstruct [:id, :customer, :items, status: :pending, total: 0.0]
end

order = %Order{id: 1, customer: "Alice", items: ["Widget"], total: 99.99}

# Match struct type
%Order{} = order  # Matches any Order struct
IO.puts("Matched Order struct")

# Extract specific fields
%Order{customer: customer, total: total} = order
IO.inspect({customer, total}, label: "Extracted customer and total")

# Match literal values
%Order{status: :pending} = order  # Works!
IO.puts("Matched pending order")

# Pattern matching in function heads
defmodule OrderProcessor do
  def process(%Order{status: :pending} = order) do
    "Processing pending order ##{order.id} for #{order.customer}"
  end

  def process(%Order{status: :shipped} = order) do
    "Order ##{order.id} already shipped"
  end

  def process(%Order{status: :completed}) do
    "Order already completed"
  end

  def process(%Order{} = order) do
    "Order ##{order.id} has status: #{order.status}"
  end
end

IO.puts(OrderProcessor.process(%Order{id: 1, customer: "Alice"}))
IO.puts(OrderProcessor.process(%Order{id: 2, customer: "Bob", status: :shipped}))
IO.puts(OrderProcessor.process(%Order{id: 3, customer: "Charlie", status: :completed}))
IO.puts(OrderProcessor.process(%Order{id: 4, customer: "Dave", status: :cancelled}))

# Structs only match their own type!
# %Order{} = %{}  # Would fail - not an Order!

# -----------------------------------------------------------------------------
# Section 7: Struct Type Safety
# -----------------------------------------------------------------------------

IO.puts("\n--- Struct Type Safety ---")

defmodule Email do
  defstruct [:to, :subject, :body, sent: false]
end

defmodule SMS do
  defstruct [:to, :message, sent: false]
end

# Different struct types don't match
email = %Email{to: "test@example.com", subject: "Hi", body: "Hello"}
sms = %SMS{to: "+1234567890", message: "Hello"}

IO.inspect(email, label: "Email")
IO.inspect(sms, label: "SMS")

# Type-safe function
defmodule Notifier do
  def send(%Email{} = email) do
    "Sending email to #{email.to}: #{email.subject}"
  end

  def send(%SMS{} = sms) do
    "Sending SMS to #{sms.to}: #{sms.message}"
  end

  # This won't match plain maps
  def send(other) do
    "Unknown notification type: #{inspect(other)}"
  end
end

IO.puts(Notifier.send(email))
IO.puts(Notifier.send(sms))
IO.puts(Notifier.send(%{to: "someone", message: "hi"}))

# This compile-time safety is a major benefit of structs!

# -----------------------------------------------------------------------------
# Section 8: Structs and Protocols
# -----------------------------------------------------------------------------

IO.puts("\n--- Structs and Protocols ---")

# Structs can implement protocols (covered in depth later)
# Here's a preview using the built-in Inspect protocol

defmodule SecretData do
  defstruct [:id, :password, :api_key]

  # Custom inspect to hide sensitive data
  defimpl Inspect do
    def inspect(%SecretData{id: id}, _opts) do
      "#SecretData<id: #{id}, [REDACTED]>"
    end
  end
end

secret = %SecretData{id: 1, password: "hunter2", api_key: "abc123"}
IO.inspect(secret, label: "Secret data")
# Sensitive fields are hidden!

# Compare with a regular struct
IO.inspect(%Book{title: "Test", author: "Someone"}, label: "Regular struct")

# -----------------------------------------------------------------------------
# Section 9: Common Patterns with Structs
# -----------------------------------------------------------------------------

IO.puts("\n--- Common Patterns with Structs ---")

# Pattern 1: Constructor functions
defmodule Person do
  defstruct [:name, :email, age: 0, active: true]

  # Named constructor
  def new(name, email, opts \\ []) do
    age = Keyword.get(opts, :age, 0)
    active = Keyword.get(opts, :active, true)
    %Person{name: name, email: email, age: age, active: active}
  end

  # Alternative constructors
  def guest(name) do
    %Person{name: name, email: "guest@example.com", active: false}
  end
end

IO.inspect(Person.new("Alice", "alice@test.com"), label: "Person.new")
IO.inspect(Person.new("Bob", "bob@test.com", age: 25), label: "With options")
IO.inspect(Person.guest("Visitor"), label: "Person.guest")

# Pattern 2: Validation in constructor
defmodule Account do
  @enforce_keys [:email]
  defstruct [:email, :username, balance: 0.0]

  def new(email, username \\ nil) when is_binary(email) do
    if String.contains?(email, "@") do
      {:ok, %Account{email: email, username: username || email_to_username(email)}}
    else
      {:error, :invalid_email}
    end
  end

  defp email_to_username(email) do
    email |> String.split("@") |> List.first()
  end
end

IO.inspect(Account.new("alice@example.com"), label: "Valid account")
IO.inspect(Account.new("invalid"), label: "Invalid email")

# Pattern 3: Transformation functions
defmodule Player do
  defstruct [:name, score: 0, level: 1]

  def add_points(%Player{} = player, points) when points > 0 do
    new_score = player.score + points
    new_level = div(new_score, 100) + 1
    %{player | score: new_score, level: new_level}
  end

  def reset_score(%Player{} = player) do
    %{player | score: 0, level: 1}
  end
end

player = %Player{name: "Gamer"}
IO.inspect(player, label: "Initial")

player = Player.add_points(player, 50)
IO.inspect(player, label: "After 50 points")

player = Player.add_points(player, 75)
IO.inspect(player, label: "After 75 more points")

player = Player.reset_score(player)
IO.inspect(player, label: "After reset")

# -----------------------------------------------------------------------------
# Section 10: Structs vs Maps
# -----------------------------------------------------------------------------

IO.puts("\n--- Structs vs Maps ---")

IO.puts("""
When to use Structs:
  - Known, fixed set of fields
  - Want compile-time guarantees
  - Need type-based pattern matching
  - Building domain models
  - Want to implement protocols

When to use Maps:
  - Dynamic/unknown keys
  - External data (JSON, user input)
  - Simple data passing
  - No need for type guarantees

Key differences:
  - Structs: compile-time field checking
  - Structs: can't add arbitrary keys
  - Structs: pattern match on type
  - Maps: flexible, dynamic keys
""")

# Example: Use struct for internal model
defmodule UserModel do
  defstruct [:id, :name, :email]
end

# Example: Use map for external/dynamic data
external_data = %{"id" => 1, "name" => "Alice", "extra_field" => "value"}
IO.inspect(external_data, label: "External data (map)")

# Convert to struct when needed
user = %UserModel{
  id: external_data["id"],
  name: external_data["name"],
  email: external_data["email"]  # Will be nil
}
IO.inspect(user, label: "Internal model (struct)")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: Define a Struct
# Difficulty: Easy
#
# Define a struct called Car with:
# - make (required)
# - model (required)
# - year (default: current year)
# - mileage (default: 0)
# - color (default: nil)
#
# Create 2-3 Car instances with different values.
#
# Your code here:

IO.puts("\nExercise 1: Define Car struct")

# Exercise 2: Constructor Function
# Difficulty: Easy
#
# Add a new/3 function to a Rectangle struct that:
# - Takes width, height, and optional color
# - Returns the struct
# - Also add an area/1 function that calculates width * height
#
# defmodule Rectangle do
#   defstruct [:width, :height, color: :black]
#
#   def new(width, height, opts \\ []) do
#     # Your implementation
#   end
#
#   def area(%Rectangle{} = rect) do
#     # Your implementation
#   end
# end
#
# Your code here:

IO.puts("\nExercise 2: Rectangle with constructor")

# Exercise 3: Pattern Matching
# Difficulty: Medium
#
# Create a StatusMessage struct with fields: type, content, timestamp
# Types can be: :info, :warning, :error
#
# Create a format_message/1 function that returns different strings
# based on the message type using pattern matching.
#
# Your code here:

IO.puts("\nExercise 3: Pattern matching with struct")

# Exercise 4: State Transitions
# Difficulty: Medium
#
# Create a TrafficLight struct with a :color field (default: :red)
# Valid colors are: :red, :yellow, :green
#
# Implement next_state/1 that cycles through the colors:
# red -> green -> yellow -> red
#
# Also implement is_go?/1 that returns true only for green
#
# Your code here:

IO.puts("\nExercise 4: Traffic light state machine")

# Exercise 5: Bank Account
# Difficulty: Hard
#
# Create a BankAccount struct with:
# - account_number (required)
# - owner (required)
# - balance (default: 0.0)
# - status (default: :active)
#
# Implement these functions:
# - deposit/2: add money (only if active, positive amount)
# - withdraw/2: remove money (only if active, sufficient balance)
# - freeze/1: change status to :frozen
# - close/1: change status to :closed (only if balance is 0)
#
# Each function should return {:ok, updated_account} or {:error, reason}
#
# Your code here:

IO.puts("\nExercise 5: Bank account operations")

# Exercise 6: Polymorphic Handling
# Difficulty: Hard
#
# Create structs for different shapes: Circle, Square, Triangle
# Each should have appropriate fields (radius, side, base/height)
#
# Create a Geometry module with:
# - area/1 that calculates area for any shape
# - describe/1 that returns a string description
#
# Use pattern matching on the struct type.
#
# Your code here:

IO.puts("\nExercise 6: Polymorphic shapes")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

1. Structs are maps with compile-time guarantees:
   - defstruct [:field1, :field2, field3: default]
   - @enforce_keys for required fields

2. Creating structs:
   - %ModuleName{field: value}
   - Constructor functions: Module.new(args)

3. Accessing fields:
   - struct.field (preferred)
   - struct[:field]
   - Map.get(struct, :field)

4. Updating structs:
   - %{struct | field: new_value}
   - struct(old_struct, changes)

5. Pattern matching:
   - %ModuleName{} matches type
   - %ModuleName{field: value} extracts/matches
   - Great for type-safe function dispatch

6. Benefits over maps:
   - Compile-time field checking
   - Cannot add arbitrary keys
   - Type-based pattern matching
   - Protocol implementations

7. Common patterns:
   - Constructor functions (new/1, new/2)
   - Validation in constructors
   - Transformation functions
   - State machines

Next: 09_pattern_matching.exs - Deep dive into pattern matching
""")
