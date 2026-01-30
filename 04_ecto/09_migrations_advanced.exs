# ============================================================================
# Lesson 09: Advanced Migrations
# ============================================================================
#
# Beyond basic table and column operations, migrations support indexes,
# constraints, foreign key references, and other advanced features that
# ensure data integrity and query performance.
#
# Learning Objectives:
# - Create indexes for query optimization
# - Add unique constraints
# - Define foreign key references
# - Add check constraints
# - Use exclusion constraints (PostgreSQL)
# - Understand constraint naming conventions
#
# Prerequisites:
# - Lesson 08: Migrations Basics
# - Basic SQL knowledge
#
# ============================================================================

IO.puts("=" |> String.duplicate(70))
IO.puts("Lesson 09: Advanced Migrations")
IO.puts("=" |> String.duplicate(70))

# -----------------------------------------------------------------------------
# Section 1: Creating Indexes
# -----------------------------------------------------------------------------
#
# Indexes improve query performance by allowing the database to find
# rows quickly without scanning the entire table.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 1: Creating Indexes ---\n")

basic_index_example = """
defmodule MyApp.Repo.Migrations.AddIndexes do
  use Ecto.Migration

  def change do
    # Single column index
    create index(:users, [:email])

    # Multi-column index (composite)
    create index(:orders, [:user_id, :status])

    # Named index
    create index(:products, [:sku], name: :products_sku_lookup)
  end
end
"""

IO.puts("Basic index creation:")
IO.puts(basic_index_example)

IO.puts("""
When to create indexes:
- Columns used frequently in WHERE clauses
- Columns used in JOIN conditions
- Columns used in ORDER BY
- Foreign key columns (for efficient joins)

Note: Indexes speed up reads but slow down writes.
Don't over-index!
""")

# -----------------------------------------------------------------------------
# Section 2: Unique Indexes
# -----------------------------------------------------------------------------
#
# Unique indexes enforce that no two rows have the same value(s)
# in the indexed column(s).
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 2: Unique Indexes ---\n")

unique_index_example = """
defmodule MyApp.Repo.Migrations.AddUniqueIndexes do
  use Ecto.Migration

  def change do
    # Unique index on single column
    create unique_index(:users, [:email])

    # Unique index on multiple columns
    create unique_index(:team_members, [:team_id, :user_id])

    # Partial unique index (PostgreSQL)
    # Only active users must have unique emails
    create unique_index(:users, [:email],
      where: "is_active = true",
      name: :users_active_email_index
    )
  end
end
"""

IO.puts("Unique index examples:")
IO.puts(unique_index_example)

IO.puts("""
Unique vs NOT NULL:
- Unique index: No duplicate values (NULL allowed multiple times)
- NOT NULL: Column cannot be NULL
- Often used together: unique_index + NOT NULL
""")

# -----------------------------------------------------------------------------
# Section 3: Unique Constraints
# -----------------------------------------------------------------------------
#
# Unique constraints are similar to unique indexes but are defined
# as table constraints and can be referenced by name.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 3: Unique Constraints ---\n")

unique_constraint_example = """
defmodule MyApp.Repo.Migrations.AddUniqueConstraints do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :username, :string, null: false
      timestamps()
    end

    # Create unique constraint (different from unique index)
    create unique_index(:users, [:email], name: :users_email_unique)
    create unique_index(:users, [:username], name: :users_username_unique)
  end
end
"""

IO.puts("Unique constraints:")
IO.puts(unique_constraint_example)

IO.puts("""
In Ecto schemas, you handle unique constraint violations with:

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username])
    |> validate_required([:email, :username])
    |> unique_constraint(:email, name: :users_email_unique)
    |> unique_constraint(:username, name: :users_username_unique)
  end

The name: option must match the constraint/index name.
""")

# -----------------------------------------------------------------------------
# Section 4: Foreign Key References
# -----------------------------------------------------------------------------
#
# References create foreign key constraints that ensure referential
# integrity between related tables.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 4: Foreign Key References ---\n")

