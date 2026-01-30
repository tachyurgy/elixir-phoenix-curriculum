# ==============================================================================
# REPO BASICS - INSERT, UPDATE, DELETE, AND QUERY OPERATIONS
# ==============================================================================
#
# The Repo module is the primary interface for database operations in Ecto.
# It provides functions for CRUD operations, queries, transactions, and more.
#
# This lesson covers the fundamental Repo operations you'll use daily.
#
# ==============================================================================
# TABLE OF CONTENTS
# ==============================================================================
#
# 1. Repo Overview
# 2. Insert Operations
# 3. Update Operations
# 4. Delete Operations
# 5. Query Operations (get, get_by, all, one)
# 6. Aggregate Functions
# 7. Transactions
# 8. Exercises
#
# ==============================================================================

# ==============================================================================
# PREREQUISITE: Sample Schema for Examples
# ==============================================================================
#
# We'll use this schema throughout the lesson. Don't worry about the details
# yet - schemas are covered in the next lesson.

defmodule MyApp.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :age, :integer
    field :active, :boolean, default: true

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :age, :active])
    |> validate_required([:name, :email])
    |> unique_constraint(:email)
  end
end

# Assume MyApp.Repo is already set up as shown in lesson 01

# ==============================================================================
# SECTION 1: REPO OVERVIEW
# ==============================================================================

defmodule RepoOverview do
  @moduledoc """
  The Repo module provides database operations.

  Key concepts:
  - All database operations go through the Repo
  - Operations return tagged tuples {:ok, result} or {:error, reason}
  - Bang versions (insert!, get!) raise on error
  - Changesets are used for validation before insert/update
  """

  # The Repo provides these main categories of functions:
  #
  # WRITE OPERATIONS:
  # - insert/2, insert!/2
  # - update/2, update!/2
  # - delete/2, delete!/2
  # - insert_or_update/2
  # - insert_all/3
  # - update_all/3
  # - delete_all/2
  #
  # READ OPERATIONS:
  # - get/3, get!/3
  # - get_by/3, get_by!/3
  # - one/2, one!/2
  # - all/2
  # - exists?/2
  # - aggregate/4
  #
  # TRANSACTION:
  # - transaction/2
  #
  # PRELOADING:
  # - preload/3

  def example_usage do
    # All Repo functions are called on the Repo module directly
    # MyApp.Repo.insert(changeset)
    # MyApp.Repo.get(User, 1)
    # MyApp.Repo.all(User)
    :ok
  end
end

# ==============================================================================
# SECTION 2: INSERT OPERATIONS
# ==============================================================================

defmodule InsertOperations do
  @moduledoc """
  Inserting records into the database.
  """

  alias MyApp.{Repo, User}

  # ---------------------------------------------------------------------------
  # insert/2 - Insert a single record
  # ---------------------------------------------------------------------------

  def insert_with_changeset do
    # The preferred way: use a changeset for validation
    attrs = %{name: "Alice", email: "alice@example.com", age: 30}

    changeset = User.changeset(%User{}, attrs)

    case Repo.insert(changeset) do
      {:ok, user} ->
        IO.puts("Created user with ID: #{user.id}")
        user

      {:error, changeset} ->
        IO.puts("Failed to create user:")
        IO.inspect(changeset.errors)
        nil
    end
  end

  def insert_struct_directly do
    # You can insert a struct directly (bypasses validation!)
    # This is generally not recommended
    {:ok, user} = Repo.insert(%User{
      name: "Bob",
      email: "bob@example.com",
      age: 25
    })

    user
  end

  # ---------------------------------------------------------------------------
  # insert!/2 - Insert or raise exception
  # ---------------------------------------------------------------------------

  def insert_bang do
    # Raises Ecto.InvalidChangesetError if changeset is invalid
    # Raises Ecto.ConstraintError if database constraint is violated
    attrs = %{name: "Charlie", email: "charlie@example.com"}
    changeset = User.changeset(%User{}, attrs)

    user = Repo.insert!(changeset)
    IO.puts("Created user: #{user.name}")
    user
  end

  # ---------------------------------------------------------------------------
  # insert_all/3 - Bulk insert multiple records
  # ---------------------------------------------------------------------------

  def insert_multiple_users do
    users = [
      %{name: "User 1", email: "user1@example.com", inserted_at: DateTime.utc_now(), updated_at: DateTime.utc_now()},
      %{name: "User 2", email: "user2@example.com", inserted_at: DateTime.utc_now(), updated_at: DateTime.utc_now()},
      %{name: "User 3", email: "user3@example.com", inserted_at: DateTime.utc_now(), updated_at: DateTime.utc_now()}
    ]

    # Returns {count, nil} by default
    {count, nil} = Repo.insert_all(User, users)
    IO.puts("Inserted #{count} users")

    # With returning option to get inserted records
    {count, inserted_users} = Repo.insert_all(User, users, returning: true)
    IO.puts("Inserted #{count} users")
    Enum.each(inserted_users, fn user ->
      IO.puts("  - #{user.name} (ID: #{user.id})")
    end)

    # With on_conflict for upserts
    {count, _} = Repo.insert_all(
      User,
      users,
      on_conflict: :replace_all,
      conflict_target: :email
    )

    count
  end

  # ---------------------------------------------------------------------------
  # insert_or_update/2 - Insert if new, update if exists
  # ---------------------------------------------------------------------------

  def insert_or_update_example do
    # Requires a changeset with a primary key set (for updates)
    # or without a primary key (for inserts)

    # This will INSERT (no id set)
    new_user_changeset = User.changeset(%User{}, %{
      name: "New User",
      email: "new@example.com"
    })

    {:ok, user} = Repo.insert_or_update(new_user_changeset)

    # This will UPDATE (id is set from previous insert)
    update_changeset = User.changeset(user, %{name: "Updated User"})
    {:ok, updated_user} = Repo.insert_or_update(update_changeset)

    updated_user
  end
