# ============================================================================
# Lesson 20: Import, Alias, Require, and Use
# ============================================================================
#
# Elixir provides four directives for working with modules:
# - import: Brings functions into the current scope
# - alias: Creates shortcuts for module names
# - require: Ensures a module is compiled (needed for macros)
# - use: Invokes a module's __using__ macro
#
# Learning Objectives:
# - Understand when and how to use each directive
# - Master selective imports with only/except
# - Create clear and maintainable code with aliases
# - Understand the difference between require and import
# - Learn how use enables powerful metaprogramming
#
# Prerequisites:
# - Understanding of modules (Lesson 19)
# - Basic understanding of macros (conceptual)
#
# ============================================================================

IO.puts("=" |> String.duplicate(70))
IO.puts("Lesson 20: Import, Alias, Require, and Use")
IO.puts("=" |> String.duplicate(70))

# -----------------------------------------------------------------------------
# Section 1: The alias Directive
# -----------------------------------------------------------------------------
#
# `alias` creates a shortcut for a module name. This is useful when:
# - Working with deeply nested modules
# - The full module name is long and used frequently
# - You want to make code more readable
#
# Syntax: alias Module.Path.Name
# Result: You can now use just `Name` instead of `Module.Path.Name`
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 1: The alias Directive ---\n")

# Define some nested modules to work with
defmodule MyApplication.Services.UserManagement.Authentication do
  def login(username) do
    {:ok, "#{username} logged in successfully"}
  end

  def logout(username) do
    {:ok, "#{username} logged out"}
  end

  def current_user do
    "admin"
  end
end

defmodule MyApplication.Services.UserManagement.Authorization do
  def can?(user, action) do
    user == "admin" or action == :read
  end

  def roles_for(user) do
    if user == "admin", do: [:admin, :user], else: [:user]
  end
end

# Without alias - verbose!
result1 = MyApplication.Services.UserManagement.Authentication.login("alice")
IO.inspect(result1, label: "Without alias")

# Using alias to create shortcuts
defmodule UserController do
  # Basic alias - uses the last part of the module name
  alias MyApplication.Services.UserManagement.Authentication
  alias MyApplication.Services.UserManagement.Authorization

  def perform_login(username) do
    # Now we can use just Authentication instead of the full path
    case Authentication.login(username) do
      {:ok, message} ->
        roles = Authorization.roles_for(username)
        {:ok, message, roles}
      error -> error
    end
  end

  def check_permission(user, action) do
    Authorization.can?(user, action)
  end
end

IO.inspect(UserController.perform_login("bob"), label: "With alias")
IO.puts("Can bob read? #{UserController.check_permission("bob", :read)}")
IO.puts("Can bob delete? #{UserController.check_permission("bob", :delete)}")

# Alias with custom name using :as
defmodule AnotherController do
  alias MyApplication.Services.UserManagement.Authentication, as: Auth
  alias MyApplication.Services.UserManagement.Authorization, as: Authz

  def demo do
    user = Auth.current_user()
    can_delete = Authz.can?(user, :delete)
    "User: #{user}, Can delete: #{can_delete}"
  end
end

IO.puts("\nWith custom alias names: #{AnotherController.demo()}")

# Multiple aliases at once
defmodule BulkAliasExample do
  alias MyApplication.Services.UserManagement.{Authentication, Authorization}

  def show_info do
    user = Authentication.current_user()
    roles = Authorization.roles_for(user)
    "#{user} has roles: #{inspect(roles)}"
  end
end

IO.puts("Bulk alias: #{BulkAliasExample.show_info()}")

# -----------------------------------------------------------------------------
# Section 2: The import Directive
# -----------------------------------------------------------------------------
#
# `import` brings functions from a module into the current scope,
# allowing you to call them without the module prefix.
#
# Use import sparingly! It can make code harder to understand because
# it's not clear where functions come from.
#
# Best practice: Use `only:` or `except:` to limit what's imported.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 2: The import Directive ---\n")

defmodule MathHelpers do
  def square(x), do: x * x
  def cube(x), do: x * x * x
  def double(x), do: x * 2
  def triple(x), do: x * 3
  def half(x), do: x / 2
  def negate(x), do: -x
