# ============================================================================
# Lesson 22: Protocols
# ============================================================================
#
# Protocols are Elixir's mechanism for achieving ad-hoc polymorphism.
# Unlike behaviours (which are module-based), protocols dispatch based
# on the data type of the first argument.
#
# Learning Objectives:
# - Understand the difference between protocols and behaviours
# - Define protocols with defprotocol
# - Implement protocols with defimpl
# - Work with built-in protocols (String.Chars, Enumerable, etc.)
# - Implement protocols for custom structs
# - Use protocol consolidation
# - Handle fallbacks with Any
#
# Prerequisites:
# - Understanding of modules (Lesson 19)
# - Understanding of behaviours (Lesson 21)
# - Understanding of structs
#
# ============================================================================

IO.puts("=" |> String.duplicate(70))
IO.puts("Lesson 22: Protocols")
IO.puts("=" |> String.duplicate(70))

# -----------------------------------------------------------------------------
# Section 1: What Are Protocols?
# -----------------------------------------------------------------------------
#
# Protocols enable polymorphism based on data type. The key difference
# from behaviours:
#
# - Behaviours: Module implements interface (module-based dispatch)
# - Protocols: Type implements interface (data-type dispatch)
#
# Example: The String.Chars protocol allows different types to define
# how they convert to strings via to_string/1.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 1: What Are Protocols? ---\n")

IO.puts("""
Protocols vs Behaviours:

Behaviours:
  - Contract for modules
  - Module declares @behaviour
  - Called as Module.function(args)

Protocols:
  - Contract for data types
  - Types implement with defimpl
  - Called as Protocol.function(data)
  - Dispatch based on first argument's type

Example: String.Chars protocol
  - to_string(123)    -> dispatches to Integer implementation
  - to_string(:hello) -> dispatches to Atom implementation
  - to_string("hi")   -> dispatches to BitString implementation
""")

# Demonstrate built-in String.Chars protocol
IO.puts("Built-in String.Chars protocol examples:")
IO.puts("  to_string(123) = #{to_string(123)}")
IO.puts("  to_string(:hello) = #{to_string(:hello)}")
IO.puts("  to_string([1,2,3]) = #{to_string([1, 2, 3])}")
IO.puts("  to_string(3.14) = #{to_string(3.14)}")

# -----------------------------------------------------------------------------
# Section 2: Defining Protocols with defprotocol
# -----------------------------------------------------------------------------
#
# Use defprotocol to define a protocol. Inside, you specify the
# function signatures that implementations must provide.
#
# Syntax:
# defprotocol ProtocolName do
#   @doc "Description"
#   def function_name(data, ...)
# end
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 2: Defining Protocols with defprotocol ---\n")

# Define a simple protocol for size/length
defprotocol Sizeable do
  @moduledoc """
  A protocol for getting the size of data structures.
  """

  @doc "Returns the size/length of the data structure"
  def size(data)
end

# Define a protocol for JSON encoding
defprotocol JSONEncodable do
  @moduledoc """
  A protocol for converting data to JSON strings.
  """

  @doc "Converts the data to a JSON string representation"
  def encode(data)

  @doc "Returns the JSON type name"
  def type_name(data)
end

# Define a protocol with multiple functions
defprotocol Printable do
  @moduledoc """
  A protocol for human-readable printing.
  """

  @doc "Returns a short representation (for logs, debugging)"
  def short(data)

  @doc "Returns a detailed representation (for display)"
  def detailed(data)

  @doc "Returns a representation suitable for reports"
  def for_report(data)
end

IO.puts("Defined protocols: Sizeable, JSONEncodable, Printable")

# -----------------------------------------------------------------------------
# Section 3: Implementing Protocols with defimpl
# -----------------------------------------------------------------------------
#
# Use defimpl to implement a protocol for a specific type.
#
# Syntax:
# defimpl ProtocolName, for: TypeName do
#   def function_name(data, ...) do
#     ...
#   end
# end
#
# TypeName can be: Integer, Float, Atom, BitString, List, Map, Tuple,
# Function, PID, Port, Reference, or any struct module name.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 3: Implementing Protocols with defimpl ---\n")

