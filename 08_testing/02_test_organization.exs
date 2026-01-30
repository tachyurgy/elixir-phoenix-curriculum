# ==============================================================================
# Test Organization - Structuring Tests Effectively
# ==============================================================================
#
# Well-organized tests are easier to read, maintain, and debug. This lesson
# covers ExUnit's built-in tools for organizing tests: describe blocks,
# setup callbacks, and tags.
#
# Topics covered:
# - describe blocks for grouping related tests
# - setup and setup_all callbacks
# - Test context and data sharing
# - Tags for categorizing and filtering tests
# - on_exit callbacks for cleanup
#
# ==============================================================================

ExUnit.start()

# ==============================================================================
# Section 1: describe Blocks - Grouping Related Tests
# ==============================================================================

defmodule DescribeBlocksTest do
  use ExUnit.Case

  # describe groups related tests together
  # It adds structure and improves test output readability

  describe "String.upcase/1" do
    test "converts lowercase to uppercase" do
      assert String.upcase("hello") == "HELLO"
    end

    test "keeps uppercase unchanged" do
      assert String.upcase("HELLO") == "HELLO"
    end

    test "handles mixed case" do
      assert String.upcase("HeLLo WoRLd") == "HELLO WORLD"
    end

    test "handles empty string" do
      assert String.upcase("") == ""
    end

    test "handles numbers and special characters" do
      assert String.upcase("hello123!@#") == "HELLO123!@#"
    end
  end

  describe "String.downcase/1" do
    test "converts uppercase to lowercase" do
      assert String.downcase("HELLO") == "hello"
    end

    test "keeps lowercase unchanged" do
      assert String.downcase("hello") == "hello"
    end

    test "handles mixed case" do
      assert String.downcase("HeLLo WoRLd") == "hello world"
    end
  end

  # You can nest describe blocks (though not commonly done)
  describe "String functions" do
    describe "length operations" do
      test "String.length/1 returns character count" do
        assert String.length("hello") == 5
      end

      test "byte_size/1 returns byte count" do
        assert byte_size("hello") == 5
        # Unicode characters may have different byte sizes
        assert byte_size("héllo") == 6  # é is 2 bytes in UTF-8
      end
    end
  end
end

# ==============================================================================
# Section 2: setup Callback - Per-Test Setup
# ==============================================================================

defmodule SetupExamplesTest do
  use ExUnit.Case

  # setup runs before EACH test in the module
  # It returns a map that gets merged into the test context

  setup do
    # This runs before every test
    user = %{id: 1, name: "Alice", email: "alice@example.com"}
    admin = %{id: 2, name: "Admin", email: "admin@example.com", role: :admin}

    # Return values to be added to context
    {:ok, user: user, admin: admin}
  end

  # Tests receive context as second argument
  test "user has correct name", %{user: user} do
    assert user.name == "Alice"
  end

  test "user has correct email", %{user: user} do
    assert user.email == "alice@example.com"
  end

  test "admin has admin role", %{admin: admin} do
    assert admin.role == :admin
  end

  # You can pattern match only what you need
  test "users have different ids", context do
    assert context.user.id != context.admin.id
  end
end

# ==============================================================================
# Section 3: setup with describe - Scoped Setup
# ==============================================================================

defmodule ScopedSetupTest do
  use ExUnit.Case

  # Module-level setup runs for ALL tests
  setup do
    {:ok, shared_value: "available everywhere"}
  end

  describe "group A" do
    # This setup only runs for tests in this describe block
    setup do
      {:ok, group_a_value: "only in group A"}
    end

    test "has both shared and group values", context do
      assert context.shared_value == "available everywhere"
      assert context.group_a_value == "only in group A"
    end
  end

  describe "group B" do
    setup do
      {:ok, group_b_value: "only in group B"}
    end

    test "has shared value and group B value", context do
      assert context.shared_value == "available everywhere"
      assert context.group_b_value == "only in group B"
      # group_a_value is NOT available here
      refute Map.has_key?(context, :group_a_value)
    end
  end

  # Tests outside describe blocks only get module-level setup
  test "outside describe only has shared value", context do
    assert context.shared_value == "available everywhere"
    refute Map.has_key?(context, :group_a_value)
    refute Map.has_key?(context, :group_b_value)
  end
