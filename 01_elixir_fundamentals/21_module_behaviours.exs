# ============================================================================
# Lesson 21: Module Behaviours
# ============================================================================
#
# Behaviours in Elixir provide a way to define a set of function signatures
# that a module must implement. They're similar to interfaces in other
# languages and enable polymorphism through a contract-based approach.
#
# Learning Objectives:
# - Understand what behaviours are and why they're useful
# - Define behaviours with @callback
# - Implement behaviours with @behaviour
# - Use @impl for explicit callback implementation
# - Handle optional callbacks with @optional_callbacks
# - Apply behaviours in practical scenarios
#
# Prerequisites:
# - Understanding of modules (Lesson 19)
# - Understanding of import/alias/require/use (Lesson 20)
#
# ============================================================================

IO.puts("=" |> String.duplicate(70))
IO.puts("Lesson 21: Module Behaviours")
IO.puts("=" |> String.duplicate(70))

# -----------------------------------------------------------------------------
# Section 1: What Are Behaviours?
# -----------------------------------------------------------------------------
#
# A behaviour defines a contract - a set of functions that implementing
# modules must provide. This enables:
#
# 1. Polymorphism - Different modules can implement the same interface
# 2. Documentation - Clear specification of required functions
# 3. Compile-time checks - Warnings if callbacks are missing
# 4. Code organization - Consistent APIs across modules
#
# Think of behaviours as "interfaces" or "abstract base classes" from OOP.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 1: What Are Behaviours? ---\n")

IO.puts("""
Behaviours define contracts that modules must follow.

Example: The GenServer behaviour requires:
- init/1
- handle_call/3
- handle_cast/2
- etc.

Any module that declares @behaviour GenServer must implement these callbacks.
""")

# -----------------------------------------------------------------------------
# Section 2: Defining a Behaviour with @callback
# -----------------------------------------------------------------------------
#
# To create a behaviour, define a module with @callback attributes.
# Each @callback specifies a function signature using typespecs.
#
# Syntax:
# @callback function_name(arg_type) :: return_type
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 2: Defining a Behaviour with @callback ---\n")

# Define a Parser behaviour
defmodule Parser do
  @moduledoc """
  A behaviour for parsing different data formats.

  Modules implementing this behaviour must be able to parse
  strings into Elixir data structures and handle errors.
  """

  @doc "Parses a string into a data structure"
  @callback parse(input :: String.t()) :: {:ok, any()} | {:error, String.t()}

  @doc "Returns the supported file extensions"
  @callback extensions() :: [String.t()]

  @doc "Validates if input can be parsed"
  @callback valid?(input :: String.t()) :: boolean()
end

IO.puts("Defined Parser behaviour with callbacks:")
IO.puts("  - parse/1 :: {:ok, any()} | {:error, String.t()}")
IO.puts("  - extensions/0 :: [String.t()]")
IO.puts("  - valid?/1 :: boolean()")

# A more complex behaviour with various return types
defmodule Storage do
  @moduledoc """
  A behaviour for storage backends (database, file, memory, etc.)
  """

  @type key :: String.t() | atom()
  @type value :: any()
  @type error :: {:error, term()}

  @callback get(key()) :: {:ok, value()} | error()
  @callback put(key(), value()) :: :ok | error()
  @callback delete(key()) :: :ok | error()
  @callback list_keys() :: {:ok, [key()]} | error()
  @callback clear() :: :ok | error()
end

IO.puts("\nDefined Storage behaviour with CRUD callbacks")

# -----------------------------------------------------------------------------
# Section 3: Implementing a Behaviour with @behaviour
# -----------------------------------------------------------------------------
#
# To implement a behaviour, declare it with @behaviour and then
# define all required callback functions.
#
# If you forget to implement a callback, you'll get a compile-time warning.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 3: Implementing a Behaviour ---\n")

# Implement the Parser behaviour for JSON (simplified)
defmodule JSONParser do
  @behaviour Parser

  @impl Parser
  def parse(input) do
    # Simplified JSON parsing (in real code, use Jason library)
    try do
      # Very basic "parsing" for demonstration
      cond do
        String.starts_with?(input, "{") and String.ends_with?(input, "}") ->
          {:ok, %{parsed: true, format: :json, content: input}}
        String.starts_with?(input, "[") and String.ends_with?(input, "]") ->
          {:ok, %{parsed: true, format: :json_array, content: input}}
        true ->
          {:error, "Invalid JSON format"}
      end
    rescue
      _ -> {:error, "Parse error"}
    end
  end

  @impl Parser
  def extensions do
    [".json", ".JSON"]
  end

  @impl Parser
  def valid?(input) do
    case parse(input) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end