# Implement Sizeable for built-in types
defimpl Sizeable, for: BitString do
  def size(string), do: String.length(string)
end

defimpl Sizeable, for: List do
  def size(list), do: length(list)
end

defimpl Sizeable, for: Map do
  def size(map), do: map_size(map)
end

defimpl Sizeable, for: Tuple do
  def size(tuple), do: tuple_size(tuple)
end

# Test the Sizeable implementations
IO.puts("Sizeable protocol implementations:")
IO.puts("  Sizeable.size(\"hello\") = #{Sizeable.size("hello")}")
IO.puts("  Sizeable.size([1,2,3,4,5]) = #{Sizeable.size([1, 2, 3, 4, 5])}")
IO.puts("  Sizeable.size(%{a: 1, b: 2}) = #{Sizeable.size(%{a: 1, b: 2})}")
IO.puts("  Sizeable.size({1, 2, 3}) = #{Sizeable.size({1, 2, 3})}")

# Implement JSONEncodable for built-in types
defimpl JSONEncodable, for: Integer do
  def encode(int), do: Integer.to_string(int)
  def type_name(_), do: "number"
end

defimpl JSONEncodable, for: Float do
  def encode(float), do: Float.to_string(float)
  def type_name(_), do: "number"
end

defimpl JSONEncodable, for: BitString do
  def encode(string), do: "\"#{escape(string)}\""
  def type_name(_), do: "string"

  defp escape(string) do
    string
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
    |> String.replace("\n", "\\n")
    |> String.replace("\t", "\\t")
  end
end

defimpl JSONEncodable, for: Atom do
  def encode(nil), do: "null"
  def encode(true), do: "true"
  def encode(false), do: "false"
  def encode(atom), do: "\"#{Atom.to_string(atom)}\""

  def type_name(nil), do: "null"
  def type_name(bool) when is_boolean(bool), do: "boolean"
  def type_name(_), do: "string"
end

defimpl JSONEncodable, for: List do
  def encode(list) do
    elements = Enum.map(list, &JSONEncodable.encode/1)
    "[#{Enum.join(elements, ",")}]"
  end
  def type_name(_), do: "array"
end

defimpl JSONEncodable, for: Map do
  def encode(map) do
    pairs = Enum.map(map, fn {k, v} ->
      key = if is_atom(k), do: Atom.to_string(k), else: to_string(k)
      "\"#{key}\":#{JSONEncodable.encode(v)}"
    end)
    "{#{Enum.join(pairs, ",")}}"
  end
  def type_name(_), do: "object"
end

IO.puts("\nJSONEncodable protocol implementations:")
IO.puts("  encode(42) = #{JSONEncodable.encode(42)}")
IO.puts("  encode(3.14) = #{JSONEncodable.encode(3.14)}")
IO.puts("  encode(\"hello\") = #{JSONEncodable.encode("hello")}")
IO.puts("  encode(true) = #{JSONEncodable.encode(true)}")
IO.puts("  encode(nil) = #{JSONEncodable.encode(nil)}")
IO.puts("  encode([1,2,3]) = #{JSONEncodable.encode([1, 2, 3])}")
IO.puts("  encode(%{name: \"Alice\", age: 30}) = #{JSONEncodable.encode(%{name: "Alice", age: 30})}")

# Nested structures
nested = %{
  users: [
    %{name: "Alice", active: true},
    %{name: "Bob", active: false}
  ],
  count: 2
}
IO.puts("  encode(nested) = #{JSONEncodable.encode(nested)}")