end

# ==============================================================================
# Section 4: setup_all - One-Time Setup
# ==============================================================================

defmodule SetupAllExamplesTest do
  use ExUnit.Case

  # setup_all runs ONCE before all tests in the module
  # Useful for expensive setup that can be shared

  setup_all do
    IO.puts("\n  [setup_all] Running expensive setup once...")

    # Simulate expensive operation
    expensive_data = Enum.to_list(1..100)

    # This data is shared (read-only) across all tests
    {:ok, expensive_data: expensive_data, setup_time: System.monotonic_time()}
  end

  # Regular setup still runs before each test
  setup context do
    IO.puts("  [setup] Running for test: #{context.test}")
    {:ok, test_specific: :some_value}
  end

  test "first test", %{expensive_data: data} do
    assert length(data) == 100
  end

  test "second test", %{expensive_data: data, setup_time: time} do
    assert Enum.sum(data) == 5050
    assert is_integer(time)
  end

  test "third test has test-specific setup", %{test_specific: value} do
    assert value == :some_value
  end
end

# ==============================================================================
# Section 5: Multiple setup Callbacks
# ==============================================================================

defmodule MultipleSetupTest do
  use ExUnit.Case

  # You can have multiple setup callbacks
  # They run in order and contexts are merged

  setup do
    {:ok, value1: 1}
  end

  setup do
    {:ok, value2: 2}
  end

  setup context do
    # Later setups can access earlier setup values
    {:ok, sum: context.value1 + context.value2}
  end

  test "all setup values are available", context do
    assert context.value1 == 1
    assert context.value2 == 2
    assert context.sum == 3
  end
end

# ==============================================================================
# Section 6: on_exit - Cleanup After Tests
# ==============================================================================

defmodule CleanupExamplesTest do
  use ExUnit.Case

  setup do
    # Create a temporary file
    path = "/tmp/test_file_#{:rand.uniform(10000)}.txt"
    File.write!(path, "test content")

    # on_exit registers a callback to run AFTER the test
    # Even if the test fails!
    on_exit(fn ->
      File.rm(path)
      IO.puts("  [cleanup] Removed #{path}")
    end)

    {:ok, file_path: path}
  end

  test "file exists during test", %{file_path: path} do
    assert File.exists?(path)
    assert File.read!(path) == "test content"
  end

  test "another test with different file", %{file_path: path} do
    # Each test gets its own file due to random name
    assert File.exists?(path)
  end
end

# ==============================================================================
# Section 7: Named on_exit Callbacks
# ==============================================================================

defmodule NamedCleanupTest do
  use ExUnit.Case

  setup do
    # Named callbacks can be overridden or identified in logs
    on_exit(:cleanup_database, fn ->
      IO.puts("  [cleanup] Database cleanup")
    end)

    on_exit(:cleanup_files, fn ->
      IO.puts("  [cleanup] File cleanup")
    end)

    :ok
  end

  test "callbacks run in reverse order of registration" do
    # cleanup_files runs first (LIFO order)
    # cleanup_database runs second
    assert true
  end
end

# ==============================================================================
# Section 8: Tags - Categorizing Tests
# ==============================================================================

defmodule TagExamplesTest do
  use ExUnit.Case

  # Tags can be applied to individual tests
  @tag :slow
  test "this is a slow test" do
    :timer.sleep(100)
    assert true
  end

  @tag :integration
  test "this is an integration test" do
    assert true
  end

  # Multiple tags
  @tag :slow
  @tag :integration
  @tag priority: :high
  test "slow integration test with high priority" do
    assert true
  end

  # Tag with value
  @tag timeout: 120_000
  test "test with custom timeout" do
    assert true
  end

  # Fast tests (no tags means they're "normal" unit tests)
  test "fast unit test" do
    assert 1 + 1 == 2
  end
end