references_example = """
defmodule MyApp.Repo.Migrations.CreateOrdersWithReferences do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :total, :decimal, precision: 10, scale: 2
      add :status, :string, default: "pending"

      # Foreign key to users table
      add :user_id, references(:users), null: false

      timestamps()
    end

    # Index on foreign key for faster joins
    create index(:orders, [:user_id])
  end
end
"""

IO.puts("Basic references:")
IO.puts(references_example)

references_options = """
defmodule MyApp.Repo.Migrations.ReferencesWithOptions do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :body, :text, null: false

      # Reference with on_delete behavior
      add :post_id, references(:posts, on_delete: :delete_all), null: false

      # Reference with on_update behavior
      add :author_id, references(:users, on_update: :update_all)

      # Reference with custom column name
      add :parent_id, references(:comments, column: :id)

      # Reference with custom foreign key type
      add :category_id, references(:categories, type: :binary_id)

      # Reference to table with different primary key name
      add :product_id, references(:products, column: :product_code, type: :string)

      timestamps()
    end
  end
end
"""

IO.puts("\nReferences with options:")
IO.puts(references_options)

IO.puts("""
on_delete options:
  :nothing       - Do nothing (default)
  :delete_all    - Delete referencing rows
  :nilify_all    - Set foreign key to NULL
  :restrict      - Prevent deletion if references exist

on_update options:
  :nothing       - Do nothing (default)
  :update_all    - Update referencing rows
  :nilify_all    - Set foreign key to NULL
  :restrict      - Prevent update if references exist
""")

# -----------------------------------------------------------------------------
# Section 5: Self-Referential and Polymorphic References
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 5: Self-Referential and Polymorphic References ---\n")

self_reference_example = """
defmodule MyApp.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string, null: false

      # Self-referential: category has optional parent
      add :parent_id, references(:categories, on_delete: :nilify_all)

      timestamps()
    end

    create index(:categories, [:parent_id])
  end
end

# Polymorphic association pattern
defmodule MyApp.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :body, :text, null: false

      # Polymorphic reference (can belong to Post or Article)
      add :commentable_id, :integer, null: false
      add :commentable_type, :string, null: false

      timestamps()
    end

    # Composite index for polymorphic lookup
    create index(:comments, [:commentable_type, :commentable_id])
  end
end
"""

IO.puts("Self-referential and polymorphic references:")
IO.puts(self_reference_example)

# -----------------------------------------------------------------------------
# Section 6: Check Constraints
# -----------------------------------------------------------------------------
#
# Check constraints validate that values meet certain conditions.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 6: Check Constraints ---\n")

check_constraint_example = """
defmodule MyApp.Repo.Migrations.AddCheckConstraints do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string, null: false
      add :price, :decimal, precision: 10, scale: 2
      add :quantity, :integer

      timestamps()
    end

    # Price must be positive
    create constraint(:products, :price_must_be_positive,
      check: "price > 0"
    )

    # Quantity must be non-negative
    create constraint(:products, :quantity_must_be_non_negative,
      check: "quantity >= 0"
    )
  end
end

# Adding check constraint to existing table
defmodule MyApp.Repo.Migrations.AddAgeConstraint do
  use Ecto.Migration

  def change do
    create constraint(:users, :age_must_be_valid,
      check: "age >= 0 AND age <= 150"
    )
  end
end
"""

IO.puts("Check constraints:")
IO.puts(check_constraint_example)

IO.puts("""
In schemas, handle check constraint violations with:

  def changeset(product, attrs) do
    product
    |> cast(attrs, [:price, :quantity])
    |> check_constraint(:price, name: :price_must_be_positive,
         message: "must be greater than zero")
    |> check_constraint(:quantity, name: :quantity_must_be_non_negative,
         message: "cannot be negative")
  end
""")

