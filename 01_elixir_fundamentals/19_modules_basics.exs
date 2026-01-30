# ============================================================================
# Lesson 19: Modules Basics
# ============================================================================
#
# Modules are the primary way to organize code in Elixir. They serve as
# namespaces for functions and provide a way to encapsulate related
# functionality together.
#
# Learning Objectives:
# - Define modules using defmodule
# - Create public and private functions
# - Use module attributes (@moduledoc, @doc, custom attributes)
# - Understand module naming conventions
# - Work with nested modules
#
# Prerequisites:
# - Understanding of functions (anonymous and named)
# - Basic Elixir syntax
#
# ============================================================================

IO.puts("=" |> String.duplicate(70))
IO.puts("Lesson 19: Modules Basics")
IO.puts("=" |> String.duplicate(70))

# -----------------------------------------------------------------------------
# Section 1: Defining Modules with defmodule
# -----------------------------------------------------------------------------
#
# A module is defined using defmodule. By convention, module names use
# CamelCase (also called PascalCase). Modules contain functions defined
# with def (public) or defp (private).
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 1: Defining Modules with defmodule ---\n")

# A simple module with one function
defmodule Greeter do
  def hello(name) do
    "Hello, #{name}!"
  end
end

# Call the function using Module.function syntax
IO.puts(Greeter.hello("World"))
IO.puts(Greeter.hello("Elixir Developer"))

# Modules can have multiple functions
defmodule Calculator do
  def add(a, b) do
    a + b
  end

  def subtract(a, b) do
    a - b
  end

  def multiply(a, b) do
    a * b
  end

  def divide(a, b) when b != 0 do
    a / b
  end
end

IO.puts("\nCalculator examples:")
IO.puts("10 + 5 = #{Calculator.add(10, 5)}")
IO.puts("10 - 5 = #{Calculator.subtract(10, 5)}")
IO.puts("10 * 5 = #{Calculator.multiply(10, 5)}")
IO.puts("10 / 5 = #{Calculator.divide(10, 5)}")

# -----------------------------------------------------------------------------
# Section 2: Public vs Private Functions (def vs defp)
# -----------------------------------------------------------------------------
#
# - def: Defines a public function that can be called from outside the module
# - defp: Defines a private function that can only be called within the module
#
# Private functions are useful for internal helper functions that shouldn't
# be part of the module's public API.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 2: Public vs Private Functions ---\n")

defmodule StringFormatter do
  # Public function - can be called from outside
  def format_name(first, last) do
    "#{capitalize_word(first)} #{capitalize_word(last)}"
  end

  # Public function
  def format_greeting(name) do
    greeting = build_greeting()
    "#{greeting}, #{name}!"
  end

  # Private function - only accessible within this module
  defp capitalize_word(word) do
    String.capitalize(word)
  end

  # Another private function
  defp build_greeting do
    "Welcome"
  end
end

IO.puts(StringFormatter.format_name("john", "doe"))
IO.puts(StringFormatter.format_greeting("Alice"))

# Trying to call a private function from outside would cause an error:
# StringFormatter.capitalize_word("test")  # This would fail!
IO.puts("\nNote: Private functions (defp) cannot be called from outside the module")

# -----------------------------------------------------------------------------
# Section 3: Module Documentation with @moduledoc and @doc
# -----------------------------------------------------------------------------
#
# Elixir has first-class support for documentation using module attributes:
# - @moduledoc: Documents the entire module
# - @doc: Documents individual functions
#
# Documentation is accessible at runtime and through tools like ExDoc.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 3: Module Documentation ---\n")

