# ============================================================================
# Lesson 7: Ecto.Adapters.SQL.Sandbox
# ============================================================================
#
# Master database testing with Ecto's SQL Sandbox. Learn how to write isolated,
# concurrent database tests that never leak data between test cases.
#
# Key Topics:
# - SQL Sandbox fundamentals
# - DataCase module setup
# - Async vs sync tests
# - Ownership and process isolation
# - Testing with multiple connections
#
# Prerequisites:
# - Understanding of Ecto basics (Section 5)
# - ExUnit fundamentals (Lessons 1-3)
# - Process basics (Section 4)

# ============================================================================
# Section 1: Understanding the SQL Sandbox
# ============================================================================

defmodule EctoSandboxIntro do
  @moduledoc """
  The Ecto SQL Sandbox solves a critical testing problem: how do you run
  database tests in isolation without them interfering with each other?

  ## The Problem

  Without isolation, tests that modify the database can:
  - Leave behind data that affects other tests
  - Create race conditions in concurrent tests
  - Produce inconsistent results on different runs

  ## The Solution: SQL Sandbox

  The sandbox wraps each test in a database transaction that is rolled back
  at the end of the test. This means:

  1. Each test starts with a clean database
  2. Changes made during a test are isolated
  3. Tests can run concurrently without conflicts
  4. No manual cleanup is needed

  ## How It Works

  ```
  ┌──────────────────────────────────────────────────────────────┐
  │                    SQL Sandbox Flow                          │
  │                                                              │
  │  Test Process         Sandbox              Database          │
  │       │                  │                    │              │
  │       │──checkout()────►│                    │              │
  │       │                  │──BEGIN TRANSACTION─►              │
  │       │                  │                    │              │
  │       │──insert()──────►│────INSERT─────────►│              │
  │       │                  │                    │              │
  │       │──query()───────►│────SELECT─────────►│              │
  │       │                  │                    │              │
  │       │  [test ends]     │                    │              │
  │       │                  │──ROLLBACK──────────►              │
  │       │                  │                    │              │
  │       ▼                  ▼                    ▼              │
  └──────────────────────────────────────────────────────────────┘
  ```
  """
end

# ============================================================================
# Section 2: Configuring the SQL Sandbox
# ============================================================================

defmodule SandboxConfiguration do
  @moduledoc """
  How to configure the SQL Sandbox for your test environment.
  """

  # In config/test.exs, you configure the pool:
  @test_config """
  # config/test.exs

  import Config

  config :my_app, MyApp.Repo,
    username: "postgres",
    password: "postgres",
    hostname: "localhost",
    database: "my_app_test\#{System.get_env("MIX_TEST_PARTITION")}",
    pool: Ecto.Adapters.SQL.Sandbox,  # <-- Key configuration!
    pool_size: 10

  # Print only warnings and errors during test
  config :logger, level: :warning
  """

  # In test/test_helper.exs, you set the sandbox mode:
  @test_helper """
  # test/test_helper.exs

  ExUnit.start()

  # Set the sandbox mode before running tests
  Ecto.Adapters.SQL.Sandbox.mode(MyApp.Repo, :manual)
  """

  # The sandbox supports three modes:
  @sandbox_modes """
  Sandbox Modes:

  1. :manual (default for tests)
     - Each test must explicitly checkout a connection
     - Most control, most isolation
     - Required for async tests

  2. :shared
     - All processes share the same connection
     - Useful for integration tests
     - Cannot run async

  3. :auto
     - Not typically used in tests
     - Normal pool behavior
  """
end

# ============================================================================
# Section 3: The DataCase Module
# ============================================================================