# -----------------------------------------------------------------------------
# Section 4: Protocols for Custom Structs
# -----------------------------------------------------------------------------
#
# Protocols really shine when working with custom structs. Each struct
# is its own type, so you can implement protocols specifically for it.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 4: Protocols for Custom Structs ---\n")

# Define some structs
defmodule User do
  defstruct [:id, :name, :email, :role]
end

defmodule Product do
  defstruct [:id, :name, :price, :category]
end

defmodule Order do
  defstruct [:id, :user, :items, :total, :status]
end

# Implement Printable for User
defimpl Printable, for: User do
  def short(%User{name: name, role: role}) do
    "#{name} (#{role})"
  end

  def detailed(%User{id: id, name: name, email: email, role: role}) do
    """
    User ##{id}
      Name: #{name}
      Email: #{email}
      Role: #{role}
    """
  end

  def for_report(%User{id: id, name: name, role: role}) do
    "| #{id} | #{name} | #{role} |"
  end
end

# Implement Printable for Product
defimpl Printable, for: Product do
  def short(%Product{name: name, price: price}) do
    "#{name} ($#{price})"
  end

  def detailed(%Product{id: id, name: name, price: price, category: category}) do
    """
    Product ##{id}
      Name: #{name}
      Price: $#{price}
      Category: #{category}
    """
  end

  def for_report(%Product{id: id, name: name, price: price, category: category}) do
    "| #{id} | #{name} | $#{price} | #{category} |"
  end
end

# Implement Printable for Order
defimpl Printable, for: Order do
  def short(%Order{id: id, total: total, status: status}) do
    "Order ##{id}: $#{total} (#{status})"
  end

  def detailed(%Order{id: id, user: user, items: items, total: total, status: status}) do
    items_str = Enum.map(items, &Printable.short/1) |> Enum.join(", ")
    """
    Order ##{id}
      Customer: #{Printable.short(user)}
      Items: #{items_str}
      Total: $#{total}
      Status: #{status}
    """
  end

  def for_report(%Order{id: id, user: user, total: total, status: status}) do
    "| #{id} | #{user.name} | $#{total} | #{status} |"
  end
end

# Implement Sizeable for our structs
defimpl Sizeable, for: Order do
  def size(%Order{items: items}), do: length(items)
end

# Implement JSONEncodable for our structs
defimpl JSONEncodable, for: User do
  def encode(%User{} = user) do
    JSONEncodable.encode(%{
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role
    })
  end
  def type_name(_), do: "User"
end

defimpl JSONEncodable, for: Product do
  def encode(%Product{} = product) do
    JSONEncodable.encode(%{
      id: product.id,
      name: product.name,
      price: product.price,
      category: product.category
    })
  end
  def type_name(_), do: "Product"
end

# Create instances and test
user = %User{id: 1, name: "Alice", email: "alice@example.com", role: :admin}
product1 = %Product{id: 101, name: "Widget", price: 29.99, category: "Tools"}
product2 = %Product{id: 102, name: "Gadget", price: 49.99, category: "Electronics"}
order = %Order{id: 1001, user: user, items: [product1, product2], total: 79.98, status: :pending}

IO.puts("Printable protocol for custom structs:")
IO.puts("\nUser short: #{Printable.short(user)}")
IO.puts("Product short: #{Printable.short(product1)}")
IO.puts("Order short: #{Printable.short(order)}")

IO.puts("\nUser detailed:")
IO.puts(Printable.detailed(user))

IO.puts("Order detailed:")
IO.puts(Printable.detailed(order))

IO.puts("Report format:")
IO.puts("| ID | Name | Role |")
IO.puts(Printable.for_report(user))
IO.puts("\n| ID | Name | Price | Category |")
IO.puts(Printable.for_report(product1))
IO.puts(Printable.for_report(product2))

IO.puts("\nSizeable for Order (item count): #{Sizeable.size(order)}")

IO.puts("\nJSONEncodable for User:")
IO.puts(JSONEncodable.encode(user))