defmodule MathOperations do
  @moduledoc """
  A module providing basic mathematical operations.

  This module contains functions for common math operations
  like factorial, power, and checking if numbers are even or odd.

  ## Examples

      iex> MathOperations.factorial(5)
      120

      iex> MathOperations.even?(4)
      true
  """

  @doc """
  Calculates the factorial of a non-negative integer.

  ## Parameters
    - n: A non-negative integer

  ## Examples

      iex> MathOperations.factorial(0)
      1

      iex> MathOperations.factorial(5)
      120
  """
  def factorial(0), do: 1
  def factorial(n) when n > 0 do
    n * factorial(n - 1)
  end

  @doc """
  Raises a number to a given power.

  ## Parameters
    - base: The base number
    - exponent: The exponent (must be non-negative)

  ## Examples

      iex> MathOperations.power(2, 3)
      8
  """
  def power(base, 0), do: 1
  def power(base, exponent) when exponent > 0 do
    base * power(base, exponent - 1)
  end

  @doc """
  Checks if a number is even.

  Returns `true` if the number is even, `false` otherwise.
  """
  def even?(n), do: rem(n, 2) == 0

  @doc """
  Checks if a number is odd.

  Returns `true` if the number is odd, `false` otherwise.
  """
  def odd?(n), do: rem(n, 2) != 0

  @doc false  # This hides the function from documentation
  def internal_helper do
    "This function won't appear in generated docs"
  end
end

IO.puts("factorial(5) = #{MathOperations.factorial(5)}")
IO.puts("power(2, 10) = #{MathOperations.power(2, 10)}")
IO.puts("even?(42) = #{MathOperations.even?(42)}")
IO.puts("odd?(42) = #{MathOperations.odd?(42)}")

# Access documentation at runtime
IO.puts("\nAccessing documentation at runtime:")
{:docs_v1, _, :elixir, _, module_doc, _, _} = Code.fetch_docs(MathOperations)
case module_doc do
  %{"en" => doc} -> IO.puts("Module doc preview: #{String.slice(doc, 0, 60)}...")
  _ -> IO.puts("No module documentation found")
end

# -----------------------------------------------------------------------------
# Section 4: Custom Module Attributes
# -----------------------------------------------------------------------------
#
# Beyond @moduledoc and @doc, you can define custom module attributes.
# These are compile-time constants that can be used throughout your module.
#
# Common uses:
# - Configuration values
# - Constants
# - Metadata
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 4: Custom Module Attributes ---\n")

defmodule AppConfig do
  # Custom module attributes (compile-time constants)
  @app_name "My Awesome App"
  @version "1.0.0"
  @author "Elixir Developer"
  @max_retries 3
  @timeout_ms 5000
  @supported_formats [:json, :xml, :csv]

  @moduledoc """
  Application configuration module.
  Version: #{@version}
  """

  def app_name, do: @app_name
  def version, do: @version
  def author, do: @author

  def config do
    %{
      name: @app_name,
      version: @version,
      author: @author,
      max_retries: @max_retries,
      timeout_ms: @timeout_ms,
      formats: @supported_formats
    }
  end

  def retry_operation(operation, attempt \\ 1) do
    if attempt <= @max_retries do
      case operation.() do
        {:ok, result} -> {:ok, result}
        {:error, _} -> retry_operation(operation, attempt + 1)
      end
    else
      {:error, :max_retries_exceeded}
    end
  end

  def supported_format?(format) do
    format in @supported_formats
  end
end

IO.puts("App Name: #{AppConfig.app_name()}")
IO.puts("Version: #{AppConfig.version()}")
IO.puts("Author: #{AppConfig.author()}")
IO.puts("\nFull config:")
IO.inspect(AppConfig.config(), pretty: true)
IO.puts("\nSupported format :json? #{AppConfig.supported_format?(:json)}")
IO.puts("Supported format :yaml? #{AppConfig.supported_format?(:yaml)}")

# Module attributes can be accumulated
defmodule PluginRegistry do
  # Using accumulate: true allows multiple values
  Module.register_attribute(__MODULE__, :plugins, accumulate: true)

  @plugins :authentication
  @plugins :logging
  @plugins :caching

  def registered_plugins do
    # Note: Accumulated attributes are stored in reverse order
    @plugins |> Enum.reverse()
  end
end

IO.puts("\nRegistered plugins: #{inspect(PluginRegistry.registered_plugins())}")

# -----------------------------------------------------------------------------
# Section 5: Nested Modules
# -----------------------------------------------------------------------------
#
# Modules can be nested to create hierarchical namespaces.
# Nested modules are defined with dot notation in their names.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 5: Nested Modules ---\n")

# Nested modules using dot notation
defmodule MyApp.Users do
  @moduledoc "User management functionality"

  def list_all do
    ["Alice", "Bob", "Charlie"]
  end
end