end

# Import all functions from a module
defmodule FullImportExample do
  import MathHelpers

  def calculate(x) do
    # Can call functions without MathHelpers. prefix
    result = x
    |> double()
    |> square()
    |> negate()

    "double, square, negate of #{x} = #{result}"
  end
end

IO.puts(FullImportExample.calculate(3))

# Import with :only - RECOMMENDED approach
defmodule SelectiveImportExample do
  # Only import specific functions (name/arity pairs)
  import MathHelpers, only: [square: 1, cube: 1]

  def powers(x) do
    "#{x} squared: #{square(x)}, cubed: #{cube(x)}"
  end
end

IO.puts(SelectiveImportExample.powers(4))

# Import with :except - exclude specific functions
defmodule ExceptImportExample do
  import MathHelpers, except: [negate: 1, half: 1]

  def transform(x) do
    x |> double() |> triple() |> square()
  end
end

IO.puts("Transform 2: #{ExceptImportExample.transform(2)}")

# Import from Elixir's standard library
defmodule ListProcessor do
  # Import specific Enum functions we'll use frequently
  import Enum, only: [map: 2, filter: 2, reduce: 3]

  def process(list) do
    list
    |> filter(&(&1 > 0))      # Keep positive numbers
    |> map(&(&1 * 2))          # Double them
    |> reduce(0, &(&1 + &2))   # Sum them
  end
end

IO.puts("Process [-1, 2, -3, 4, 5]: #{ListProcessor.process([-1, 2, -3, 4, 5])}")

# Import with :only and :macros or :functions
defmodule ImportTypeExample do
  # Import only functions (not macros)
  import Kernel, only: :functions

  # Or import only macros
  # import SomeModule, only: :macros
end

# Scoped imports - imports only apply within their scope
defmodule ScopedImportExample do
  def with_import do
    import MathHelpers, only: [double: 1]
    double(10)
  end

  def without_import do
    # double/1 is not available here!
    MathHelpers.double(10)
  end
end

IO.puts("Scoped import: #{ScopedImportExample.with_import()}")
IO.puts("Without import: #{ScopedImportExample.without_import()}")

# -----------------------------------------------------------------------------
# Section 3: The require Directive
# -----------------------------------------------------------------------------
#
# `require` ensures a module is compiled and loaded before using it.
# This is necessary when you want to use macros from another module.
#
# Macros are expanded at compile time, so the module defining them
# must be available during compilation.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 3: The require Directive ---\n")

# Logger is a common example - it provides macros
defmodule LoggingExample do
  require Logger

  def do_something do
    Logger.info("Starting operation")
    result = 1 + 1
    Logger.debug("Calculated result: #{result}")
    Logger.warning("This is a warning")
    result
  end
end

IO.puts("Logger example (may not show output depending on log level):")
LoggingExample.do_something()
IO.puts("(Logger output depends on configuration)")

# Custom module with macros
defmodule Assertions do
  defmacro assert_equal(left, right) do
    quote do
      left_val = unquote(left)
      right_val = unquote(right)
      if left_val == right_val do
        IO.puts("PASS: #{inspect(left_val)} == #{inspect(right_val)}")
        :ok
      else
        IO.puts("FAIL: #{inspect(left_val)} != #{inspect(right_val)}")
        :error
      end
    end
  end

  defmacro assert_true(expression) do
    quote do
      if unquote(expression) do
        IO.puts("PASS: expression is true")
        :ok
      else
        IO.puts("FAIL: expression is false")
        :error
      end
    end
  end
end

defmodule TestRunner do
  # Must require to use macros
  require Assertions

  def run_tests do
    IO.puts("\nRunning assertions:")
    Assertions.assert_equal(2 + 2, 4)
    Assertions.assert_equal(10 * 10, 100)
    Assertions.assert_true(String.length("hello") == 5)
    Assertions.assert_equal([1, 2, 3], [1, 2, 3])
  end
end

TestRunner.run_tests()

# Note: alias doesn't require require
# But import automatically requires the module
defmodule RequireVsImportDemo do
  # This works because import implicitly requires
  import Integer, only: [is_even: 1]

  def check(n) do
    # is_even is a macro, but import handled the require
    if is_even(n), do: "#{n} is even", else: "#{n} is odd"
  end