# Running tests with tags from command line:
#
# mix test --only slow          # Run only tests tagged :slow
# mix test --exclude slow       # Run all except :slow tests
# mix test --only integration   # Run only integration tests
# mix test --include slow       # Include :slow even if excluded by default
#
# In test_helper.exs, you can exclude by default:
# ExUnit.configure(exclude: [:slow, :integration])

# ==============================================================================
# Section 9: Module Tags
# ==============================================================================

defmodule ModuleTagsTest do
  use ExUnit.Case

  # @moduletag applies to ALL tests in the module
  @moduletag :database
  @moduletag timeout: 60_000

  test "all tests in this module have :database tag" do
    assert true
  end

  test "all tests have 60 second timeout" do
    assert true
  end

  # Individual tags are added to module tags
  @tag :slow
  test "this test has both :database and :slow tags" do
    assert true
  end
end

# ==============================================================================
# Section 10: Tags in describe Blocks
# ==============================================================================

defmodule DescribeTagsTest do
  use ExUnit.Case

  describe "user authentication" do
    # @describetag applies to all tests in the describe block
    @describetag :auth

    test "valid credentials authenticate" do
      # Has :auth tag
      assert true
    end

    test "invalid credentials fail" do
      # Also has :auth tag
      assert true
    end

    @tag :slow
    test "slow auth test" do
      # Has both :auth and :slow tags
      assert true
    end
  end

  describe "public endpoints" do
    @describetag :public

    test "homepage loads" do
      # Has :public tag, not :auth
      assert true
    end
  end
end

# ==============================================================================
# Section 11: Accessing Tags in Tests
# ==============================================================================

defmodule AccessingTagsTest do
  use ExUnit.Case

  @tag feature: :login
  @tag user_type: :admin
  test "tags are accessible in context", context do
    # Tags are available in the test context under :tags key
    # But individual tags are also directly in context
    assert context[:feature] == :login
    assert context[:user_type] == :admin
  end

  setup context do
    # Setup can also access tags
    if context[:feature] == :login do
      {:ok, login_required: true}
    else
      {:ok, login_required: false}
    end
  end

  @tag feature: :login
  test "setup uses tags", context do
    assert context.login_required == true
  end

  @tag feature: :dashboard
  test "different feature tag", context do
    assert context.login_required == false
  end
end

# ==============================================================================
# Section 12: Practical Example - Complete Test File Structure
# ==============================================================================

defmodule UserService do
  @moduledoc "Example service module"

  defstruct [:id, :name, :email, :active]

  def new(attrs) do
    %__MODULE__{
      id: attrs[:id] || generate_id(),
      name: attrs[:name],
      email: attrs[:email],
      active: attrs[:active] || true
    }
  end

  defp generate_id, do: :rand.uniform(10000)

  def activate(%__MODULE__{} = user), do: %{user | active: true}
  def deactivate(%__MODULE__{} = user), do: %{user | active: false}

  def valid?(%__MODULE__{name: name, email: email})
      when is_binary(name) and is_binary(email) do
    String.length(name) > 0 and String.contains?(email, "@")
  end
  def valid?(_), do: false
end

