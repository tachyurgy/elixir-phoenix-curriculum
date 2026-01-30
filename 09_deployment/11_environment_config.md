# Environment Configuration in Production

Master the art of configuring Elixir applications for different environments. Learn to manage secrets securely, handle environment variables properly, and implement robust configuration strategies for production deployments.

## Learning Objectives

- Understand Elixir's configuration system and compile-time vs runtime config
- Implement secure secrets management
- Use environment variables effectively
- Configure applications for multiple environments
- Implement configuration validation

## Prerequisites

- Section 1-8 completed
- Basic understanding of Mix releases
- Familiarity with environment variables

---

## Understanding Elixir Configuration

### The Configuration System

Elixir uses a layered configuration system that has evolved significantly. Understanding the differences between compile-time and runtime configuration is crucial for production deployments.

```
Configuration Loading Order
===========================

config/config.exs          # Base configuration (compile-time)
       ↓
config/dev.exs             # Environment-specific (compile-time)
config/test.exs
config/prod.exs
       ↓
config/runtime.exs         # Runtime configuration (runtime)
       ↓
Application Start          # Application is ready
```

### Compile-Time vs Runtime Configuration

```elixir
# config/config.exs - Compiled into the release
# These values are FIXED when you build your release

import Config

config :my_app,
  # This is evaluated at COMPILE TIME
  compiled_at: DateTime.utc_now(),
  static_value: "This never changes after build"

# config/runtime.exs - Evaluated when the app STARTS
# These values can differ between deployments

import Config

config :my_app,
  # This is evaluated at RUNTIME
  started_at: DateTime.utc_now(),
  database_url: System.get_env("DATABASE_URL")
```

**Key Difference**: If you build a release on your CI server and deploy it to production, compile-time config reflects the CI environment, while runtime config reflects the production environment.

---

## Runtime Configuration Deep Dive

### Basic runtime.exs Setup

```elixir
# config/runtime.exs
import Config

# Only run this configuration in production releases
if config_env() == :prod do
  # DATABASE CONFIGURATION
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :my_app, MyApp.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6,
    ssl: System.get_env("DATABASE_SSL") == "true",
    ssl_opts: [
      verify: :verify_peer,
      cacerts: :public_key.cacerts_get(),
      server_name_indication: String.to_charlist(System.get_env("DATABASE_HOST") || "localhost"),
      customize_hostname_check: [
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      ]
    ]

  # PHOENIX ENDPOINT CONFIGURATION
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :my_app, MyAppWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # MAILER CONFIGURATION
  config :my_app, MyApp.Mailer,
    adapter: Swoosh.Adapters.Mailgun,
    api_key: System.get_env("MAILGUN_API_KEY"),
    domain: System.get_env("MAILGUN_DOMAIN")
end
```

### Environment Variable Parsing Helpers

```elixir
# lib/my_app/config_helpers.ex
defmodule MyApp.ConfigHelpers do
  @moduledoc """
  Helper functions for parsing environment variables.
  """

  @doc """
  Gets an environment variable or raises if missing.
  """
  def get_env!(key) do
    System.get_env(key) ||
      raise ArgumentError, "environment variable #{key} is not set"
  end

  @doc """
  Gets an environment variable with a default value.
  """
  def get_env(key, default \\ nil) do
    System.get_env(key) || default
  end

  @doc """
  Parses an integer from environment variable.
  """
  def get_env_integer(key, default) do
    case System.get_env(key) do
      nil -> default
      val -> String.to_integer(val)
    end
  end

  @doc """
  Parses a boolean from environment variable.
  Accepts: "true", "1", "yes" as truthy values.
  """
  def get_env_boolean(key, default \\ false) do
    case System.get_env(key) do
      nil -> default
      val -> val in ~w(true 1 yes TRUE YES)
    end
  end

  @doc """
  Parses a comma-separated list from environment variable.
  """
  def get_env_list(key, default \\ []) do
    case System.get_env(key) do
      nil -> default
      "" -> default
      val -> String.split(val, ",", trim: true) |> Enum.map(&String.trim/1)
    end
  end

  @doc """
  Parses a URL and extracts components.
  """
  def parse_database_url(url) do
    uri = URI.parse(url)

    %{
      hostname: uri.host,
      port: uri.port || 5432,
      username: uri.userinfo && String.split(uri.userinfo, ":") |> List.first(),
      password: uri.userinfo && String.split(uri.userinfo, ":") |> List.last(),
      database: uri.path && String.trim_leading(uri.path, "/")
    }
  end
end
```

