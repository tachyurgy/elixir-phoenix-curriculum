# ============================================================================
# Lesson 10: Data Migrations
# ============================================================================
#
# Data migrations involve transforming existing data as part of a schema
# change. This requires careful consideration of transaction safety,
# performance, and reversibility.
#
# Learning Objectives:
# - Execute data transformations in migrations
# - Use Repo operations within migrations safely
# - Handle large data sets without blocking
# - Understand backfilling strategies
# - Apply best practices for production migrations
#
# Prerequisites:
# - Lessons 08-09: Migration basics and advanced
# - Understanding of Ecto.Repo operations
#
# ============================================================================

IO.puts("=" |> String.duplicate(70))
IO.puts("Lesson 10: Data Migrations")
IO.puts("=" |> String.duplicate(70))

# -----------------------------------------------------------------------------
# Section 1: When Do You Need Data Migrations?
# -----------------------------------------------------------------------------
#
# Data migrations are needed when schema changes affect existing data.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 1: When Do You Need Data Migrations? ---\n")

IO.puts("""
Common scenarios requiring data migrations:

1. Splitting a column into multiple columns
   - address -> street, city, state, zip

2. Combining multiple columns into one
   - first_name, last_name -> full_name

3. Changing data format
   - String phone numbers -> E.164 format

4. Backfilling computed columns
   - Adding slug from title

5. Changing column type
   - status string -> status enum/integer

6. Setting default values for existing rows
   - Adding a new required column

7. Migrating data between tables
   - Normalizing denormalized data

8. Data cleanup
   - Removing duplicates, fixing inconsistencies
""")

# -----------------------------------------------------------------------------
# Section 2: Using execute/1 for Simple Data Operations
# -----------------------------------------------------------------------------
#
# For simple data operations, raw SQL with execute/1 is efficient.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 2: Using execute/1 for Simple Data Operations ---\n")

simple_execute_example = """
defmodule MyApp.Repo.Migrations.BackfillUserStatus do
  use Ecto.Migration

  def up do
    # Add the new column
    alter table(:users) do
      add :status, :string
    end

    # Backfill existing rows
    execute "UPDATE users SET status = 'active' WHERE status IS NULL"
  end

  def down do
    alter table(:users) do
      remove :status
    end
  end
end

# Setting default based on existing data
defmodule MyApp.Repo.Migrations.SetOrderPriority do
  use Ecto.Migration

  def up do
    alter table(:orders) do
      add :priority, :string
    end

    # Set priority based on total amount
    execute \"\"\"
    UPDATE orders
    SET priority = CASE
      WHEN total > 1000 THEN 'high'
      WHEN total > 100 THEN 'medium'
      ELSE 'low'
    END
    \"\"\"
  end

  def down do
    alter table(:orders) do
      remove :priority
    end
  end
end
"""

IO.puts("Using execute/1:")
IO.puts(simple_execute_example)

# -----------------------------------------------------------------------------
# Section 3: Using Repo in Migrations
# -----------------------------------------------------------------------------
#
# For complex transformations, you can use Ecto.Repo within migrations.
# This requires careful setup and consideration.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 3: Using Repo in Migrations ---\n")

repo_migration_example = """
defmodule MyApp.Repo.Migrations.MigrateUserNames do
  use Ecto.Migration

  # Import Ecto.Query for building queries
  import Ecto.Query

  def up do
    # Add new columns
    alter table(:users) do
      add :first_name, :string
      add :last_name, :string
    end

    # Flush ensures the alter is applied before querying
    flush()

    # Define a private schema for this migration
    # (Don't use your app's schema - it might change!)
    defmodule User do
      use Ecto.Schema

      schema "users" do
        field :name, :string
        field :first_name, :string
        field :last_name, :string
      end
    end

    # Query and update using Repo
    MyApp.Repo.all(User)
    |> Enum.each(fn user ->
      [first | rest] = String.split(user.name || "", " ", parts: 2)
      last = Enum.join(rest, " ")

      MyApp.Repo.update_all(
        from(u in User, where: u.id == ^user.id),
        set: [first_name: first, last_name: last]
      )
    end)
  end

  def down do
    alter table(:users) do
      remove :first_name
      remove :last_name
    end
  end
end
"""

IO.puts("Using Repo in migrations:")
IO.puts(repo_migration_example)

