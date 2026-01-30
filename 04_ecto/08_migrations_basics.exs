# ============================================================================
# Lesson 08: Migrations Basics
# ============================================================================
#
# Migrations are version-controlled changes to your database schema. They
# allow you to evolve your database structure over time in a consistent
# and reproducible way across all environments.
#
# Learning Objectives:
# - Generate migrations using mix ecto.gen.migration
# - Create tables with various column types
# - Add and remove columns from existing tables
# - Understand migration versioning and running migrations
# - Write reversible migrations
#
# Prerequisites:
# - Ecto repository configured
# - Basic understanding of database schemas
#
# ============================================================================

IO.puts("=" |> String.duplicate(70))
IO.puts("Lesson 08: Migrations Basics")
IO.puts("=" |> String.duplicate(70))

# -----------------------------------------------------------------------------
# Section 1: What Are Migrations?
# -----------------------------------------------------------------------------
#
# Migrations are Elixir modules that define changes to your database.
# Each migration has a timestamp that determines the order of execution.
# Migrations can be run forward (up) or rolled back (down).
#
# Key benefits:
# - Version control for database schema
# - Reproducible across environments
# - Team collaboration on schema changes
# - Easy rollback of changes
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 1: What Are Migrations? ---\n")

IO.puts("""
Migrations are generated with:

    mix ecto.gen.migration create_users

This creates a file like:
    priv/repo/migrations/20240115120000_create_users.exs

The timestamp (20240115120000) ensures migrations run in order.
""")

# Example migration structure (this is documentation, not executable)
migration_example = """
defmodule MyApp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    # Migration code goes here
  end
end
"""

IO.puts("Basic migration structure:")
IO.puts(migration_example)

# -----------------------------------------------------------------------------
# Section 2: Creating Tables
# -----------------------------------------------------------------------------
#
# The create table/2 macro defines a new database table.
# Inside the block, you define columns using various type functions.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 2: Creating Tables ---\n")

create_table_example = """
defmodule MyApp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :name, :string
      add :age, :integer
      add :is_active, :boolean, default: true
      add :bio, :text
      add :balance, :decimal, precision: 10, scale: 2

      timestamps()  # Adds inserted_at and updated_at
    end
  end
end
"""

IO.puts("Creating a users table:")
IO.puts(create_table_example)

IO.puts("""
Common column types:
  :string     - VARCHAR (default 255 chars)
  :text       - TEXT (unlimited length)
  :integer    - INTEGER
  :bigint     - BIGINT (for large numbers)
  :float      - FLOAT
  :decimal    - DECIMAL (precise, for money)
  :boolean    - BOOLEAN
  :date       - DATE
  :time       - TIME
  :naive_datetime - TIMESTAMP without timezone
  :utc_datetime   - TIMESTAMP with timezone
  :uuid       - UUID
  :binary     - BLOB/BYTEA
  :map        - JSONB (PostgreSQL)
  {:array, :string} - Array of strings
""")

# -----------------------------------------------------------------------------
# Section 3: Column Options
# -----------------------------------------------------------------------------
#
# Columns can have various options that define constraints and defaults.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 3: Column Options ---\n")

column_options_example = """
defmodule MyApp.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      # Required field (NOT NULL constraint)
      add :name, :string, null: false

      # Default value
      add :status, :string, default: "draft"

      # Size limit for strings
      add :sku, :string, size: 50

      # Decimal with precision
      add :price, :decimal, precision: 10, scale: 2

      # Array type (PostgreSQL)
      add :tags, {:array, :string}, default: []

      # Map/JSON type
      add :metadata, :map, default: %{}

      timestamps()
    end
  end
end
"""

IO.puts("Column options example:")
IO.puts(column_options_example)

IO.puts("""
Available column options:
  null: false     - NOT NULL constraint
  default: value  - Default value
  size: 50        - Maximum size for strings
  precision: 10   - Total digits for decimal
  scale: 2        - Digits after decimal point
  primary_key: true - Mark as primary key
""")

# -----------------------------------------------------------------------------
# Section 4: Table Options
# -----------------------------------------------------------------------------
#
# The table itself can have options like custom primary keys or prefixes.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 4: Table Options ---\n")

table_options_example = """
# Using UUID as primary key
defmodule MyApp.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string

      timestamps()
    end
  end
end

# Table without primary key (for join tables)
defmodule MyApp.Repo.Migrations.CreateUserRoles do
  use Ecto.Migration

  def change do
    create table(:user_roles, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :role_id, references(:roles, on_delete: :delete_all)

      timestamps()
    end
  end
end

# Using a prefix (PostgreSQL schemas)
defmodule MyApp.Repo.Migrations.CreateTenantUsers do
  use Ecto.Migration

  def change do
    create table(:users, prefix: "tenant_123") do
      add :email, :string

      timestamps()
    end
  end
end
"""

IO.puts("Table options examples:")
IO.puts(table_options_example)