defmodule UserServiceTest do
  use ExUnit.Case

  # Module-level documentation tag
  @moduletag :unit

  # Shared setup for all tests
  setup do
    valid_attrs = %{name: "John Doe", email: "john@example.com"}
    {:ok, valid_attrs: valid_attrs}
  end

  describe "new/1" do
    test "creates user with valid attributes", %{valid_attrs: attrs} do
      user = UserService.new(attrs)

      assert user.name == "John Doe"
      assert user.email == "john@example.com"
      assert user.active == true
      assert is_integer(user.id)
    end

    test "allows custom id" do
      user = UserService.new(%{id: 42, name: "Jane", email: "jane@test.com"})
      assert user.id == 42
    end

    test "defaults active to true" do
      user = UserService.new(%{name: "Test", email: "test@test.com"})
      assert user.active == true
    end

    test "allows setting active to false" do
      user = UserService.new(%{name: "Test", email: "test@test.com", active: false})
      assert user.active == false
    end
  end

  describe "activate/1" do
    setup %{valid_attrs: attrs} do
      user = UserService.new(Map.put(attrs, :active, false))
      {:ok, user: user}
    end

    test "sets user active to true", %{user: user} do
      activated = UserService.activate(user)
      assert activated.active == true
    end

    test "keeps other fields unchanged", %{user: user} do
      activated = UserService.activate(user)
      assert activated.name == user.name
      assert activated.email == user.email
      assert activated.id == user.id
    end
  end

  describe "deactivate/1" do
    setup %{valid_attrs: attrs} do
      user = UserService.new(attrs)
      {:ok, user: user}
    end

    test "sets user active to false", %{user: user} do
      deactivated = UserService.deactivate(user)
      assert deactivated.active == false
    end
  end

  describe "valid?/1" do
    test "returns true for valid user", %{valid_attrs: attrs} do
      user = UserService.new(attrs)
      assert UserService.valid?(user)
    end

    test "returns false for missing name" do
      user = UserService.new(%{email: "test@test.com"})
      refute UserService.valid?(user)
    end

    test "returns false for missing email" do
      user = UserService.new(%{name: "Test"})
      refute UserService.valid?(user)
    end

    test "returns false for empty name" do
      user = UserService.new(%{name: "", email: "test@test.com"})
      refute UserService.valid?(user)
    end

    test "returns false for email without @" do
      user = UserService.new(%{name: "Test", email: "invalid-email"})
      refute UserService.valid?(user)
    end

    @tag :edge_case
    test "returns false for non-User struct" do
      refute UserService.valid?(%{name: "Test", email: "test@test.com"})
      refute UserService.valid?(nil)
      refute UserService.valid?("not a user")
    end
  end
end

# ==============================================================================
# Exercises
# ==============================================================================

defmodule ShoppingCart do
  @moduledoc "A simple shopping cart implementation for testing practice."

  defstruct items: [], discount_code: nil

  def new, do: %__MODULE__{}

  def add_item(cart, item) when is_map(item) do
    %{cart | items: [item | cart.items]}
  end

  def remove_item(cart, item_id) do
    %{cart | items: Enum.reject(cart.items, &(&1.id == item_id))}
  end

  def apply_discount(cart, code) do
    %{cart | discount_code: code}
  end

  def total(%{items: items, discount_code: code}) do
    subtotal = Enum.reduce(items, 0, fn item, acc ->
      acc + (item.price * item.quantity)
    end)

    apply_discount_to_total(subtotal, code)
  end

  defp apply_discount_to_total(total, nil), do: total
  defp apply_discount_to_total(total, "SAVE10"), do: total * 0.9
  defp apply_discount_to_total(total, "SAVE20"), do: total * 0.8
  defp apply_discount_to_total(total, _), do: total

  def item_count(%{items: items}) do
    Enum.reduce(items, 0, fn item, acc -> acc + item.quantity end)
  end

  def empty?(cart), do: cart.items == []
end