IO.puts("\nJSONEncodable for Product:")
IO.puts(JSONEncodable.encode(product1))

# -----------------------------------------------------------------------------
# Section 5: The Any Fallback
# -----------------------------------------------------------------------------
#
# You can define a fallback implementation using `for: Any` that handles
# any type that doesn't have a specific implementation.
#
# To use Any, the protocol must be defined with @fallback_to_any true,
# or the struct must derive the protocol.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 5: The Any Fallback ---\n")

# Define a protocol with fallback enabled
defprotocol Describable do
  @fallback_to_any true

  @doc "Returns a human-readable description"
  def describe(data)
end

# Implement for Any - this is the fallback
defimpl Describable, for: Any do
  def describe(data) do
    "A #{inspect(data.__struct__ || :unknown)} value: #{inspect(data)}"
  end
end

# Specific implementations override the fallback
defimpl Describable, for: Integer do
  def describe(int), do: "The integer #{int}"
end

defimpl Describable, for: List do
  def describe([]), do: "An empty list"
  def describe(list), do: "A list with #{length(list)} elements"
end

defimpl Describable, for: User do
  def describe(%User{name: name}), do: "A user named #{name}"
end

# Test fallback behavior
IO.puts("Describable protocol with Any fallback:")
IO.puts("  Integer: #{Describable.describe(42)}")
IO.puts("  List: #{Describable.describe([1, 2, 3])}")
IO.puts("  User: #{Describable.describe(user)}")

# Structs without specific implementation use Any fallback
defmodule UnknownThing do
  defstruct [:data]
end

unknown = %UnknownThing{data: "mystery"}
IO.puts("  UnknownThing (fallback): #{Describable.describe(unknown)}")

# Using @derive to opt into Any implementation
defmodule DerivedStruct do
  @derive [Describable]  # Uses the Any implementation
  defstruct [:value]
end

derived = %DerivedStruct{value: 123}
IO.puts("  DerivedStruct (derived): #{Describable.describe(derived)}")

# -----------------------------------------------------------------------------
# Section 6: Deriving Protocols
# -----------------------------------------------------------------------------
#
# The @derive attribute lets a struct automatically get an implementation
# of a protocol, either from Any or from a custom derivation mechanism.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 6: Deriving Protocols ---\n")

# Example: Deriving Inspect for custom representation
defmodule SecretData do
  # Derive with custom options
  @derive {Inspect, only: [:id, :name]}
  defstruct [:id, :name, :secret_key, :password]
end

secret = %SecretData{
  id: 1,
  name: "Configuration",
  secret_key: "super-secret-key-12345",
  password: "password123"
}

IO.puts("SecretData with derived Inspect (hides sensitive fields):")
IO.inspect(secret)

# Another example with Enumerable derive would require implementing
# a custom derive mechanism, which is advanced

# Protocol with custom derive implementation
defprotocol Taggable do
  @fallback_to_any true
  def tags(data)
end

defimpl Taggable, for: Any do
  # Default: use struct name as tag
  def tags(%{__struct__: module}) do
    [module |> Module.split() |> List.last() |> String.downcase() |> String.to_atom()]
  end

  def tags(_), do: [:unknown]
end

defmodule BlogPost do
  @derive [Taggable]
  defstruct [:title, :body, :author]
end

defmodule Comment do
  @derive [Taggable]
  defstruct [:content, :author]
end

post = %BlogPost{title: "Hello", body: "World", author: "Alice"}
comment = %Comment{content: "Great post!", author: "Bob"}

IO.puts("\nTaggable protocol with derive:")
IO.puts("  BlogPost tags: #{inspect(Taggable.tags(post))}")
IO.puts("  Comment tags: #{inspect(Taggable.tags(comment))}")