end

# ==============================================================================
# SECTION 3: UPDATE OPERATIONS
# ==============================================================================

defmodule UpdateOperations do
  @moduledoc """
  Updating records in the database.
  """

  alias MyApp.{Repo, User}
  import Ecto.Query

  # ---------------------------------------------------------------------------
  # update/2 - Update a single record
  # ---------------------------------------------------------------------------

  def update_user do
    # First, fetch the user
    user = Repo.get!(User, 1)

    # Create a changeset with the updates
    changeset = User.changeset(user, %{name: "Updated Name", age: 31})

    # Perform the update
    case Repo.update(changeset) do
      {:ok, user} ->
        IO.puts("Updated user: #{user.name}")
        user

      {:error, changeset} ->
        IO.puts("Failed to update:")
        IO.inspect(changeset.errors)
        nil
    end
  end

  # ---------------------------------------------------------------------------
  # update!/2 - Update or raise exception
  # ---------------------------------------------------------------------------

  def update_bang do
    user = Repo.get!(User, 1)
    changeset = User.changeset(user, %{name: "New Name"})

    # Raises if changeset is invalid or constraint is violated
    updated_user = Repo.update!(changeset)
    updated_user
  end

  # ---------------------------------------------------------------------------
  # update_all/3 - Bulk update multiple records
  # ---------------------------------------------------------------------------

  def update_all_users do
    # Update all users older than 30 to be inactive
    query = from u in User, where: u.age > 30

    # The set option specifies what to update
    {count, nil} = Repo.update_all(query, set: [active: false])
    IO.puts("Deactivated #{count} users")

    # You can use expressions in updates
    {count, _} = Repo.update_all(
      User,
      inc: [age: 1]  # Increment age by 1 for all users
    )

    # With conditions and returning
    query = from u in User,
      where: u.active == true,
      select: u

    {count, users} = Repo.update_all(
      query,
      [set: [updated_at: DateTime.utc_now()]],
      returning: true
    )

    {count, users}
  end

  # ---------------------------------------------------------------------------
  # Conditional updates with dynamic values
  # ---------------------------------------------------------------------------

  def conditional_update do
    import Ecto.Query

    # Update using subquery or fragment
    query = from u in User,
      where: u.active == true,
      update: [set: [
        name: fragment("upper(?)", u.name),
        updated_at: ^DateTime.utc_now()
      ]]

    Repo.update_all(query, [])
  end
end

# ==============================================================================
# SECTION 4: DELETE OPERATIONS
# ==============================================================================