defmodule DataCaseExample do
  @moduledoc """
  DataCase is a test case template for tests that need database access.
  Phoenix generates this for you, but understanding it is crucial.
  """

  # Typical DataCase implementation
  @data_case_module """
  # test/support/data_case.ex

  defmodule MyApp.DataCase do
    @moduledoc \"\"\"
    This module defines the setup for tests requiring
    access to the application's data layer.

    You may define functions here to be used as helpers in
    your tests.

    Finally, if the test case interacts with the database,
    we enable the SQL sandbox, so changes done to the database
    are reverted at the end of every test.
    \"\"\"

    use ExUnit.CaseTemplate

    using do
      quote do
        alias MyApp.Repo

        import Ecto
        import Ecto.Changeset
        import Ecto.Query
        import MyApp.DataCase
      end
    end

    setup tags do
      # Set up the sandbox
      pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MyApp.Repo, shared: not tags[:async])

      # Clean up when the test finishes
      on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

      :ok
    end

    @doc \"\"\"
    A helper that transforms changeset errors into a map of messages.

        assert {:error, changeset} = Accounts.create_user(%{password: "short"})
        assert "should be at least 12 character(s)" in errors_on(changeset).password
        assert %{password: ["should be at least 12 character(s)"]} = errors_on(changeset)
    \"\"\"
    def errors_on(changeset) do
      Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
        Regex.replace(~r"%{(\\w+)}", message, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)
    end
  end
  """
end

# ============================================================================
# Section 4: Using DataCase in Tests
# ============================================================================

defmodule DataCaseUsage do
  @moduledoc """
  Examples of using DataCase in your tests.
  """

  # Basic usage with async: true
  @basic_async_test """
  # test/my_app/accounts_test.exs

  defmodule MyApp.AccountsTest do
    use MyApp.DataCase, async: true

    alias MyApp.Accounts
    alias MyApp.Accounts.User

    describe "users" do
      @valid_attrs %{
        email: "test@example.com",
        name: "Test User",
        password: "password123456"
      }
      @invalid_attrs %{email: nil, name: nil, password: nil}

      test "create_user/1 with valid data creates a user" do
        assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
        assert user.email == "test@example.com"
        assert user.name == "Test User"
        # Password should be hashed, not stored plain
        refute user.password_hash == "password123456"
      end

      test "create_user/1 with invalid data returns error changeset" do
        assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
      end

      test "list_users/0 returns all users" do
        {:ok, user} = Accounts.create_user(@valid_attrs)
        assert Accounts.list_users() == [user]
      end

      test "get_user!/1 returns the user with given id" do
        {:ok, user} = Accounts.create_user(@valid_attrs)
        assert Accounts.get_user!(user.id) == user
      end

      test "delete_user/1 deletes the user" do
        {:ok, user} = Accounts.create_user(@valid_attrs)
        assert {:ok, %User{}} = Accounts.delete_user(user)
        assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
      end
    end
  end
  """

  # Using setup blocks with DataCase
  @setup_example """
  defmodule MyApp.PostsTest do
    use MyApp.DataCase, async: true

    alias MyApp.Blog
    alias MyApp.Blog.Post
    alias MyApp.Accounts

    # Setup that creates fixture data
    setup do
      {:ok, user} = Accounts.create_user(%{
        email: "author@example.com",
        name: "Author",
        password: "password123456"
      })

      # Return data to be available in tests
      %{user: user}
    end

    describe "posts" do
      test "create_post/2 creates a post for user", %{user: user} do
        attrs = %{title: "Test Post", body: "Content here"}

        assert {:ok, %Post{} = post} = Blog.create_post(user, attrs)
        assert post.title == "Test Post"
        assert post.user_id == user.id
      end

      test "list_posts_by_user/1 returns user's posts", %{user: user} do
        {:ok, post1} = Blog.create_post(user, %{title: "Post 1", body: "Body 1"})
        {:ok, post2} = Blog.create_post(user, %{title: "Post 2", body: "Body 2"})

        posts = Blog.list_posts_by_user(user)

        assert length(posts) == 2
        assert Enum.map(posts, & &1.id) |> Enum.sort() == [post1.id, post2.id] |> Enum.sort()
      end
    end
  end
  """
end

# ============================================================================
# Section 5: Async vs Sync Tests
# ============================================================================

