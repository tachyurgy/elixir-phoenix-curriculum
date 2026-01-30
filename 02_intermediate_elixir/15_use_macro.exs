# ============================================================================
# Lesson 15: The use Macro and __using__ Callback
# ============================================================================
#
# The `use` macro is a powerful mechanism for code injection in Elixir.
# It allows modules to inject code into other modules, enabling patterns
# like behaviours, protocols, and DSLs.
#
# Topics covered:
# - Understanding the `use` directive
# - The __using__/1 callback macro
# - Injecting code into modules
# - Building reusable abstractions
# - Common patterns with use
#
# ============================================================================

IO.puts """
================================================================================
                    THE USE MACRO AND CODE INJECTION
================================================================================
"""

# ============================================================================
# Part 1: Understanding `use`
# ============================================================================

IO.puts """
--------------------------------------------------------------------------------
Part 1: Understanding the `use` Directive
--------------------------------------------------------------------------------

The `use` directive is a macro that calls the __using__/1 macro in another
module. It's a way to inject code (functions, macros, module attributes)
into the calling module.

When you write:
    use MyModule, option: value

Elixir transforms this into:
    require MyModule
    MyModule.__using__(option: value)

The __using__ macro returns quoted code that gets injected into the module.
"""

# Simple demonstration of what use does
defmodule SimpleDemo do
  defmacro __using__(_opts) do
    quote do
      IO.puts("Code injected from SimpleDemo!")
      def injected_function, do: "I was injected!"
    end
  end
end

defmodule MyModule do
  use SimpleDemo
end

IO.puts "Calling injected function: #{MyModule.injected_function()}"

# ============================================================================
# Part 2: The __using__ Callback
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 2: The __using__/1 Callback Macro
--------------------------------------------------------------------------------

The __using__/1 callback is a macro that receives options and returns
quoted code to be injected. The options come from the `use` call.
"""

defmodule Greeter do
  defmacro __using__(opts) do
    greeting = Keyword.get(opts, :greeting, "Hello")

    quote do
      # This code is injected into the module that `use`s Greeter
      @greeting unquote(greeting)

      def greet(name) do
        "#{@greeting}, #{name}!"
      end

      def greeting do
        @greeting
      end
    end
  end
end

# Using with default options
defmodule EnglishGreeter do
  use Greeter
end

# Using with custom options
defmodule SpanishGreeter do
  use Greeter, greeting: "Hola"
end

defmodule FrenchGreeter do
  use Greeter, greeting: "Bonjour"
end

IO.puts "--- Greeter Examples ---"
IO.puts EnglishGreeter.greet("World")
IO.puts SpanishGreeter.greet("Mundo")
IO.puts FrenchGreeter.greet("Monde")

# ============================================================================
# Part 3: Injecting Multiple Things
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 3: Injecting Functions, Macros, and Module Attributes
--------------------------------------------------------------------------------

You can inject any valid Elixir code including functions, macros,
module attributes, and even other `use` statements.
"""

defmodule FullInjection do
  defmacro __using__(opts) do
    prefix = Keyword.get(opts, :prefix, "default")

    quote do
      # Inject a module attribute
      @prefix unquote(prefix)
      @injected_at DateTime.utc_now() |> DateTime.to_string()

      # Inject regular functions
      def get_prefix, do: @prefix
      def get_injection_time, do: @injected_at

      # Inject a macro
      defmacro log(message) do
        prefix = @prefix
        quote do
          IO.puts("[#{unquote(prefix)}] #{unquote(message)}")
        end
      end

      # Inject a private function
      defp internal_helper(value) do
        "#{@prefix}: #{value}"
      end

      # Inject a function that uses the private helper
      def process(value) do
        internal_helper(value)
      end
    end
  end
end

defmodule MyService do
  use FullInjection, prefix: "MyService"

  require __MODULE__  # Required to use the injected macro

  def do_work do
    log("Starting work...")
    result = process("important data")
    log("Work complete!")
    result
  end
end

IO.puts "--- Full Injection Example ---"
IO.puts "Prefix: #{MyService.get_prefix()}"
IO.puts "Injection time: #{MyService.get_injection_time()}"
IO.puts "Process result: #{MyService.process("test")}"
IO.puts "\nDoing work:"
MyService.do_work()