IO.puts("""
Important notes:
- Use flush() after schema changes before querying
- Define private schemas in the migration (not app schemas)
- App schemas may change, breaking old migrations
""")

# -----------------------------------------------------------------------------
# Section 4: Inline Schema Pattern
# -----------------------------------------------------------------------------
#
# Define schemas inside migrations to avoid coupling with application code.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 4: Inline Schema Pattern ---\n")

inline_schema_example = """
defmodule MyApp.Repo.Migrations.NormalizePhoneNumbers do
  use Ecto.Migration

  import Ecto.Query

  # Define schema inside migration - isolated from app changes
  defmodule UserMigration do
    use Ecto.Schema

    @primary_key {:id, :id, autogenerate: true}
    schema "users" do
      field :phone, :string
    end
  end

  def up do
    flush()

    # Process each user
    from(u in UserMigration, where: not is_nil(u.phone))
    |> MyApp.Repo.all()
    |> Enum.each(fn user ->
      normalized = normalize_phone(user.phone)

      from(u in UserMigration, where: u.id == ^user.id)
      |> MyApp.Repo.update_all(set: [phone: normalized])
    end)
  end

  def down do
    # Phone normalization is typically not reversible
    :ok
  end

  defp normalize_phone(phone) do
    phone
    |> String.replace(~r/[^0-9]/, "")
    |> then(fn
      "1" <> rest when byte_size(rest) == 10 -> "+1" <> rest
      digits when byte_size(digits) == 10 -> "+1" <> digits
      other -> other
    end)
  end
end
"""

IO.puts("Inline schema pattern:")
IO.puts(inline_schema_example)

# -----------------------------------------------------------------------------
# Section 5: Batched Data Migrations
# -----------------------------------------------------------------------------
#
# For large tables, process data in batches to avoid memory issues
# and long-running transactions.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 5: Batched Data Migrations ---\n")

batched_migration_example = """
defmodule MyApp.Repo.Migrations.BackfillSlugsBatched do
  use Ecto.Migration

  import Ecto.Query

  @batch_size 1000

  defmodule PostMigration do
    use Ecto.Schema

    schema "posts" do
      field :title, :string
      field :slug, :string
    end
  end

  def up do
    alter table(:posts) do
      add :slug, :string
    end

    create index(:posts, [:slug])

    flush()

    # Process in batches
    process_batch(0)
  end

  defp process_batch(offset) do
    posts =
      from(p in PostMigration,
        where: is_nil(p.slug),
        limit: @batch_size,
        offset: ^offset
      )
      |> MyApp.Repo.all()

    if posts == [] do
      :done
    else
      Enum.each(posts, fn post ->
        slug = Slug.slugify(post.title)

        from(p in PostMigration, where: p.id == ^post.id)
        |> MyApp.Repo.update_all(set: [slug: slug])
      end)

      # Process next batch
      process_batch(offset + @batch_size)
    end
  end

  def down do
    drop index(:posts, [:slug])

    alter table(:posts) do
      remove :slug
    end
  end
end
"""

IO.puts("Batched processing:")
IO.puts(batched_migration_example)

stream_example = """
# Alternative: Using Repo.stream for memory efficiency
defmodule MyApp.Repo.Migrations.BackfillWithStream do
  use Ecto.Migration

  import Ecto.Query

  def up do
    flush()

    MyApp.Repo.transaction(fn ->
      from(p in "posts", where: is_nil(p.slug), select: [:id, :title])
      |> MyApp.Repo.stream(max_rows: 500)
      |> Stream.each(fn post ->
        slug = Slug.slugify(post.title)

        from(p in "posts", where: p.id == ^post.id)
        |> MyApp.Repo.update_all(set: [slug: slug])
      end)
      |> Stream.run()
    end, timeout: :infinity)
  end

  def down do
    :ok
  end
end
"""

IO.puts("\nUsing Repo.stream:")
IO.puts(stream_example)

# -----------------------------------------------------------------------------
# Section 6: Safe Column Addition with Backfill
# -----------------------------------------------------------------------------
#
# When adding NOT NULL columns with defaults, follow a multi-step process.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 6: Safe Column Addition with Backfill ---\n")