### Using Config Helpers in runtime.exs

```elixir
# config/runtime.exs
import Config
import MyApp.ConfigHelpers

if config_env() == :prod do
  config :my_app, MyApp.Repo,
    url: get_env!("DATABASE_URL"),
    pool_size: get_env_integer("POOL_SIZE", 10),
    ssl: get_env_boolean("DATABASE_SSL", true),
    timeout: get_env_integer("DATABASE_TIMEOUT", 15_000)

  config :my_app, :features,
    enable_analytics: get_env_boolean("ENABLE_ANALYTICS", false),
    allowed_origins: get_env_list("CORS_ORIGINS", ["https://example.com"]),
    max_upload_size: get_env_integer("MAX_UPLOAD_SIZE", 10_485_760)
end
```

---

## Secrets Management

### Understanding Secrets vs Configuration

```
┌─────────────────────────────────────────────────────────────────┐
│                 Configuration Categories                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  PUBLIC CONFIG              │  SECRETS                          │
│  (Can be in code)           │  (Never in code)                  │
│                             │                                    │
│  - Log levels               │  - Database passwords             │
│  - Feature flags            │  - API keys                       │
│  - Timeouts                 │  - Secret key base                │
│  - Pool sizes               │  - Encryption keys                │
│  - Public URLs              │  - OAuth secrets                  │
│  - Rate limits              │  - Payment credentials            │
│                             │                                    │
│  ✓ Git-safe                 │  ✗ Never commit                   │
│  ✓ Code review              │  ✓ Rotate regularly               │
│                             │  ✓ Audit access                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Secrets Management Options

#### Option 1: Environment Variables (Simple)

```bash
# .env file (NEVER commit this)
export DATABASE_URL="ecto://user:password@localhost/myapp_prod"
export SECRET_KEY_BASE="super-secret-key-here..."
export MAILGUN_API_KEY="key-xxxxx"

# Load in your shell
source .env

# Or use a tool like direnv
# .envrc
dotenv
```

```elixir
# config/runtime.exs
config :my_app, MyApp.Repo,
  url: System.get_env("DATABASE_URL")
```

#### Option 2: Encrypted Secrets File

```elixir
# Generate a master key (store this securely, NOT in git)
# mix phx.gen.secret > config/master.key

# config/credentials.enc (encrypted, can be in git)
# Decrypt using the master key

defmodule MyApp.Credentials do
  @master_key_path "config/master.key"
  @credentials_path "config/credentials.enc"

  def get(key) do
    credentials()[key]
  end

  defp credentials do
    master_key = File.read!(@master_key_path) |> String.trim()
    encrypted = File.read!(@credentials_path)

    # Decrypt using AES-256-GCM
    <<iv::binary-16, tag::binary-16, ciphertext::binary>> =
      Base.decode64!(encrypted)

    key = :crypto.hash(:sha256, master_key)

    :crypto.crypto_one_time_aead(
      :aes_256_gcm,
      key,
      iv,
      ciphertext,
      "",
      tag,
      false
    )
    |> Jason.decode!(keys: :atoms)
  end
end
```

#### Option 3: HashiCorp Vault Integration

```elixir
# mix.exs
defp deps do
  [
    {:vaultex, "~> 1.0"}
  ]
end