# ============================================================================
# Part 4: Common Patterns with use
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 4: Common Patterns with `use`
--------------------------------------------------------------------------------

The `use` directive is commonly used for:
1. Implementing behaviour callbacks with default implementations
2. Creating DSLs (Domain Specific Languages)
3. Generating boilerplate code
4. Mixing in functionality
"""

# Pattern 1: Behaviour with defaults
defmodule Animal do
  @callback speak() :: String.t()
  @callback move() :: String.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Animal

      # Default implementation
      def move, do: "walking"

      # Allow overriding
      defoverridable move: 0
    end
  end
end

defmodule Dog do
  use Animal

  def speak, do: "Woof!"
  # move/0 uses the default implementation
end

defmodule Fish do
  use Animal

  def speak, do: "Blub!"
  def move, do: "swimming"  # Override the default
end

IO.puts "--- Behaviour with Defaults ---"
IO.puts "Dog says: #{Dog.speak()}, #{Dog.move()}"
IO.puts "Fish says: #{Fish.speak()}, #{Fish.move()}"

# Pattern 2: GenServer-like pattern
defmodule SimpleServer do
  defmacro __using__(_opts) do
    quote do
      def start do
        spawn(__MODULE__, :loop, [initial_state()])
      end

      def loop(state) do
        receive do
          {:get, caller} ->
            send(caller, {:state, state})
            loop(state)
          {:update, func} ->
            loop(func.(state))
          :stop ->
            :ok
        end
      end

      # Default initial state - can be overridden
      def initial_state, do: %{}
      defoverridable initial_state: 0
    end
  end
end

defmodule Counter do
  use SimpleServer

  def initial_state, do: 0

  def get(pid) do
    send(pid, {:get, self()})
    receive do
      {:state, state} -> state
    end
  end

  def increment(pid) do
    send(pid, {:update, fn state -> state + 1 end})
  end
end

IO.puts "\n--- Simple Server Pattern ---"
pid = Counter.start()
IO.puts "Initial count: #{Counter.get(pid)}"
Counter.increment(pid)
Counter.increment(pid)
IO.puts "After two increments: #{Counter.get(pid)}"
send(pid, :stop)

# ============================================================================
# Part 5: Building a Mini DSL
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 5: Building a Mini DSL with `use`
--------------------------------------------------------------------------------

One of the most powerful uses of __using__ is creating DSLs.
Let's build a simple test framework DSL.
"""

defmodule MiniTest do
  defmacro __using__(_opts) do
    quote do
      import MiniTest
      Module.register_attribute(__MODULE__, :tests, accumulate: true)
      @before_compile MiniTest
    end
  end

  defmacro test(description, do: block) do
    func_name = String.to_atom("test_" <> String.replace(description, " ", "_"))

    quote do
      @tests {unquote(description), unquote(func_name)}
      def unquote(func_name)() do
        unquote(block)
      end
    end
  end

  defmacro assert_equal(left, right) do
    quote do
      left_val = unquote(left)
      right_val = unquote(right)

      if left_val == right_val do
        :ok
      else
        raise "Assertion failed: #{inspect(left_val)} != #{inspect(right_val)}"
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def run_tests do
        IO.puts("\nRunning tests for #{inspect(__MODULE__)}:")
        IO.puts(String.duplicate("-", 50))

        results = Enum.map(@tests, fn {desc, func} ->
          try do
            apply(__MODULE__, func, [])
            IO.puts("  [PASS] #{desc}")
            :pass
          rescue
            e ->
              IO.puts("  [FAIL] #{desc}")
              IO.puts("         #{Exception.message(e)}")
              :fail
          end
        end)

        passes = Enum.count(results, &(&1 == :pass))
        fails = Enum.count(results, &(&1 == :fail))

        IO.puts(String.duplicate("-", 50))
        IO.puts("Results: #{passes} passed, #{fails} failed")

        {passes, fails}
      end
    end
  end
end

defmodule MathTests do
  use MiniTest

  test "addition works correctly" do
    assert_equal 1 + 1, 2
    assert_equal 2 + 2, 4
  end

  test "multiplication works correctly" do
    assert_equal 3 * 4, 12
    assert_equal 5 * 5, 25
  end

  test "division works correctly" do
    assert_equal div(10, 2), 5
    assert_equal div(9, 3), 3
  end

  test "this test fails on purpose" do
    assert_equal 1 + 1, 3
  end