safe_addition_example = """
# Step 1: Add column as nullable
defmodule MyApp.Repo.Migrations.Step1AddRoleColumn do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role, :string  # Nullable first
    end
  end
end

# Step 2: Backfill data (separate migration)
defmodule MyApp.Repo.Migrations.Step2BackfillRoles do
  use Ecto.Migration

  def up do
    execute "UPDATE users SET role = 'user' WHERE role IS NULL"
  end

  def down do
    # No reversal needed
    :ok
  end
end

# Step 3: Add NOT NULL constraint (separate migration)
defmodule MyApp.Repo.Migrations.Step3MakeRoleRequired do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :role, :string, null: false, default: "user",
        from: {:string, null: true, default: nil}
    end
  end
end
"""

IO.puts("Safe column addition process:")
IO.puts(safe_addition_example)

IO.puts("""
Why split into three migrations?

1. Single migration with NOT NULL:
   - Locks table while setting default on all rows
   - Can cause downtime on large tables

2. Three-step approach:
   - Step 1: Fast schema change (no data modification)
   - Step 2: Backfill can run in batches, interruptible
   - Step 3: Constraint added after data is ready

3. Benefits:
   - Zero/minimal downtime
   - Can deploy between steps
   - Easier to debug if issues occur
""")

# -----------------------------------------------------------------------------
# Section 7: Renaming Columns with Data Preservation
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 7: Renaming Columns with Data Preservation ---\n")

rename_column_example = """
# Safe approach: Copy data, don't rename directly
defmodule MyApp.Repo.Migrations.RenameEmailToEmailAddress do
  use Ecto.Migration

  def up do
    # Add new column
    alter table(:users) do
      add :email_address, :string
    end

    flush()

    # Copy data
    execute "UPDATE users SET email_address = email"

    # Add constraints to new column
    create unique_index(:users, [:email_address])

    # Note: Don't remove old column here
    # Let app code migrate first, then remove in future migration
  end

  def down do
    drop unique_index(:users, [:email_address])

    alter table(:users) do
      remove :email_address
    end
  end
end

# Later migration after app code is updated:
defmodule MyApp.Repo.Migrations.DropOldEmailColumn do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :email, :string, null: false
    end
  end
end
"""

IO.puts("Safe column rename process:")
IO.puts(rename_column_example)

# -----------------------------------------------------------------------------
# Section 8: Data Type Changes
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 8: Data Type Changes ---\n")

type_change_example = """
# Changing string status to enum/integer
defmodule MyApp.Repo.Migrations.ChangeStatusToEnum do
  use Ecto.Migration

  def up do
    # Add new integer column
    alter table(:orders) do
      add :status_code, :integer
    end

    flush()

    # Map string values to integers
    execute \"\"\"
    UPDATE orders
    SET status_code = CASE status
      WHEN 'pending' THEN 0
      WHEN 'processing' THEN 1
      WHEN 'shipped' THEN 2
      WHEN 'delivered' THEN 3
      WHEN 'cancelled' THEN 4
      ELSE 0
    END
    \"\"\"

    # Make new column required
    alter table(:orders) do
      modify :status_code, :integer, null: false, from: {:integer, null: true}
    end

    # Create index on new column
    create index(:orders, [:status_code])
  end

  def down do
    drop index(:orders, [:status_code])

    alter table(:orders) do
      remove :status_code
    end
  end
end

# After app migration complete, remove old column:
defmodule MyApp.Repo.Migrations.RemoveStringStatus do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      remove :status, :string
    end
  end
end
"""

IO.puts("Changing data types:")
IO.puts(type_change_example)

# -----------------------------------------------------------------------------
# Section 9: Data Migration Outside Transactions
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 9: Data Migration Outside Transactions ---\n")

non_transactional_example = """
defmodule MyApp.Repo.Migrations.LargeDataMigration do
  use Ecto.Migration

  # Disable wrapping in transaction
  @disable_ddl_transaction true
  @disable_migration_lock true

  import Ecto.Query

  @batch_size 10_000

  def up do
    # Run schema changes in a transaction
    Ecto.Migration.repo().transaction(fn ->
      alter table(:products) do
        add :search_vector, :tsvector
      end
    end)

    # Backfill outside transaction in batches
    backfill_batch(0)

    # Create index concurrently (must be outside transaction)
    create index(:products, [:search_vector],
      using: :gin,
      concurrently: true
    )
  end

  defp backfill_batch(offset) do
    {count, _} =
      from(p in "products",
        where: is_nil(p.search_vector),
        limit: @batch_size
      )
      |> MyApp.Repo.update_all(
        set: [
          search_vector: fragment(
            "to_tsvector('english', coalesce(name, '') || ' ' || coalesce(description, ''))"
          )
        ]
      )

    if count > 0 do
      # Small delay to reduce database load
      Process.sleep(100)
      backfill_batch(offset + count)
    end
  end

  def down do
    drop index(:products, [:search_vector], concurrently: true)

    alter table(:products) do
      remove :search_vector
    end
  end
end
"""