end

# Implement Parser for CSV
defmodule CSVParser do
  @behaviour Parser

  @impl Parser
  def parse(input) do
    lines = String.split(input, "\n", trim: true)
    rows = Enum.map(lines, &String.split(&1, ","))
    {:ok, rows}
  end

  @impl Parser
  def extensions do
    [".csv", ".CSV"]
  end

  @impl Parser
  def valid?(input) do
    lines = String.split(input, "\n", trim: true)
    Enum.all?(lines, &(String.contains?(&1, ",") or String.length(&1) > 0))
  end
end

# Test the implementations
IO.puts("Testing JSONParser:")
IO.inspect(JSONParser.parse("{\"name\": \"Alice\"}"), label: "  parse JSON object")
IO.inspect(JSONParser.parse("[1, 2, 3]"), label: "  parse JSON array")
IO.inspect(JSONParser.parse("invalid"), label: "  parse invalid")
IO.inspect(JSONParser.extensions(), label: "  extensions")
IO.inspect(JSONParser.valid?("{\"valid\": true}"), label: "  valid?")

IO.puts("\nTesting CSVParser:")
csv_data = "name,age,city\nAlice,30,NYC\nBob,25,LA"
IO.inspect(CSVParser.parse(csv_data), label: "  parse CSV")
IO.inspect(CSVParser.extensions(), label: "  extensions")
IO.inspect(CSVParser.valid?(csv_data), label: "  valid?")

# -----------------------------------------------------------------------------
# Section 4: The @impl Attribute
# -----------------------------------------------------------------------------
#
# @impl marks a function as a callback implementation. This provides:
#
# 1. Documentation - Clear indication of behaviour callbacks
# 2. Compile-time verification - Warning if @impl function isn't a callback
# 3. Better error messages - Helps identify mistakes
#
# You can use @impl true or @impl BehaviourName
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 4: The @impl Attribute ---\n")

defmodule InMemoryStorage do
  @behaviour Storage

  # Using @impl with the behaviour name for clarity
  @impl Storage
  def get(key) do
    case Process.get(key) do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end

  @impl Storage
  def put(key, value) do
    Process.put(key, value)
    :ok
  end

  @impl Storage
  def delete(key) do
    Process.delete(key)
    :ok
  end

  @impl Storage
  def list_keys do
    keys = Process.get_keys()
    |> Enum.filter(&is_atom/1)  # Filter only our keys
    {:ok, keys}
  end

  @impl Storage
  def clear do
    Process.get_keys()
    |> Enum.each(&Process.delete/1)
    :ok
  end

  # Non-callback function (no @impl)
  def count do
    {:ok, keys} = list_keys()
    length(keys)
  end
end

IO.puts("Testing InMemoryStorage:")
IO.inspect(InMemoryStorage.put(:user, "Alice"), label: "  put :user")
IO.inspect(InMemoryStorage.put(:count, 42), label: "  put :count")
IO.inspect(InMemoryStorage.get(:user), label: "  get :user")
IO.inspect(InMemoryStorage.get(:missing), label: "  get :missing")
IO.inspect(InMemoryStorage.count(), label: "  count (non-callback)")
IO.inspect(InMemoryStorage.delete(:count), label: "  delete :count")
IO.inspect(InMemoryStorage.clear(), label: "  clear")

# @impl true is shorthand when there's only one behaviour
defmodule SimpleExample do
  @behaviour Parser

  @impl true  # Equivalent to @impl Parser when only one behaviour
  def parse(input), do: {:ok, input}

  @impl true
  def extensions, do: [".txt"]

  @impl true
  def valid?(_input), do: true
end

IO.puts("\nSimpleExample using @impl true:")
IO.inspect(SimpleExample.parse("hello"), label: "  parse")