end

IO.puts "--- Mini Test DSL ---"
MathTests.run_tests()

# ============================================================================
# Part 6: Using __before_compile__ and __after_compile__
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 6: Compile-Time Hooks
--------------------------------------------------------------------------------

__before_compile__/1 - Called just before the module is compiled
__after_compile__/2 - Called just after the module is compiled

These are useful for generating code based on accumulated attributes.
"""

defmodule CompileHooks do
  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :routes, accumulate: true)
      @before_compile CompileHooks
    end
  end

  defmacro route(method, path, handler) do
    quote do
      @routes {unquote(method), unquote(path), unquote(handler)}
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def list_routes do
        @routes
        |> Enum.reverse()
        |> Enum.map(fn {method, path, handler} ->
          "#{String.upcase(to_string(method))} #{path} -> #{handler}"
        end)
      end

      def dispatch(method, path) do
        routes = @routes |> Enum.reverse()

        case Enum.find(routes, fn {m, p, _} -> m == method and p == path end) do
          {_, _, handler} -> {:ok, handler}
          nil -> {:error, :not_found}
        end
      end
    end
  end
end

defmodule MyRouter do
  use CompileHooks

  route :get, "/", :index
  route :get, "/users", :list_users
  route :post, "/users", :create_user
  route :get, "/users/:id", :show_user
  route :delete, "/users/:id", :delete_user
end

IO.puts "--- Compile Hooks Example ---"
IO.puts "Routes defined:"
for route <- MyRouter.list_routes() do
  IO.puts "  #{route}"
end

IO.puts "\nDispatching requests:"
IO.inspect(MyRouter.dispatch(:get, "/"), label: "GET /")
IO.inspect(MyRouter.dispatch(:post, "/users"), label: "POST /users")
IO.inspect(MyRouter.dispatch(:put, "/users"), label: "PUT /users")

# ============================================================================
# Exercises
# ============================================================================

IO.puts """

================================================================================
                              EXERCISES
================================================================================
"""

IO.puts """
--------------------------------------------------------------------------------
Exercise 1: Configurable Logger
--------------------------------------------------------------------------------
Create a module that when `use`d, injects logging functions with configurable:
- Log level (:debug, :info, :warn, :error)
- Prefix (module name or custom)
- Include timestamp option
"""

# Exercise 1 Solution:
defmodule ConfigurableLogger do
  defmacro __using__(opts) do
    level = Keyword.get(opts, :level, :info)
    prefix = Keyword.get(opts, :prefix, nil)
    include_timestamp = Keyword.get(opts, :timestamp, false)

    levels = [:debug, :info, :warn, :error]
    level_index = Enum.find_index(levels, &(&1 == level)) || 1

    quote do
      @log_level unquote(level)
      @log_levels unquote(levels)
      @log_level_index unquote(level_index)
      @log_prefix unquote(prefix)
      @include_timestamp unquote(include_timestamp)

      defp log_prefix do
        @log_prefix || inspect(__MODULE__)
      end

      defp format_message(level, message) do
        timestamp = if @include_timestamp do
          "[#{DateTime.utc_now() |> DateTime.to_string()}] "
        else
          ""
        end

        "#{timestamp}[#{String.upcase(to_string(level))}] [#{log_prefix()}] #{message}"
      end

      defp should_log?(level) do
        level_idx = Enum.find_index(@log_levels, &(&1 == level)) || 0
        level_idx >= @log_level_index
      end

      def debug(message) do
        if should_log?(:debug), do: IO.puts(format_message(:debug, message))
      end

      def info(message) do
        if should_log?(:info), do: IO.puts(format_message(:info, message))
      end

      def warn(message) do
        if should_log?(:warn), do: IO.puts(format_message(:warn, message))
      end

      def error(message) do
        if should_log?(:error), do: IO.puts(format_message(:error, message))
      end
    end
  end
end

defmodule MyApp.Service do
  use ConfigurableLogger, level: :info, prefix: "Service", timestamp: true

  def process do
    debug("Starting process (this won't show)")
    info("Processing data...")
    warn("Something might be wrong")
    error("Critical error!")
  end
end

IO.puts "--- Exercise 1 Solution ---"
MyApp.Service.process()

IO.puts """