# -----------------------------------------------------------------------------
# Section 7: Built-in Protocols
# -----------------------------------------------------------------------------
#
# Elixir comes with several built-in protocols:
# - String.Chars - for to_string/1
# - Inspect - for inspect/1 (debugging representation)
# - Enumerable - for Enum functions
# - Collectable - for Enum.into/2
# - List.Chars - for to_charlist/1
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 7: Built-in Protocols ---\n")

# Implementing String.Chars for a custom struct
defmodule Money do
  defstruct [:amount, :currency]

  def new(amount, currency \\ :USD) do
    %Money{amount: amount, currency: currency}
  end
end

defimpl String.Chars, for: Money do
  def to_string(%Money{amount: amount, currency: currency}) do
    symbol = case currency do
      :USD -> "$"
      :EUR -> "€"
      :GBP -> "£"
      :JPY -> "¥"
      _ -> "#{currency} "
    end
    "#{symbol}#{:erlang.float_to_binary(amount / 1, decimals: 2)}"
  end
end

money_usd = Money.new(1999, :USD)
money_eur = Money.new(1599, :EUR)

IO.puts("String.Chars implementation for Money:")
IO.puts("  #{money_usd}")
IO.puts("  #{money_eur}")
IO.puts("  Interpolation works: I have #{money_usd} in my wallet")

# Implementing Inspect for custom representation
defimpl Inspect, for: Money do
  import Inspect.Algebra

  def inspect(%Money{amount: amount, currency: currency}, opts) do
    concat([
      "#Money<",
      to_doc(amount, opts),
      " ",
      to_doc(currency, opts),
      ">"
    ])
  end
end

IO.puts("\nInspect implementation for Money:")
IO.inspect(money_usd)
IO.inspect(money_eur)

# Implementing Enumerable for a custom collection
defmodule Playlist do
  defstruct [:name, :songs]

  def new(name, songs \\ []) do
    %Playlist{name: name, songs: songs}
  end

  def add_song(%Playlist{songs: songs} = playlist, song) do
    %{playlist | songs: songs ++ [song]}
  end
end

defimpl Enumerable, for: Playlist do
  def count(%Playlist{songs: songs}) do
    {:ok, length(songs)}
  end

  def member?(%Playlist{songs: songs}, song) do
    {:ok, song in songs}
  end

  def reduce(%Playlist{songs: songs}, acc, fun) do
    Enumerable.List.reduce(songs, acc, fun)
  end

  def slice(%Playlist{songs: songs}) do
    size = length(songs)
    {:ok, size, &Enum.slice(songs, &1, &2)}
  end
end

playlist = Playlist.new("My Favorites")
|> Playlist.add_song("Song A")
|> Playlist.add_song("Song B")
|> Playlist.add_song("Song C")

IO.puts("\nEnumerable implementation for Playlist:")
IO.puts("  Count: #{Enum.count(playlist)}")
IO.puts("  Member? 'Song A': #{Enum.member?(playlist, "Song A")}")
IO.puts("  Member? 'Song Z': #{Enum.member?(playlist, "Song Z")}")
IO.puts("  First: #{Enum.at(playlist, 0)}")
IO.puts("  All songs: #{inspect(Enum.to_list(playlist))}")
IO.puts("  Uppercase: #{inspect(Enum.map(playlist, &String.upcase/1))}")

# Implementing Collectable
defimpl Collectable, for: Playlist do
  def into(%Playlist{name: name, songs: songs}) do
    collector_fun = fn
      list, {:cont, song} -> [song | list]
      list, :done -> %Playlist{name: name, songs: songs ++ Enum.reverse(list)}
      _list, :halt -> :ok
    end

    {[], collector_fun}
  end
end

IO.puts("\nCollectable implementation for Playlist:")
new_songs = ["Song D", "Song E"]
updated_playlist = Enum.into(new_songs, playlist)
IO.puts("  After adding songs: #{inspect(Enum.to_list(updated_playlist))}")

# Using for comprehension (uses both Enumerable and Collectable)
numbered = for {song, idx} <- Enum.with_index(playlist, 1), into: Playlist.new("Numbered") do
  "#{idx}. #{song}"