defmodule DeleteOperations do
  @moduledoc """
  Deleting records from the database.
  """

  alias MyApp.{Repo, User}
  import Ecto.Query

  # ---------------------------------------------------------------------------
  # delete/2 - Delete a single record
  # ---------------------------------------------------------------------------

  def delete_user do
    # First, fetch the user
    user = Repo.get!(User, 1)

    case Repo.delete(user) do
      {:ok, deleted_user} ->
        IO.puts("Deleted user: #{deleted_user.name}")
        deleted_user

      {:error, changeset} ->
        # Can fail if there are foreign key constraints
        IO.puts("Failed to delete:")
        IO.inspect(changeset.errors)
        nil
    end
  end

  # ---------------------------------------------------------------------------
  # delete!/2 - Delete or raise exception
  # ---------------------------------------------------------------------------

  def delete_bang do
    user = Repo.get!(User, 1)

    # Raises if delete fails
    deleted_user = Repo.delete!(user)
    deleted_user
  end

  # ---------------------------------------------------------------------------
  # Delete with changeset (for constraint handling)
  # ---------------------------------------------------------------------------

  def delete_with_changeset do
    user = Repo.get!(User, 1)

    # You can use a changeset to handle constraints
    changeset =
      user
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.no_assoc_constraint(:posts)  # Prevent deletion if has posts

    Repo.delete(changeset)
  end

  # ---------------------------------------------------------------------------
  # delete_all/2 - Bulk delete multiple records
  # ---------------------------------------------------------------------------

  def delete_inactive_users do
    query = from u in User, where: u.active == false

    # Returns {count, nil} by default
    {count, nil} = Repo.delete_all(query)
    IO.puts("Deleted #{count} inactive users")

    count
  end

  def delete_old_users do
    # Delete users who haven't been updated in 30 days
    thirty_days_ago = DateTime.add(DateTime.utc_now(), -30, :day)

    query = from u in User,
      where: u.updated_at < ^thirty_days_ago

    {count, _} = Repo.delete_all(query)
    count
  end

  # ---------------------------------------------------------------------------
  # Soft delete pattern
  # ---------------------------------------------------------------------------

  def soft_delete(user) do
    # Instead of deleting, set a deleted_at timestamp
    # (Requires deleted_at field in schema)
    user
    |> Ecto.Changeset.change(deleted_at: DateTime.utc_now())
    |> Repo.update()
  end
end

# ==============================================================================
# SECTION 5: QUERY OPERATIONS (GET, GET_BY, ALL, ONE)
# ==============================================================================

defmodule QueryOperations do
  @moduledoc """
  Fetching records from the database.
  """

  alias MyApp.{Repo, User}
  import Ecto.Query

  # ---------------------------------------------------------------------------
  # get/3 - Fetch by primary key
  # ---------------------------------------------------------------------------

  def get_by_id do
    # Returns nil if not found
    case Repo.get(User, 1) do
      nil -> IO.puts("User not found")
      user -> IO.puts("Found user: #{user.name}")
    end
  end

  def get_bang_by_id do
    # Raises Ecto.NoResultsError if not found
    user = Repo.get!(User, 1)
    IO.puts("Found user: #{user.name}")
    user
  end

  # ---------------------------------------------------------------------------
  # get_by/3 - Fetch by specific fields
  # ---------------------------------------------------------------------------

  def get_by_email do
    # Returns nil if not found
    case Repo.get_by(User, email: "alice@example.com") do
      nil -> IO.puts("User not found")
      user -> IO.puts("Found user: #{user.name}")
    end

    # Multiple conditions (AND)
    Repo.get_by(User, name: "Alice", active: true)
  end

  def get_by_bang do
    # Raises Ecto.NoResultsError if not found
    user = Repo.get_by!(User, email: "alice@example.com")
    user
  end

  # ---------------------------------------------------------------------------
  # all/2 - Fetch all matching records
  # ---------------------------------------------------------------------------

  def get_all_users do
    # Get all users
    users = Repo.all(User)
    IO.puts("Total users: #{length(users)}")
    users
  end

  def get_filtered_users do
    # With a query
    query = from u in User,
      where: u.active == true,
      order_by: [asc: u.name]

    active_users = Repo.all(query)
    active_users
  end

  def get_users_with_limit do
    # Pagination with limit and offset
    query = from u in User,
      limit: 10,
      offset: 0,
      order_by: [desc: u.inserted_at]

    Repo.all(query)
  end

  # ---------------------------------------------------------------------------
  # one/2 - Fetch exactly one record
  # ---------------------------------------------------------------------------

  def get_one_user do
    # Returns nil if no result
    # Raises Ecto.MultipleResultsError if more than one result
    query = from u in User,
      where: u.email == "alice@example.com"

    case Repo.one(query) do
      nil -> IO.puts("User not found")
      user -> IO.puts("Found: #{user.name}")
    end
  end

  def get_one_bang do
    # Raises if no result OR multiple results
    query = from u in User, where: u.id == 1
    user = Repo.one!(query)
    user
  end

  # ---------------------------------------------------------------------------
  # exists?/2 - Check if any records match
  # ---------------------------------------------------------------------------

  def check_email_exists(email) do
    query = from u in User, where: u.email == ^email

    if Repo.exists?(query) do
      IO.puts("Email already taken!")
      true
    else
      IO.puts("Email available")
      false
    end
  end

  # ---------------------------------------------------------------------------
  # reload/2 - Reload a struct from database
  # ---------------------------------------------------------------------------

  def reload_user(user) do
    # Useful after concurrent updates
    refreshed_user = Repo.reload(user)
    # Returns nil if the record was deleted
    refreshed_user

    # Or raise if not found
    refreshed_user = Repo.reload!(user)
    refreshed_user
  end