--------------------------------------------------------------------------------
Exercise 2: Struct Builder
--------------------------------------------------------------------------------
Create a module that when `use`d with field definitions, automatically:
- Creates a struct with those fields
- Generates a new/1 function
- Generates getter functions for each field
- Generates setter functions that return a new struct
"""

# Exercise 2 Solution:
defmodule StructBuilder do
  defmacro __using__(opts) do
    fields = Keyword.get(opts, :fields, [])

    struct_fields = for {name, default} <- fields do
      {name, default}
    end

    getters = for {name, _default} <- fields do
      quote do
        def unquote(name)(%__MODULE__{} = struct) do
          Map.get(struct, unquote(name))
        end
      end
    end

    setters = for {name, _default} <- fields do
      setter_name = String.to_atom("set_#{name}")
      quote do
        def unquote(setter_name)(%__MODULE__{} = struct, value) do
          %{struct | unquote(name) => value}
        end
      end
    end

    quote do
      defstruct unquote(struct_fields)

      def new(attrs \\ %{}) do
        struct(__MODULE__, attrs)
      end

      unquote_splicing(getters)
      unquote_splicing(setters)
    end
  end
end

defmodule Person do
  use StructBuilder, fields: [
    name: "",
    age: 0,
    email: nil
  ]
end

IO.puts "\n--- Exercise 2 Solution ---"
person = Person.new(name: "Alice", age: 30, email: "alice@example.com")
IO.inspect(person, label: "Created person")
IO.puts "Name: #{Person.name(person)}"
IO.puts "Age: #{Person.age(person)}"

updated = Person.set_age(person, 31)
IO.inspect(updated, label: "After birthday")

IO.puts """

--------------------------------------------------------------------------------
Exercise 3: Event Emitter
--------------------------------------------------------------------------------
Create a module that provides event handling capabilities:
- on/2 to register event handlers
- emit/2 to trigger events
- Handlers should be accumulated and called in order
"""

# Exercise 3 Solution:
defmodule EventEmitter do
  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :handlers, accumulate: true)
      @before_compile EventEmitter
      import EventEmitter
    end
  end

  defmacro on(event, do: block) do
    quote do
      @handlers {unquote(event), fn -> unquote(block) end}
    end
  end

  defmacro on(event, handler) do
    quote do
      @handlers {unquote(event), unquote(handler)}
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def emit(event, data \\ nil) do
        handlers = @handlers
        |> Enum.reverse()
        |> Enum.filter(fn {e, _} -> e == event end)
        |> Enum.map(fn {_, handler} -> handler end)

        for handler <- handlers do
          case :erlang.fun_info(handler)[:arity] do
            0 -> handler.()
            1 -> handler.(data)
            _ -> handler.(event, data)
          end
        end

        :ok
      end

      def list_events do
        @handlers
        |> Enum.reverse()
        |> Enum.map(fn {event, _} -> event end)
        |> Enum.uniq()
      end
    end
  end
end

defmodule UserEvents do
  use EventEmitter

  on :user_created do
    IO.puts("  -> Sending welcome email...")
  end

  on :user_created, fn user ->
    IO.puts("  -> Logging creation: #{inspect(user)}")
  end

  on :user_deleted, fn user ->
    IO.puts("  -> Cleaning up data for: #{inspect(user)}")
  end

  on :user_deleted do
    IO.puts("  -> Sending goodbye email...")
  end
end

IO.puts "\n--- Exercise 3 Solution ---"
IO.puts "Registered events: #{inspect(UserEvents.list_events())}"

IO.puts "\nEmitting :user_created event:"
UserEvents.emit(:user_created, %{name: "Alice"})

IO.puts "\nEmitting :user_deleted event:"
UserEvents.emit(:user_deleted, %{name: "Bob"})

IO.puts """

--------------------------------------------------------------------------------
Exercise 4: Validation DSL
--------------------------------------------------------------------------------
Create a validation DSL that allows defining validations like:
  validates :name, presence: true, length: {2, 50}
  validates :email, format: ~r/@/
  validates :age, numericality: {0, 150}
