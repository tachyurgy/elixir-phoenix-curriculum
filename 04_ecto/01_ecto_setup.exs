# ==============================================================================
# ECTO SETUP - MIX PROJECT CONFIGURATION
# ==============================================================================
#
# Ecto is Elixir's database wrapper and query generator. It provides:
# - A standardized way to interact with databases
# - Data validation through changesets
# - Schema definitions for mapping database tables to Elixir structs
# - Query composition with a powerful DSL
# - Database migrations
#
# This lesson covers setting up Ecto in a Mix project from scratch.
#
# ==============================================================================
# TABLE OF CONTENTS
# ==============================================================================
#
# 1. Creating a New Mix Project
# 2. Adding Ecto Dependencies
# 3. Configuring the Repository
# 4. Creating the Repo Module
# 5. Database Configuration
# 6. Running Ecto Tasks
# 7. Exercises
#
# ==============================================================================

# ==============================================================================
# SECTION 1: CREATING A NEW MIX PROJECT
# ==============================================================================
#
# First, create a new Mix project with a supervision tree:
#
#   $ mix new my_app --sup
#
# The --sup flag is important because Ecto requires a supervision tree to
# manage database connection pools.
#
# Project structure after creation:
#
#   my_app/
#   ├── lib/
#   │   ├── my_app.ex
#   │   └── my_app/
#   │       └── application.ex
#   ├── test/
#   │   ├── my_app_test.exs
#   │   └── test_helper.exs
#   ├── mix.exs
#   └── README.md

# ==============================================================================
# SECTION 2: ADDING ECTO DEPENDENCIES
# ==============================================================================
#
# In your mix.exs file, add Ecto and a database adapter to the deps function.
#
# Ecto supports multiple database adapters:
# - ecto_sql + postgrex: PostgreSQL (most common)
# - ecto_sql + myxql: MySQL
# - ecto_sql + tds: Microsoft SQL Server
# - ecto_sqlite3: SQLite
#
# Example mix.exs configuration:

defmodule MixExsExample do
  @moduledoc """
  Example of how mix.exs should be configured for Ecto.
  """

  # This is what your mix.exs should look like:
  def project do
    [
      app: :my_app,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Optional: specify Elixir and OTP versions
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger],
      mod: {MyApp.Application, []}
    ]
  end

  defp deps do
    [
      # Ecto SQL - the main Ecto package for SQL databases
      {:ecto_sql, "~> 3.11"},

      # PostgreSQL adapter (choose one adapter)
      {:postgrex, "~> 0.17"},

      # OR MySQL adapter
      # {:myxql, "~> 0.6"},

      # OR SQLite adapter
      # {:ecto_sqlite3, "~> 0.12"},

      # Optional but recommended for development
      {:jason, "~> 1.4"},  # JSON library often used with Ecto
    ]
  end
end

# After adding dependencies, run:
#   $ mix deps.get

# ==============================================================================
# SECTION 3: CONFIGURING THE REPOSITORY
# ==============================================================================
#
# Ecto uses a "Repo" module as the main entry point for database operations.
# The Repo wraps the database connection and provides functions like:
# - insert, update, delete
# - get, get_by, all
# - transaction
#
# Step 1: Generate the Repo (optional - can be done manually)
#
#   $ mix ecto.gen.repo -r MyApp.Repo
#
# This creates:
# - lib/my_app/repo.ex
# - Updates config/config.exs with database configuration

# ==============================================================================
# SECTION 4: CREATING THE REPO MODULE
# ==============================================================================
#
# The Repo module is typically very simple:

defmodule MyApp.Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres
    # For MySQL:   adapter: Ecto.Adapters.MyXQL
    # For SQLite:  adapter: Ecto.Adapters.SQLite3
end

# The use macro provides all the standard Repo functions.
# You can add custom functions to the Repo if needed:

