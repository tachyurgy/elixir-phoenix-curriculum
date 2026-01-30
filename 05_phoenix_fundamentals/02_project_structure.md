# Phoenix Project Structure

## Introduction

Understanding the Phoenix project structure is essential for effective development. This guide provides a detailed explanation of every directory and file in a Phoenix application.

## High-Level Overview

```
my_app/
├── _build/              # Compiled bytecode
├── assets/              # Frontend assets (JS, CSS, images)
├── config/              # Environment configurations
├── deps/                # External dependencies
├── lib/                 # Application source code
│   ├── my_app/          # Business logic (contexts, schemas)
│   ├── my_app_web/      # Web interface (controllers, views, templates)
│   ├── my_app.ex        # Main application module
│   └── my_app_web.ex    # Web module with shared imports
├── priv/                # Private application files
│   ├── gettext/         # Internationalization
│   ├── repo/            # Database migrations and seeds
│   └── static/          # Static files served directly
├── test/                # Test files
├── .formatter.exs       # Code formatter configuration
├── .gitignore           # Git ignore rules
├── mix.exs              # Project configuration
├── mix.lock             # Locked dependency versions
└── README.md            # Project documentation
```

## The `lib/` Directory

The `lib/` directory contains all your application code, split into two main parts.

### `lib/my_app/` - Business Logic

This directory contains your domain logic, independent of the web layer.

```
lib/my_app/
├── application.ex       # OTP Application supervision tree
├── repo.ex              # Ecto repository
├── mailer.ex            # Email sending configuration
└── [contexts]/          # Business logic contexts
    ├── accounts.ex      # Accounts context
    ├── accounts/
    │   ├── user.ex      # User schema
    │   └── user_token.ex
    └── catalog.ex       # Another context
```

#### `application.ex`

Defines the OTP application and its supervision tree:

```elixir
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MyAppWeb.Telemetry,
      MyApp.Repo,
      {DNSCluster, query: Application.get_env(:my_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MyApp.PubSub},
      {Finch, name: MyApp.Finch},
      MyAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    MyAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
```

#### `repo.ex`

Database repository configuration:

```elixir
defmodule MyApp.Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres
end
```

### `lib/my_app_web/` - Web Layer

This directory contains everything related to the web interface.

```
lib/my_app_web/
├── components/           # Phoenix components
│   ├── core_components.ex    # Core UI components
│   └── layouts.ex            # Layout components
├── controllers/         # Request handlers
│   ├── page_controller.ex
│   ├── page_html.ex
│   └── page_html/
│       └── home.html.heex
├── live/                # LiveView modules
├── endpoint.ex          # HTTP endpoint configuration
├── router.ex            # Route definitions
├── telemetry.ex         # Metrics and instrumentation
├── gettext.ex           # Internationalization helper
└── [channel files]      # WebSocket channels
```

#### `endpoint.ex`

The entry point for all HTTP requests:

```elixir
defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  # Session configuration
  @session_options [
    store: :cookie,
    key: "_my_app_key",
    signing_salt: "abc123",
    same_site: "Lax"
  ]

  # Serve static files
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
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

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

#### `router.ex`

Defines all application routes:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MyAppWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/api", MyAppWeb do
    pipe_through :api
    # API routes
  end
end
```

### `lib/my_app_web.ex` - Web Module

Provides shared imports for controllers, views, and components:

```elixir
defmodule MyAppWeb do
  @moduledoc """
  The entrypoint for defining your web interface.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: MyAppWeb.Layouts]

      import Plug.Conn
      import MyAppWeb.Gettext

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MyAppWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent
      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      import Phoenix.HTML
      import MyAppWeb.CoreComponents
      import MyAppWeb.Gettext
      alias Phoenix.LiveView.JS
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: MyAppWeb.Endpoint,
        router: MyAppWeb.Router,
        statics: MyAppWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
```

## The `config/` Directory

Contains all configuration files:

```
config/
├── config.exs           # Shared configuration
├── dev.exs              # Development configuration
├── test.exs             # Test configuration
├── prod.exs             # Production configuration
└── runtime.exs          # Runtime configuration (env vars)
```

### `config.exs` - Shared Configuration

```elixir
import Config

# General application configuration
config :my_app,
  ecto_repos: [MyApp.Repo],
  generators: [timestamp_type: :utc_datetime]

# Endpoint configuration
config :my_app, MyAppWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MyAppWeb.ErrorHTML, json: MyAppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MyApp.PubSub,
  live_view: [signing_salt: "abc123"]

# Mailer configuration
config :my_app, MyApp.Mailer, adapter: Swoosh.Adapters.Local

# Logger configuration
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# JSON library
config :phoenix, :json_library, Jason

# Import environment-specific config
import_config "#{config_env()}.exs"
```