defmodule AsyncVsSyncTests do
  @moduledoc """
  Understanding when to use async tests and when sync tests are needed.
  """

  @comparison """
  ┌─────────────────────────────────────────────────────────────────┐
  │            Async vs Sync Database Tests                        │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │  async: true                        async: false (default)     │
  │  ───────────                        ─────────────────────      │
  │                                                                 │
  │  ✓ Tests run concurrently           ✓ Tests run sequentially   │
  │  ✓ Faster test suite                ✓ Simpler to reason about  │
  │  ✓ Each test owns its connection    ✓ Shared connection pool   │
  │                                                                 │
  │  ✗ Cannot use :shared mode          ✓ Can use :shared mode     │
  │  ✗ External processes need          ✓ External processes work  │
  │    explicit allowance                 automatically             │
  │                                                                 │
  │  Use when:                          Use when:                   │
  │  - Tests are independent            - Tests share global state  │
  │  - No external process calls        - Using GenServers that     │
  │  - Testing contexts/queries           access database           │
  │                                     - Integration tests         │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
  """

  # Async test example
  @async_example """
  defmodule MyApp.Products.CatalogTest do
    # async: true means this module's tests can run
    # concurrently with tests from other async modules
    use MyApp.DataCase, async: true

    alias MyApp.Products.Catalog

    describe "products" do
      test "create_product/1 with valid data" do
        attrs = %{name: "Widget", price: 1999, sku: "WIDGET-001"}

        assert {:ok, product} = Catalog.create_product(attrs)
        assert product.name == "Widget"
      end

      test "create_product/1 validates price is positive" do
        attrs = %{name: "Widget", price: -100, sku: "WIDGET-001"}

        assert {:error, changeset} = Catalog.create_product(attrs)
        assert "must be greater than 0" in errors_on(changeset).price
      end
    end
  end
  """

  # Sync test example (when async won't work)
  @sync_example """
  defmodule MyApp.Workers.NotificationWorkerTest do
    # async: false because this test interacts with
    # a GenServer that makes database calls
    use MyApp.DataCase, async: false

    alias MyApp.Workers.NotificationWorker
    alias MyApp.Accounts

    describe "notify_user/2" do
      setup do
        # Start the notification worker
        start_supervised!(NotificationWorker)

        {:ok, user} = Accounts.create_user(%{
          email: "user@example.com",
          name: "Test",
          password: "password123456"
        })

        %{user: user}
      end

      test "sends notification and records in database", %{user: user} do
        # The worker is a separate process, so it needs
        # access to the same database connection
        assert :ok = NotificationWorker.notify_user(user.id, "Hello!")

        # Give the async worker time to process
        Process.sleep(100)

        # Verify the notification was recorded
        notifications = Accounts.list_notifications(user)
        assert length(notifications) == 1
      end
    end
  end
  """
end

# ============================================================================
# Section 6: Connection Ownership and Allowances
# ============================================================================