# lib/my_app/vault.ex
defmodule MyApp.Vault do
  use Vaultex.Client,
    vault_addr: System.get_env("VAULT_ADDR"),
    auth_method: :kubernetes,
    auth_path: "auth/kubernetes/login"

  def get_database_credentials do
    {:ok, %{"data" => data}} = read("secret/data/myapp/database")
    data
  end

  def get_api_key(service) do
    {:ok, %{"data" => %{"api_key" => key}}} =
      read("secret/data/myapp/#{service}")
    key
  end
end

# config/runtime.exs
if config_env() == :prod do
  # Start Vault client early
  {:ok, _} = Application.ensure_all_started(:vaultex)

  db_creds = MyApp.Vault.get_database_credentials()

  config :my_app, MyApp.Repo,
    hostname: db_creds["hostname"],
    username: db_creds["username"],
    password: db_creds["password"],
    database: db_creds["database"]
end
```

#### Option 4: AWS Secrets Manager

```elixir
# mix.exs
defp deps do
  [
    {:ex_aws, "~> 2.4"},
    {:ex_aws_secrets_manager, "~> 2.0"},
    {:hackney, "~> 1.18"},
    {:jason, "~> 1.4"}
  ]
end

# lib/my_app/secrets.ex
defmodule MyApp.Secrets do
  @moduledoc """
  Fetches secrets from AWS Secrets Manager.
  """

  def get_secret(secret_name) do
    {:ok, %{"SecretString" => secret_string}} =
      ExAws.SecretsManager.get_secret_value(secret_name)
      |> ExAws.request()

    Jason.decode!(secret_string)
  end

  def get_database_url do
    secrets = get_secret("myapp/production/database")

    "ecto://#{secrets["username"]}:#{secrets["password"]}" <>
    "@#{secrets["host"]}:#{secrets["port"]}/#{secrets["database"]}"
  end
end

# config/runtime.exs
if config_env() == :prod do
  config :my_app, MyApp.Repo,
    url: MyApp.Secrets.get_database_url(),
    pool_size: 10
end
```

#### Option 5: Google Cloud Secret Manager

```elixir
# mix.exs
defp deps do
  [
    {:goth, "~> 1.4"},
    {:google_api_secret_manager, "~> 0.18"}
  ]
end

# lib/my_app/gcp_secrets.ex
defmodule MyApp.GCPSecrets do
  @project_id System.get_env("GCP_PROJECT_ID")

  def get_secret(name, version \\ "latest") do
    {:ok, token} = Goth.fetch(MyApp.Goth)

    conn = GoogleApi.SecretManager.V1.Connection.new(token.token)

    secret_path = "projects/#{@project_id}/secrets/#{name}/versions/#{version}"

    {:ok, %{payload: %{data: data}}} =
      GoogleApi.SecretManager.V1.Api.Projects.secretmanager_projects_secrets_versions_access(
        conn,
        secret_path
      )

    Base.decode64!(data)
  end
end
```

---

## Configuration Validation

### Validating at Startup

```elixir
# lib/my_app/config_validator.ex
defmodule MyApp.ConfigValidator do
  @moduledoc """
  Validates application configuration at startup.
  Fails fast if required configuration is missing or invalid.
  """

  require Logger

  @required_configs [
    {:my_app, MyApp.Repo, :url},
    {:my_app, MyAppWeb.Endpoint, :secret_key_base},
    {:my_app, MyApp.Mailer, :api_key}
  ]

  def validate! do
    errors =
      @required_configs
      |> Enum.map(&validate_config/1)
      |> Enum.reject(&is_nil/1)

    if errors != [] do
      error_message = """

      ========================================
      CONFIGURATION ERRORS DETECTED
      ========================================
      #{Enum.join(errors, "\n")}
      ========================================

      Please set the required environment variables and restart.
      """

      Logger.error(error_message)
      raise RuntimeError, error_message
    end

    Logger.info("Configuration validation passed")
    :ok
  end

  defp validate_config({app, module, key}) do
    case Application.get_env(app, module) do
      nil ->
        "Missing configuration for #{inspect(module)}"
      config when is_list(config) ->
        case Keyword.get(config, key) do
          nil -> "Missing #{key} in #{inspect(module)} configuration"
          "" -> "Empty #{key} in #{inspect(module)} configuration"
          _ -> nil
        end
      _ ->
        nil
    end
  end