end
IO.puts("  Numbered songs: #{inspect(Enum.to_list(numbered))}")

# -----------------------------------------------------------------------------
# Section 8: Protocol Consolidation
# -----------------------------------------------------------------------------
#
# In production, Elixir consolidates protocols for performance.
# During development, protocols are dispatched dynamically.
#
# Consolidation pre-computes the dispatch table, making protocol
# calls much faster.
#
# This is automatic in Mix projects with `mix compile`.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 8: Protocol Consolidation ---\n")

IO.puts("""
Protocol Consolidation:

In development:
- Protocols dispatch dynamically at runtime
- Allows for redefining implementations
- Slightly slower but more flexible

In production (after mix compile --force):
- Protocols are consolidated
- Dispatch tables are pre-computed
- Much faster protocol calls
- No runtime protocol implementation changes

Check if a protocol is consolidated:
  Protocol.consolidated?(Enumerable)  # true in compiled code

In your mix.exs:
  def project do
    [
      # Consolidation is enabled by default for :prod
      consolidate_protocols: Mix.env() == :prod
    ]
  end
""")

# -----------------------------------------------------------------------------
# Section 9: Protocols vs Behaviours - When to Use Each
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 9: Protocols vs Behaviours ---\n")

IO.puts("""
When to use PROTOCOLS:
- Polymorphism based on DATA TYPE
- Different types need the same operation
- You control the protocol definition
- External types can implement your protocol
- Examples: to_string, inspect, encode/decode

When to use BEHAVIOURS:
- Polymorphism based on MODULES
- Multiple modules implementing same interface
- Callback-based design (like GenServer)
- Plugin systems
- Examples: GenServer, Supervisor, Ecto.Adapter

Key Differences:

  Protocols:                    Behaviours:
  - defprotocol + defimpl       - @callback + @behaviour
  - Dispatch on first arg type  - Dispatch on module
  - Type-based polymorphism     - Module-based polymorphism
  - Can extend external types   - Module implements interface

Example scenarios:

  Protocol: "I want all data types to be convertible to JSON"
  -> defprotocol JSONEncodable

  Behaviour: "I want multiple storage backends with same API"
  -> @callback for Storage behaviour

  Protocol: "I want to customize how my struct is displayed"
  -> defimpl Inspect, for: MyStruct

  Behaviour: "I want to build a plugin system"
  -> Define @callbacks that plugins must implement
""")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Exercise 1: Define and Implement a Simple Protocol
Difficulty: Easy

Create a protocol called `Measurable` with:
- measure(data) :: {number(), String.t()}  # Returns {value, unit}

Implement it for:
- BitString (returns character count, unit: "characters")
- List (returns length, unit: "elements")
- Map (returns key count, unit: "keys")

Test with sample data.

Your code here:
""")

# defprotocol Measurable do
#   ...
# end
#
# defimpl Measurable, for: BitString do
#   ...
# end

IO.puts("""

Exercise 2: Protocol for Custom Structs
Difficulty: Easy

Create:
1. A `Circle` struct with :radius
2. A `Square` struct with :side
3. A `Triangle` struct with :base and :height

Then create a `Geometry` protocol with:
- area(shape) :: float()
- perimeter(shape) :: float()

Implement the protocol for all three structs.

Your code here:
""")

# defmodule Circle do
#   defstruct [:radius]
# end
#
# defprotocol Geometry do
#   ...
# end

IO.puts("""

Exercise 3: Implement String.Chars
Difficulty: Medium

Create a `Duration` struct with :hours, :minutes, :seconds fields.

Implement the String.Chars protocol so that:
- Duration with 1 hour, 30 minutes, 45 seconds displays as "1h 30m 45s"
- Zero values should be omitted: 0 hours, 5 minutes, 0 seconds -> "5m"
- Handle edge cases (all zeros -> "0s")