"""

# Exercise 4 Solution:
defmodule ValidationDSL do
  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :validations, accumulate: true)
      @before_compile ValidationDSL
      import ValidationDSL
    end
  end

  defmacro validates(field, opts) do
    quote do
      @validations {unquote(field), unquote(opts)}
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def validate(data) do
        errors = @validations
        |> Enum.reverse()
        |> Enum.flat_map(fn {field, opts} ->
          value = Map.get(data, field)
          validate_field(field, value, opts)
        end)

        if errors == [], do: :ok, else: {:error, errors}
      end

      defp validate_field(field, value, opts) do
        Enum.flat_map(opts, fn
          {:presence, true} ->
            if is_nil(value) or value == "" do
              [{field, "must be present"}]
            else
              []
            end

          {:length, {min, max}} ->
            len = if is_binary(value), do: String.length(value), else: 0
            if len < min or len > max do
              [{field, "length must be between #{min} and #{max}"}]
            else
              []
            end

          {:format, regex} ->
            if is_binary(value) and Regex.match?(regex, value) do
              []
            else
              [{field, "has invalid format"}]
            end

          {:numericality, {min, max}} ->
            if is_number(value) and value >= min and value <= max do
              []
            else
              [{field, "must be a number between #{min} and #{max}"}]
            end

          _ -> []
        end)
      end
    end
  end
end

defmodule UserValidation do
  use ValidationDSL

  validates :name, presence: true, length: {2, 50}
  validates :email, presence: true, format: ~r/@/
  validates :age, numericality: {0, 150}
end

IO.puts "\n--- Exercise 4 Solution ---"
valid_data = %{name: "Alice Johnson", email: "alice@example.com", age: 30}
invalid_data = %{name: "A", email: "invalid", age: 200}

IO.inspect(UserValidation.validate(valid_data), label: "Valid data")
IO.inspect(UserValidation.validate(invalid_data), label: "Invalid data")

IO.puts """

--------------------------------------------------------------------------------
Exercise 5: Plugin System
--------------------------------------------------------------------------------
Create a plugin system where:
- A base module can be extended with plugins
- Plugins can add functions to the base module
- Plugins can be enabled/disabled via options
"""

# Exercise 5 Solution:
defmodule PluginSystem do
  defmacro __using__(opts) do
    plugins = Keyword.get(opts, :plugins, [])

    plugin_code = for plugin <- plugins do
      quote do
        unquote(plugin).__plugin__()
      end
    end

    quote do
      @plugins unquote(plugins)

      def plugins, do: @plugins

      unquote_splicing(plugin_code)
    end
  end

  defmacro defplugin(do: block) do
    quote do
      defmacro __plugin__ do
        unquote(Macro.escape(block))
      end
    end
  end
end

defmodule Plugins.Math do
  require PluginSystem
  PluginSystem.defplugin do
    def add(a, b), do: a + b
    def subtract(a, b), do: a - b
    def multiply(a, b), do: a * b
  end
end

defmodule Plugins.String do
  require PluginSystem
  PluginSystem.defplugin do
    def upcase(s), do: String.upcase(s)
    def downcase(s), do: String.downcase(s)
    def reverse(s), do: String.reverse(s)
  end
end

defmodule Plugins.List do
  require PluginSystem
  PluginSystem.defplugin do
    def sum(list), do: Enum.sum(list)
    def average(list), do: Enum.sum(list) / length(list)
  end
end

defmodule MyUtilities do
  use PluginSystem, plugins: [Plugins.Math, Plugins.String, Plugins.List]
end

IO.puts "\n--- Exercise 5 Solution ---"
IO.puts "Loaded plugins: #{inspect(MyUtilities.plugins())}"
IO.puts "\nMath operations:"
IO.puts "  add(5, 3) = #{MyUtilities.add(5, 3)}"
IO.puts "  multiply(4, 7) = #{MyUtilities.multiply(4, 7)}"
IO.puts "\nString operations:"
IO.puts "  upcase(\"hello\") = #{MyUtilities.upcase("hello")}"
IO.puts "  reverse(\"world\") = #{MyUtilities.reverse("world")}"
IO.puts "\nList operations:"
IO.puts "  sum([1,2,3,4,5]) = #{MyUtilities.sum([1, 2, 3, 4, 5])}"
IO.puts "  average([1,2,3,4,5]) = #{MyUtilities.average([1, 2, 3, 4, 5])}"

IO.puts """