# -----------------------------------------------------------------------------
# Section 5: Optional Callbacks
# -----------------------------------------------------------------------------
#
# Sometimes not all callbacks are required. Use @optional_callbacks to
# specify which callbacks are optional.
#
# Modules implementing the behaviour don't need to implement optional
# callbacks (no warnings if missing).
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 5: Optional Callbacks ---\n")

defmodule Plugin do
  @moduledoc """
  A behaviour for application plugins.

  Required: init/1, run/2
  Optional: cleanup/1, configure/1
  """

  @callback init(config :: map()) :: {:ok, state :: any()} | {:error, reason :: term()}
  @callback run(input :: any(), state :: any()) :: {:ok, result :: any()} | {:error, reason :: term()}
  @callback cleanup(state :: any()) :: :ok
  @callback configure(options :: keyword()) :: {:ok, map()} | {:error, term()}

  # Mark cleanup and configure as optional
  @optional_callbacks cleanup: 1, configure: 1

  # Helper to safely call optional callbacks
  def safe_cleanup(module, state) do
    if function_exported?(module, :cleanup, 1) do
      module.cleanup(state)
    else
      :ok
    end
  end

  def safe_configure(module, options) do
    if function_exported?(module, :configure, 1) do
      module.configure(options)
    else
      {:ok, %{}}
    end
  end
end

# Plugin that implements only required callbacks
defmodule MinimalPlugin do
  @behaviour Plugin

  @impl Plugin
  def init(config) do
    {:ok, %{initialized: true, config: config}}
  end

  @impl Plugin
  def run(input, state) do
    result = "Processed: #{inspect(input)} with #{inspect(state)}"
    {:ok, result}
  end

  # cleanup/1 and configure/1 are optional - not implemented
end

# Plugin that implements all callbacks
defmodule FullPlugin do
  @behaviour Plugin

  @impl Plugin
  def init(config) do
    IO.puts("  FullPlugin initializing...")
    {:ok, %{initialized: true, config: config, resources: []}}
  end

  @impl Plugin
  def run(input, state) do
    IO.puts("  FullPlugin running...")
    {:ok, %{input: input, processed_by: __MODULE__, state: state}}
  end

  @impl Plugin
  def cleanup(state) do
    IO.puts("  FullPlugin cleaning up resources: #{inspect(state.resources)}")
    :ok
  end

  @impl Plugin
  def configure(options) do
    IO.puts("  FullPlugin configuring with: #{inspect(options)}")
    {:ok, Enum.into(options, %{})}
  end
end

IO.puts("Testing MinimalPlugin (optional callbacks not implemented):")
{:ok, state1} = MinimalPlugin.init(%{name: "test"})
IO.inspect(MinimalPlugin.run("data", state1), label: "  run")
IO.puts("  Safe cleanup: #{inspect(Plugin.safe_cleanup(MinimalPlugin, state1))}")

IO.puts("\nTesting FullPlugin (all callbacks implemented):")
{:ok, config} = FullPlugin.configure(debug: true, verbose: false)
{:ok, state2} = FullPlugin.init(config)
IO.inspect(FullPlugin.run("data", state2), label: "  run")
FullPlugin.cleanup(state2)

# -----------------------------------------------------------------------------
# Section 6: Multiple Behaviours
# -----------------------------------------------------------------------------
#
# A module can implement multiple behaviours. Just declare each one
# with @behaviour and implement all their callbacks.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 6: Multiple Behaviours ---\n")

defmodule Serializable do
  @callback serialize(data :: any()) :: binary()
  @callback deserialize(binary :: binary()) :: {:ok, any()} | {:error, term()}
end

defmodule Comparable do
  @callback compare(a :: any(), b :: any()) :: :lt | :eq | :gt
  @callback equal?(a :: any(), b :: any()) :: boolean()
end

# A module implementing both behaviours
defmodule User do
  @behaviour Serializable
  @behaviour Comparable

  defstruct [:id, :name, :email]

  # Serializable callbacks
  @impl Serializable
  def serialize(%User{} = user) do
    "USER:#{user.id}:#{user.name}:#{user.email}"
  end

  @impl Serializable
  def deserialize(binary) do
    case String.split(binary, ":") do
      ["USER", id, name, email] ->
        {:ok, %User{id: String.to_integer(id), name: name, email: email}}
      _ ->
        {:error, :invalid_format}
    end
  end

  # Comparable callbacks
  @impl Comparable
  def compare(%User{id: id1}, %User{id: id2}) do
    cond do
      id1 < id2 -> :lt
      id1 > id2 -> :gt
      true -> :eq
    end
  end

  @impl Comparable
  def equal?(%User{id: id1}, %User{id: id2}) do
    id1 == id2
  end
