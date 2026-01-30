# ==============================================================================
# Lesson 19: Transactions in Ecto
# ==============================================================================
#
# Database transactions ensure that a series of operations either all succeed
# or all fail together (atomicity). This is crucial for maintaining data
# integrity when multiple related changes need to be made.
#
# In this lesson, you will learn:
# - What transactions are and why they matter
# - Using Repo.transaction/1 and Repo.transaction/2
# - Rolling back transactions
# - Transaction isolation levels
# - Nested transactions and savepoints
# - Best practices for transaction handling
#
# ==============================================================================

# ==============================================================================
# Section 1: Understanding Transactions
# ==============================================================================
#
# ACID Properties:
# - Atomicity: All operations succeed or all fail
# - Consistency: Database remains in a valid state
# - Isolation: Concurrent transactions don't interfere
# - Durability: Committed changes are permanent
#
# When to use transactions:
# - Multiple related database operations
# - Operations that must succeed or fail together
# - When updating related tables
# - Financial operations
# - Any operation where partial completion is problematic

# ==============================================================================
# Section 2: Basic Repo.transaction/1
# ==============================================================================

defmodule BasicTransactions do
  @moduledoc """
  Basic transaction usage with Repo.transaction/1.
  """

  alias MyApp.Repo
  alias MyApp.Accounts.{User, Profile}
  alias MyApp.Billing.{Order, OrderItem}

  # ---------------------------------------------------------------------------
  # Basic transaction with anonymous function
  # ---------------------------------------------------------------------------

  def create_user_with_profile(user_attrs, profile_attrs) do
    Repo.transaction(fn ->
      # Insert user
      user =
        %User{}
        |> User.changeset(user_attrs)
        |> Repo.insert!()

      # Insert profile linked to user
      profile =
        %Profile{}
        |> Profile.changeset(Map.put(profile_attrs, :user_id, user.id))
        |> Repo.insert!()

      # Return the results
      {user, profile}
    end)
    # Returns {:ok, {user, profile}} on success
    # Returns {:error, reason} on failure
  end

  # ---------------------------------------------------------------------------
  # Handling errors in transactions
  # ---------------------------------------------------------------------------

  def create_user_with_error_handling(user_attrs, profile_attrs) do
    Repo.transaction(fn ->
      # Using non-bang version for more control
      case %User{} |> User.changeset(user_attrs) |> Repo.insert() do
        {:ok, user} ->
          case create_profile_for_user(user, profile_attrs) do
            {:ok, profile} ->
              {user, profile}
            {:error, changeset} ->
              # Explicitly rollback with error info
              Repo.rollback({:profile_error, changeset})
          end
        {:error, changeset} ->
          Repo.rollback({:user_error, changeset})
      end
    end)
    # Returns {:error, {:user_error, changeset}} or
    # {:error, {:profile_error, changeset}} on failure
  end

  defp create_profile_for_user(user, attrs) do
    %Profile{}
    |> Profile.changeset(Map.put(attrs, :user_id, user.id))
    |> Repo.insert()
  end

  # ---------------------------------------------------------------------------
  # Transaction with multiple operations
  # ---------------------------------------------------------------------------

  def transfer_money(from_account_id, to_account_id, amount) do
    Repo.transaction(fn ->
      # Lock both accounts to prevent concurrent modifications
      from_account = Repo.get!(Account, from_account_id, lock: "FOR UPDATE")
      to_account = Repo.get!(Account, to_account_id, lock: "FOR UPDATE")

      # Check sufficient balance
      if from_account.balance < amount do
        Repo.rollback(:insufficient_funds)
      end

      # Deduct from source
      from_account
      |> Ecto.Changeset.change(balance: from_account.balance - amount)
      |> Repo.update!()

      # Add to destination
      to_account
      |> Ecto.Changeset.change(balance: to_account.balance + amount)
      |> Repo.update!()

      # Record the transfer
      %Transfer{}
      |> Transfer.changeset(%{
        from_account_id: from_account_id,
        to_account_id: to_account_id,
        amount: amount,
        transferred_at: DateTime.utc_now()
      })
      |> Repo.insert!()
    end)
  end
end

# ==============================================================================
# Section 3: Repo.rollback
# ==============================================================================