end

IO.puts("\n#{RequireVsImportDemo.check(42)}")
IO.puts(RequireVsImportDemo.check(17))

# -----------------------------------------------------------------------------
# Section 4: The use Directive
# -----------------------------------------------------------------------------
#
# `use` is the most powerful directive. It allows a module to inject
# code into the caller's module. When you call `use SomeModule`, Elixir:
#
# 1. requires SomeModule
# 2. calls SomeModule.__using__/1 macro
# 3. Injects the returned code into your module
#
# This is commonly used for:
# - Implementing behaviours
# - Adding common functionality
# - Framework integration (Phoenix, Ecto, etc.)
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 4: The use Directive ---\n")

# A module that can be "used"
defmodule Loggable do
  defmacro __using__(opts) do
    prefix = Keyword.get(opts, :prefix, "LOG")

    quote do
      def log(message) do
        IO.puts("[#{unquote(prefix)}] #{message}")
      end

      def log(level, message) do
        IO.puts("[#{unquote(prefix)}:#{level}] #{message}")
      end
    end
  end
end

defmodule MyService do
  use Loggable, prefix: "MyService"

  def perform_action do
    log("Starting action")
    result = 42
    log(:info, "Action completed with result: #{result}")
    result
  end
end

defmodule AnotherService do
  use Loggable  # Uses default prefix "LOG"

  def do_work do
    log("Doing work...")
    log(:debug, "Work details here")
  end
end

IO.puts("Using Loggable in MyService:")
MyService.perform_action()

IO.puts("\nUsing Loggable in AnotherService:")
AnotherService.do_work()

# A more complex use example - adding common CRUD functionality
defmodule CRUDHelpers do
  defmacro __using__(opts) do
    resource = Keyword.fetch!(opts, :resource)

    quote do
      @resource_name unquote(resource)

      def list do
        IO.puts("Listing all #{@resource_name}s")
        []
      end

      def get(id) do
        IO.puts("Getting #{@resource_name} with id: #{id}")
        %{id: id, type: @resource_name}
      end

      def create(attrs) do
        IO.puts("Creating #{@resource_name} with: #{inspect(attrs)}")
        {:ok, Map.put(attrs, :id, :rand.uniform(1000))}
      end

      def update(id, attrs) do
        IO.puts("Updating #{@resource_name} #{id} with: #{inspect(attrs)}")
        {:ok, Map.put(attrs, :id, id)}
      end

      def delete(id) do
        IO.puts("Deleting #{@resource_name} with id: #{id}")
        :ok
      end
    end
  end
end

defmodule UserRepository do
  use CRUDHelpers, resource: :user
end

defmodule ProductRepository do
  use CRUDHelpers, resource: :product
end

IO.puts("\nUsing CRUDHelpers:")
UserRepository.list()
UserRepository.get(1)
UserRepository.create(%{name: "Alice"})

ProductRepository.list()
ProductRepository.get(42)

# Combining use with callbacks
defmodule Pluggable do
  @callback init(opts :: keyword()) :: any()
  @callback call(data :: any(), state :: any()) :: any()

  defmacro __using__(_opts) do
    quote do
      @behaviour Pluggable

      def init(opts), do: opts
      defoverridable init: 1
    end
  end
end

defmodule MyPlug do
  use Pluggable

  # Override init if needed
  def init(opts) do
    Keyword.put(opts, :initialized_at, DateTime.utc_now())
  end

  def call(data, state) do
    IO.puts("MyPlug called with data: #{inspect(data)}")
    IO.puts("State: #{inspect(state)}")
    {:ok, data}
  end
end

IO.puts("\nPluggable example:")
state = MyPlug.init(name: "test")
MyPlug.call("hello", state)

# -----------------------------------------------------------------------------
# Section 5: Combining Directives
# -----------------------------------------------------------------------------
#
# In real applications, you'll often use multiple directives together.
# Here's the conventional order:
#
# defmodule MyModule do
#   @moduledoc "..."
#
#   use SomeFramework
#
#   import SomeHelpers
#
#   alias Long.Module.Name
#
#   require SomeMacros
#
#   # ... rest of module
# end
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 5: Combining Directives ---\n")