# -----------------------------------------------------------------------------
# Section 7: Exclusion Constraints (PostgreSQL)
# -----------------------------------------------------------------------------
#
# Exclusion constraints prevent overlapping ranges or conflicting values.
# Requires the btree_gist extension.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 7: Exclusion Constraints (PostgreSQL) ---\n")

exclusion_example = """
defmodule MyApp.Repo.Migrations.CreateRoomBookings do
  use Ecto.Migration

  def up do
    # Enable required extension
    execute "CREATE EXTENSION IF NOT EXISTS btree_gist"

    create table(:room_bookings) do
      add :room_id, references(:rooms), null: false
      add :starts_at, :utc_datetime, null: false
      add :ends_at, :utc_datetime, null: false

      timestamps()
    end

    # Prevent overlapping bookings for the same room
    execute \"\"\"
    ALTER TABLE room_bookings
    ADD CONSTRAINT no_overlapping_bookings
    EXCLUDE USING gist (
      room_id WITH =,
      tstzrange(starts_at, ends_at) WITH &&
    )
    \"\"\"
  end

  def down do
    drop table(:room_bookings)
    execute "DROP EXTENSION IF EXISTS btree_gist"
  end
end
"""

IO.puts("Exclusion constraint example:")
IO.puts(exclusion_example)

IO.puts("""
In schemas, handle exclusion constraints with:

  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [:room_id, :starts_at, :ends_at])
    |> exclusion_constraint(:room_id,
         name: :no_overlapping_bookings,
         message: "room is already booked for this time")
  end
""")

# -----------------------------------------------------------------------------
# Section 8: Index Types and Options
# -----------------------------------------------------------------------------
#
# Different index types optimize for different query patterns.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 8: Index Types and Options ---\n")

index_types_example = """
defmodule MyApp.Repo.Migrations.SpecializedIndexes do
  use Ecto.Migration

  def change do
    # B-tree index (default, good for equality and range)
    create index(:users, [:created_at])

    # Hash index (PostgreSQL, equality only)
    create index(:users, [:status], using: :hash)

    # GIN index (for arrays, JSONB, full-text search)
    create index(:products, [:tags], using: :gin)

    # GiST index (for geometric, full-text, ranges)
    create index(:locations, [:coordinates], using: :gist)

    # Partial index (only index certain rows)
    create index(:orders, [:user_id],
      where: "status = 'active'",
      name: :orders_active_user_idx
    )

    # Expression index
    create index(:users, ["lower(email)"],
      name: :users_lower_email_idx
    )

    # Covering index (includes additional columns)
    create index(:orders, [:user_id],
      include: [:status, :total],
      name: :orders_user_covering_idx
    )
  end
end
"""

IO.puts("Specialized index types:")
IO.puts(index_types_example)

# -----------------------------------------------------------------------------
# Section 9: Concurrent Index Creation
# -----------------------------------------------------------------------------
#
# For production databases, create indexes concurrently to avoid locking.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 9: Concurrent Index Creation ---\n")

concurrent_index_example = """
defmodule MyApp.Repo.Migrations.AddIndexConcurrently do
  use Ecto.Migration

  # Disable DDL transaction for concurrent operations
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    # Create index without blocking writes
    create index(:users, [:email], concurrently: true)
  end
end

# Drop index concurrently
defmodule MyApp.Repo.Migrations.DropIndexConcurrently do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    drop index(:users, [:email], concurrently: true)
  end
end
"""

IO.puts("Concurrent index operations:")
IO.puts(concurrent_index_example)

IO.puts("""
Important notes for concurrent indexes:
- Must disable DDL transaction
- Cannot be run inside a transaction
- May take longer than regular index creation
- Essential for production to avoid downtime
""")

# -----------------------------------------------------------------------------
# Section 10: Dropping Constraints and Indexes
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 10: Dropping Constraints and Indexes ---\n")