defmodule ShoppingCartTest do
  use ExUnit.Case

  @moduletag :shopping

  # Exercise: Complete the test setup and tests below

  # Setup that creates sample items
  setup do
    item1 = %{id: 1, name: "Widget", price: 10.00, quantity: 2}
    item2 = %{id: 2, name: "Gadget", price: 25.00, quantity: 1}
    item3 = %{id: 3, name: "Gizmo", price: 5.00, quantity: 5}

    {:ok, item1: item1, item2: item2, item3: item3}
  end

  describe "new/0" do
    test "creates empty cart" do
      cart = ShoppingCart.new()
      assert cart.items == []
      assert cart.discount_code == nil
    end
  end

  describe "add_item/2" do
    test "adds item to empty cart", %{item1: item} do
      cart = ShoppingCart.new() |> ShoppingCart.add_item(item)
      assert length(cart.items) == 1
      assert hd(cart.items) == item
    end

    test "adds multiple items", %{item1: item1, item2: item2} do
      cart = ShoppingCart.new()
             |> ShoppingCart.add_item(item1)
             |> ShoppingCart.add_item(item2)

      assert length(cart.items) == 2
    end
  end

  describe "remove_item/2" do
    setup %{item1: item1, item2: item2} do
      cart = ShoppingCart.new()
             |> ShoppingCart.add_item(item1)
             |> ShoppingCart.add_item(item2)

      {:ok, cart: cart}
    end

    test "removes item by id", %{cart: cart, item1: item1} do
      updated = ShoppingCart.remove_item(cart, item1.id)
      assert length(updated.items) == 1
      refute Enum.any?(updated.items, &(&1.id == item1.id))
    end

    test "does nothing for non-existent id", %{cart: cart} do
      updated = ShoppingCart.remove_item(cart, 999)
      assert length(updated.items) == 2
    end
  end

  describe "total/1" do
    test "calculates total for single item", %{item1: item} do
      cart = ShoppingCart.new() |> ShoppingCart.add_item(item)
      # item1: price 10.00 * quantity 2 = 20.00
      assert ShoppingCart.total(cart) == 20.00
    end

    test "calculates total for multiple items", %{item1: item1, item2: item2, item3: item3} do
      cart = ShoppingCart.new()
             |> ShoppingCart.add_item(item1)  # 10 * 2 = 20
             |> ShoppingCart.add_item(item2)  # 25 * 1 = 25
             |> ShoppingCart.add_item(item3)  # 5 * 5 = 25

      assert ShoppingCart.total(cart) == 70.00
    end

    test "applies SAVE10 discount", %{item1: item} do
      cart = ShoppingCart.new()
             |> ShoppingCart.add_item(item)
             |> ShoppingCart.apply_discount("SAVE10")

      # 20.00 * 0.9 = 18.00
      assert ShoppingCart.total(cart) == 18.00
    end

    test "applies SAVE20 discount", %{item1: item} do
      cart = ShoppingCart.new()
             |> ShoppingCart.add_item(item)
             |> ShoppingCart.apply_discount("SAVE20")

      # 20.00 * 0.8 = 16.00
      assert ShoppingCart.total(cart) == 16.00
    end

    test "ignores invalid discount code", %{item1: item} do
      cart = ShoppingCart.new()
             |> ShoppingCart.add_item(item)
             |> ShoppingCart.apply_discount("INVALID")

      assert ShoppingCart.total(cart) == 20.00
    end

    test "returns 0 for empty cart" do
      assert ShoppingCart.total(ShoppingCart.new()) == 0
    end
  end

  describe "item_count/1" do
    test "returns 0 for empty cart" do
      assert ShoppingCart.item_count(ShoppingCart.new()) == 0
    end

    test "sums quantities of all items", %{item1: item1, item2: item2} do
      cart = ShoppingCart.new()
             |> ShoppingCart.add_item(item1)  # quantity: 2
             |> ShoppingCart.add_item(item2)  # quantity: 1

      assert ShoppingCart.item_count(cart) == 3
    end
  end

  describe "empty?/1" do
    test "returns true for empty cart" do
      assert ShoppingCart.empty?(ShoppingCart.new())
    end

    test "returns false for cart with items", %{item1: item} do
      cart = ShoppingCart.new() |> ShoppingCart.add_item(item)
      refute ShoppingCart.empty?(cart)
    end
  end
end

# ==============================================================================
# Summary
# ==============================================================================

# Key concepts covered:
#
# 1. describe blocks - Group related tests together
# 2. setup - Runs before each test, returns context
# 3. setup_all - Runs once before all tests
# 4. on_exit - Cleanup callback after test
# 5. Tags - Categorize and filter tests
#   - @tag for individual tests
#   - @moduletag for entire module
#   - @describetag for describe block
#
# Best practices:
# - Use describe blocks to organize tests by function or feature
# - Keep setup focused and minimal
# - Use setup_all for expensive, shareable setup
# - Always clean up resources with on_exit
# - Use tags to categorize slow, integration, or feature tests
#
# Command line options:
# - mix test --only tag_name
# - mix test --exclude tag_name
# - mix test --include tag_name
#
# Next lesson: Advanced assertions (assert_raise, assert_receive, etc.)