defmodule MyApp.Users.Authentication do
  @moduledoc "User authentication"

  def login(username, password) do
    # Simplified example
    if username == "admin" and password == "secret" do
      {:ok, "Logged in as #{username}"}
    else
      {:error, "Invalid credentials"}
    end
  end

  def logout(username) do
    {:ok, "#{username} logged out"}
  end
end

defmodule MyApp.Users.Permissions do
  @moduledoc "User permissions management"

  @admin_permissions [:read, :write, :delete, :admin]
  @user_permissions [:read, :write]

  def permissions_for(:admin), do: @admin_permissions
  def permissions_for(:user), do: @user_permissions
  def permissions_for(_), do: [:read]
end

IO.puts("All users: #{inspect(MyApp.Users.list_all())}")
IO.inspect(MyApp.Users.Authentication.login("admin", "secret"), label: "Login result")
IO.puts("Admin permissions: #{inspect(MyApp.Users.Permissions.permissions_for(:admin))}")
IO.puts("User permissions: #{inspect(MyApp.Users.Permissions.permissions_for(:user))}")

# Alternative: Define nested modules inside the parent
defmodule MyApp.Orders do
  @moduledoc "Order management"

  def create(items) do
    {:ok, %{id: :rand.uniform(1000), items: items}}
  end

  # Nested module defined inside parent
  defmodule Item do
    @moduledoc "Order item"

    def new(name, price, quantity \\ 1) do
      %{name: name, price: price, quantity: quantity, total: price * quantity}
    end
  end

  defmodule Calculator do
    @moduledoc "Order calculations"

    def total(items) do
      Enum.reduce(items, 0, fn item, acc -> acc + item.total end)
    end
  end
end

# Note: Even though defined inside, they're still accessed with full path
item1 = MyApp.Orders.Item.new("Widget", 10.00, 2)
item2 = MyApp.Orders.Item.new("Gadget", 25.00, 1)
items = [item1, item2]

IO.puts("\nOrder items:")
IO.inspect(items, pretty: true)
IO.puts("Order total: $#{MyApp.Orders.Calculator.total(items)}")

# -----------------------------------------------------------------------------
# Section 6: Module Functions as First-Class Values
# -----------------------------------------------------------------------------
#
# Module functions can be captured and passed around using the & operator.
# This creates a function reference that can be used like any other function.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 6: Module Functions as First-Class Values ---\n")

defmodule ListOperations do
  def double(x), do: x * 2
  def square(x), do: x * x
  def increment(x), do: x + 1
end

numbers = [1, 2, 3, 4, 5]

# Capture module function with &Module.function/arity
doubled = Enum.map(numbers, &ListOperations.double/1)
squared = Enum.map(numbers, &ListOperations.square/1)
incremented = Enum.map(numbers, &ListOperations.increment/1)

IO.puts("Original: #{inspect(numbers)}")
IO.puts("Doubled: #{inspect(doubled)}")
IO.puts("Squared: #{inspect(squared)}")
IO.puts("Incremented: #{inspect(incremented)}")

# Store function references in variables
transform = &ListOperations.double/1
IO.puts("\nUsing stored function reference: #{inspect(Enum.map(numbers, transform))}")

# Apply function using apply/3
result = apply(ListOperations, :square, [5])
IO.puts("apply(ListOperations, :square, [5]) = #{result}")

# -----------------------------------------------------------------------------
# Section 7: Module Introspection
# -----------------------------------------------------------------------------
#
# Elixir provides ways to inspect modules at runtime to discover
# their functions, attributes, and other metadata.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 7: Module Introspection ---\n")

defmodule InspectableModule do
  @custom_attr "Hello from attribute"

  def public_one, do: 1
  def public_two(x), do: x * 2
  def public_three(x, y, z), do: x + y + z

  defp private_helper, do: :secret
end

# Get list of exported functions
IO.puts("Exported functions from InspectableModule:")
InspectableModule.__info__(:functions)
|> Enum.each(fn {name, arity} ->
  IO.puts("  #{name}/#{arity}")
end)

# Check if a module is loaded
IO.puts("\nIs InspectableModule loaded? #{Code.ensure_loaded?(InspectableModule)}")
IO.puts("Is NonExistentModule loaded? #{Code.ensure_loaded?(NonExistentModule)}")