defmodule RollbackExamples do
  @moduledoc """
  Using Repo.rollback/1 to abort transactions.
  """

  alias MyApp.Repo

  # ---------------------------------------------------------------------------
  # Explicit rollback with reason
  # ---------------------------------------------------------------------------

  def create_order_with_validation(order_attrs, items) do
    Repo.transaction(fn ->
      # Create order
      order = create_order!(order_attrs)

      # Validate total item count
      if length(items) > 100 do
        Repo.rollback(:too_many_items)
      end

      # Create order items
      order_items = Enum.map(items, fn item_attrs ->
        create_order_item!(order, item_attrs)
      end)

      # Calculate and validate total
      total = Enum.reduce(order_items, 0, &(&1.price * &1.quantity + &2))

      if total > 10_000 do
        Repo.rollback({:order_too_large, total})
      end

      # Update order with total
      order
      |> Ecto.Changeset.change(total: total)
      |> Repo.update!()
    end)
  end

  defp create_order!(attrs), do: %Order{} |> Order.changeset(attrs) |> Repo.insert!()
  defp create_order_item!(order, attrs) do
    %OrderItem{}
    |> OrderItem.changeset(Map.put(attrs, :order_id, order.id))
    |> Repo.insert!()
  end

  # ---------------------------------------------------------------------------
  # Rollback with changeset error
  # ---------------------------------------------------------------------------

  def create_with_changeset_rollback(attrs) do
    Repo.transaction(fn ->
      changeset = %SomeSchema{} |> SomeSchema.changeset(attrs)

      if changeset.valid? do
        Repo.insert!(changeset)
      else
        Repo.rollback(changeset)
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Pattern matching rollback results
  # ---------------------------------------------------------------------------

  def handle_transaction_result(result) do
    case result do
      {:ok, value} ->
        # Transaction succeeded
        {:ok, value}

      {:error, :insufficient_funds} ->
        # Specific known error
        {:error, "Not enough money in account"}

      {:error, {:validation_failed, field}} ->
        # Error with context
        {:error, "Validation failed for #{field}"}

      {:error, %Ecto.Changeset{} = changeset} ->
        # Changeset error
        {:error, format_changeset_errors(changeset)}

      {:error, reason} ->
        # Unknown error
        {:error, "Transaction failed: #{inspect(reason)}"}
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end

# ==============================================================================
# Section 4: Transaction Options
# ==============================================================================

defmodule TransactionOptions do
  @moduledoc """
  Using Repo.transaction/2 with options.
  """

  alias MyApp.Repo

  # ---------------------------------------------------------------------------
  # Timeout option
  # ---------------------------------------------------------------------------

  def long_running_transaction(data) do
    # Default timeout is 15 seconds
    # Increase for long operations
    Repo.transaction(
      fn ->
        # Long running operation
        process_large_dataset(data)
      end,
      timeout: 60_000  # 60 seconds
    )
  end

  defp process_large_dataset(data), do: data

  # ---------------------------------------------------------------------------
  # Log option
  # ---------------------------------------------------------------------------

  def transaction_with_logging(func) do
    Repo.transaction(
      func,
      log: :info  # or :debug, false
    )
  end

  # ---------------------------------------------------------------------------
  # Sandbox option (for testing)
  # ---------------------------------------------------------------------------

  def transaction_in_sandbox(func) do
    # Useful when running concurrent tests
    Repo.transaction(
      func,
      sandbox: true
    )
  end
end

# ==============================================================================
# Section 5: Transaction Isolation Levels
# ==============================================================================

defmodule IsolationLevels do
  @moduledoc """
  Understanding transaction isolation levels.

  Isolation levels control how transactions interact with concurrent operations.
  Higher isolation = more protection, but potentially lower performance.
  """

  alias MyApp.Repo

  # ---------------------------------------------------------------------------
  # Isolation Level Overview
  # ---------------------------------------------------------------------------

  @doc """
  Isolation levels from least to most strict:

  1. READ UNCOMMITTED
     - Can see uncommitted changes from other transactions
     - Allows "dirty reads"
     - Rarely used

  2. READ COMMITTED (PostgreSQL default)
     - Only sees committed changes
     - May see different data if re-reading (non-repeatable reads)
     - May see new rows appear (phantom reads)

  3. REPEATABLE READ
     - Consistent view of data throughout transaction
     - Prevents non-repeatable reads
     - May still have phantom reads in some databases

  4. SERIALIZABLE
     - Transactions appear to execute sequentially
     - Highest isolation, prevents all anomalies
     - May need to retry on serialization failures
  """

  # ---------------------------------------------------------------------------
  # Setting isolation level in PostgreSQL
  # ---------------------------------------------------------------------------

  def serializable_transaction(func) do
    # Set isolation level before transaction work
    Repo.transaction(fn ->
      # Execute raw SQL to set isolation level
      Repo.query!("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")
      func.()
    end)
  end

  # Alternative using Ecto SQL
  def with_isolation_level(level, func) when level in [:serializable, :repeatable_read, :read_committed] do
    isolation = level |> to_string() |> String.upcase() |> String.replace("_", " ")

    Repo.transaction(fn ->
      Repo.query!("SET TRANSACTION ISOLATION LEVEL #{isolation}")
      func.()
    end)
  end

  # ---------------------------------------------------------------------------
  # Handling serialization failures
  # ---------------------------------------------------------------------------

  def serializable_with_retry(func, max_retries \\ 3) do
    do_serializable_retry(func, max_retries, 0)
  end

  defp do_serializable_retry(func, max_retries, attempt) when attempt < max_retries do
    result = Repo.transaction(fn ->
      Repo.query!("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")
      func.()
    end)

    case result do
      {:ok, value} ->
        {:ok, value}

      {:error, %Postgrex.Error{postgres: %{code: :serialization_failure}}} ->
        # Retry after brief delay
        Process.sleep(100 * (attempt + 1))
        do_serializable_retry(func, max_retries, attempt + 1)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp do_serializable_retry(_func, max_retries, _attempt) do
    {:error, :max_retries_exceeded}
  end

  # ---------------------------------------------------------------------------
  # Row locking for concurrency control
  # ---------------------------------------------------------------------------

  def with_row_lock(schema, id, func) do
    Repo.transaction(fn ->
      # Lock the specific row for update
      record = Repo.get!(schema, id, lock: "FOR UPDATE")
      func.(record)
    end)
  end

  def with_row_lock_nowait(schema, id, func) do
    Repo.transaction(fn ->
      # Fail immediately if row is locked
      try do
        record = Repo.get!(schema, id, lock: "FOR UPDATE NOWAIT")
        func.(record)
      rescue
        Postgrex.Error ->
          Repo.rollback(:row_locked)
      end
    end)
  end

  def with_row_lock_skip(schema, query, func) do
    import Ecto.Query

    Repo.transaction(fn ->
      # Skip locked rows (useful for job queues)
      records =
        from(s in schema, where: ^query, lock: "FOR UPDATE SKIP LOCKED")
        |> Repo.all()

      func.(records)
    end)
  end
end

# ==============================================================================
# Section 6: Nested Transactions and Savepoints
# ==============================================================================

defmodule NestedTransactions do
  @moduledoc """
  Handling nested transactions with savepoints.

  Ecto uses savepoints for nested transactions. When you call
  Repo.transaction inside another transaction, it creates a savepoint.
  """

  alias MyApp.Repo

  # ---------------------------------------------------------------------------
  # Automatic savepoints (nested transactions)
  # ---------------------------------------------------------------------------

  def outer_transaction do
    Repo.transaction(fn ->
      # Create first record
      first = create_first_record!()

      # This creates a savepoint
      result = Repo.transaction(fn ->
        create_second_record!()
      end)

      case result do
        {:ok, second} ->
          # Inner transaction succeeded
          {first, second}
        {:error, _reason} ->
          # Inner transaction failed, but outer can continue
          # or choose to rollback entirely
          Repo.rollback(:inner_failed)
      end
    end)
  end

  defp create_first_record!, do: %{}
  defp create_second_record!, do: %{}

  # ---------------------------------------------------------------------------
  # Optional nested operations
  # ---------------------------------------------------------------------------

  def create_order_with_optional_notification(order_attrs, user) do
    Repo.transaction(fn ->
      # Main operation - must succeed
      order = create_order!(order_attrs)

      # Optional operation - failure shouldn't rollback order
      Repo.transaction(fn ->
        create_notification!(user, order)
      end)
      |> case do
        {:ok, _notification} ->
          :notification_sent
        {:error, _reason} ->
          # Log error but continue
          Logger.warn("Failed to create notification")
          :notification_failed
      end

      order
    end)
  end

  defp create_order!(attrs), do: attrs
  defp create_notification!(_user, _order), do: :ok

  # ---------------------------------------------------------------------------
  # Explicit savepoints
  # ---------------------------------------------------------------------------

  def with_manual_savepoint(func, savepoint_name) do
    Repo.transaction(fn ->
      # Create savepoint
      Repo.query!("SAVEPOINT #{savepoint_name}")

      try do
        result = func.()
        # Release savepoint on success
        Repo.query!("RELEASE SAVEPOINT #{savepoint_name}")
        result
      rescue
        e ->
          # Rollback to savepoint on error
          Repo.query!("ROLLBACK TO SAVEPOINT #{savepoint_name}")
          reraise e, __STACKTRACE__
      end
    end)
  end
end

# ==============================================================================
# Section 7: Transaction Patterns
# ==============================================================================

defmodule TransactionPatterns do
  @moduledoc """
  Common patterns for working with transactions.
  """

  alias MyApp.Repo
  import Ecto.Query

  # ---------------------------------------------------------------------------
  # Pattern 1: With-pattern for cleaner transaction handling
  # ---------------------------------------------------------------------------

  def create_user_and_profile(user_attrs, profile_attrs) do
    Repo.transaction(fn ->
      with {:ok, user} <- create_user(user_attrs),
           {:ok, profile} <- create_profile(user, profile_attrs) do
        {user, profile}
      else
        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  defp create_user(attrs) do
    %User{} |> User.changeset(attrs) |> Repo.insert()
  end

  defp create_profile(user, attrs) do
    %Profile{}
    |> Profile.changeset(Map.put(attrs, :user_id, user.id))
    |> Repo.insert()
  end

  # ---------------------------------------------------------------------------
  # Pattern 2: Batch operations in transaction
  # ---------------------------------------------------------------------------

  def create_many_in_transaction(items) do
    Repo.transaction(fn ->
      Enum.map(items, fn item_attrs ->
        %Item{}
        |> Item.changeset(item_attrs)
        |> Repo.insert!()
      end)
    end)
  end

  # ---------------------------------------------------------------------------
  # Pattern 3: Read-Modify-Write with locking
  # ---------------------------------------------------------------------------

  def increment_counter(record_id) do
    Repo.transaction(fn ->
      # Lock and read
      record = Repo.get!(Counter, record_id, lock: "FOR UPDATE")

      # Modify and write
      record
      |> Ecto.Changeset.change(count: record.count + 1)
      |> Repo.update!()
    end)
  end

  # ---------------------------------------------------------------------------
  # Pattern 4: Idempotent transactions
  # ---------------------------------------------------------------------------

  def process_payment_idempotent(payment_id, amount) do
    Repo.transaction(fn ->
      # Check if already processed
      case Repo.get_by(ProcessedPayment, payment_id: payment_id) do
        nil ->
          # Not processed yet
          process_new_payment(payment_id, amount)

        existing ->
          # Already processed - return existing result
          existing
      end
    end)
  end

  defp process_new_payment(payment_id, amount) do
    # Do the actual processing
    result = %ProcessedPayment{}
    |> ProcessedPayment.changeset(%{payment_id: payment_id, amount: amount})
    |> Repo.insert!()

    result
  end

  # ---------------------------------------------------------------------------
  # Pattern 5: Conditional transaction
  # ---------------------------------------------------------------------------

  def maybe_in_transaction(should_use_transaction, func) do
    if should_use_transaction do
      Repo.transaction(func)
    else
      {:ok, func.()}
    end
  end
end

# ==============================================================================
# Section 8: Best Practices
# ==============================================================================

best_practices = """
Transaction Best Practices:

1. Keep transactions short
   - Long transactions hold locks and block other operations
   - Do expensive computations outside the transaction

2. Handle all error cases
   - Use pattern matching on transaction results
   - Provide meaningful error reasons with Repo.rollback

3. Don't swallow errors
   - Always propagate or handle errors explicitly
   - Log unexpected errors

4. Use appropriate isolation level
   - READ COMMITTED is usually sufficient
   - Use SERIALIZABLE for critical financial operations
   - Be prepared to retry on serialization failures

5. Use row locking for concurrent updates
   - SELECT FOR UPDATE prevents race conditions
   - Use NOWAIT or SKIP LOCKED for non-blocking operations

6. Be careful with external calls
   - Don't make HTTP calls inside transactions
   - Don't send emails inside transactions
   - These can't be rolled back!

7. Test transaction behavior
   - Test rollback scenarios
   - Test concurrent access
   - Test timeout handling

8. Consider using Ecto.Multi
   - For complex multi-step operations
   - Better organization and error handling
   - See next lesson!
"""

IO.puts(best_practices)

# ==============================================================================
# Exercises
# ==============================================================================

defmodule Exercises do
  @moduledoc """
  Practice exercises for transactions.
  """

  # Exercise 1: Basic transaction
  #
  # Write a function that creates an Order and its OrderItems in a transaction.
  # If any item fails validation, the entire operation should rollback.
  # Return {:ok, order} or {:error, reason}
  #
  # Your solution:
  def create_order_with_items(order_attrs, items) do
    # TODO: Implement
  end

  # Exercise 2: Transaction with rollback
  #
  # Write a function that transfers credits between two users.
  # Validate that:
  # - Source user has enough credits
  # - Transfer amount is positive
  # - Both users exist
  # Return appropriate error reasons on failure.
  #
  # Your solution:
  def transfer_credits(from_user_id, to_user_id, amount) do
    # TODO: Implement
  end

  # Exercise 3: Handling concurrent access
  #
  # Write a function that reserves inventory for an order.
  # Use row locking to prevent overselling.
  # Return {:ok, reservation} or {:error, :insufficient_stock}
  #
  # Your solution:
  def reserve_inventory(product_id, quantity) do
    # TODO: Implement
  end

  # Exercise 4: Transaction with retry
  #
  # Write a function that wraps a transaction with retry logic.
  # It should retry up to N times on specific errors
  # (e.g., serialization failure, deadlock).
  #
  # Your solution:
  def with_retry(func, max_retries \\ 3) do
    # TODO: Implement
  end

  # Exercise 5: Nested transactions
  #
  # Write a function that creates a user with multiple optional
  # associated records (profile, preferences, notification_settings).
  # Each association creation should be in its own nested transaction.
  # The main user creation should succeed even if optional records fail.
  #
  # Your solution:
  def create_user_with_optional_records(user_attrs, opts \\ []) do
    # TODO: Implement
  end

  # Exercise 6: Idempotent operation
  #
  # Write an idempotent function that processes a webhook event.
  # If the event has already been processed, return the existing result.
  # Use a processed_events table to track processed event IDs.
  #
  # Your solution:
  def process_webhook_event(event_id, payload) do
    # TODO: Implement
  end
end

# ==============================================================================
# Exercise Solutions
# ==============================================================================

defmodule ExerciseSolutions do
  @moduledoc false

  alias MyApp.Repo
  import Ecto.Query

  # Solution 1
  def create_order_with_items(order_attrs, items) do
    Repo.transaction(fn ->
      # Create order
      order = %Order{}
      |> Order.changeset(order_attrs)
      |> Repo.insert!()

      # Create all items
      order_items = Enum.map(items, fn item_attrs ->
        %OrderItem{}
        |> OrderItem.changeset(Map.put(item_attrs, :order_id, order.id))
        |> Repo.insert!()
      end)

      # Update order total
      total = Enum.reduce(order_items, Decimal.new(0), fn item, acc ->
        Decimal.add(acc, Decimal.mult(item.price, item.quantity))
      end)

      order
      |> Ecto.Changeset.change(total: total)
      |> Repo.update!()
    end)
  end

  # Solution 2
  def transfer_credits(from_user_id, to_user_id, amount) do
    Repo.transaction(fn ->
      # Validate amount
      if amount <= 0 do
        Repo.rollback(:invalid_amount)
      end

      # Lock and fetch users
      from_user = case Repo.get(User, from_user_id, lock: "FOR UPDATE") do
        nil -> Repo.rollback(:source_user_not_found)
        user -> user
      end

      to_user = case Repo.get(User, to_user_id, lock: "FOR UPDATE") do
        nil -> Repo.rollback(:target_user_not_found)
        user -> user
      end

      # Check balance
      if from_user.credits < amount do
        Repo.rollback(:insufficient_credits)
      end

      # Perform transfer
      from_user
      |> Ecto.Changeset.change(credits: from_user.credits - amount)
      |> Repo.update!()

      to_user
      |> Ecto.Changeset.change(credits: to_user.credits + amount)
      |> Repo.update!()

      %{from: from_user_id, to: to_user_id, amount: amount}
    end)
  end

  # Solution 3
  def reserve_inventory(product_id, quantity) do
    Repo.transaction(fn ->
      # Lock and fetch product
      product = Repo.get!(Product, product_id, lock: "FOR UPDATE")

      # Check stock
      if product.stock < quantity do
        Repo.rollback(:insufficient_stock)
      end

      # Reduce stock
      product
      |> Ecto.Changeset.change(stock: product.stock - quantity)
      |> Repo.update!()

      # Create reservation
      %Reservation{}
      |> Reservation.changeset(%{
        product_id: product_id,
        quantity: quantity,
        reserved_at: DateTime.utc_now()
      })
      |> Repo.insert!()
    end)
  end

  # Solution 4
  def with_retry(func, max_retries \\ 3) do
    do_retry(func, max_retries, 0)
  end

  defp do_retry(func, max_retries, attempt) when attempt < max_retries do
    case Repo.transaction(func) do
      {:ok, result} ->
        {:ok, result}

      {:error, %Postgrex.Error{postgres: %{code: code}}}
      when code in [:serialization_failure, :deadlock_detected] ->
        Process.sleep(50 * :math.pow(2, attempt) |> round())
        do_retry(func, max_retries, attempt + 1)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp do_retry(_func, _max_retries, _attempt) do
    {:error, :max_retries_exceeded}
  end

  # Solution 5
  def create_user_with_optional_records(user_attrs, opts \\ []) do
    Repo.transaction(fn ->
      # Main user creation - must succeed
      user = %User{}
      |> User.changeset(user_attrs)
      |> Repo.insert!()

      # Optional profile
      if profile_attrs = opts[:profile] do
        Repo.transaction(fn ->
          %Profile{}
          |> Profile.changeset(Map.put(profile_attrs, :user_id, user.id))
          |> Repo.insert!()
        end)
      end

      # Optional preferences
      if pref_attrs = opts[:preferences] do
        Repo.transaction(fn ->
          %Preferences{}
          |> Preferences.changeset(Map.put(pref_attrs, :user_id, user.id))
          |> Repo.insert!()
        end)
      end

      # Optional notification settings
      if notif_attrs = opts[:notification_settings] do
        Repo.transaction(fn ->
          %NotificationSettings{}
          |> NotificationSettings.changeset(Map.put(notif_attrs, :user_id, user.id))
          |> Repo.insert!()
        end)
      end

      user
    end)
  end

  # Solution 6
  def process_webhook_event(event_id, payload) do
    Repo.transaction(fn ->
      # Check if already processed
      case Repo.get_by(ProcessedEvent, event_id: event_id) do
        %ProcessedEvent{} = existing ->
          # Already processed - return existing
          {:already_processed, existing.result}

        nil ->
          # Process the event
          result = do_process_event(payload)

          # Record as processed
          %ProcessedEvent{}
          |> ProcessedEvent.changeset(%{
            event_id: event_id,
            result: result,
            processed_at: DateTime.utc_now()
          })
          |> Repo.insert!()

          {:processed, result}
      end
    end)
  end

  defp do_process_event(payload) do
    # Actual event processing logic
    payload
  end
end

# ==============================================================================
# Key Takeaways
# ==============================================================================
#
# 1. Transactions ensure atomicity - all operations succeed or fail together
#
# 2. Use Repo.transaction/1 with an anonymous function for basic transactions
#
# 3. Use Repo.rollback/1 to abort a transaction with a specific reason
#
# 4. Transaction results are always {:ok, result} or {:error, reason}
#
# 5. Understand isolation levels:
#    - READ COMMITTED for most cases
#    - SERIALIZABLE for critical operations (with retry logic)
#
# 6. Use row locking (FOR UPDATE) to prevent race conditions
#
# 7. Nested transactions create savepoints automatically
#
# 8. Keep transactions short and avoid external calls inside them
#
# 9. Consider Ecto.Multi for complex multi-step operations (next lesson)
#
# ==============================================================================