IO.puts("Non-transactional migration:")
IO.puts(non_transactional_example)

# -----------------------------------------------------------------------------
# Section 10: Data Migration Best Practices
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 10: Data Migration Best Practices ---\n")

IO.puts("""
Best Practices for Data Migrations:

1. NEVER reference application schemas
   - Schemas change over time
   - Old migrations will break
   - Define inline schemas or use raw SQL

2. Keep schema changes separate from data changes
   - Easier to debug
   - Can rollback independently
   - Better for blue-green deployments

3. Make migrations idempotent when possible
   - Can be safely re-run
   - Use WHERE clauses to skip processed rows
   - Example: WHERE new_column IS NULL

4. Consider production impact
   - Test with production-sized data
   - Measure execution time
   - Plan for interruption/restart

5. Batch large data operations
   - Avoid memory issues
   - Reduce lock contention
   - Allow other queries to run

6. Add indexes after data migration
   - Faster to build on existing data
   - Use CONCURRENTLY in production

7. Have a rollback plan
   - Test down/0 function
   - Consider irreversible operations
   - Sometimes accept no rollback

8. Log progress for long migrations
   - Monitor batch progress
   - Easier to estimate completion
   - Helpful for debugging

9. Use execute over Repo when possible
   - Raw SQL is faster
   - No ORM overhead
   - More predictable performance

10. Consider separate deploy for data migrations
    - Run schema change first
    - Deploy app code
    - Run data migration
    - Add constraints last
""")

# -----------------------------------------------------------------------------
# Section 11: Mix Tasks for Data Migrations
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 11: Mix Tasks for Data Migrations ---\n")

mix_task_example = """
# lib/mix/tasks/backfill_slugs.ex
defmodule Mix.Tasks.BackfillSlugs do
  @moduledoc \"\"\"
  Backfills slugs for all posts.

  Usage:
    mix backfill_slugs
    mix backfill_slugs --batch-size 500
  \"\"\"

  use Mix.Task

  import Ecto.Query

  @shortdoc "Backfill post slugs"

  def run(args) do
    # Start the application
    Mix.Task.run("app.start")

    {opts, _, _} = OptionParser.parse(args,
      strict: [batch_size: :integer]
    )

    batch_size = Keyword.get(opts, :batch_size, 1000)

    IO.puts("Starting slug backfill with batch size: \#{batch_size}")

    process_batch(batch_size, 0, 0)
  end

  defp process_batch(batch_size, offset, total_processed) do
    posts =
      from(p in MyApp.Post,
        where: is_nil(p.slug),
        limit: ^batch_size,
        select: [:id, :title]
      )
      |> MyApp.Repo.all()

    if posts == [] do
      IO.puts("Completed! Total processed: \#{total_processed}")
    else
      Enum.each(posts, fn post ->
        slug = Slug.slugify(post.title)

        from(p in MyApp.Post, where: p.id == ^post.id)
        |> MyApp.Repo.update_all(set: [slug: slug])
      end)

      count = length(posts)
      new_total = total_processed + count
      IO.puts("Processed batch: \#{count}, Total: \#{new_total}")

      process_batch(batch_size, offset + batch_size, new_total)
    end
  end
end
"""

IO.puts("Using Mix tasks for data migrations:")
IO.puts(mix_task_example)

IO.puts("""
Benefits of Mix tasks over migration data changes:
- Can run independently of deployments
- Easier to monitor and restart
- Can accept parameters
- Better logging and error handling
- Can run in background
""")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Exercise 1: Simple Data Backfill
Difficulty: Easy

Write a migration that:
1. Adds a 'display_name' column to the users table
2. Backfills it by combining first_name and last_name
3. Uses execute/1 with raw SQL