--------------------------------------------------------------------------------
Exercise 6: State Machine DSL
--------------------------------------------------------------------------------
Create a state machine DSL where you can define:
- States and their allowed transitions
- Actions to perform on transitions
- A way to check if a transition is valid
"""

# Exercise 6 Solution:
defmodule StateMachine do
  defmacro __using__(opts) do
    initial = Keyword.get(opts, :initial, :new)

    quote do
      Module.register_attribute(__MODULE__, :states, accumulate: true)
      Module.register_attribute(__MODULE__, :transitions, accumulate: true)
      @initial_state unquote(initial)
      @before_compile StateMachine
      import StateMachine
    end
  end

  defmacro state(name, opts \\ []) do
    quote do
      @states {unquote(name), unquote(opts)}
    end
  end

  defmacro transition(from, event, to, opts \\ []) do
    quote do
      @transitions {unquote(from), unquote(event), unquote(to), unquote(opts)}
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def initial_state, do: @initial_state

      def states do
        @states |> Enum.reverse() |> Enum.map(fn {name, _} -> name end)
      end

      def transitions do
        @transitions |> Enum.reverse()
      end

      def can_transition?(current, event) do
        Enum.any?(transitions(), fn {from, e, _to, _opts} ->
          from == current and e == event
        end)
      end

      def transition(current, event) do
        case Enum.find(transitions(), fn {from, e, _to, _opts} ->
          from == current and e == event
        end) do
          {_from, _event, to, opts} ->
            if action = Keyword.get(opts, :action) do
              action.()
            end
            {:ok, to}
          nil ->
            {:error, "Cannot transition from #{current} via #{event}"}
        end
      end

      def valid_events(current) do
        transitions()
        |> Enum.filter(fn {from, _e, _to, _opts} -> from == current end)
        |> Enum.map(fn {_from, event, _to, _opts} -> event end)
      end
    end
  end
end

defmodule OrderStateMachine do
  use StateMachine, initial: :pending

  state :pending
  state :confirmed
  state :shipped
  state :delivered
  state :cancelled

  transition :pending, :confirm, :confirmed,
    action: fn -> IO.puts("  -> Sending confirmation email") end

  transition :pending, :cancel, :cancelled,
    action: fn -> IO.puts("  -> Refunding payment") end

  transition :confirmed, :ship, :shipped,
    action: fn -> IO.puts("  -> Generating shipping label") end

  transition :confirmed, :cancel, :cancelled,
    action: fn -> IO.puts("  -> Refunding payment") end

  transition :shipped, :deliver, :delivered,
    action: fn -> IO.puts("  -> Sending delivery confirmation") end
end

IO.puts "\n--- Exercise 6 Solution ---"
IO.puts "States: #{inspect(OrderStateMachine.states())}"
IO.puts "Initial state: #{OrderStateMachine.initial_state()}"

IO.puts "\nSimulating order flow:"
state = :pending
IO.puts "Current state: #{state}"
IO.puts "Valid events: #{inspect(OrderStateMachine.valid_events(state))}"

{:ok, state} = OrderStateMachine.transition(state, :confirm)
IO.puts "After :confirm -> #{state}"

{:ok, state} = OrderStateMachine.transition(state, :ship)
IO.puts "After :ship -> #{state}"

{:ok, state} = OrderStateMachine.transition(state, :deliver)
IO.puts "After :deliver -> #{state}"

IO.puts "\nInvalid transition test:"
IO.inspect(OrderStateMachine.transition(:delivered, :cancel))

IO.puts """

================================================================================
                              SUMMARY
================================================================================

Key concepts from this lesson:

1. The `use` directive:
   - Calls __using__/1 macro in the target module
   - Injects the returned quoted code into the calling module
   - Allows passing options: use Module, option: value

2. The __using__/1 callback:
   - Must be a macro (receives and returns AST)
   - Receives options keyword list
   - Returns quoted code to inject

3. What can be injected:
   - Module attributes
   - Functions and macros
   - Other use statements
   - Compile-time hooks

4. Compile-time hooks:
   - @before_compile - code generation before compilation
   - @after_compile - actions after compilation
   - Module.register_attribute with accumulate: true

5. Common patterns:
   - Behaviour defaults with defoverridable
   - DSLs for testing, routing, validation
   - Code generation from accumulated attributes
   - Plugin systems

6. Best practices:
   - Keep __using__ code minimal
   - Use import/require for additional functionality
   - Document what gets injected
   - Consider using behaviors when appropriate

================================================================================
"""
