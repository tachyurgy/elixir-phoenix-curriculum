# Phoenix Server - Starting and Configuration

## Introduction

This guide covers how to start the Phoenix server, configure endpoints, and manage different environments. Understanding these concepts is essential for both development and production deployments.

## Starting the Phoenix Server

### Basic Server Start

```bash
# Start the server
mix phx.server

# Output:
# [info] Running MyAppWeb.Endpoint with Bandit 1.5.0 at http://127.0.0.1:4000 (http)
# [info] Access MyAppWeb.Endpoint at http://localhost:4000
```

### Interactive Mode (Recommended for Development)

```bash
# Start with IEx shell - allows live interaction
iex -S mix phx.server

# Now you can:
# - Inspect application state
# - Test functions directly
# - Reload modules
# - Debug issues
```

### Using the IEx Shell

```elixir
# In iex -S mix phx.server

# Test a context function
MyApp.Accounts.list_users()

# Check configuration
Application.get_env(:my_app, MyAppWeb.Endpoint)

# Reload a module after changes
r MyApp.Accounts

# Recompile the project
recompile()

# Check router routes
MyAppWeb.Router.__routes__()
```

## Endpoint Configuration

The endpoint is the entry point for all web requests. It's configured in multiple places.

### `lib/my_app_web/endpoint.ex`

```elixir
defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  @session_options [
    store: :cookie,
    key: "_my_app_key",
    signing_salt: "your_signing_salt",
    same_site: "Lax"
  ]

  # WebSocket connection for LiveView
  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve static files at "/" from priv/static
  plug Plug.Static,
    at: "/",
    from: :my_app,
    gzip: false,
    only: MyAppWeb.static_paths()

  # Code reloading in development
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :my_app
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  # Parse request body
  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug MyAppWeb.Router
end
```

### Endpoint Configuration Options

```elixir
# config/config.exs
config :my_app, MyAppWeb.Endpoint,
  # URL configuration for link generation
  url: [host: "localhost", port: 4000, scheme: "http"],

  # HTTP server adapter
  adapter: Bandit.PhoenixAdapter,  # or Phoenix.Endpoint.Cowboy2Adapter

  # Error handling
  render_errors: [
    formats: [html: MyAppWeb.ErrorHTML, json: MyAppWeb.ErrorJSON],
    layout: false
  ],

  # PubSub for real-time features
  pubsub_server: MyApp.PubSub,

  # LiveView configuration
  live_view: [signing_salt: "your_salt_here"]
```

### Development-Specific Configuration

```elixir
# config/dev.exs
config :my_app, MyAppWeb.Endpoint,
  # HTTP server settings
  http: [ip: {127, 0, 0, 1}, port: 4000],

  # Allow connections from any origin (dev only!)
  check_origin: false,

  # Enable code reloading
  code_reloader: true,

  # Show detailed error pages
  debug_errors: true,

  # Secret key for signing (use a real one in production)
  secret_key_base: "long_random_string_for_development...",

  # Asset watchers
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:my_app, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:my_app, ~w(--watch)]}
  ]

# Live reload patterns
config :my_app, MyAppWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/my_app_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]
```

### Production Configuration

```elixir
# config/prod.exs
config :my_app, MyAppWeb.Endpoint,
  # Don't include code reloader
  code_reloader: false,

  # Enable gzip compression for static files
  cache_static_manifest: "priv/static/cache_manifest.json",

  # Force SSL
  force_ssl: [rewrite_on: [:x_forwarded_proto]]

# config/runtime.exs (environment variables at runtime)
if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE is required"

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :my_app, MyAppWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},  # Listen on all interfaces
      port: port
    ],
    secret_key_base: secret_key_base,
    server: true  # Start the server (needed for releases)
end
```

## Environment Management

Phoenix uses the `MIX_ENV` environment variable to determine the current environment.

### Available Environments

```bash
# Development (default)
MIX_ENV=dev mix phx.server
# or simply:
mix phx.server

# Test
MIX_ENV=test mix test

# Production
MIX_ENV=prod mix phx.server
```

### Environment-Specific Behavior

```elixir
# In your code, check the environment
case Mix.env() do
  :dev -> IO.puts("Running in development")
  :test -> IO.puts("Running tests")
  :prod -> IO.puts("Running in production")
end

# Or use compile-time checks
if Mix.env() == :dev do
  # Development-only code
end

# In config files
import Config

config :my_app, :some_feature,
  enabled: config_env() != :test
```

### Configuration Loading Order

1. `config/config.exs` - Base configuration (loaded first)
2. `config/#{env}.exs` - Environment-specific (dev.exs, test.exs, prod.exs)
3. `config/runtime.exs` - Runtime configuration (loaded at application start)

```elixir
# config/config.exs
import Config

config :my_app, :api_url, "http://default.api.com"

# This loads the environment-specific file
import_config "#{config_env()}.exs"
```

```elixir
# config/dev.exs
import Config

config :my_app, :api_url, "http://localhost:3000"
```

```elixir
# config/runtime.exs
import Config

if config_env() == :prod do
  config :my_app, :api_url, System.get_env("API_URL")
end
```