# -----------------------------------------------------------------------------
# Section 5: Adding Columns to Existing Tables
# -----------------------------------------------------------------------------
#
# Use alter table/2 to modify existing tables.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 5: Adding Columns to Existing Tables ---\n")

alter_table_example = """
defmodule MyApp.Repo.Migrations.AddPhoneToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :phone, :string
      add :verified_at, :utc_datetime
      add :settings, :map, default: %{}
    end
  end
end
"""

IO.puts("Adding columns:")
IO.puts(alter_table_example)

# Adding column with default for existing rows
add_with_default = """
defmodule MyApp.Repo.Migrations.AddStatusToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      # This will set "pending" for all existing rows
      add :status, :string, default: "pending", null: false
    end
  end
end
"""

IO.puts("Adding column with default value:")
IO.puts(add_with_default)

# -----------------------------------------------------------------------------
# Section 6: Removing Columns
# -----------------------------------------------------------------------------
#
# Use remove/1 or remove/2 to delete columns. For reversible migrations,
# you need to specify the column type.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 6: Removing Columns ---\n")

remove_column_example = """
# Simple remove (not reversible)
defmodule MyApp.Repo.Migrations.RemoveBioFromUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :bio
    end
  end
end

# Reversible remove (specify type for rollback)
defmodule MyApp.Repo.Migrations.RemovePhoneFromUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :phone, :string  # Type needed for rollback
    end
  end
end

# Remove with all options for full reversibility
defmodule MyApp.Repo.Migrations.RemoveStatusFromProducts do
  use Ecto.Migration

  def change do
    alter table(:products) do
      remove :status, :string, default: "active", null: false
    end
  end
end
"""

IO.puts("Removing columns:")
IO.puts(remove_column_example)

# -----------------------------------------------------------------------------
# Section 7: Modifying Columns
# -----------------------------------------------------------------------------
#
# Use modify/3 to change column properties.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 7: Modifying Columns ---\n")

modify_column_example = """
defmodule MyApp.Repo.Migrations.ModifyUsersEmail do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # Change column type or constraints
      modify :email, :string, null: false, from: :string

      # Change string size
      modify :name, :string, size: 100, from: {:string, size: 50}

      # Change to different type
      modify :age, :integer, from: :string
    end
  end
end
"""

IO.puts("Modifying columns:")
IO.puts(modify_column_example)

IO.puts("""
Note: The 'from:' option makes modify reversible.
Without it, Ecto won't know the original state for rollback.
""")

# -----------------------------------------------------------------------------
# Section 8: Renaming Tables and Columns
# -----------------------------------------------------------------------------
#
# Use rename/2 and rename/3 for renaming operations.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 8: Renaming Tables and Columns ---\n")

rename_example = """
defmodule MyApp.Repo.Migrations.RenameUsersTable do
  use Ecto.Migration

  def change do
    # Rename a table
    rename table(:users), to: table(:accounts)
  end
end

defmodule MyApp.Repo.Migrations.RenameUserColumns do
  use Ecto.Migration

  def change do
    # Rename a column
    rename table(:users), :name, to: :full_name
    rename table(:users), :email, to: :email_address
  end
end
"""

IO.puts("Renaming tables and columns:")
IO.puts(rename_example)

# -----------------------------------------------------------------------------
# Section 9: Up and Down vs Change
# -----------------------------------------------------------------------------
#
# While change/0 auto-generates rollback for most operations,
# some operations require explicit up/0 and down/0 functions.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 9: Up and Down vs Change ---\n")

up_down_example = """
# Using change (auto-reversible)
defmodule MyApp.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string
      timestamps()
    end
  end
end

# Using up/down (explicit control)
defmodule MyApp.Repo.Migrations.AddIndexToPosts do
  use Ecto.Migration

  def up do
    # Run when migrating
    execute "CREATE INDEX CONCURRENTLY posts_title_idx ON posts (title)"
  end

  def down do
    # Run when rolling back
    execute "DROP INDEX posts_title_idx"
  end
end

# Mixing change with up/down
defmodule MyApp.Repo.Migrations.ComplexMigration do
  use Ecto.Migration

  def up do
    create table(:logs) do
      add :message, :text
      timestamps()
    end

    execute "INSERT INTO logs (message, inserted_at, updated_at)
             VALUES ('Migration complete', NOW(), NOW())"
  end

  def down do
    drop table(:logs)
  end
end
"""

IO.puts("Using up/down functions:")
IO.puts(up_down_example)

# -----------------------------------------------------------------------------
# Section 10: Running Migrations
# -----------------------------------------------------------------------------
#
# Ecto provides mix tasks to run and manage migrations.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 10: Running Migrations ---\n")

IO.puts("""
Common migration commands:

  # Run all pending migrations
  mix ecto.migrate

  # Rollback the last migration
  mix ecto.rollback

  # Rollback multiple migrations
  mix ecto.rollback --step 3

  # Rollback to a specific version
  mix ecto.rollback --to 20240115120000

  # Check migration status
  mix ecto.migrations

  # Create the database
  mix ecto.create

  # Drop the database
  mix ecto.drop

  # Reset database (drop, create, migrate)
  mix ecto.reset

  # Run migrations for specific repo
  mix ecto.migrate --repo MyApp.Repo

  # Run in a specific environment
  MIX_ENV=prod mix ecto.migrate
""")

