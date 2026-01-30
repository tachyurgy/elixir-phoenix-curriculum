# Phoenix New - Project Creation

## Introduction

The `mix phx.new` command is your gateway to creating Phoenix applications. This comprehensive guide covers all available options and best practices for starting new Phoenix projects.

## Prerequisites

Before creating a Phoenix project, ensure you have:

```bash
# Check Elixir version (1.14+ recommended)
elixir --version

# Check Phoenix installer
mix phx.new --version

# Install Phoenix if needed
mix archive.install hex phx_new
```

## Basic Project Creation

### Minimal Command

```bash
mix phx.new my_app
```

This creates a full-featured Phoenix application with:
- Ecto for database interactions
- HTML views with Tailwind CSS
- LiveView for real-time features
- Mailer configuration
- Assets pipeline with esbuild

### Project Naming Conventions

```bash
# Snake_case for the project name
mix phx.new my_app           # Creates MyApp module

# With custom module name
mix phx.new my_app --module MyApplication

# With custom app name (OTP application name)
mix phx.new my_app --app my_custom_app
```

## Command Options Reference

### Database Options

```bash
# Default: PostgreSQL
mix phx.new my_app

# Use MySQL
mix phx.new my_app --database mysql

# Use MSSQL
mix phx.new my_app --database mssql

# Use SQLite3 (great for development/small projects)
mix phx.new my_app --database sqlite3

# No database at all
mix phx.new my_app --no-ecto
```

### Web Layer Options

```bash
# Full web application (default)
mix phx.new my_app

# API-only application (no HTML, no assets)
mix phx.new my_app --no-html --no-assets

# Without LiveView
mix phx.new my_app --no-live

# Without Tailwind CSS
mix phx.new my_app --no-tailwind

# Without esbuild (bring your own asset pipeline)
mix phx.new my_app --no-esbuild

# Without mailer
mix phx.new my_app --no-mailer
```

### Umbrella Applications

```bash
# Create an umbrella project
mix phx.new my_app --umbrella

# This creates:
# my_app_umbrella/
#   apps/
#     my_app/          # Business logic
#     my_app_web/      # Phoenix web layer
```

### Installation Options

```bash
# Skip dependency installation
mix phx.new my_app --no-install

# Skip git initialization
mix phx.new my_app --no-git

# Generate in a specific directory
mix phx.new my_app --app my_app /custom/path
```

### Binary ID Options

```bash
# Use UUIDs as primary keys (binary_id)
mix phx.new my_app --binary-id
```

## Common Project Configurations

### Full-Featured Web Application

```bash
# Standard web app with all features
mix phx.new my_app
cd my_app
mix setup  # Creates DB, installs deps, runs migrations
mix phx.server
```

### JSON API Backend

```bash
# API-only Phoenix application
mix phx.new my_api --no-html --no-assets --no-live --no-tailwind --no-esbuild

# Project structure is lighter:
# - No templates
# - No static assets
# - No LiveView
# - JSON-focused responses
```

### Microservice with SQLite

```bash
# Lightweight service with embedded database
mix phx.new my_service --database sqlite3 --no-html --no-assets
```

### LiveView-Focused Application

```bash
# Full LiveView application (default includes LiveView)
mix phx.new my_app

# The generated app includes:
# - LiveView hooks
# - Real-time features
# - Phoenix.LiveDashboard
```

## Post-Creation Steps

### 1. Configure the Database

Edit `config/dev.exs`:

```elixir
config :my_app, MyApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "my_app_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

### 2. Create and Migrate Database

```bash
# Create the database
mix ecto.create

# Run migrations (if any)
mix ecto.migrate

# Or use setup which does all of the above plus deps
mix setup
```

### 3. Start the Server

```bash
# Start in development mode
mix phx.server

# Start with IEx shell
iex -S mix phx.server
```

### 4. Verify Installation

Visit `http://localhost:4000` to see the welcome page.

## Generated Files Overview

After running `mix phx.new my_app`, you get:

```
my_app/
├── _build/              # Compiled files
├── assets/              # Frontend assets (JS, CSS)
├── config/              # Configuration files
├── deps/                # Dependencies
├── lib/
│   ├── my_app/          # Business logic
│   ├── my_app_web/      # Web layer
│   └── my_app.ex        # Main application module
├── priv/
│   ├── repo/            # Database migrations
│   └── static/          # Static files
├── test/                # Test files
├── .formatter.exs       # Code formatter config
├── .gitignore
├── mix.exs              # Project configuration
└── README.md
```

## Generators After Project Creation

Phoenix provides additional generators:

```bash
# Generate a complete HTML resource
mix phx.gen.html Accounts User users name:string email:string

# Generate a JSON API resource
mix phx.gen.json Accounts User users name:string email:string

# Generate a LiveView resource
mix phx.gen.live Accounts User users name:string email:string

# Generate just a context
mix phx.gen.context Accounts User users name:string email:string

# Generate just a schema
mix phx.gen.schema Accounts.User users name:string email:string

# Generate authentication
mix phx.gen.auth Accounts User users

# Generate a channel
mix phx.gen.channel Room

# Generate a presence tracker
mix phx.gen.presence

# Generate a notifier
mix phx.gen.notifier Accounts
```

## Best Practices

### 1. Choose Options Wisely

```bash
# For a typical web app, defaults are excellent
mix phx.new my_app

# For an API, be explicit about what you don't need
mix phx.new my_api --no-html --no-assets --no-live --no-tailwind

# For microservices, consider SQLite
mix phx.new my_service --database sqlite3
```

### 2. Use Binary IDs for Distributed Systems

```bash
# UUIDs prevent ID conflicts in distributed databases
mix phx.new my_distributed_app --binary-id
```

### 3. Consider Umbrella for Large Projects

```bash
# Umbrella projects separate concerns cleanly
mix phx.new my_platform --umbrella
```

### 4. Development Workflow

```bash
# After creating a project
cd my_app

# Install dependencies and create database
mix setup

# Start server with shell access
iex -S mix phx.server

# Run tests
mix test

# Check code formatting
mix format --check-formatted

# Run static analysis
mix credo
```

## Troubleshooting Common Issues

### Database Connection Failed

```bash
# Check PostgreSQL is running
pg_isready

# Verify credentials in config/dev.exs
# Ensure database user has CREATE permission
```

### Port Already in Use

```elixir
# Change port in config/dev.exs
config :my_app, MyAppWeb.Endpoint,
  http: [port: 4001]  # Changed from 4000
```

### Node.js/npm Errors

```bash
# Ensure Node.js is installed (for asset compilation)
node --version

# Phoenix 1.7+ uses esbuild (no Node.js required by default)
# But some assets may still need npm
```

### Dependencies Won't Compile

```bash
# Clean and rebuild
mix deps.clean --all
mix deps.get
mix compile
```

## Summary

The `mix phx.new` command is highly configurable:

| Option | Purpose |
|--------|---------|
| `--no-ecto` | Skip database layer |
| `--no-html` | Skip HTML views |
| `--no-assets` | Skip asset pipeline |
| `--no-live` | Skip LiveView |
| `--no-tailwind` | Skip Tailwind CSS |
| `--no-mailer` | Skip email support |
| `--database` | Choose database adapter |
| `--binary-id` | Use UUIDs as primary keys |
| `--umbrella` | Create umbrella project |
| `--no-install` | Skip mix deps.get |

Choose options based on your project requirements, and remember that you can always add features later through generators and dependencies.