end

user1 = %User{id: 1, name: "Alice", email: "alice@example.com"}
user2 = %User{id: 2, name: "Bob", email: "bob@example.com"}

IO.puts("Testing User module with multiple behaviours:")

# Test Serializable
serialized = User.serialize(user1)
IO.puts("  Serialized: #{serialized}")
IO.inspect(User.deserialize(serialized), label: "  Deserialized")

# Test Comparable
IO.puts("  Compare user1 vs user2: #{User.compare(user1, user2)}")
IO.puts("  user1 equal? user1: #{User.equal?(user1, user1)}")
IO.puts("  user1 equal? user2: #{User.equal?(user1, user2)}")

# -----------------------------------------------------------------------------
# Section 7: Behaviours for Polymorphism
# -----------------------------------------------------------------------------
#
# One of the main uses of behaviours is achieving polymorphism.
# You can write code that works with any module implementing a behaviour.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 7: Behaviours for Polymorphism ---\n")

defmodule Notifier do
  @moduledoc "Behaviour for notification systems"

  @callback notify(recipient :: String.t(), message :: String.t()) ::
    {:ok, reference :: String.t()} | {:error, reason :: term()}

  @callback supports?(recipient :: String.t()) :: boolean()
end

defmodule EmailNotifier do
  @behaviour Notifier

  @impl Notifier
  def notify(recipient, message) do
    IO.puts("    [EMAIL] Sending to #{recipient}: #{message}")
    {:ok, "email-#{:rand.uniform(10000)}"}
  end

  @impl Notifier
  def supports?(recipient) do
    String.contains?(recipient, "@")
  end
end

defmodule SMSNotifier do
  @behaviour Notifier

  @impl Notifier
  def notify(recipient, message) do
    IO.puts("    [SMS] Sending to #{recipient}: #{String.slice(message, 0, 160)}")
    {:ok, "sms-#{:rand.uniform(10000)}"}
  end

  @impl Notifier
  def supports?(recipient) do
    String.match?(recipient, ~r/^\+?\d{10,}$/)
  end
end

defmodule SlackNotifier do
  @behaviour Notifier

  @impl Notifier
  def notify(recipient, message) do
    IO.puts("    [SLACK] Sending to #{recipient}: #{message}")
    {:ok, "slack-#{:rand.uniform(10000)}"}
  end

  @impl Notifier
  def supports?(recipient) do
    String.starts_with?(recipient, "#") or String.starts_with?(recipient, "@")
  end
end

# Polymorphic notification dispatcher
defmodule NotificationService do
  @notifiers [EmailNotifier, SMSNotifier, SlackNotifier]

  def send_notification(recipient, message) do
    notifier = find_notifier(recipient)

    if notifier do
      notifier.notify(recipient, message)
    else
      {:error, :no_suitable_notifier}
    end
  end

  def send_to_all(recipients, message) do
    Enum.map(recipients, fn recipient ->
      {recipient, send_notification(recipient, message)}
    end)
  end

  defp find_notifier(recipient) do
    Enum.find(@notifiers, fn notifier ->
      notifier.supports?(recipient)
    end)
  end
end

IO.puts("Polymorphic notification dispatch:")
recipients = [
  "alice@example.com",
  "+15551234567",
  "#general",
  "@bob"
]

results = NotificationService.send_to_all(recipients, "Hello from Elixir behaviours!")

IO.puts("\nResults:")
Enum.each(results, fn {recipient, result} ->
  IO.puts("  #{recipient}: #{inspect(result)}")
end)

# -----------------------------------------------------------------------------
# Section 8: Default Implementations with __using__
# -----------------------------------------------------------------------------
#
# You can combine behaviours with __using__ to provide default
# implementations that modules can override.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 8: Default Implementations with __using__ ---\n")