defmodule ConnectionOwnership do
  @moduledoc """
  Understanding how the sandbox manages connection ownership
  and how to share connections between processes.
  """

  @ownership_model """
  Connection Ownership Model:

  ┌─────────────────────────────────────────────────────────────────┐
  │                                                                 │
  │   Test Process (Owner)                                         │
  │   ┌─────────────────────┐                                      │
  │   │ checkout() creates  │                                      │
  │   │ owned connection    │                                      │
  │   └─────────┬───────────┘                                      │
  │             │                                                   │
  │             │ allow()                                           │
  │             ▼                                                   │
  │   ┌─────────────────────┐     ┌─────────────────────┐         │
  │   │ Child Process 1    │     │ Child Process 2     │         │
  │   │ (allowed)          │     │ (allowed)           │         │
  │   └─────────────────────┘     └─────────────────────┘         │
  │             │                         │                        │
  │             └────────┬────────────────┘                        │
  │                      │                                          │
  │                      ▼                                          │
  │             ┌─────────────────────┐                            │
  │             │ Shared Connection   │                            │
  │             │ (same transaction)  │                            │
  │             └─────────────────────┘                            │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
  """

  # Manual checkout and ownership
  @manual_checkout """
  defmodule MyApp.ManualSandboxTest do
    use ExUnit.Case

    alias MyApp.Repo
    alias Ecto.Adapters.SQL.Sandbox

    setup do
      # Manually checkout a connection
      :ok = Sandbox.checkout(Repo)

      # The test process now owns a connection
      # All database calls from this process use that connection
      :ok
    end

    test "manual sandbox usage" do
      # This query uses the checked-out connection
      result = Repo.all(MyApp.User)
      assert is_list(result)
    end
  end
  """

  # Allowing other processes
  @allowing_processes """
  defmodule MyApp.AllowanceTest do
    use MyApp.DataCase, async: true

    alias MyApp.{Repo, Accounts}
    alias Ecto.Adapters.SQL.Sandbox

    test "allowing a spawned process to use the connection" do
      # Create some test data
      {:ok, user} = Accounts.create_user(%{
        email: "test@example.com",
        name: "Test",
        password: "password123456"
      })

      # Spawn a process that needs database access
      parent = self()

      task = Task.async(fn ->
        # This process was started by the test, so it's automatically
        # allowed when using DataCase. But for manual cases:
        #
        # Sandbox.allow(Repo, parent, self())

        # Now this process can query the database
        found_user = Accounts.get_user!(user.id)
        send(parent, {:found, found_user})
      end)

      Task.await(task)

      assert_receive {:found, ^user}
    end

    test "allowing a GenServer to use the connection" do
      # For processes not started by the test, you need explicit allow

      # Get the test's connection owner
      owner = Sandbox.get_owner(Repo)

      # Start a GenServer
      {:ok, server} = GenServer.start_link(MyApp.SomeServer, [])

      # Allow the server to use our connection
      Sandbox.allow(Repo, owner, server)

      # Now the server can make database calls that participate
      # in the same transaction as the test
    end
  end
  """

  # Shared mode for integration tests
  @shared_mode """
  defmodule MyApp.IntegrationTest do
    use MyApp.DataCase, async: false

    alias Ecto.Adapters.SQL.Sandbox

    setup do
      # Put sandbox in shared mode for this test
      # All processes will share the same connection
      Sandbox.mode(MyApp.Repo, {:shared, self()})

      on_exit(fn ->
        # Reset to manual mode after the test
        Sandbox.mode(MyApp.Repo, :manual)
      end)

      :ok
    end

    test "integration test with multiple processes" do
      # In shared mode, any process can access the database
      # without explicit allowance. Useful for integration tests
      # that spawn many processes.

      # However, you cannot run async with shared mode!
    end
  end
  """
end

# ============================================================================
# Section 7: Testing with External Processes
# ============================================================================

defmodule ExternalProcessTesting do
  @moduledoc """
  Strategies for testing code that involves external processes
  accessing the database.
  """

  # Phoenix.ConnTest integration
  @phoenix_integration """
  # When testing Phoenix controllers with database access,
  # Phoenix.ConnTest handles sandbox setup automatically.

  defmodule MyAppWeb.UserControllerTest do
    use MyAppWeb.ConnCase

    alias MyApp.Accounts

    describe "POST /users" do
      test "creates user and returns JSON", %{conn: conn} do
        # The conn is set up with proper sandbox access
        conn = post(conn, ~p"/api/users", %{
          user: %{
            email: "new@example.com",
            name: "New User",
            password: "password123456"
          }
        })

        assert %{"id" => id} = json_response(conn, 201)["data"]

        # Verify in database (same transaction)
        assert Accounts.get_user!(id).email == "new@example.com"
      end
    end
  end
  """

  # Testing Oban workers
  @oban_testing """
  defmodule MyApp.Workers.EmailWorkerTest do
    use MyApp.DataCase, async: true

    alias MyApp.Workers.EmailWorker
    alias MyApp.Accounts

    # Oban provides testing utilities that work with the sandbox

    test "processes email job" do
      {:ok, user} = Accounts.create_user(%{
        email: "test@example.com",
        name: "Test",
        password: "password123456"
      })

      # Perform the job inline (doesn't spawn a new process)
      assert :ok = perform_job(EmailWorker, %{user_id: user.id})

      # Verify side effects in the same transaction
      updated_user = Accounts.get_user!(user.id)
      assert updated_user.welcome_email_sent
    end
  end
  """

  # Testing with Cachex or other external stores
  @external_stores """
  defmodule MyApp.CachedQueriesTest do
    use MyApp.DataCase, async: true

    alias MyApp.Products

    setup do
      # Clear cache before each test
      Cachex.clear(:products_cache)
      :ok
    end

    test "caches product lookup" do
      {:ok, product} = Products.create_product(%{
        name: "Cached Item",
        price: 999
      })

      # First call hits database
      assert Products.get_product_cached(product.id) == product

      # Second call should hit cache (but still works in sandbox)
      assert Products.get_product_cached(product.id) == product
    end
  end
  """