### `dev.exs` - Development Configuration

```elixir
import Config

# Database configuration
config :my_app, MyApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "my_app_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Development endpoint configuration
config :my_app, MyAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev_secret_key_base...",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:my_app, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:my_app, ~w(--watch)]}
  ]

# Live reload configuration
config :my_app, MyAppWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/my_app_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Development-only settings
config :my_app, dev_routes: true
config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
config :phoenix_live_view, :debug_heex_annotations, true
```

### `runtime.exs` - Runtime Configuration

```elixir
import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "DATABASE_URL environment variable is missing"

  config :my_app, MyApp.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    ssl: true

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE environment variable is missing"

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :my_app, MyAppWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base
end
```

## The `priv/` Directory

Contains private application files that are not compiled:

```
priv/
├── gettext/             # Translation files
│   └── en/
│       └── LC_MESSAGES/
│           └── errors.po
├── repo/
│   ├── migrations/      # Database migrations
│   │   ├── 20240101000000_create_users.exs
│   │   └── 20240102000000_add_email_to_users.exs
│   └── seeds.exs        # Database seed data
└── static/              # Static assets
    ├── assets/          # Compiled assets (generated)
    ├── images/
    ├── favicon.ico
    └── robots.txt
```

### Database Migrations

```elixir
# priv/repo/migrations/20240101000000_create_users.exs
defmodule MyApp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string, null: false
      add :hashed_password, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
  end
end
```

### Database Seeds

```elixir
# priv/repo/seeds.exs
alias MyApp.Repo
alias MyApp.Accounts.User

# Create admin user
Repo.insert!(%User{
  name: "Admin",
  email: "admin@example.com",
  hashed_password: Bcrypt.hash_pwd_salt("password123")
})

# Create sample data
for i <- 1..10 do
  Repo.insert!(%User{
    name: "User #{i}",
    email: "user#{i}@example.com",
    hashed_password: Bcrypt.hash_pwd_salt("password123")
  })
end
```

## The `assets/` Directory

Frontend assets managed by esbuild and Tailwind:

```
assets/
├── css/
│   └── app.css          # Main CSS file (Tailwind)
├── js/
│   └── app.js           # Main JavaScript file
├── vendor/              # Third-party assets
└── tailwind.config.js   # Tailwind configuration
```

### `assets/js/app.js`

```javascript
// Include Phoenix HTML helpers
import "phoenix_html"

// Include Phoenix LiveView
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Connect if there are any LiveViews on the page
liveSocket.connect()

// Expose liveSocket on window for web console debug logs and latency simulation
window.liveSocket = liveSocket
```

### `assets/css/app.css`

```css
@import "tailwindcss/base";
@import "tailwindcss/components";
@import "tailwindcss/utilities";

/* Custom styles */
@layer components {
  .btn-primary {
    @apply bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded;
  }
}
```

## The `test/` Directory

Contains all test files:

```
test/
├── my_app/              # Business logic tests
│   └── accounts_test.exs
├── my_app_web/          # Web layer tests
│   ├── controllers/
│   │   └── page_controller_test.exs
│   └── live/
├── support/             # Test helpers
│   ├── conn_case.ex
│   ├── data_case.ex
│   └── fixtures/
│       └── accounts_fixtures.ex
└── test_helper.exs      # Test configuration
```

### Test Support Files

```elixir
# test/support/conn_case.ex
defmodule MyAppWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint MyAppWeb.Endpoint

      use MyAppWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import MyAppWeb.ConnCase
    end
  end

  setup tags do
    MyApp.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
```

## Root Files

### `mix.exs` - Project Configuration

```elixir
defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_app,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {MyApp.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7.18"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons, "~> 0.5"},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind my_app", "esbuild my_app"],
      "assets.deploy": [
        "tailwind my_app --minify",
        "esbuild my_app --minify",
        "phx.digest"
      ]
    ]
  end
end
```

### `.formatter.exs` - Code Formatter

```elixir
[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
]
```

## Summary

| Directory | Purpose |
|-----------|---------|
| `lib/my_app/` | Business logic, contexts, schemas |
| `lib/my_app_web/` | Web layer, controllers, views |
| `config/` | Environment-specific configuration |
| `priv/repo/` | Database migrations and seeds |
| `priv/static/` | Static assets |
| `assets/` | Frontend source files |
| `test/` | Test files and support |
| `_build/` | Compiled bytecode |
| `deps/` | External dependencies |

Understanding this structure helps you:
- Know where to add new features
- Find existing code quickly
- Maintain proper separation of concerns
- Follow Phoenix conventions