end

# ==============================================================================
# SECTION 6: AGGREGATE FUNCTIONS
# ==============================================================================

defmodule AggregateOperations do
  @moduledoc """
  Aggregate functions for calculations across records.
  """

  alias MyApp.{Repo, User}
  import Ecto.Query

  # ---------------------------------------------------------------------------
  # aggregate/4 - Perform aggregate calculations
  # ---------------------------------------------------------------------------

  def count_users do
    # Count all users
    count = Repo.aggregate(User, :count)
    IO.puts("Total users: #{count}")

    # Count with condition
    query = from u in User, where: u.active == true
    active_count = Repo.aggregate(query, :count)
    IO.puts("Active users: #{active_count}")

    count
  end

  def sum_ages do
    # Sum of a specific field
    total_age = Repo.aggregate(User, :sum, :age)
    IO.puts("Sum of all ages: #{total_age}")
    total_age
  end

  def average_age do
    # Average of a field
    avg_age = Repo.aggregate(User, :avg, :age)
    IO.puts("Average age: #{avg_age}")
    avg_age
  end

  def min_max_age do
    min_age = Repo.aggregate(User, :min, :age)
    max_age = Repo.aggregate(User, :max, :age)

    IO.puts("Age range: #{min_age} - #{max_age}")
    {min_age, max_age}
  end

  # ---------------------------------------------------------------------------
  # Aggregates with queries
  # ---------------------------------------------------------------------------

  def aggregate_active_users do
    query = from u in User, where: u.active == true

    %{
      count: Repo.aggregate(query, :count),
      avg_age: Repo.aggregate(query, :avg, :age),
      max_age: Repo.aggregate(query, :max, :age)
    }
  end
end

# ==============================================================================
# SECTION 7: TRANSACTIONS
# ==============================================================================

defmodule TransactionOperations do
  @moduledoc """
  Database transactions for atomic operations.
  """

  alias MyApp.{Repo, User}
  alias Ecto.Multi

  # ---------------------------------------------------------------------------
  # transaction/2 - Simple transaction
  # ---------------------------------------------------------------------------

  def simple_transaction do
    Repo.transaction(fn ->
      user1 = Repo.insert!(%User{name: "User 1", email: "user1@example.com"})
      user2 = Repo.insert!(%User{name: "User 2", email: "user2@example.com"})

      # If anything raises, the transaction is rolled back
      {user1, user2}
    end)
    # Returns {:ok, {user1, user2}} or {:error, reason}
  end

  def transaction_with_rollback do
    result = Repo.transaction(fn ->
      user = Repo.insert!(%User{name: "Test", email: "test@example.com"})

      # Explicit rollback
      if user.name == "Test" do
        Repo.rollback(:invalid_name)
      end

      user
    end)

    case result do
      {:ok, user} -> IO.puts("Created: #{user.name}")
      {:error, :invalid_name} -> IO.puts("Rolled back: invalid name")
    end
  end

  # ---------------------------------------------------------------------------
  # Ecto.Multi - Complex transactions
  # ---------------------------------------------------------------------------

  def multi_transaction do
    # Ecto.Multi allows composable, named transaction steps
    Multi.new()
    |> Multi.insert(:user, %User{name: "Alice", email: "alice@example.com"})
    |> Multi.insert(:admin, fn %{user: _user} ->
      %User{name: "Admin", email: "admin@example.com"}
    end)
    |> Multi.update(:deactivate, fn %{user: user} ->
      User.changeset(user, %{active: false})
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user, admin: admin, deactivate: deactivated}} ->
        IO.puts("All operations succeeded")
        {user, admin, deactivated}

      {:error, failed_operation, failed_value, changes_so_far} ->
        IO.puts("Failed at: #{failed_operation}")
        IO.inspect(failed_value)
        IO.inspect(changes_so_far)
        nil
    end
  end

  def multi_with_run do
    # Multi.run allows arbitrary functions
    Multi.new()
    |> Multi.insert(:user, User.changeset(%User{}, %{
      name: "Test",
      email: "test@example.com"
    }))
    |> Multi.run(:send_email, fn _repo, %{user: user} ->
      # Simulate sending email
      # In real code, this might actually send an email
      IO.puts("Would send welcome email to #{user.email}")
      {:ok, :email_sent}
    end)
    |> Repo.transaction()
  end

  # ---------------------------------------------------------------------------
  # Transaction with explicit isolation levels
  # ---------------------------------------------------------------------------

  def transaction_with_isolation do
    Repo.transaction(
      fn ->
        # Operations here
        Repo.all(User)
      end,
      isolation: :serializable
      # Other options: :read_committed, :repeatable_read
    )
  end