end

# ============================================================================
# Section 8: Common Patterns and Best Practices
# ============================================================================

defmodule SandboxBestPractices do
  @moduledoc """
  Best practices for using the SQL Sandbox effectively.
  """

  @patterns """
  Best Practices for SQL Sandbox Testing:

  1. Default to async: true
     - Only use async: false when absolutely necessary
     - Async tests are faster and encourage better isolation

  2. Use fixtures/factories for test data
     - Don't rely on seeds or existing data
     - Each test should set up its own data

  3. Keep tests independent
     - Tests should not depend on each other's data
     - Use setup blocks for common data

  4. Be careful with raw SQL
     - Queries outside Ecto may bypass the sandbox
     - Always use Repo functions when possible

  5. Handle timeouts appropriately
     - Long-running operations may exceed checkout timeout
     - Configure :ownership_timeout if needed

  6. Clean up non-database side effects
     - Files, external APIs, caches need manual cleanup
     - Use on_exit callbacks for cleanup
  """

  # Handling timeouts
  @timeout_handling """
  defmodule MyApp.LongRunningTest do
    use MyApp.DataCase, async: true

    # Increase ownership timeout for slow tests
    @moduletag timeout: 120_000

    setup do
      # Extend checkout ownership timeout
      Ecto.Adapters.SQL.Sandbox.checkout(
        MyApp.Repo,
        ownership_timeout: 120_000
      )

      :ok
    end

    test "processing large dataset" do
      # This test does expensive operations
      # The extended timeout prevents sandbox timeout errors
    end
  end
  """

  # Testing database constraints
  @constraint_testing """
  defmodule MyApp.ConstraintTest do
    use MyApp.DataCase, async: true

    alias MyApp.Accounts

    test "unique email constraint" do
      attrs = %{email: "unique@example.com", name: "User 1", password: "pass123456"}

      {:ok, _user1} = Accounts.create_user(attrs)

      # Second user with same email should fail
      {:error, changeset} = Accounts.create_user(%{attrs | name: "User 2"})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "foreign key constraint" do
      # Try to create a post with non-existent user
      {:error, changeset} = MyApp.Blog.create_post(%{
        title: "Orphan Post",
        body: "No author",
        user_id: 999_999  # Non-existent user
      })

      assert "does not exist" in errors_on(changeset).user_id
    end
  end
  """
end

# ============================================================================
# Section 9: Troubleshooting Common Issues
# ============================================================================