drop_example = """
defmodule MyApp.Repo.Migrations.DropConstraintsAndIndexes do
  use Ecto.Migration

  def change do
    # Drop index
    drop index(:users, [:email])

    # Drop named index
    drop index(:users, [:email], name: :users_email_idx)

    # Drop unique index
    drop unique_index(:users, [:username])

    # Drop constraint
    drop constraint(:products, :price_must_be_positive)

    # Drop index if exists
    drop_if_exists index(:users, [:old_column])
  end
end
"""

IO.puts("Dropping constraints and indexes:")
IO.puts(drop_example)

# -----------------------------------------------------------------------------
# Section 11: Constraint Naming Conventions
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 11: Constraint Naming Conventions ---\n")

IO.puts("""
Ecto generates default constraint names, but explicit naming is recommended:

Index naming:
  {table}_{column(s)}_{type}_index
  Examples:
    users_email_index
    orders_user_id_status_index

Unique constraint naming:
  {table}_{column(s)}_unique
  Examples:
    users_email_unique
    team_members_team_id_user_id_unique

Foreign key naming:
  {table}_{column}_fkey
  Examples:
    orders_user_id_fkey
    comments_post_id_fkey

Check constraint naming:
  {table}_{description}
  Examples:
    products_price_must_be_positive
    users_age_must_be_valid

Benefits of explicit naming:
- Consistent across environments
- Easier error messages
- Better schema documentation
- Required for changeset constraint functions
""")

# -----------------------------------------------------------------------------
# Section 12: Real-World Migration Example
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 12: Real-World Migration Example ---\n")

real_world_example = """
defmodule MyApp.Repo.Migrations.CreateEcommerceSchema do
  use Ecto.Migration

  def change do
    # Categories with self-reference
    create table(:categories) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :parent_id, references(:categories, on_delete: :nilify_all)
      add :position, :integer, default: 0

      timestamps()
    end

    create unique_index(:categories, [:slug])
    create index(:categories, [:parent_id])

    # Products
    create table(:products) do
      add :name, :string, null: false
      add :description, :text
      add :price, :decimal, precision: 10, scale: 2, null: false
      add :sku, :string, null: false
      add :quantity, :integer, default: 0
      add :is_active, :boolean, default: true
      add :metadata, :map, default: %{}
      add :category_id, references(:categories, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:products, [:sku])
    create index(:products, [:category_id])
    create index(:products, [:is_active, :category_id],
      name: :products_active_category_idx
    )

    # Constraints
    create constraint(:products, :price_must_be_positive,
      check: "price >= 0"
    )
    create constraint(:products, :quantity_non_negative,
      check: "quantity >= 0"
    )

    # Orders
    create table(:orders) do
      add :status, :string, null: false, default: "pending"
      add :total, :decimal, precision: 10, scale: 2, null: false
      add :user_id, references(:users, on_delete: :restrict), null: false
      add :shipping_address, :map
      add :notes, :text

      timestamps()
    end

    create index(:orders, [:user_id])
    create index(:orders, [:status])
    create index(:orders, [:inserted_at])

    # Order items
    create table(:order_items) do
      add :quantity, :integer, null: false
      add :unit_price, :decimal, precision: 10, scale: 2, null: false
      add :order_id, references(:orders, on_delete: :delete_all), null: false
      add :product_id, references(:products, on_delete: :restrict), null: false

      timestamps()
    end

    create index(:order_items, [:order_id])
    create index(:order_items, [:product_id])
    create unique_index(:order_items, [:order_id, :product_id])

    create constraint(:order_items, :quantity_must_be_positive,
      check: "quantity > 0"
    )
  end
end
"""

IO.puts("Complete e-commerce schema migration:")
IO.puts(real_world_example)

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Exercise 1: Create Indexes for Performance
Difficulty: Easy

You have a users table with columns: email, username, created_at, last_login_at.
Write a migration that adds:
- Unique index on email
- Unique index on username
- Index on created_at for sorting queries
- Index on last_login_at for filtering