end

# ==============================================================================
# SECTION 8: PRELOADING ASSOCIATIONS
# ==============================================================================

defmodule PreloadOperations do
  @moduledoc """
  Loading associated records.
  Note: Associations are covered in detail in a later lesson.
  """

  alias MyApp.{Repo, User}
  import Ecto.Query

  # Assuming User has many :posts association
  def preload_examples do
    # Preload after fetching
    user = Repo.get!(User, 1)
    user_with_posts = Repo.preload(user, :posts)

    # Preload multiple associations
    user_with_all = Repo.preload(user, [:posts, :comments])

    # Nested preloads
    user_nested = Repo.preload(user, posts: :comments)

    # Preload in query
    query = from u in User,
      where: u.active == true,
      preload: [:posts]

    users_with_posts = Repo.all(query)

    # Preload with custom query
    recent_posts_query = from p in "posts",
      where: p.inserted_at > ago(7, "day"),
      order_by: [desc: p.inserted_at]

    user_recent = Repo.preload(user, posts: recent_posts_query)

    {user_with_posts, user_with_all, user_nested, users_with_posts, user_recent}
  end
end

# ==============================================================================
# EXERCISES
# ==============================================================================

defmodule Exercises do
  @moduledoc """
  Practice exercises for Repo operations.
  """

  alias MyApp.{Repo, User}
  import Ecto.Query

  # ---------------------------------------------------------------------------
  # Exercise 1: Basic Insert
  # ---------------------------------------------------------------------------
  # Write a function that creates a new user with the given name and email.
  # Return {:ok, user} on success or {:error, changeset} on failure.

  def create_user(name, email) do
    # Your code here
    # Hint: Create a changeset and use Repo.insert/1
  end

  # ---------------------------------------------------------------------------
  # Exercise 2: Find or Create
  # ---------------------------------------------------------------------------
  # Write a function that finds a user by email, or creates one if not found.
  # Return the existing or newly created user.

  def find_or_create_user(name, email) do
    # Your code here
    # Hint: Use Repo.get_by/2, then Repo.insert/1 if nil
  end

  # ---------------------------------------------------------------------------
  # Exercise 3: Bulk Update
  # ---------------------------------------------------------------------------
  # Write a function that deactivates all users who are older than a given age.
  # Return the count of affected users.

  def deactivate_users_older_than(age) do
    # Your code here
    # Hint: Use Repo.update_all/3 with a query
  end

  # ---------------------------------------------------------------------------
  # Exercise 4: Safe Delete
  # ---------------------------------------------------------------------------
  # Write a function that deletes a user by ID, but only if they are inactive.
  # Return {:ok, user} if deleted, {:error, :not_found} if not found,
  # or {:error, :still_active} if the user is still active.

  def delete_inactive_user(user_id) do
    # Your code here
    # Hint: Get the user first, check active status, then delete
  end

  # ---------------------------------------------------------------------------
  # Exercise 5: Statistics
  # ---------------------------------------------------------------------------
  # Write a function that returns statistics about users:
  # - Total count
  # - Active count
  # - Average age
  # - Oldest user's age

  def user_statistics do
    # Your code here
    # Hint: Use Repo.aggregate/3 and /4
  end

  # ---------------------------------------------------------------------------
  # Exercise 6: Transaction
  # ---------------------------------------------------------------------------
  # Write a function that creates two users in a transaction.
  # If either insert fails, both should be rolled back.
  # Return {:ok, {user1, user2}} or {:error, reason}.

  def create_user_pair(name1, email1, name2, email2) do
    # Your code here
    # Hint: Use Repo.transaction/1 or Ecto.Multi
  end

  # ---------------------------------------------------------------------------
  # EXERCISE SOLUTIONS
  # ---------------------------------------------------------------------------

  def solutions do
    """
    Exercise 1 Solution:
    --------------------
    def create_user(name, email) do
      %User{}
      |> User.changeset(%{name: name, email: email})
      |> Repo.insert()
    end

    Exercise 2 Solution:
    --------------------
    def find_or_create_user(name, email) do
      case Repo.get_by(User, email: email) do
        nil ->
          %User{}
          |> User.changeset(%{name: name, email: email})
          |> Repo.insert!()
        user ->
          user
      end
    end

    Exercise 3 Solution:
    --------------------
    def deactivate_users_older_than(age) do
      query = from u in User, where: u.age > ^age
      {count, _} = Repo.update_all(query, set: [active: false])
      count
    end

    Exercise 4 Solution:
    --------------------
    def delete_inactive_user(user_id) do
      case Repo.get(User, user_id) do
        nil ->
          {:error, :not_found}
        %User{active: true} ->
          {:error, :still_active}
        user ->
          Repo.delete(user)
      end
    end

    Exercise 5 Solution:
    --------------------
    def user_statistics do
      active_query = from u in User, where: u.active == true

      %{
        total_count: Repo.aggregate(User, :count),
        active_count: Repo.aggregate(active_query, :count),
        average_age: Repo.aggregate(User, :avg, :age),
        oldest_age: Repo.aggregate(User, :max, :age)
      }
    end

    Exercise 6 Solution:
    --------------------
    def create_user_pair(name1, email1, name2, email2) do
      alias Ecto.Multi

      Multi.new()
      |> Multi.insert(:user1, User.changeset(%User{}, %{name: name1, email: email1}))
      |> Multi.insert(:user2, User.changeset(%User{}, %{name: name2, email: email2}))
      |> Repo.transaction()
      |> case do
        {:ok, %{user1: user1, user2: user2}} ->
          {:ok, {user1, user2}}
        {:error, _failed_op, changeset, _changes} ->
          {:error, changeset.errors}
      end
    end
    """
  end