defmodule DataProcessor do
  @moduledoc """
  Example module showing how directives are typically combined.
  """

  # use comes first (may inject aliases, imports, etc.)
  use Loggable, prefix: "DataProcessor"

  # Then imports
  import Enum, only: [map: 2, filter: 2, reduce: 3, count: 1]

  # Then aliases
  alias MyApplication.Services.UserManagement.Authentication, as: Auth

  # Then require (if needed separately)
  require Logger

  def process(data) when is_list(data) do
    log("Processing #{count(data)} items")

    result = data
    |> filter(&is_number/1)
    |> map(&(&1 * 2))
    |> reduce(0, &+/2)

    log(:info, "Result: #{result}")
    result
  end

  def get_current_user do
    Auth.current_user()
  end
end

IO.puts("Combined directives example:")
DataProcessor.process([1, "a", 2, :b, 3, nil, 4, 5])
IO.puts("Current user: #{DataProcessor.get_current_user()}")

# -----------------------------------------------------------------------------
# Section 6: Scoping and Lexical Contexts
# -----------------------------------------------------------------------------
#
# All directives are lexically scoped. They only apply within the
# current scope (module, function, or block).
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 6: Scoping and Lexical Contexts ---\n")

defmodule ScopingDemo do
  # Module-level import - available throughout the module
  import String, only: [upcase: 1, downcase: 1]

  def module_level_import do
    upcase("hello")  # Works because of module-level import
  end

  def function_level_import do
    # Function-level import - only available in this function
    import Integer, only: [digits: 1]
    digits(12345)
  end

  def block_level_import do
    result = if true do
      import List, only: [first: 1]
      first([1, 2, 3])  # Works inside this block
    end
    # first/1 is NOT available here
    result
  end

  # Alias scoping works the same way
  alias MyApplication.Services.UserManagement.Authentication, as: Auth

  def aliased_function do
    Auth.current_user()
  end
end

IO.puts("Module-level import: #{ScopingDemo.module_level_import()}")
IO.puts("Function-level import: #{inspect(ScopingDemo.function_level_import())}")
IO.puts("Block-level import: #{ScopingDemo.block_level_import()}")
IO.puts("Aliased function: #{ScopingDemo.aliased_function()}")

# -----------------------------------------------------------------------------
# Section 7: Best Practices
# -----------------------------------------------------------------------------
#
# 1. Prefer alias over import when possible
#    - Makes it clear where functions come from
#    - alias Module, then call Module.function()
#
# 2. Use import sparingly
#    - Always use :only to limit what's imported
#    - Good for DSLs or frequently used helpers
#
# 3. use is for framework integration
#    - Understand what code is being injected
#    - Read the __using__ macro to know what you get
#
# 4. require is rare
#    - Only needed for macros when not using import
#    - import automatically requires
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 7: Best Practices Summary ---\n")

IO.puts("""
Best Practices:

1. Order of directives in a module:
   - use (first, as it may inject other directives)
   - import (with :only)
   - alias (with :as if needed)
   - require (rarely needed explicitly)

2. Prefer alias over import:
   # Good - clear where function comes from
   alias MyApp.Users
   Users.list_all()

   # Less clear - where does list_all come from?
   import MyApp.Users
   list_all()

3. When using import, always specify :only:
   # Good
   import Enum, only: [map: 2, filter: 2]

   # Bad - imports everything
   import Enum

4. Use meaningful alias names:
   # Good
   alias MyApp.LongModuleName, as: ShortName

   # Confusing
   alias MyApp.Users, as: X
""")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Exercise 1: Working with alias
Difficulty: Easy

Given these module definitions (already defined above):
- MyApplication.Services.UserManagement.Authentication
- MyApplication.Services.UserManagement.Authorization

Create a module called `AdminPanel` that:
1. Uses alias to create shortcuts for both modules
2. Has a function `admin_actions/0` that calls functions from both modules
3. Uses the multi-alias syntax to alias both at once

Your code here:
""")

# defmodule AdminPanel do
#   alias ...
#   ...
# end

IO.puts("""

Exercise 2: Selective Imports
Difficulty: Easy