defmodule SandboxTroubleshooting do
  @moduledoc """
  Common issues and their solutions when working with the SQL Sandbox.
  """

  @common_issues """
  Common SQL Sandbox Issues and Solutions:

  ┌─────────────────────────────────────────────────────────────────┐
  │ Issue: DBConnection.OwnershipError                             │
  ├─────────────────────────────────────────────────────────────────┤
  │ Cause: A process tried to use the database without a           │
  │        checked-out connection                                   │
  │                                                                 │
  │ Solutions:                                                      │
  │ 1. Ensure the process is allowed:                              │
  │    Sandbox.allow(Repo, owner_pid, process_pid)                 │
  │                                                                 │
  │ 2. Use shared mode for integration tests:                      │
  │    Sandbox.mode(Repo, {:shared, self()})                       │
  │                                                                 │
  │ 3. For async tests, make sure DataCase is properly configured  │
  └─────────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────────┐
  │ Issue: Tests pass individually but fail together               │
  ├─────────────────────────────────────────────────────────────────┤
  │ Cause: Tests are sharing state outside the database            │
  │        (ETS tables, application env, caches, files)            │
  │                                                                 │
  │ Solutions:                                                      │
  │ 1. Reset external state in setup/on_exit                       │
  │ 2. Use unique identifiers in tests                             │
  │ 3. Isolate external dependencies                               │
  └─────────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────────┐
  │ Issue: Ownership timeout errors                                 │
  ├─────────────────────────────────────────────────────────────────┤
  │ Cause: Test or operation took longer than ownership_timeout    │
  │                                                                 │
  │ Solutions:                                                      │
  │ 1. Increase timeout in checkout:                               │
  │    Sandbox.checkout(Repo, ownership_timeout: 60_000)           │
  │                                                                 │
  │ 2. Optimize slow tests                                         │
  │                                                                 │
  │ 3. Split into smaller, faster tests                            │
  └─────────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────────┐
  │ Issue: Data leaking between tests                              │
  ├─────────────────────────────────────────────────────────────────┤
  │ Cause: Using :auto mode or missing sandbox configuration       │
  │                                                                 │
  │ Solutions:                                                      │
  │ 1. Verify pool: Ecto.Adapters.SQL.Sandbox in test config       │
  │                                                                 │
  │ 2. Ensure Sandbox.mode(Repo, :manual) in test_helper.exs       │
  │                                                                 │
  │ 3. Check that DataCase is being used correctly                 │
  └─────────────────────────────────────────────────────────────────┘
  """
end

# ============================================================================
# Section 10: Advanced Sandbox Techniques
# ============================================================================

defmodule AdvancedSandboxTechniques do
  @moduledoc """
  Advanced patterns for complex testing scenarios.
  """

  # Testing with multiple repos
  @multiple_repos """
  defmodule MyApp.MultiRepoTest do
    use ExUnit.Case

    alias Ecto.Adapters.SQL.Sandbox

    setup do
      # Checkout connections for multiple repos
      :ok = Sandbox.checkout(MyApp.Repo)
      :ok = Sandbox.checkout(MyApp.ReadReplica)
      :ok = Sandbox.checkout(MyApp.AnalyticsRepo)

      :ok
    end

    test "query across multiple repos" do
      # Each repo has its own isolated transaction
    end
  end
  """

  # Custom DataCase with multiple repos
  @multi_repo_data_case """
  defmodule MyApp.MultiRepoDataCase do
    use ExUnit.CaseTemplate

    using do
      quote do
        alias MyApp.Repo
        alias MyApp.ReadReplica
        import Ecto
        import Ecto.Query
        import MyApp.MultiRepoDataCase
      end
    end

    setup tags do
      repos = [MyApp.Repo, MyApp.ReadReplica]

      pids = Enum.map(repos, fn repo ->
        Ecto.Adapters.SQL.Sandbox.start_owner!(repo, shared: not tags[:async])
      end)

      on_exit(fn ->
        Enum.each(pids, &Ecto.Adapters.SQL.Sandbox.stop_owner/1)
      end)

      :ok
    end
  end
  """

  # Testing database transactions explicitly
  @transaction_testing """
  defmodule MyApp.TransactionTest do
    use MyApp.DataCase, async: true

    alias MyApp.{Repo, Accounts, Billing}

    test "transaction rollback on error" do
      {:ok, user} = Accounts.create_user(%{
        email: "test@example.com",
        name: "Test",
        password: "password123456"
      })

      # This function uses Repo.transaction internally
      result = Billing.charge_and_record(user, amount: 100)

      case result do
        {:ok, _} ->
          # Transaction committed, verify both changes
          assert Billing.get_balance(user) == -100
          assert length(Billing.get_transactions(user)) == 1

        {:error, :payment_failed} ->
          # Transaction rolled back, no changes
          assert Billing.get_balance(user) == 0
          assert Billing.get_transactions(user) == []
      end
    end

    test "nested transaction behavior" do
      # Ecto uses savepoints for nested transactions
      Repo.transaction(fn ->
        {:ok, user} = Accounts.create_user(%{
          email: "outer@example.com",
          name: "Outer",
          password: "password123456"
        })

        # Inner transaction
        result = Repo.transaction(fn ->
          Accounts.create_user(%{
            email: "inner@example.com",
            name: "Inner",
            password: "password123456"
          })
        end)

        # Inner transaction result
        assert {:ok, {:ok, inner_user}} = {:ok, result}

        # Both users exist within the outer transaction
        assert Accounts.get_user!(user.id)
        assert Accounts.get_user!(inner_user.id)
      end)
    end
  end
  """