# -----------------------------------------------------------------------------
# Section 11: Migration Best Practices
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 11: Migration Best Practices ---\n")

IO.puts("""
Migration Best Practices:

1. Keep migrations small and focused
   - One logical change per migration
   - Easier to debug and rollback

2. Always test rollback
   - Run: mix ecto.rollback
   - Then: mix ecto.migrate
   - Ensure both directions work

3. Make migrations reversible when possible
   - Use remove/2 with type for columns
   - Use modify/3 with from: option
   - Avoid raw SQL in change/0

4. Never modify old migrations
   - If already run in production, create new migration
   - Modifying history breaks consistency

5. Use descriptive names
   - create_users, add_email_to_users, remove_legacy_columns

6. Consider production impact
   - Large tables take time to alter
   - Add columns as nullable first
   - Consider background data migrations

7. Add NOT NULL constraints carefully
   - Add column as nullable first
   - Backfill data
   - Then add constraint in separate migration
""")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Exercise 1: Create a Products Table
Difficulty: Easy

Write a migration that creates a products table with:
- name (string, required)
- description (text)
- price (decimal with precision 10, scale 2, required)
- quantity (integer, default 0)
- sku (string, max 20 characters, required)
- timestamps

Write your migration:
""")

# defmodule MyApp.Repo.Migrations.CreateProducts do
#   use Ecto.Migration
#
#   def change do
#     # Your code here
#   end
# end

IO.puts("""

Exercise 2: Create a Blog Schema
Difficulty: Easy

Create migrations for a blog with:
1. authors table: name, email (required), bio
2. posts table: title (required), body (text), published (boolean, default false)

Write both migrations:
""")

# Migration 1: CreateAuthors
# Migration 2: CreatePosts

IO.puts("""

Exercise 3: Add Columns to Existing Table
Difficulty: Medium

Write a migration that adds these columns to an existing users table:
- avatar_url (string)
- role (string, default "user", required)
- last_login_at (utc_datetime)
- preferences (map, default empty map)

Make sure the migration is reversible.
""")

# defmodule MyApp.Repo.Migrations.AddFieldsToUsers do
#   use Ecto.Migration
#
#   def change do
#     # Your code here
#   end
# end

IO.puts("""

Exercise 4: Modify Column Properties
Difficulty: Medium

Write a migration that:
1. Changes the name column from string to text
2. Makes the email column required (NOT NULL)
3. Changes the age column from string to integer

Make the migration reversible.
""")

# defmodule MyApp.Repo.Migrations.ModifyUserColumns do
#   use Ecto.Migration
#
#   def change do
#     # Your code here
#   end
# end

IO.puts("""

Exercise 5: Create Table with UUID Primary Key
Difficulty: Medium

Write a migration for an events table that uses UUID as the primary key:
- id (uuid, primary key)
- name (string, required)
- event_type (string)
- payload (map)
- occurred_at (utc_datetime, required)
- timestamps

Hint: Use primary_key: false option on the table.
""")

# defmodule MyApp.Repo.Migrations.CreateEvents do
#   use Ecto.Migration
#
#   def change do
#     # Your code here
#   end
# end

IO.puts("""

Exercise 6: Complex Table Restructuring
Difficulty: Hard

You have an existing orders table with a single 'address' text column.
Write a migration that:
1. Adds separate address columns: street, city, state, postal_code, country
2. Should work even if the table has existing data

Consider:
- Adding new columns first (nullable)
- How would you handle existing data? (covered more in data migrations)
- Making the migration reversible

Write your migration:
""")

# defmodule MyApp.Repo.Migrations.SplitOrderAddress do
#   use Ecto.Migration
#
#   def change do
#     # Your code here
#   end
# end

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Key takeaways from this lesson:

1. Generate migrations with: mix ecto.gen.migration name
   - Creates timestamped file in priv/repo/migrations/

2. Creating tables:
   - create table(:name) do ... end
   - Use add/2 or add/3 for columns
   - timestamps() adds inserted_at and updated_at

3. Column types: :string, :text, :integer, :decimal, :boolean,
   :date, :utc_datetime, :uuid, :map, {:array, :type}

4. Column options: null: false, default: value, size: n,
   precision: n, scale: n

5. Modifying tables:
   - alter table(:name) do ... end
   - add/2, remove/2, modify/3

6. Renaming: rename table(:old), to: table(:new)
            rename table(:t), :old_col, to: :new_col

7. Use change/0 for auto-reversible migrations
   Use up/0 and down/0 for complex cases

8. Migration commands:
   - mix ecto.migrate (run)
   - mix ecto.rollback (undo)
   - mix ecto.migrations (status)

Next: 09_migrations_advanced.exs - Indexes, constraints, and references
""")