## HTTP Server Options

### Bandit (Default in Phoenix 1.7+)

```elixir
# config/dev.exs
config :my_app, MyAppWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  http: [
    ip: {127, 0, 0, 1},
    port: 4000
  ]
```

### Cowboy (Alternative)

```elixir
# In mix.exs, add cowboy dependency
{:plug_cowboy, "~> 2.5"}

# In config
config :my_app, MyAppWeb.Endpoint,
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  http: [port: 4000]
```

### HTTPS Configuration

```elixir
# config/dev.exs - HTTPS in development
config :my_app, MyAppWeb.Endpoint,
  https: [
    port: 4001,
    cipher_suite: :strong,
    keyfile: "priv/cert/selfsigned_key.pem",
    certfile: "priv/cert/selfsigned.pem"
  ]

# Generate self-signed certificates
# mix phx.gen.cert
```

### Port Configuration

```elixir
# Listen on specific port
config :my_app, MyAppWeb.Endpoint,
  http: [port: 4000]

# Listen on port from environment variable
config :my_app, MyAppWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT") || "4000")]

# Listen on multiple ports (less common)
# You would need custom supervision for this
```

### Binding to Network Interfaces

```elixir
# Localhost only (secure for development)
http: [ip: {127, 0, 0, 1}, port: 4000]

# All IPv4 interfaces
http: [ip: {0, 0, 0, 0}, port: 4000]

# All interfaces (IPv4 and IPv6)
http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: 4000]

# Specific interface
http: [ip: {192, 168, 1, 100}, port: 4000]
```

## URL Configuration

URL configuration affects link generation, not the actual server binding.

```elixir
# Development
config :my_app, MyAppWeb.Endpoint,
  url: [host: "localhost", port: 4000]

# Production behind a load balancer
config :my_app, MyAppWeb.Endpoint,
  url: [host: "myapp.com", port: 443, scheme: "https"],
  http: [port: 4000]  # Internal port

# Using a path prefix (subdirectory deployment)
config :my_app, MyAppWeb.Endpoint,
  url: [host: "myapp.com", path: "/app"]
```

### Generated URLs

```elixir
# In your code
MyAppWeb.Endpoint.url()
# => "https://myapp.com"

MyAppWeb.Endpoint.static_url()
# => "https://myapp.com"

# In templates with verified routes
~p"/users/123"
# => "/users/123"

url(~p"/users/123")
# => "https://myapp.com/users/123"
```

## Server Lifecycle

### Starting the Server Programmatically

```elixir
# The endpoint is started by the application supervisor
# lib/my_app/application.ex

def start(_type, _args) do
  children = [
    # ... other children
    MyAppWeb.Endpoint  # Starts the HTTP server
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

### Conditional Server Start

```elixir
# In releases, you might want to control server start
# config/runtime.exs

config :my_app, MyAppWeb.Endpoint,
  server: System.get_env("PHX_SERVER") == "true"
```

### Graceful Shutdown

Phoenix handles graceful shutdown automatically:

```elixir
# The endpoint drains connections on shutdown
# You can configure the drain timeout

config :my_app, MyAppWeb.Endpoint,
  drainer: [
    batch_interval: 1000,  # Check every 1 second
    batch_size: 1000       # Max connections to drain per batch
  ]
```

## Development Tools

### Live Reload

Automatically reloads the browser when files change:

```elixir
# config/dev.exs
config :my_app, MyAppWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/my_app_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]
```

### Code Reloading

Recompiles changed modules without restarting:

```elixir
# Enabled by default in dev
config :my_app, MyAppWeb.Endpoint,
  code_reloader: true
```

### Debug Error Pages

Shows detailed error information in development:

```elixir
config :my_app, MyAppWeb.Endpoint,
  debug_errors: true
```

### Phoenix LiveDashboard

Access at `/dev/dashboard` in development:

```elixir
# router.ex
if Application.compile_env(:my_app, :dev_routes) do
  import Phoenix.LiveDashboard.Router

  scope "/dev" do
    pipe_through :browser

    live_dashboard "/dashboard",
      metrics: MyAppWeb.Telemetry
  end
end
```

## Useful Commands

```bash
# Start server
mix phx.server

# Start with IEx
iex -S mix phx.server

# Run in specific environment
MIX_ENV=prod mix phx.server

# Show all routes
mix phx.routes

# Generate secret key base
mix phx.gen.secret

# Digest static assets (production)
mix phx.digest

# Clean digested assets
mix phx.digest.clean
```

## Summary

| Concept | Description |
|---------|-------------|
| `mix phx.server` | Start the Phoenix server |
| `iex -S mix phx.server` | Start with interactive shell |
| Endpoint | Entry point for HTTP requests |
| `config/dev.exs` | Development configuration |
| `config/prod.exs` | Production configuration |
| `config/runtime.exs` | Runtime environment variables |
| `MIX_ENV` | Environment variable for environment |
| Live Reload | Auto-reload on file changes |
| Code Reloader | Recompile modules on change |

Understanding these concepts ensures you can effectively develop and deploy Phoenix applications.