Write your migration:
""")

# defmodule MyApp.Repo.Migrations.AddDisplayName do
#   use Ecto.Migration
#
#   def up do
#     # Your code here
#   end
#
#   def down do
#     # Your code here
#   end
# end

IO.puts("""

Exercise 2: Safe NOT NULL Column Addition
Difficulty: Medium

You need to add a required 'category' column to a products table
with a default value of 'general'. Existing products should get
this default value.

Write three migrations:
1. Add the column (nullable)
2. Backfill data
3. Add NOT NULL constraint

Write your migrations:
""")

# Migration 1: AddCategoryColumn
# Migration 2: BackfillCategories
# Migration 3: MakeCategoryRequired

IO.puts("""

Exercise 3: Batched Data Migration with Progress
Difficulty: Medium

Write a migration that:
1. Adds a 'word_count' integer column to posts
2. Backfills it by counting words in the 'body' column
3. Processes in batches of 500
4. Prints progress after each batch

Write your migration:
""")

# defmodule MyApp.Repo.Migrations.AddWordCount do
#   use Ecto.Migration
#
#   import Ecto.Query
#
#   @batch_size 500
#
#   def up do
#     # Your code here
#   end
#
#   def down do
#     # Your code here
#   end
# end

IO.puts("""

Exercise 4: Column Type Change with Data Mapping
Difficulty: Medium

Your orders table has a 'priority' string column with values:
"low", "medium", "high", "urgent"

Write a migration to convert this to an integer column:
- low -> 1
- medium -> 2
- high -> 3
- urgent -> 4

The migration should be reversible.

Write your migration:
""")

# defmodule MyApp.Repo.Migrations.ChangePriorityToInteger do
#   use Ecto.Migration
#
#   def up do
#     # Your code here
#   end
#
#   def down do
#     # Your code here
#   end
# end

IO.puts("""

Exercise 5: Normalizing Denormalized Data
Difficulty: Hard

You have an orders table with embedded address fields:
- shipping_street
- shipping_city
- shipping_state
- shipping_zip

Create a migration that:
1. Creates a new addresses table
2. Migrates unique addresses from orders
3. Adds address_id foreign key to orders
4. Links orders to their addresses

Write your migration:
""")

# defmodule MyApp.Repo.Migrations.NormalizeAddresses do
#   use Ecto.Migration
#
#   import Ecto.Query
#
#   def up do
#     # Your code here
#   end
#
#   def down do
#     # Your code here
#   end
# end

IO.puts("""

Exercise 6: Production-Safe Large Table Migration
Difficulty: Hard

Write a migration for a production database with millions of rows that:
1. Adds a 'search_terms' column (tsvector for PostgreSQL)
2. Backfills it from 'title' and 'description' columns
3. Creates a GIN index for searching
4. Uses concurrent operations and batching
5. Is safe to run without downtime

Consider:
- Disabling DDL transactions
- Concurrent index creation
- Batch processing
- Progress logging

Write your migration:
""")

# defmodule MyApp.Repo.Migrations.AddSearchTerms do
#   use Ecto.Migration
#
#   # What attributes do you need?
#
#   def up do
#     # Your code here
#   end
#
#   def down do
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

1. Data migrations modify existing data during schema changes
   - Backfilling new columns
   - Transforming data formats
   - Normalizing/denormalizing data

2. Use execute/1 for simple SQL operations
   - UPDATE, INSERT, DELETE statements
   - Fast and straightforward

3. Use Repo in migrations carefully:
   - Call flush() after schema changes
   - Define inline schemas (not app schemas)
   - Old migrations must work with current code

4. Batch large data operations:
   - Avoid memory issues
   - Reduce table locks
   - Allow progress monitoring

5. Safe column addition process:
   - Add column (nullable) -> Backfill -> Add constraint
   - Three separate migrations
   - Zero downtime possible

6. Use @disable_ddl_transaction for:
   - Concurrent index creation
   - Large data migrations
   - Operations that can't run in transaction

7. Best practices:
   - Never reference app schemas
   - Keep schema and data changes separate
   - Make migrations idempotent
   - Consider Mix tasks for large backfills
   - Test with production-sized data

8. Consider deployment strategy:
   - Blue-green deployments
   - Rolling updates
   - Data migration timing

Next: 11_query_basics.exs - Introduction to Ecto.Query
""")