end

# ==============================================================================
# KEY TAKEAWAYS
# ==============================================================================
#
# 1. INSERT OPERATIONS:
#    - insert/1: Returns {:ok, struct} or {:error, changeset}
#    - insert!/1: Returns struct or raises exception
#    - insert_all/3: Bulk insert, returns {count, result}
#
# 2. UPDATE OPERATIONS:
#    - update/1: Requires a changeset, returns {:ok, struct} or {:error, changeset}
#    - update!/1: Returns struct or raises
#    - update_all/3: Bulk update with query
#
# 3. DELETE OPERATIONS:
#    - delete/1: Returns {:ok, struct} or {:error, changeset}
#    - delete!/1: Returns struct or raises
#    - delete_all/2: Bulk delete with query
#
# 4. QUERY OPERATIONS:
#    - get/2: Fetch by primary key, returns nil if not found
#    - get_by/2: Fetch by fields, returns nil if not found
#    - all/1: Fetch all matching records
#    - one/1: Fetch exactly one record
#    - exists?/1: Check if any records match
#
# 5. BANG VERSIONS (!):
#    - Raise exceptions instead of returning error tuples
#    - Use when you expect the operation to succeed
#    - Useful in pipelines and transactions
#
# 6. TRANSACTIONS:
#    - Use Repo.transaction/1 for simple transactions
#    - Use Ecto.Multi for complex, composable transactions
#    - Transactions automatically rollback on exceptions
#
# ==============================================================================
# NEXT LESSON: 03_schemas.exs - Learn about Ecto Schemas
# ==============================================================================