Your code here:
""")

# defmodule Duration do
#   defstruct hours: 0, minutes: 0, seconds: 0
# end
#
# defimpl String.Chars, for: Duration do
#   ...
# end

IO.puts("""

Exercise 4: Protocol with Any Fallback
Difficulty: Medium

Create a `Hashable` protocol with:
- hash(data) :: String.t()

Implement it with:
- A fallback for Any that uses :erlang.phash2
- Specific implementation for BitString using SHA256
- Specific implementation for Map that hashes sorted key-value pairs

Use @fallback_to_any true and test with various types.

Your code here:
""")

# defprotocol Hashable do
#   @fallback_to_any true
#   ...
# end

IO.puts("""

Exercise 5: Implement Enumerable
Difficulty: Hard

Create a `Range2D` struct representing a 2D range of coordinates:
  %Range2D{x_range: 0..2, y_range: 0..2}

Implement Enumerable so that you can:
- Enumerate all {x, y} coordinate pairs
- Use Enum.count, Enum.member?, etc.
- Use in for comprehensions

Example:
  range = %Range2D{x_range: 0..1, y_range: 0..1}
  Enum.to_list(range)  # [{0,0}, {0,1}, {1,0}, {1,1}]

Your code here:
""")

# defmodule Range2D do
#   defstruct [:x_range, :y_range]
# end
#
# defimpl Enumerable, for: Range2D do
#   ...
# end

IO.puts("""

Exercise 6: Complete Protocol Suite
Difficulty: Hard

Create a `Fraction` struct for representing fractions:
  %Fraction{numerator: 1, denominator: 2}  # represents 1/2

Implement these protocols:
1. String.Chars - display as "1/2"
2. Inspect - display as #Fraction<1/2>
3. A custom `Numeric` protocol with:
   - add(a, b)
   - subtract(a, b)
   - multiply(a, b)
   - divide(a, b)
   - to_float(a)

Include functions to create and simplify fractions.
Implement Numeric for both Fraction and Integer.

Your code here:
""")

# defmodule Fraction do
#   defstruct [:numerator, :denominator]
#
#   def new(num, denom) do
#     ...
#   end
#
#   def simplify(%Fraction{} = f) do
#     ...
#   end
# end
#
# defprotocol Numeric do
#   ...
# end

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Key takeaways from this lesson:

1. Protocols Enable Type-Based Polymorphism:
   - Different types can implement the same interface
   - Dispatch based on the first argument's type
   - Think: "how should THIS type handle THIS operation?"

2. Defining Protocols:
   defprotocol ProtocolName do
     def function(data)
     def another(data, arg)
   end

3. Implementing Protocols:
   defimpl ProtocolName, for: TypeName do
     def function(data), do: ...
   end

4. Available Types for Implementation:
   - Built-in: Integer, Float, Atom, BitString, List, Map, Tuple
   - Structs: Use the module name
   - Any: Fallback for unimplemented types

5. The Any Fallback:
   - Enable with @fallback_to_any true in protocol
   - Or use @derive [ProtocolName] in struct
   - Provides default behavior for all types

6. Built-in Protocols:
   - String.Chars (to_string/1)
   - Inspect (inspect/1)
   - Enumerable (Enum functions)
   - Collectable (Enum.into/2)

7. Protocols vs Behaviours:
   - Protocols: Data-type polymorphism
   - Behaviours: Module-based polymorphism
   - Choose based on what you're dispatching on

8. Protocol Consolidation:
   - Automatic in Mix projects
   - Pre-computes dispatch for performance
   - Enabled in production builds

9. Best Practices:
   - Implement String.Chars for user-facing display
   - Implement Inspect for developer-facing debugging
   - Consider Enumerable for collection-like structs
   - Use @derive when Any implementation is sufficient

This completes the module system fundamentals!
Next section: Concurrency and OTP basics
""")