defmodule Cacheable do
  @moduledoc """
  A behaviour for caching with default implementations.

  Modules using this behaviour get default implementations for
  all callbacks, which they can override as needed.
  """

  @callback get(key :: term()) :: {:ok, term()} | :miss
  @callback put(key :: term(), value :: term(), ttl :: integer()) :: :ok
  @callback delete(key :: term()) :: :ok
  @callback clear() :: :ok
  @callback stats() :: map()

  @optional_callbacks stats: 0

  defmacro __using__(_opts) do
    quote do
      @behaviour Cacheable

      # Default in-memory implementation using process dictionary
      @impl Cacheable
      def get(key) do
        case Process.get({:cache, key}) do
          nil -> :miss
          {value, expires_at} ->
            if DateTime.compare(DateTime.utc_now(), expires_at) == :lt do
              {:ok, value}
            else
              delete(key)
              :miss
            end
        end
      end

      @impl Cacheable
      def put(key, value, ttl \\ 300) do
        expires_at = DateTime.add(DateTime.utc_now(), ttl, :second)
        Process.put({:cache, key}, {value, expires_at})
        :ok
      end

      @impl Cacheable
      def delete(key) do
        Process.delete({:cache, key})
        :ok
      end

      @impl Cacheable
      def clear do
        Process.get_keys()
        |> Enum.filter(&match?({:cache, _}, &1))
        |> Enum.each(&Process.delete/1)
        :ok
      end

      # Allow modules to override these defaults
      defoverridable get: 1, put: 3, delete: 1, clear: 0
    end
  end
end

# Use default implementations
defmodule SimpleCache do
  use Cacheable
  # All defaults are used as-is
end

# Override some implementations
defmodule LoggingCache do
  use Cacheable

  @impl Cacheable
  def put(key, value, ttl \\ 300) do
    IO.puts("    [LoggingCache] Storing #{inspect(key)} with TTL #{ttl}s")
    # Call the "super" implementation by reimplementing
    expires_at = DateTime.add(DateTime.utc_now(), ttl, :second)
    Process.put({:cache, key}, {value, expires_at})
    :ok
  end

  @impl Cacheable
  def get(key) do
    result = case Process.get({:cache, key}) do
      nil -> :miss
      {value, expires_at} ->
        if DateTime.compare(DateTime.utc_now(), expires_at) == :lt do
          {:ok, value}
        else
          delete(key)
          :miss
        end
    end
    IO.puts("    [LoggingCache] Get #{inspect(key)} -> #{inspect(result)}")
    result
  end

  # Add optional stats callback
  @impl Cacheable
  def stats do
    count = Process.get_keys()
    |> Enum.filter(&match?({:cache, _}, &1))
    |> length()
    %{entries: count, type: :logging_cache}
  end
end

IO.puts("Testing SimpleCache (default implementations):")
SimpleCache.put(:a, "value_a", 60)
SimpleCache.put(:b, "value_b", 60)
IO.inspect(SimpleCache.get(:a), label: "  get :a")
IO.inspect(SimpleCache.get(:missing), label: "  get :missing")
SimpleCache.clear()

IO.puts("\nTesting LoggingCache (overridden implementations):")
LoggingCache.put(:x, "value_x", 120)
LoggingCache.get(:x)
LoggingCache.get(:y)
IO.inspect(LoggingCache.stats(), label: "  stats")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Exercise 1: Define a Shape Behaviour
Difficulty: Easy

Create a behaviour called `Shape` with these callbacks:
- area() :: float() - returns the area
- perimeter() :: float() - returns the perimeter
- name() :: String.t() - returns the shape name

Then implement the behaviour for `Circle` and `Rectangle` structs.

Your code here:
""")

# defmodule Shape do
#   @callback ...
# end
#
# defmodule Circle do
#   @behaviour Shape
#   defstruct [:radius]
#   ...
# end
#
# defmodule Rectangle do
#   @behaviour Shape
#   defstruct [:width, :height]
#   ...
# end

IO.puts("""

Exercise 2: Payment Processor Behaviour
Difficulty: Easy

Create a `PaymentProcessor` behaviour with callbacks:
- process_payment(amount, currency) :: {:ok, transaction_id} | {:error, reason}
- refund(transaction_id) :: {:ok, refund_id} | {:error, reason}
- supports_currency?(currency) :: boolean()

Implement it for `StripeProcessor` and `PayPalProcessor` modules.

Your code here:
""")

# defmodule PaymentProcessor do
#   ...
# end

IO.puts("""

