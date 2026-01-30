# Appendix A3: IEx Productivity Tips

IEx (Interactive Elixir) is a powerful REPL that's essential for Elixir development. This guide covers tips, helpers, and configuration to maximize your productivity.

## Table of Contents

1. [Getting Started with IEx](#getting-started-with-iex)
2. [Essential Helpers](#essential-helpers)
3. [Navigation and History](#navigation-and-history)
4. [Configuring .iex.exs](#configuring-iexexs)
5. [Working with Projects](#working-with-projects)
6. [Debugging in IEx](#debugging-in-iex)
7. [Advanced Features](#advanced-features)
8. [Productivity Workflows](#productivity-workflows)

---

## Getting Started with IEx

### Starting IEx

```bash
# Basic IEx
iex

# With Mix project loaded
iex -S mix

# With Phoenix server
iex -S mix phx.server

# With specific environment
MIX_ENV=test iex -S mix

# Named node for distribution
iex --sname myapp
iex --name myapp@hostname
```

### Exiting IEx

```elixir
# Graceful exit (preferred)
System.halt(0)

# Quick exit
# Press Ctrl+C twice

# Or use the break menu
# Press Ctrl+C once, then 'a' for abort
```

---

## Essential Helpers

IEx provides many helper functions. Access the full list with `h()`.

### Getting Help

```elixir
# List all helpers
iex> h()

# Help for a module
iex> h(Enum)

# Help for a specific function
iex> h(Enum.map)
iex> h(Enum.map/2)

# Help for operators
iex> h(|>)
iex> h(=)
```

### Inspecting Values

```elixir
# Inspect with default options
iex> i([1, 2, 3])
Term
  [1, 2, 3]
Data type
  List
Reference modules
  List

# Inspect with custom options
iex> IO.inspect([1, 2, 3], limit: 2, label: "my list")
my list: [1, 2, ...]
```

### Type Information

```elixir
# Get type information
iex> t(Enum)       # Types defined in module
iex> t(String.t)   # Specific type info

# Get specs (function signatures)
iex> s(Enum.map)
iex> s(Enum.map/2)
```

### Documentation

```elixir
# Open documentation in browser (if configured)
iex> open(Enum)
iex> open(Enum.map/2)

# Get behavior callbacks
iex> b(GenServer)

# Get exports
iex> exports(Enum)
```

### Code Information

```elixir
# Recompile current project
iex> recompile()

# Recompile specific module
iex> r(MyModule)

# Compile a file
iex> c("path/to/file.ex")

# Load and compile a file
iex> l(MyModule)

# Get module information
iex> i(Enum)
```

### Value History

```elixir
# Access previous results
iex> 1 + 1
2
iex> v()        # Last result: 2
iex> v(-1)      # Same as v(): 2
iex> v(-2)      # Second to last result
iex> v(1)       # Result from line 1
```

### Process Information

```elixir
# List all processes
iex> Process.list()

# Current process
iex> self()

# Process info
iex> Process.info(self())
iex> Process.info(self(), :memory)

# Registered processes
iex> Process.registered()
```

---

## Navigation and History

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+A` | Move to beginning of line |
| `Ctrl+E` | Move to end of line |
| `Ctrl+B` | Move backward one character |
| `Ctrl+F` | Move forward one character |
| `Alt+B` | Move backward one word |
| `Alt+F` | Move forward one word |
| `Ctrl+P` or `Up` | Previous history entry |
| `Ctrl+N` or `Down` | Next history entry |
| `Ctrl+R` | Reverse search history |
| `Ctrl+L` | Clear screen |
| `Ctrl+U` | Delete from cursor to beginning |
| `Ctrl+K` | Delete from cursor to end |
| `Ctrl+W` | Delete previous word |
| `Ctrl+D` | Delete character or exit |
| `Tab` | Autocomplete |

### Multiline Input

```elixir
# Multiline expressions are supported
iex> defmodule Example do
...>   def hello do
...>     "world"
...>   end
...> end

# Cancel multiline with
# Ctrl+C or #iex:break
iex> defmodule Broken do
...> #iex:break
iex>
```

### Autocomplete

```elixir
# Tab completion for modules
iex> Enum.<Tab>
# Shows all Enum functions

# Tab completion for functions
iex> Enum.ma<Tab>
# Shows: map, map_every, map_intersperse, map_join, map_reduce, max, max_by

# Tab completion for variables
iex> my_va<Tab>
# Completes to my_variable if defined
```

---

## Configuring .iex.exs

Create a `.iex.exs` file for custom IEx configuration. IEx looks for this file in:

1. Current directory
2. Home directory (`~/.iex.exs`)

### Basic Configuration

```elixir
# ~/.iex.exs

# Custom prompt
IEx.configure(
  colors: [
    syntax_colors: [
      number: :yellow,
      atom: :cyan,
      string: :green,
      boolean: :magenta,
      nil: :magenta
    ],
    eval_result: [:cyan, :bright],
    eval_error: [:red, :bright],
    eval_info: [:yellow, :bright]
  ],
  default_prompt:
    "#{IO.ANSI.green()}%prefix#{IO.ANSI.reset()}" <>
    "(#{IO.ANSI.cyan()}%counter#{IO.ANSI.reset()})>",
  alive_prompt:
    "#{IO.ANSI.green()}%prefix#{IO.ANSI.reset()}" <>
    "(#{IO.ANSI.cyan()}%node#{IO.ANSI.reset()})>",
  history_size: 100,
  inspect: [
    pretty: true,
    limit: :infinity,
    width: 80
  ]
)
```

### Useful Aliases and Imports

```elixir
# ~/.iex.exs

# Common imports
import_if_available(Ecto.Query)
import_if_available(Ecto.Changeset)

# Alias common modules
alias MyApp.{Repo, User, Account}

# Helper functions
defmodule IExHelpers do
  def reload! do
    Mix.Task.reenable("compile.elixir")
    Application.stop(Mix.Project.config()[:app])
    Mix.Task.run("compile.elixir")
    Application.start(Mix.Project.config()[:app])
  end

  def clear do
    IO.write([IO.ANSI.home(), IO.ANSI.clear()])
  end

  def copy(term) do
    text =
      if is_binary(term) do
        term
      else
        inspect(term, limit: :infinity, pretty: true)
      end

    port = Port.open({:spawn, "pbcopy"}, [:binary])
    Port.command(port, text)
    Port.close(port)
    :ok
  end

  def paste do
    {text, 0} = System.cmd("pbpaste", [])
    text
  end
end

import IExHelpers
```

### Project-Specific Configuration

```elixir
# project/.iex.exs

# Only load if in correct project
if Mix.Project.config()[:app] == :my_app do
  alias MyApp.Repo
  alias MyApp.Accounts.User
  alias MyApp.Blog.{Post, Comment}

  # Shortcut for common queries
  defmodule Q do
    import Ecto.Query

    def users, do: Repo.all(User)
    def user(id), do: Repo.get(User, id)
    def posts, do: Repo.all(Post)
    def recent_posts(limit \\ 10) do
      Post
      |> order_by(desc: :inserted_at)
      |> limit(^limit)
      |> Repo.all()
    end
  end
end
```

### Phoenix-Specific Configuration

```elixir
# Phoenix project .iex.exs

if Code.ensure_loaded?(Phoenix) do
  # Import Phoenix helpers
  import Phoenix.HTML

  # Router helpers
  alias MyAppWeb.Router.Helpers, as: Routes

  # Endpoint for generating URLs
  @endpoint MyAppWeb.Endpoint

  defmodule H do
    def routes do
      MyAppWeb.Router.__routes__()
      |> Enum.map(fn r -> {r.verb, r.path, r.plug, r.plug_opts} end)
    end

    def url(path), do: MyAppWeb.Endpoint.url() <> path
  end
end
```

---

## Working with Projects

### Recompilation

```elixir
# Recompile entire project
iex> recompile()

# Recompile specific module
iex> r(MyModule)

# Force recompilation (useful after changing dependencies)
iex> Mix.Task.reenable("compile")
iex> Mix.Task.run("compile", ["--force"])

# Compile and load file
iex> c("lib/my_module.ex")
```

### Running Mix Tasks

```elixir
# Run any mix task
iex> Mix.Task.run("ecto.migrate")

# Run with arguments
iex> Mix.Task.run("test", ["test/my_test.exs"])

# Re-enable and run
iex> Mix.Task.reenable("ecto.rollback")
iex> Mix.Task.run("ecto.rollback")
```

### Working with Ecto

```elixir
# Common Ecto operations in IEx
iex> alias MyApp.{Repo, User}

# Insert
iex> Repo.insert(%User{name: "Alice"})

# Query
iex> import Ecto.Query
iex> Repo.all(from u in User, where: u.age > 21)

# Update
iex> user = Repo.get!(User, 1)
iex> Repo.update(User.changeset(user, %{name: "Bob"}))

# Delete
iex> Repo.delete(user)

# Raw SQL
iex> Ecto.Adapters.SQL.query!(Repo, "SELECT * FROM users WHERE id = $1", [1])
```

### Application Configuration

```elixir
# Read configuration
iex> Application.get_env(:my_app, :key)
iex> Application.get_all_env(:my_app)

# Set configuration (temporary, not persistent)
iex> Application.put_env(:my_app, :key, "value")

# Fetch with default
iex> Application.fetch_env!(:my_app, :key)
```

---

## Debugging in IEx

### Using IEx.pry

```elixir
# In your code
defmodule MyModule do
  def my_function(arg) do
    require IEx
    IEx.pry()  # Execution pauses here

    # Rest of function
    arg * 2
  end
end
```

Then in IEx:

```elixir
iex> MyModule.my_function(5)
# Opens pry session

pry> arg
5
pry> binding()
[arg: 5]
pry> respawn()  # Continue execution
```

### Break on Function

```elixir
# Set breakpoint on function
iex> break!(MyModule.my_function/1)

# Set conditional breakpoint
iex> break!(MyModule.my_function/1, do: arg > 10)

# List breakpoints
iex> breaks()

# Remove breakpoint
iex> remove_breaks(MyModule.my_function/1)

# Remove all breakpoints
iex> remove_breaks()
```

### Debugging Processes

```elixir
# Trace function calls
iex> :dbg.tracer()
iex> :dbg.p(:all, :c)
iex> :dbg.tpl(MyModule, :my_function, [])
# Now calls to MyModule.my_function are traced

# Stop tracing
iex> :dbg.stop()
```

### Inspecting State

```elixir
# For GenServer
iex> :sys.get_state(MyGenServer)

# With timeout
iex> :sys.get_state(MyGenServer, 5000)

# Get process statistics
iex> :sys.statistics(MyGenServer, true)
iex> :sys.statistics(MyGenServer, :get)

# Trace process
iex> :sys.trace(MyGenServer, true)
```

---

## Advanced Features

### Remote Shells

Connect to a running node:

```bash
# Start a named node
iex --sname myapp

# Connect from another terminal
iex --sname debug --remsh myapp@hostname
```

Or using `--cookie` for security:

```bash
iex --sname myapp --cookie mysecret
iex --sname debug --cookie mysecret --remsh myapp@hostname
```

### Evaluating Code from Files

```elixir
# Import code from file
iex> import_file("scripts/helpers.exs")

# If file doesn't exist, silently ignore
iex> import_file_if_available("optional_config.exs")
```

### Shell Process

```elixir
# Spawn a new shell process
iex> IEx.Helpers.respawn()

# This is useful to:
# - Escape from stuck evaluations
# - Reset shell state
# - Continue after pry
```

### Capture IO

```elixir
# Capture output
iex> ExUnit.CaptureIO.capture_io(fn -> IO.puts("hello") end)
"hello\n"

# Capture with input
iex> ExUnit.CaptureIO.capture_io("input\n", fn ->
...>   IO.gets("prompt: ")
...> end)
```

### Runtime Information

```elixir
# System info
iex> :erlang.system_info(:schedulers)
iex> :erlang.system_info(:process_count)
iex> :erlang.system_info(:atom_count)
iex> :erlang.system_info(:ets_count)

# Memory usage
iex> :erlang.memory()
iex> :erlang.memory(:total)
iex> :erlang.memory(:processes)

# Garbage collection
iex> :erlang.garbage_collect()
```

---

## Productivity Workflows

### Quick Module Testing

```elixir
# Define and test module inline
iex> defmodule QuickTest do
...>   def add(a, b), do: a + b
...> end
iex> QuickTest.add(1, 2)
3

# Redefine without warning
iex> defmodule QuickTest do
...>   def add(a, b), do: a + b + 1
...> end
```

### Working with Files

```elixir
# Read file
iex> File.read!("config/config.exs")

# Write file
iex> File.write!("output.txt", "content")

# List directory
iex> File.ls!("lib")

# Check existence
iex> File.exists?("mix.exs")
```

### HTTP Requests (with HTTPoison)

```elixir
# Quick HTTP testing
iex> HTTPoison.get!("https://api.github.com")
iex> HTTPoison.post!("https://httpbin.org/post", ~s({"key": "value"}), [{"Content-Type", "application/json"}])
```

### JSON Handling

```elixir
# Parse JSON
iex> Jason.decode!(~s({"name": "Alice", "age": 30}))
%{"name" => "Alice", "age" => 30}

# Encode to JSON
iex> Jason.encode!(%{name: "Alice", age: 30})
"{\"age\":30,\"name\":\"Alice\"}"

# Pretty print
iex> Jason.encode!(%{name: "Alice"}, pretty: true) |> IO.puts()
```

### Benchmarking

```elixir
# Simple timing
iex> :timer.tc(fn -> Enum.sum(1..1_000_000) end)
{52743, 500000500000}  # {microseconds, result}

# With Benchee (if available)
iex> Benchee.run(%{
...>   "map" => fn -> Enum.map(1..1000, &(&1 * 2)) end,
...>   "comprehension" => fn -> for x <- 1..1000, do: x * 2 end
...> })
```

### Pipeline Debugging

```elixir
# Use IO.inspect in pipelines
iex> [1, 2, 3]
...> |> IO.inspect(label: "initial")
...> |> Enum.map(&(&1 * 2))
...> |> IO.inspect(label: "after map")
...> |> Enum.sum()
...> |> IO.inspect(label: "final")
initial: [1, 2, 3]
after map: [2, 4, 6]
final: 12
12

# With dbg (Elixir 1.14+)
iex> [1, 2, 3]
...> |> Enum.map(&(&1 * 2))
...> |> Enum.sum()
...> |> dbg()
```

---

## Quick Reference Card

| Command | Description |
|---------|-------------|
| `h()` | List helpers |
| `h(Module)` | Module docs |
| `h(Module.fun/arity)` | Function docs |
| `i(term)` | Inspect term info |
| `t(Module)` | Show types |
| `s(Module.fun)` | Show specs |
| `b(Behaviour)` | Show callbacks |
| `v()` | Last result |
| `v(n)` | Result from line n |
| `recompile()` | Recompile project |
| `r(Module)` | Recompile module |
| `c("file.ex")` | Compile file |
| `break!(M.f/a)` | Set breakpoint |
| `breaks()` | List breakpoints |
| `respawn()` | New shell process |
| `clear()` | Clear screen (custom) |

---

*Last updated: January 2025*