end

# lib/my_app/application.ex
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    # Validate configuration before starting anything
    MyApp.ConfigValidator.validate!()

    children = [
      MyApp.Repo,
      MyAppWeb.Endpoint,
      # ... other children
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### Schema-Based Validation with NimbleOptions

```elixir
# mix.exs
defp deps do
  [
    {:nimble_options, "~> 1.0"}
  ]
end

# lib/my_app/config.ex
defmodule MyApp.Config do
  @moduledoc """
  Centralized configuration with validation.
  """

  @schema [
    database: [
      type: :keyword_list,
      required: true,
      keys: [
        url: [type: :string, required: true],
        pool_size: [type: :pos_integer, default: 10],
        ssl: [type: :boolean, default: false],
        timeout: [type: :pos_integer, default: 15_000]
      ]
    ],
    endpoint: [
      type: :keyword_list,
      required: true,
      keys: [
        host: [type: :string, required: true],
        port: [type: :pos_integer, required: true],
        secret_key_base: [type: :string, required: true]
      ]
    ],
    features: [
      type: :keyword_list,
      default: [],
      keys: [
        enable_signup: [type: :boolean, default: true],
        max_upload_size: [type: :pos_integer, default: 10_485_760],
        rate_limit: [type: :pos_integer, default: 100]
      ]
    ]
  ]

  def validate!(config) do
    case NimbleOptions.validate(config, @schema) do
      {:ok, validated} -> validated
      {:error, %NimbleOptions.ValidationError{} = error} ->
        raise ArgumentError, Exception.message(error)
    end
  end

  def build_from_env do
    config = [
      database: [
        url: System.get_env("DATABASE_URL"),
        pool_size: parse_int(System.get_env("POOL_SIZE"), 10),
        ssl: System.get_env("DATABASE_SSL") == "true",
        timeout: parse_int(System.get_env("DATABASE_TIMEOUT"), 15_000)
      ],
      endpoint: [
        host: System.get_env("PHX_HOST"),
        port: parse_int(System.get_env("PORT"), 4000),
        secret_key_base: System.get_env("SECRET_KEY_BASE")
      ],
      features: [
        enable_signup: System.get_env("ENABLE_SIGNUP") != "false",
        max_upload_size: parse_int(System.get_env("MAX_UPLOAD_SIZE"), 10_485_760),
        rate_limit: parse_int(System.get_env("RATE_LIMIT"), 100)
      ]
    ]

    validate!(config)
  end

  defp parse_int(nil, default), do: default
  defp parse_int(val, _default), do: String.to_integer(val)
end
```

---

## Multi-Environment Configuration

### Environment-Specific Config Files

```elixir
# config/config.exs
import Config

# Common configuration for all environments
config :my_app,
  ecto_repos: [MyApp.Repo],
  generators: [timestamp_type: :utc_datetime]

config :my_app, MyAppWeb.Endpoint,
  render_errors: [
    formats: [html: MyAppWeb.ErrorHTML, json: MyAppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MyApp.PubSub,
  live_view: [signing_salt: "something_random"]

# Import environment specific config
import_config "#{config_env()}.exs"

# config/dev.exs
import Config

config :my_app, MyApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "my_app_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :my_app, MyAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev-secret-key-not-for-production...",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:my_app, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:my_app, ~w(--watch)]}
  ]

config :my_app, dev_routes: true

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

# config/test.exs
import Config

config :my_app, MyApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "my_app_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :my_app, MyAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-secret-key-not-for-production...",
  server: false

config :my_app, MyApp.Mailer, adapter: Swoosh.Adapters.Test

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime

# config/prod.exs
import Config

# Compile-time production config (minimal - most goes in runtime.exs)
config :my_app, MyAppWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :my_app, MyApp.Mailer,
  adapter: Swoosh.Adapters.Mailgun

config :logger, level: :info

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id, :trace_id]
```

### Feature Flags with Environment Variables

```elixir
# lib/my_app/features.ex
defmodule MyApp.Features do
  @moduledoc """
  Feature flag management based on environment configuration.
  """

  def enabled?(feature) do
    features = Application.get_env(:my_app, :features, [])
    Keyword.get(features, feature, false)
  end

  def all_enabled do
    Application.get_env(:my_app, :features, [])
    |> Enum.filter(fn {_key, value} -> value == true end)
    |> Keyword.keys()
  end
end

# config/runtime.exs
config :my_app, :features,
  new_checkout: System.get_env("FEATURE_NEW_CHECKOUT") == "true",
  beta_dashboard: System.get_env("FEATURE_BETA_DASHBOARD") == "true",
  ai_recommendations: System.get_env("FEATURE_AI_RECOMMENDATIONS") == "true",
  dark_mode: System.get_env("FEATURE_DARK_MODE") == "true"

# Usage in code
if MyApp.Features.enabled?(:new_checkout) do
  # New checkout flow
else
  # Legacy checkout
end
```

---

## Release Configuration

### rel/env.sh.eex for Release Environment

```bash
#!/bin/sh
# rel/env.sh.eex
# This script is evaluated at RUNTIME before the release starts

# Set release-specific environment
export RELEASE_DISTRIBUTION="${RELEASE_DISTRIBUTION:-name}"
export RELEASE_NODE="${RELEASE_NODE:-<%= @release.name %>@127.0.0.1}"

# Memory settings
export ERL_MAX_PORTS="${ERL_MAX_PORTS:-65536}"

# Set Erlang heart to restart the VM if it becomes unresponsive
export HEART_COMMAND="${RELEASE_ROOT}/bin/${RELEASE_NAME} start"
export HEART_BEAT_TIMEOUT="${HEART_BEAT_TIMEOUT:-60}"

# Enable heart (auto-restart on crash)
export ELIXIR_ERL_OPTIONS="${ELIXIR_ERL_OPTIONS:--heart}"

# Set timezone
export TZ="${TZ:-UTC}"

# If we're in a container, use the container hostname
if [ -f /.dockerenv ]; then
  export RELEASE_NODE="${RELEASE_NAME}@$(hostname -f)"
fi
```

### rel/vm.args.eex for BEAM VM Arguments

```
## rel/vm.args.eex
## VM configuration for production

## Name of the node (use -name for distributed Erlang)
-name <%= @release.name %>@127.0.0.1

## Cookie for distributed erlang
-setcookie <%= @release.cookie %>

## Enable kernel poll for improved I/O scalability
+K true

## Enable SMP auto-detect
-smp auto

## Increase number of concurrent ports/sockets
+Q 65536

## Set the maximum number of simultaneously existing processes
+P 1000000

## Set the maximum number of atoms
+t 1048576

## Set the maximum number of ETS tables
+e 65536

## Increase the default stack size (512KB)
+sssdio 512

## Enable busy waiting on schedulers (good for high-load systems)
## Comment out if running on shared infrastructure
#+sbwt very_long
#+sbwtdcpu very_long
#+sbwtdio very_long

## Garbage collection settings
## Use generational GC with fullsweep after 20 minor collections
-env ERL_FULLSWEEP_AFTER 20

## Crash dump location
-env ERL_CRASH_DUMP_SECONDS 10
-env ERL_CRASH_DUMP /tmp/erl_crash_<%= @release.name %>.dump
```

---

## Configuration Best Practices

### 1. Fail Fast on Missing Config

```elixir
# BAD: Silent failure with default
database_url = System.get_env("DATABASE_URL") || "ecto://localhost/myapp"

# GOOD: Explicit failure
database_url =
  System.get_env("DATABASE_URL") ||
    raise "DATABASE_URL environment variable is not set"
```

### 2. Document All Environment Variables

```elixir
# config/runtime.exs

# DATABASE_URL (required)
# Format: ecto://USER:PASS@HOST:PORT/DATABASE
# Example: ecto://myapp:secret@db.example.com:5432/myapp_prod
database_url = System.get_env("DATABASE_URL") || raise "..."

# POOL_SIZE (optional, default: 10)
# Number of database connections in the pool
# Recommended: (2 * CPU_CORES) + spindles
pool_size = String.to_integer(System.get_env("POOL_SIZE") || "10")
```

### 3. Use Consistent Naming Conventions

```bash
# Prefix with APP name for custom configs
MYAPP_FEATURE_NEW_CHECKOUT=true
MYAPP_MAX_UPLOAD_SIZE=10485760

# Standard names for common configs
DATABASE_URL=...
SECRET_KEY_BASE=...
PORT=4000
PHX_HOST=example.com

# Service-specific prefixes
MAILGUN_API_KEY=...
STRIPE_SECRET_KEY=...
AWS_ACCESS_KEY_ID=...
```

### 4. Separate Sensitive and Non-Sensitive Config

```elixir
# config/prod.exs - Non-sensitive, can be in git
config :my_app,
  cache_ttl: :timer.hours(1),
  max_connections: 100,
  enable_compression: true

# config/runtime.exs - Sensitive, from environment
config :my_app,
  api_secret: System.get_env("API_SECRET"),
  database_url: System.get_env("DATABASE_URL")
```

### 5. Configuration Testing

```elixir
# test/my_app/config_test.exs
defmodule MyApp.ConfigTest do
  use ExUnit.Case, async: true

  describe "ConfigHelpers" do
    test "get_env_integer/2 parses valid integers" do
      System.put_env("TEST_INT", "42")
      assert MyApp.ConfigHelpers.get_env_integer("TEST_INT", 0) == 42
    after
      System.delete_env("TEST_INT")
    end

    test "get_env_integer/2 returns default for missing env" do
      assert MyApp.ConfigHelpers.get_env_integer("MISSING_VAR", 99) == 99
    end

    test "get_env_boolean/2 handles truthy values" do
      for value <- ~w(true 1 yes TRUE YES) do
        System.put_env("TEST_BOOL", value)
        assert MyApp.ConfigHelpers.get_env_boolean("TEST_BOOL") == true
      end
    after
      System.delete_env("TEST_BOOL")
    end

    test "get_env_list/2 parses comma-separated values" do
      System.put_env("TEST_LIST", "a, b, c")
      assert MyApp.ConfigHelpers.get_env_list("TEST_LIST") == ["a", "b", "c"]
    after
      System.delete_env("TEST_LIST")
    end
  end
end
```

---

## Common Patterns

### Config Provider for External Sources

```elixir
# lib/my_app/config_provider.ex
defmodule MyApp.ConfigProvider do
  @moduledoc """
  Custom config provider that loads configuration from external sources.
  """
  @behaviour Config.Provider

  @impl true
  def init(opts), do: opts

  @impl true
  def load(config, opts) do
    {:ok, _} = Application.ensure_all_started(:hackney)
    {:ok, _} = Application.ensure_all_started(:jason)

    source = Keyword.fetch!(opts, :source)

    external_config =
      case source do
        {:consul, path} -> load_from_consul(path)
        {:s3, bucket, key} -> load_from_s3(bucket, key)
        {:http, url} -> load_from_http(url)
      end

    Config.Reader.merge(config, external_config)
  end

  defp load_from_consul(path) do
    # Implementation for Consul KV store
  end

  defp load_from_s3(bucket, key) do
    # Implementation for S3
  end

  defp load_from_http(url) do
    {:ok, 200, _headers, body_ref} = :hackney.get(url, [], "", [])
    {:ok, body} = :hackney.body(body_ref)

    body
    |> Jason.decode!()
    |> transform_to_config()
  end

  defp transform_to_config(json) do
    [
      my_app: [
        feature_flags: json["features"],
        limits: json["limits"]
      ]
    ]
  end
end

# rel/releases.exs or mix.exs
releases: [
  my_app: [
    config_providers: [
      {MyApp.ConfigProvider, source: {:http, "https://config.example.com/myapp"}}
    ]
  ]
]
```

### Dynamic Configuration at Runtime

```elixir
# lib/my_app/dynamic_config.ex
defmodule MyApp.DynamicConfig do
  @moduledoc """
  GenServer for managing configuration that can change at runtime.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get(key, default \\ nil) do
    GenServer.call(__MODULE__, {:get, key, default})
  end

  def set(key, value) do
    GenServer.call(__MODULE__, {:set, key, value})
  end

  def reload do
    GenServer.call(__MODULE__, :reload)
  end

  @impl true
  def init(_opts) do
    {:ok, load_config()}
  end

  @impl true
  def handle_call({:get, key, default}, _from, config) do
    {:reply, Map.get(config, key, default), config}
  end

  @impl true
  def handle_call({:set, key, value}, _from, config) do
    new_config = Map.put(config, key, value)
    {:reply, :ok, new_config}
  end

  @impl true
  def handle_call(:reload, _from, _config) do
    {:reply, :ok, load_config()}
  end

  defp load_config do
    # Load from environment, file, or external source
    %{
      rate_limit: get_env_int("RATE_LIMIT", 100),
      feature_enabled: get_env_bool("FEATURE_ENABLED", false)
    }
  end

  defp get_env_int(key, default) do
    case System.get_env(key) do
      nil -> default
      val -> String.to_integer(val)
    end
  end

  defp get_env_bool(key, default) do
    case System.get_env(key) do
      nil -> default
      val -> val in ~w(true 1 yes)
    end
  end
end
```

---

## Exercises

### Exercise 1: Configuration Validator

**Difficulty**: Medium

Create a comprehensive configuration validator that:
1. Validates all required environment variables
2. Checks format of URLs, email addresses, etc.
3. Provides helpful error messages
4. Logs warnings for deprecated config

### Exercise 2: Secrets Rotation

**Difficulty**: Hard

Implement a secrets rotation system that:
1. Fetches secrets from AWS Secrets Manager or Vault
2. Caches secrets with TTL
3. Automatically refreshes before expiration
4. Handles rotation gracefully without downtime

### Exercise 3: Multi-Tenant Configuration

**Difficulty**: Hard

Build a configuration system for a multi-tenant application where:
1. Each tenant can have custom configuration
2. Configuration is loaded from a database
3. Changes take effect without restart
4. Default values cascade properly

---

## Summary

### Key Takeaways

1. **Compile-time vs Runtime**: Use `config/runtime.exs` for anything that varies between deployments
2. **Fail Fast**: Validate configuration at startup and provide clear error messages
3. **Never Commit Secrets**: Use environment variables or a secrets manager
4. **Document Everything**: Every environment variable should be documented
5. **Validate Configuration**: Use schema validation for complex configurations
6. **Test Your Config**: Write tests for configuration parsing logic

### Configuration Checklist

- [ ] All secrets are in environment variables (not in code)
- [ ] `runtime.exs` used for deployment-specific config
- [ ] Required config validated at startup
- [ ] Environment variables documented
- [ ] Config helpers tested
- [ ] Sensitive values not logged
- [ ] Defaults are sensible and documented

---

## Next Steps

Continue to [12_logging.md](12_logging.md) to learn about structured logging in production environments.