defmodule MyApp.RepoExtended do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Custom function to count all records for a schema.
  """
  def count(queryable) do
    import Ecto.Query
    aggregate(queryable, :count)
  end

  @doc """
  Soft delete - updates a deleted_at field instead of removing the record.
  """
  def soft_delete(struct) do
    struct
    |> Ecto.Changeset.change(deleted_at: DateTime.utc_now())
    |> update()
  end

  @doc """
  Get a record or raise a custom error.
  """
  def get_or_error(queryable, id) do
    case get(queryable, id) do
      nil -> {:error, :not_found}
      record -> {:ok, record}
    end
  end
end

# ==============================================================================
# SECTION 5: DATABASE CONFIGURATION
# ==============================================================================
#
# Configure your database connection in config/config.exs (or environment-
# specific config files).

# config/config.exs
defmodule ConfigExample do
  @moduledoc """
  Example configuration for Ecto.
  """

  # This goes in config/config.exs:
  def base_config do
    """
    import Config

    config :my_app,
      ecto_repos: [MyApp.Repo]

    # Import environment specific config
    import_config "\#{config_env()}.exs"
    """
  end

  # config/dev.exs - Development configuration
  def dev_config do
    """
    import Config

    config :my_app, MyApp.Repo,
      database: "my_app_dev",
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      port: 5432,
      show_sensitive_data_on_connection_error: true,
      pool_size: 10
    """
  end

  # config/test.exs - Test configuration
  def test_config do
    """
    import Config

    config :my_app, MyApp.Repo,
      database: "my_app_test\#{System.get_env("MIX_TEST_PARTITION")}",
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      port: 5432,
      # Use Sandbox for concurrent testing
      pool: Ecto.Adapters.SQL.Sandbox,
      pool_size: 10
    """
  end

  # config/prod.exs - Production configuration
  def prod_config do
    """
    import Config

    # Use environment variables in production
    config :my_app, MyApp.Repo,
      url: System.get_env("DATABASE_URL"),
      pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
      ssl: true,
      ssl_opts: [verify: :verify_none]
    """
  end

  # config/runtime.exs - Runtime configuration (Elixir 1.11+)
  def runtime_config do
    """
    import Config

    if config_env() == :prod do
      database_url =
        System.get_env("DATABASE_URL") ||
          raise "DATABASE_URL environment variable is missing"

      config :my_app, MyApp.Repo,
        url: database_url,
        pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
    end
    """
  end
end

# ==============================================================================
# SECTION 5.1: ADDING REPO TO APPLICATION SUPERVISION TREE
# ==============================================================================
#
# The Repo must be started as part of your application's supervision tree.

defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      MyApp.Repo,
      # You can also configure the Repo inline:
      # {MyApp.Repo, []},
      # Other children like PubSub, Endpoint, etc.
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# ==============================================================================
# SECTION 6: RUNNING ECTO TASKS
# ==============================================================================
#
# After setup, use these Mix tasks to manage your database:

defmodule EctoTasks do
  @moduledoc """
  Common Ecto Mix tasks and their usage.
  """

  def common_tasks do
    """
    DATABASE MANAGEMENT:
    --------------------
    $ mix ecto.create        # Create the database
    $ mix ecto.drop          # Drop the database
    $ mix ecto.reset         # Drop and recreate the database

    MIGRATIONS:
    --------------------
    $ mix ecto.gen.migration create_users  # Generate a new migration
    $ mix ecto.migrate                     # Run pending migrations
    $ mix ecto.rollback                    # Rollback the last migration
    $ mix ecto.rollback --step 3           # Rollback last 3 migrations
    $ mix ecto.migrations                  # Show migration status

    SEEDS:
    --------------------
    $ mix run priv/repo/seeds.exs          # Run database seeds

    MULTIPLE REPOS:
    --------------------
    If you have multiple repos, specify which one:
    $ mix ecto.create -r MyApp.Repo
    $ mix ecto.migrate -r MyApp.SecondaryRepo
    """
  end
end

# ==============================================================================
# SECTION 6.1: EXAMPLE MIGRATION
# ==============================================================================
#
# After running `mix ecto.gen.migration create_users`, you'll get a file
# in priv/repo/migrations/:

defmodule MyApp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :age, :integer
      add :active, :boolean, default: true

      timestamps()  # Adds inserted_at and updated_at
    end

    # Create an index for faster email lookups
    create unique_index(:users, [:email])
  end
end

# ==============================================================================
# SECTION 7: COMPLETE SETUP CHECKLIST
# ==============================================================================

defmodule SetupChecklist do
  @moduledoc """
  Complete checklist for setting up Ecto in a new project.
  """

  def checklist do
    """
    ECTO SETUP CHECKLIST:
    =====================

    [ ] 1. Create Mix project with --sup flag
        $ mix new my_app --sup

    [ ] 2. Add dependencies to mix.exs
        {:ecto_sql, "~> 3.11"}
        {:postgrex, "~> 0.17"}  # or other adapter

    [ ] 3. Run mix deps.get
        $ mix deps.get

    [ ] 4. Create Repo module at lib/my_app/repo.ex
        defmodule MyApp.Repo do
          use Ecto.Repo,
            otp_app: :my_app,
            adapter: Ecto.Adapters.Postgres
        end

    [ ] 5. Configure ecto_repos in config/config.exs
        config :my_app, ecto_repos: [MyApp.Repo]

    [ ] 6. Add database config to config/dev.exs
        config :my_app, MyApp.Repo,
          database: "my_app_dev",
          username: "postgres",
          password: "postgres",
          hostname: "localhost"

    [ ] 7. Add Repo to application.ex supervision tree
        children = [MyApp.Repo]

    [ ] 8. Create the database
        $ mix ecto.create

    [ ] 9. Generate and run first migration
        $ mix ecto.gen.migration create_users
        $ mix ecto.migrate

    [ ] 10. Verify setup
        $ iex -S mix
        iex> MyApp.Repo.all(MyApp.User)
    """
  end
end

# ==============================================================================
# SECTION 8: TROUBLESHOOTING COMMON ISSUES
# ==============================================================================

defmodule TroubleshootingGuide do
  @moduledoc """
  Common setup issues and their solutions.
  """

  def common_issues do
    """
    ISSUE: "connection refused" error
    SOLUTION: Ensure PostgreSQL is running
              $ brew services start postgresql  # macOS
              $ sudo systemctl start postgresql # Linux

    ISSUE: "role 'postgres' does not exist"
    SOLUTION: Create the postgres user
              $ createuser -s postgres

    ISSUE: "database does not exist"
    SOLUTION: Run mix ecto.create
              $ mix ecto.create

    ISSUE: "Repo is not started"
    SOLUTION: Ensure Repo is in the application supervision tree
              Check lib/my_app/application.ex

    ISSUE: "ecto_repos configuration not found"
    SOLUTION: Add to config/config.exs:
              config :my_app, ecto_repos: [MyApp.Repo]

    ISSUE: "SSL connection error"
    SOLUTION: For local development, add ssl: false to config
              Or configure SSL properly for production

    ISSUE: "migrations table already exists"
    SOLUTION: This is usually fine - it means migrations have been run
              Use mix ecto.reset for a fresh start
    """
  end
end

# ==============================================================================
# EXERCISES
# ==============================================================================

defmodule Exercises do
  @moduledoc """
  Practice exercises for Ecto setup.
  """

  # ---------------------------------------------------------------------------
  # Exercise 1: Project Initialization
  # ---------------------------------------------------------------------------
  # Create a new Mix project called "bookstore" with a supervision tree.
  # Document the command you would use.
  #
  # Answer: mix new bookstore --sup

  # ---------------------------------------------------------------------------
  # Exercise 2: Dependencies Configuration
  # ---------------------------------------------------------------------------
  # Write the deps function for a mix.exs that uses:
  # - Ecto with PostgreSQL
  # - Jason for JSON encoding
  #
  # Fill in the blanks:
  defp exercise_2_deps do
    [
      # Add ecto_sql dependency here
      # {:ecto_sql, ___},
      # Add postgrex dependency here
      # {:postgrex, ___},
      # Add jason dependency here
      # {:jason, ___}
    ]
  end

  # ---------------------------------------------------------------------------
  # Exercise 3: Repository Module
  # ---------------------------------------------------------------------------
  # Create a Repo module for an app called "blog" using MySQL.
  # The module should be Blog.Repo and use the MyXQL adapter.
  #
  # Write your answer below:
  # defmodule Blog.Repo do
  #   ???
  # end

  # ---------------------------------------------------------------------------
  # Exercise 4: Database Configuration
  # ---------------------------------------------------------------------------
  # Write the configuration for a development database with:
  # - Database name: bookstore_dev
  # - Username: dev_user
  # - Password: dev_pass
  # - Host: localhost
  # - Port: 5433 (non-standard)
  # - Pool size: 5
  #
  # Write your config below (as a string):
  def exercise_4_config do
    """
    config :bookstore, Bookstore.Repo,
      # Fill in the configuration options
    """
  end

  # ---------------------------------------------------------------------------
  # Exercise 5: Application Module
  # ---------------------------------------------------------------------------
  # Given the following Application module, add the Repo to the supervision
  # tree. The app also has a PubSub and a custom GenServer called TaskRunner.

  defmodule BookstoreApplication do
    use Application

    @impl true
    def start(_type, _args) do
      children = [
        # Add children in the correct order
        # Hint: Repo should start before components that depend on it
      ]

      opts = [strategy: :one_for_one, name: Bookstore.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end

  # ---------------------------------------------------------------------------
  # Exercise 6: Mix Tasks Sequence
  # ---------------------------------------------------------------------------
  # You've just cloned a project that uses Ecto. What sequence of commands
  # should you run to set up the database? List them in order:
  #
  # 1. ___
  # 2. ___
  # 3. ___
  # 4. ___
  #
  # Hints: get dependencies, create database, run migrations, optionally seed

  # ---------------------------------------------------------------------------
  # EXERCISE SOLUTIONS
  # ---------------------------------------------------------------------------

  def solutions do
    """
    Exercise 2 Solution:
    --------------------
    defp deps do
      [
        {:ecto_sql, "~> 3.11"},
        {:postgrex, "~> 0.17"},
        {:jason, "~> 1.4"}
      ]
    end

    Exercise 3 Solution:
    --------------------
    defmodule Blog.Repo do
      use Ecto.Repo,
        otp_app: :blog,
        adapter: Ecto.Adapters.MyXQL
    end

    Exercise 4 Solution:
    --------------------
    config :bookstore, Bookstore.Repo,
      database: "bookstore_dev",
      username: "dev_user",
      password: "dev_pass",
      hostname: "localhost",
      port: 5433,
      pool_size: 5

    Exercise 5 Solution:
    --------------------
    children = [
      Bookstore.Repo,
      {Phoenix.PubSub, name: Bookstore.PubSub},
      Bookstore.TaskRunner
    ]

    Exercise 6 Solution:
    --------------------
    1. mix deps.get
    2. mix ecto.create
    3. mix ecto.migrate
    4. mix run priv/repo/seeds.exs  (optional, if seeds exist)
    """
  end
end

# ==============================================================================
# KEY TAKEAWAYS
# ==============================================================================
#
# 1. Ecto requires a Mix project with a supervision tree (use --sup flag)
#
# 2. You need two main dependencies:
#    - ecto_sql: The main Ecto package
#    - A database adapter (postgrex, myxql, etc.)
#
# 3. The Repo module is the central point for all database operations
#
# 4. Configuration includes:
#    - ecto_repos in config.exs
#    - Database connection details in environment configs
#    - Adding Repo to the supervision tree
#
# 5. Common Mix tasks:
#    - mix ecto.create - create database
#    - mix ecto.migrate - run migrations
#    - mix ecto.gen.migration - generate new migration
#
# ==============================================================================
# NEXT LESSON: 02_repo_basics.exs - Learn about Repo operations
# ==============================================================================