Create a module called `ListAnalyzer` that:
1. Imports only `sum/1`, `max/1`, `min/1` from Enum
2. Has a function `analyze/1` that takes a list and returns a map with
   the sum, max, and min values
3. Demonstrates that other Enum functions are NOT available (comment showing this)

Your code here:
""")

# defmodule ListAnalyzer do
#   import ...
#   ...
# end

IO.puts("""

Exercise 3: Creating a Usable Module
Difficulty: Medium

Create a module called `Timestampable` that can be "used" to add timestamp
functionality to other modules. When used, it should inject:
- A function `current_timestamp/0` that returns the current DateTime
- A function `format_timestamp/1` that formats a DateTime as a string
- A function `timestamp_log/1` that prints a message with a timestamp prefix

Then create a `Logger` module that uses `Timestampable`.

Your code here:
""")

# defmodule Timestampable do
#   defmacro __using__(_opts) do
#     quote do
#       ...
#     end
#   end
# end
#
# defmodule Logger do
#   use Timestampable
#   ...
# end

IO.puts("""

Exercise 4: Require for Macros
Difficulty: Medium

Create a module called `DebugMacros` with these macros:
- `debug_value(expression)` - prints the expression text and its value
- `time_it(expression)` - times how long an expression takes to execute

Then create a `Calculator` module that requires `DebugMacros` and uses
both macros in a function called `compute/1`.

Your code here:
""")

# defmodule DebugMacros do
#   defmacro debug_value(expr) do
#     ...
#   end
#   ...
# end

IO.puts("""

Exercise 5: Complete Module with All Directives
Difficulty: Medium

Create a module called `ReportGenerator` that demonstrates all four directives:
1. `use` - Create and use a `Reportable` module that injects common report functions
2. `import` - Import specific functions from Enum
3. `alias` - Create an alias for a nested module you define
4. `require` - Require Logger for logging

The module should have a `generate/1` function that uses all the
imported/aliased/injected functionality.

Your code here:
""")

# defmodule Reportable do
#   ...
# end
#
# defmodule MyApp.Data.Formatter do
#   ...
# end
#
# defmodule ReportGenerator do
#   use Reportable
#   import ...
#   alias ...
#   require ...
#   ...
# end

IO.puts("""

Exercise 6: Building a Mini Framework
Difficulty: Hard

Create a mini "testing framework" with:

1. `TestFramework` module with `__using__/1` that injects:
   - An `@tests` accumulating attribute
   - A `test/2` macro that registers a test (name + function)
   - A `run_tests/0` function that runs all registered tests

2. `MyTests` module that uses the framework:
   - Define at least 3 tests using the `test/2` macro
   - Tests should use assertions (can be simple comparisons)

3. Run the tests and show output

Hint: This is advanced - you'll need to use Module.register_attribute
with accumulate: true, and macros that manipulate the @tests attribute.

Your code here:
""")

# This is a challenging exercise - start with a simpler version if needed!

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Key takeaways from this lesson:

1. alias - Creates shortcuts for module names
   - alias Long.Module.Name (uses Name)
   - alias Long.Module.Name, as: Short
   - alias Long.Module.{Name1, Name2} (multiple)

2. import - Brings functions into current scope
   - import Module, only: [fun: arity]  (recommended)
   - import Module, except: [fun: arity]
   - Use sparingly - can make code harder to follow

3. require - Ensures module is compiled (for macros)
   - require ModuleWithMacros
   - import automatically requires
   - Needed when using macros without import

4. use - Invokes __using__/1 macro
   - use Module or use Module, opts
   - Calls Module.__using__(opts)
   - Commonly used for framework integration

5. Directive Order Convention:
   defmodule MyModule do
     use Framework
     import Helpers, only: [...]
     alias Long.Module.Name
     require MacroModule
   end

6. All directives are lexically scoped:
   - Module-level: available throughout module
   - Function-level: available only in that function
   - Block-level: available only in that block

7. Best Practices:
   - Prefer alias over import for clarity
   - Always use :only with import
   - Understand what use injects
   - Keep directive sections organized

Next: 21_module_behaviours.exs - Learn about behaviours and callbacks
""")