end

# ============================================================================
# Exercises
# ============================================================================

defmodule EctoSandboxExercises do
  @moduledoc """
  Hands-on exercises for mastering Ecto Sandbox testing.
  """

  @exercises """
  Exercise 1: Basic DataCase Usage
  ================================
  Create a test module for a `Products` context that:
  - Uses DataCase with async: true
  - Tests CRUD operations for products
  - Uses setup to create common test data
  - Verifies database constraints (unique SKU)


  Exercise 2: Testing Associations
  ================================
  Write tests for a schema with associations:
  - Create a User -> Posts -> Comments hierarchy
  - Test creating nested data
  - Test preloading associations
  - Verify cascade deletes work correctly


  Exercise 3: Process Allowance
  =============================
  Create a test that:
  - Spawns a Task that needs database access
  - Properly allows the Task to use the sandbox
  - Verifies data created by the Task
  - Works with async: true


  Exercise 4: GenServer Integration
  =================================
  Test a GenServer that accesses the database:
  - Start the GenServer in setup
  - Allow the GenServer to use the sandbox connection
  - Call GenServer functions that read/write database
  - Verify changes in the test


  Exercise 5: Transaction Testing
  ===============================
  Test transactional behavior:
  - Create a function that uses Repo.transaction
  - Test successful transaction commits
  - Test transaction rollback on error
  - Verify data integrity after rollback


  Exercise 6: Multiple Repos
  ==========================
  If your app uses multiple repos (e.g., read replica):
  - Create a custom DataCase for multiple repos
  - Write tests that use both repos
  - Ensure isolation works for both
  """
end

# ============================================================================
# Summary
# ============================================================================

defmodule EctoSandboxSummary do
  @moduledoc """
  Key takeaways from this lesson on Ecto SQL Sandbox.

  ## Core Concepts

  1. **SQL Sandbox** wraps tests in transactions that rollback
  2. **DataCase** provides the standard setup for database tests
  3. **async: true** enables concurrent tests with isolated connections
  4. **Ownership** determines which process can use a connection
  5. **Allowance** lets multiple processes share a connection

  ## When to Use What

  - **async: true** - Default choice, tests are independent
  - **async: false** - Tests share global state or use GenServers
  - **shared mode** - Integration tests with many processes
  - **manual checkout** - Fine-grained control over connection

  ## Configuration Checklist

  1. Set `pool: Ecto.Adapters.SQL.Sandbox` in test config
  2. Call `Sandbox.mode(Repo, :manual)` in test_helper.exs
  3. Use DataCase for all database tests
  4. Allow external processes as needed

  ## Next Steps

  - Lesson 8: ExMachina factories for test data
  - Lesson 9: Testing Ecto queries and contexts
  """
end