Write your migration:
""")

# defmodule MyApp.Repo.Migrations.AddUserIndexes do
#   use Ecto.Migration
#
#   def change do
#     # Your code here
#   end
# end

IO.puts("""

Exercise 2: Foreign Keys with Different Behaviors
Difficulty: Easy

Create a migration for a comments table that:
- References posts with on_delete: :delete_all (delete comments when post deleted)
- References users with on_delete: :nilify_all (keep comments, clear author)
- Has proper indexes on foreign keys

Write your migration:
""")

# defmodule MyApp.Repo.Migrations.CreateComments do
#   use Ecto.Migration
#
#   def change do
#     # Your code here
#   end
# end

IO.puts("""

Exercise 3: Add Check Constraints
Difficulty: Medium

Write a migration for an inventory system that enforces:
- Price must be greater than 0
- Quantity must be 0 or greater
- Discount percentage must be between 0 and 100
- min_stock_level must be less than max_stock_level

Write your migration:
""")

# defmodule MyApp.Repo.Migrations.AddInventoryConstraints do
#   use Ecto.Migration
#
#   def change do
#     # Your code here
#   end
# end

IO.puts("""

Exercise 4: Composite Unique Constraints
Difficulty: Medium

Create a migration for a subscriptions table where:
- A user can only have one active subscription per plan
- Combination of user_id + plan_id + status must be unique when status = 'active'
- Use a partial unique index for this

Write your migration:
""")

# defmodule MyApp.Repo.Migrations.CreateSubscriptions do
#   use Ecto.Migration
#
#   def change do
#     # Your code here
#   end
# end

IO.puts("""

Exercise 5: Concurrent Index for Production
Difficulty: Medium

You need to add an index to a large production table without downtime.
Write a migration that:
- Creates a unique index on the transactions table for reference_number
- Uses concurrent index creation
- Properly disables DDL transaction

Write your migration:
""")

# defmodule MyApp.Repo.Migrations.AddTransactionIndexConcurrently do
#   use Ecto.Migration
#
#   # What attributes do you need?
#
#   def change do
#     # Your code here
#   end
# end

IO.puts("""

Exercise 6: Complex Schema with All Constraint Types
Difficulty: Hard

Design a migration for a booking system with:
1. rooms table: name, capacity, hourly_rate
2. bookings table: room_id, user_id, starts_at, ends_at, total_cost

Include:
- Foreign keys with appropriate on_delete
- Check constraints (capacity > 0, hourly_rate > 0, ends_at > starts_at)
- Unique constraint preventing double booking (same room, overlapping times)
- Appropriate indexes for common queries

Write your migration:
""")

# defmodule MyApp.Repo.Migrations.CreateBookingSystem do
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

1. Indexes improve query performance:
   - create index(:table, [:column])
   - create unique_index(:table, [:column])
   - Use concurrently: true for production

2. Foreign key references:
   - add :user_id, references(:users)
   - on_delete: :delete_all | :nilify_all | :restrict | :nothing
   - Always index foreign keys

3. Unique constraints:
   - Prevent duplicate values
   - Create with unique_index/3
   - Handle in changeset with unique_constraint/3

4. Check constraints:
   - Validate data at database level
   - create constraint(:table, :name, check: "condition")
   - Handle with check_constraint/3 in changeset

5. Index types (PostgreSQL):
   - B-tree (default): equality and range
   - GIN: arrays, JSONB, full-text
   - GiST: geometric, ranges
   - Hash: equality only

6. Concurrent operations:
   - @disable_ddl_transaction true
   - @disable_migration_lock true
   - Essential for production

7. Naming conventions:
   - Explicit names for constraints and indexes
   - Consistent pattern: {table}_{column}_{type}
   - Required for changeset error handling

Next: 10_migrations_data.exs - Data migrations and best practices
""")