Exercise 3: Behaviour with Optional Callbacks
Difficulty: Medium

Create a `DataExporter` behaviour with:
Required callbacks:
- export(data) :: binary()
- content_type() :: String.t()
- file_extension() :: String.t()

Optional callbacks:
- pretty_print?(data) :: binary() (formatted version)
- validate(data) :: boolean()

Create implementations: `JSONExporter`, `XMLExporter`, and `CSVExporter`
Only JSONExporter should implement the optional callbacks.

Your code here:
""")

# defmodule DataExporter do
#   ...
#   @optional_callbacks ...
# end

IO.puts("""

Exercise 4: Repository Pattern with Behaviours
Difficulty: Medium

Create a `Repository` behaviour for database operations:
- all() :: [struct()]
- get(id) :: struct() | nil
- insert(struct) :: {:ok, struct()} | {:error, changeset}
- update(struct, attrs) :: {:ok, struct()} | {:error, changeset}
- delete(struct) :: {:ok, struct()} | {:error, reason}

Implement `InMemoryRepository` using an Agent to store data.
Test with a User struct.

Your code here:
""")

# defmodule Repository do
#   ...
# end
#
# defmodule InMemoryRepository do
#   ...
# end

IO.puts("""

Exercise 5: Compose Multiple Behaviours
Difficulty: Medium

Create two behaviours:
1. `Identifiable` - callbacks: id(), identifier_type()
2. `Timestampable` - callbacks: created_at(), updated_at(), touch()

Then create an `Article` struct that implements BOTH behaviours.
The Article should have :id, :title, :body, :created_at, :updated_at fields.

Your code here:
""")

# defmodule Identifiable do
#   ...
# end
#
# defmodule Timestampable do
#   ...
# end
#
# defmodule Article do
#   @behaviour Identifiable
#   @behaviour Timestampable
#   ...
# end

IO.puts("""

Exercise 6: Behaviour with Default Implementations
Difficulty: Hard

Create a `Validatable` behaviour with:
- validate(data) :: {:ok, data} | {:error, errors}
- rules() :: keyword() (returns validation rules)
- error_messages() :: map() (custom error messages)

Use __using__ to provide default implementations:
- A default validate/1 that checks the rules
- A default error_messages/0 with generic messages

Create a `UserValidator` module that uses Validatable and defines rules:
- :name - required, min_length: 2
- :email - required, format: email
- :age - optional, min: 0, max: 150

Your code here:
""")

# defmodule Validatable do
#   @callback validate(data :: map()) :: {:ok, map()} | {:error, map()}
#   @callback rules() :: keyword()
#   @callback error_messages() :: map()
#
#   @optional_callbacks error_messages: 0
#
#   defmacro __using__(_opts) do
#     quote do
#       @behaviour Validatable
#       ...
#     end
#   end
# end
#
# defmodule UserValidator do
#   use Validatable
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

1. Behaviours Define Contracts:
   - Use @callback to specify required function signatures
   - Provides compile-time warnings for missing implementations
   - Think of them as interfaces/protocols from other languages

2. Implementing Behaviours:
   - Declare with @behaviour ModuleName
   - Must implement all required callbacks
   - Use @impl to mark callback implementations

3. @callback Syntax:
   @callback function_name(type) :: return_type

4. @impl Benefits:
   - Documents which functions are callbacks
   - Compile-time verification
   - Can use @impl true or @impl BehaviourName

5. Optional Callbacks:
   - Use @optional_callbacks [name: arity, ...]
   - Check with function_exported?/3 before calling

6. Multiple Behaviours:
   - A module can implement multiple behaviours
   - Just add multiple @behaviour declarations
   - Implement all required callbacks from each

7. Polymorphism with Behaviours:
   - Write code that works with any implementing module
   - Pass module as parameter, call behaviour callbacks
   - Enables plugin systems and extensible architectures

8. Default Implementations:
   - Combine behaviours with __using__ macro
   - Use defoverridable to allow overriding
   - Modules get defaults they can customize

9. Common Built-in Behaviours:
   - GenServer - for generic servers
   - Supervisor - for supervision trees
   - Application - for OTP applications
   - Access - for bracket access syntax

Next: 22_protocols.exs - Learn about protocols for type-based polymorphism
""")