# Check if a function is exported
IO.puts("\nFunction exported? public_one/0: #{function_exported?(InspectableModule, :public_one, 0)}")
IO.puts("Function exported? private_helper/0: #{function_exported?(InspectableModule, :private_helper, 0)}")

# Get module attributes (need to be registered with persist: true or be special attrs)
IO.puts("\nModule info:")
IO.inspect(InspectableModule.__info__(:module), label: "Module name")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Exercise 1: Basic Module Creation
Difficulty: Easy

Create a module called `Temperature` with the following functions:
- celsius_to_fahrenheit(c) - converts Celsius to Fahrenheit (F = C * 9/5 + 32)
- fahrenheit_to_celsius(f) - converts Fahrenheit to Celsius (C = (F - 32) * 5/9)
- celsius_to_kelvin(c) - converts Celsius to Kelvin (K = C + 273.15)

Test your module with some sample values.

Your code here:
""")

# defmodule Temperature do
#   ...
# end

IO.puts("""

Exercise 2: Private Helper Functions
Difficulty: Easy

Create a module called `Password` with:
- Public function: validate(password) that returns {:ok, password} or {:error, reason}
- Private function: strong_enough?(password) that checks if length >= 8
- Private function: has_number?(password) that checks if it contains a digit

A password is valid if it passes both private checks.

Your code here:
""")

# defmodule Password do
#   ...
# end

IO.puts("""

Exercise 3: Module with Documentation
Difficulty: Medium

Create a fully documented module called `Statistics` with:
- @moduledoc describing the module
- @doc for each function
- Functions: mean(list), median(list), mode(list)

Each function should have documentation with examples.

Your code here:
""")

# defmodule Statistics do
#   @moduledoc "..."
#   ...
# end

IO.puts("""

Exercise 4: Custom Module Attributes
Difficulty: Medium

Create a module called `GameConfig` that uses module attributes for:
- @max_players (set to 4)
- @min_players (set to 2)
- @default_lives (set to 3)
- @difficulty_levels (list of atoms: :easy, :medium, :hard)

Provide functions to access and validate these configurations.

Your code here:
""")

# defmodule GameConfig do
#   ...
# end

IO.puts("""

Exercise 5: Nested Modules
Difficulty: Medium

Create a nested module structure for a simple e-commerce system:
- Shop.Inventory - with functions: add_item/2, remove_item/2, list_items/0
- Shop.Cart - with functions: add_to_cart/2, remove_from_cart/2, calculate_total/1
- Shop.Order - with functions: create_order/1, get_order/1

Use module attributes to store sample data.

Your code here:
""")

# defmodule Shop do
#   ...
# end

IO.puts("""

Exercise 6: Module with Callbacks Pattern
Difficulty: Hard

Create two modules that work together:
1. `EventLogger` - stores a list of log levels as @levels attribute
   - Functions: log(level, message), filter_by_level(logs, level)

2. `Application` - uses EventLogger to track events
   - Functions: start(), perform_action(action), get_logs()

The Application should log events like :info, :warning, :error
and be able to filter logs by level.

Your code here:
""")

# defmodule EventLogger do
#   ...
# end
#
# defmodule Application do
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

1. Modules are defined with `defmodule ModuleName do ... end`
   - Use CamelCase for module names
   - Modules serve as namespaces for functions

2. Public vs Private Functions:
   - `def` creates public functions (accessible from outside)
   - `defp` creates private functions (internal only)

3. Documentation Attributes:
   - @moduledoc documents the entire module
   - @doc documents individual functions
   - @doc false hides a function from docs
   - Use markdown in documentation strings

4. Custom Module Attributes:
   - @attribute_name value defines compile-time constants
   - Accessible only within the module
   - Can be accumulated with Module.register_attribute

5. Nested Modules:
   - Use dot notation: MyApp.SubModule
   - Can be defined inline or separately
   - Create logical hierarchies for code organization

6. Module Functions as Values:
   - Capture with &Module.function/arity
   - Pass to higher-order functions like Enum.map

7. Module Introspection:
   - __info__/1 provides module information
   - function_exported?/3 checks if function exists
   - Code.ensure_loaded?/1 checks if module is available

Next: 20_import_alias_require.exs - Learn about import, alias, require, and use
""")
