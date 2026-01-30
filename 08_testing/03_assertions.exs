# ==============================================================================
# Assertions - ExUnit's Assertion Toolkit
# ==============================================================================
#
# ExUnit provides a rich set of assertion macros for testing different scenarios.
# This lesson covers all the assertion types you'll need for comprehensive testing.
#
# Topics covered:
# - assert and refute basics
# - assert_raise for exception testing
# - assert_receive for message testing
# - Pattern matching assertions
# - Custom assertion messages
# - Comparison and membership assertions
#
# ==============================================================================

ExUnit.start()

# ==============================================================================
# Section 1: assert and refute - The Basics
# ==============================================================================

defmodule BasicAssertionsTest do
  use ExUnit.Case

  # assert passes when expression is truthy (not nil or false)
  test "assert with truthy values" do
    assert true
    assert 1
    assert "hello"
    assert []  # Empty list is truthy!
    assert %{}  # Empty map is truthy!
    assert :ok
  end

  # refute passes when expression is falsy (nil or false)
  test "refute with falsy values" do
    refute false
    refute nil
  end

  # Comparison assertions with detailed failure messages
  test "assert equality" do
    assert 1 + 1 == 2
    assert "hello" == "hello"
    assert [1, 2, 3] == [1, 2, 3]
    assert %{a: 1} == %{a: 1}
  end

  test "refute equality" do
    refute 1 + 1 == 3
    refute "hello" == "world"
  end

  # ExUnit provides special handling for == comparisons
  # On failure, it shows a diff of expected vs actual
  test "assert shows helpful diff on failure" do
    # Uncomment to see the diff output:
    # assert %{a: 1, b: 2, c: 3} == %{a: 1, b: 99, c: 3}

    # The output would show:
    # left:  %{a: 1, b: 2, c: 3}
    # right: %{a: 1, b: 99, c: 3}
    assert true  # Placeholder
  end
end

# ==============================================================================
# Section 2: Custom Failure Messages
# ==============================================================================

defmodule CustomMessagesTest do
  use ExUnit.Case

  test "assert with custom message" do
    value = 42
    assert value > 0, "Expected positive number, got #{value}"

    list = [1, 2, 3]
    assert length(list) == 3, "List should have exactly 3 elements"
  end

  test "refute with custom message" do
    result = {:ok, "success"}
    refute match?({:error, _}, result), "Expected success but got error"
  end

  # Custom messages are helpful when the default message isn't clear
  test "descriptive message for complex assertion" do
    user = %{name: "Alice", age: 30, active: true}

    assert user.active,
           "User #{user.name} should be active but was inactive"

    assert user.age >= 18,
           "User must be adult (18+), but #{user.name} is #{user.age}"
  end
end

# ==============================================================================
# Section 3: Pattern Matching Assertions
# ==============================================================================

defmodule PatternMatchingAssertionsTest do
  use ExUnit.Case

  # assert with pattern matching (using =)
  test "pattern matching with assert" do
    result = {:ok, 42}

    # This asserts the pattern matches AND binds the variable
    assert {:ok, value} = result
    assert value == 42

    # Complex patterns
    response = %{status: 200, body: %{data: [1, 2, 3]}}
    assert %{status: 200, body: %{data: data}} = response
    assert data == [1, 2, 3]
  end

  # Pattern matching in lists
  test "pattern matching lists" do
    list = [1, 2, 3, 4, 5]

    assert [head | tail] = list
    assert head == 1
    assert tail == [2, 3, 4, 5]

    assert [1, 2 | rest] = list
    assert rest == [3, 4, 5]

    assert [a, b, c, d, e] = list
    assert a + e == 6
  end

  # Using match? for boolean pattern matching
  test "match? macro" do
    result = {:ok, "data"}

    # match? returns true/false, doesn't bind variables
    assert match?({:ok, _}, result)
    refute match?({:error, _}, result)

    # Useful for filtering
    results = [{:ok, 1}, {:error, "bad"}, {:ok, 2}]
    successes = Enum.filter(results, &match?({:ok, _}, &1))
    assert successes == [{:ok, 1}, {:ok, 2}]
  end

  # Pin operator in patterns
  test "pin operator in assertions" do
    expected_id = 42
    user = %{id: 42, name: "Alice"}

    assert %{id: ^expected_id, name: name} = user
    assert name == "Alice"
  end
end

# ==============================================================================
# Section 4: assert_raise - Testing Exceptions
# ==============================================================================

defmodule AssertRaiseTest do
  use ExUnit.Case

  # assert_raise checks that a specific exception is raised
  test "assert_raise with exception type" do
    assert_raise ArithmeticError, fn ->
      1 / 0
    end
  end

  # assert_raise can also check the exception message
  test "assert_raise with message" do
    assert_raise ArgumentError, "argument error", fn ->
      raise ArgumentError, "argument error"
    end
  end

  # Message can be a regex
  test "assert_raise with regex message" do
    assert_raise ArgumentError, ~r/invalid.*argument/i, fn ->
      raise ArgumentError, "Invalid argument provided"
    end
  end

  # Testing custom exceptions
  defmodule CustomError do
    defexception [:message, :code]

    @impl true
    def exception(opts) do
      msg = opts[:message] || "Custom error occurred"
      code = opts[:code] || :unknown
      %__MODULE__{message: msg, code: code}
    end
  end

  test "assert_raise with custom exception" do
    assert_raise CustomError, fn ->
      raise CustomError, message: "Something went wrong", code: :bad_input
    end
  end

  test "assert_raise returns the exception" do
    exception = assert_raise RuntimeError, fn ->
      raise "boom!"
    end

    assert exception.message == "boom!"
  end

  # Testing for specific errors
  test "assert_raise for KeyError" do
    map = %{a: 1, b: 2}

    assert_raise KeyError, fn ->
      Map.fetch!(map, :c)
    end
  end

  test "assert_raise for FunctionClauseError" do
    # When no function clause matches
    assert_raise FunctionClauseError, fn ->
      String.length(123)  # String.length expects a string
    end
  end

  # catch_error for lower-level errors
  test "catch_error for exits" do
    # catch_exit for exit signals
    assert catch_exit(exit(:shutdown)) == :shutdown
  end

  test "catch_throw for throws" do
    assert catch_throw(throw(:some_value)) == :some_value
  end
end

# ==============================================================================
# Section 5: assert_receive - Testing Message Passing
# ==============================================================================

defmodule AssertReceiveTest do
  use ExUnit.Case

  # assert_receive checks mailbox for a message
  test "basic assert_receive" do
    # Send message to self
    send(self(), :hello)

    # Assert we receive it
    assert_receive :hello
  end

  # Pattern matching in assert_receive
  test "assert_receive with pattern" do
    send(self(), {:result, 42})

    assert_receive {:result, value}
    assert value == 42
  end

  # Complex patterns
  test "assert_receive with complex pattern" do
    send(self(), {:user_created, %{id: 1, name: "Alice"}})

    assert_receive {:user_created, %{id: id, name: name}}
    assert id == 1
    assert name == "Alice"
  end

  # Custom timeout (default is 100ms)
  test "assert_receive with timeout" do
    # Spawn process that sends message after delay
    parent = self()
    spawn(fn ->
      :timer.sleep(50)
      send(parent, :delayed_message)
    end)

    # Wait up to 200ms for the message
    assert_receive :delayed_message, 200
  end

  # assert_receive with guard
  test "assert_receive with guard" do
    send(self(), {:number, 42})
    send(self(), {:number, 10})

    # Only match numbers > 20
    assert_receive {:number, n} when n > 20
    assert n == 42
  end

  # refute_receive - assert message is NOT received
  test "refute_receive" do
    # Don't send anything

    # Assert we don't receive :never_sent within 50ms
    refute_receive :never_sent, 50
  end

  # assert_received - check already-received messages (no waiting)
  test "assert_received for immediate check" do
    send(self(), :immediate)

    # assert_received doesn't wait - message must already be in mailbox
    assert_received :immediate
  end

  # refute_received
  test "refute_received" do
    send(self(), :something)

    # This message wasn't sent
    refute_received :other_thing
  end
end

# ==============================================================================
# Section 6: Practical Message Testing
# ==============================================================================

defmodule MessageTestingPracticalTest do
  use ExUnit.Case

  # Testing a module that sends messages
  defmodule Notifier do
    def notify(pid, event) do
      send(pid, {:notification, event, System.system_time()})
    end

    def broadcast(pids, event) do
      Enum.each(pids, fn pid ->
        send(pid, {:broadcast, event})
      end)
    end
  end

  test "Notifier.notify sends notification to pid" do
    Notifier.notify(self(), :user_signup)

    assert_receive {:notification, event, timestamp}
    assert event == :user_signup
    assert is_integer(timestamp)
  end

  test "Notifier.broadcast sends to all pids" do
    # Create multiple "receivers" (all actually self())
    # In real tests, you might spawn actual processes

    Notifier.broadcast([self(), self(), self()], :system_update)

    # Should receive 3 messages
    assert_receive {:broadcast, :system_update}
    assert_receive {:broadcast, :system_update}
    assert_receive {:broadcast, :system_update}

    # No more messages
    refute_receive {:broadcast, _}
  end

  # Testing async operations
  test "testing async task" do
    parent = self()

    Task.start(fn ->
      result = 1 + 1
      send(parent, {:task_complete, result})
    end)

    assert_receive {:task_complete, 2}, 500
  end

  # Multiple message assertions
  test "asserting message order" do
    send(self(), {:step, 1})
    send(self(), {:step, 2})
    send(self(), {:step, 3})

    # Messages are received in order
    assert_receive {:step, 1}
    assert_receive {:step, 2}
    assert_receive {:step, 3}
  end
end

# ==============================================================================
# Section 7: Comparison Assertions
# ==============================================================================

defmodule ComparisonAssertionsTest do
  use ExUnit.Case

  test "numeric comparisons" do
    assert 5 > 3
    assert 3 < 5
    assert 5 >= 5
    assert 5 <= 10
    assert 5 != 10
  end

  test "string comparisons" do
    assert "apple" < "banana"  # Lexicographic
    assert "hello" == "hello"
    assert "HELLO" != "hello"  # Case sensitive
  end

  test "membership with in" do
    list = [1, 2, 3, 4, 5]
    assert 3 in list
    refute 10 in list

    map = %{a: 1, b: 2}
    assert {:a, 1} in Map.to_list(map)
  end

  # Floating point comparisons
  test "floating point with delta" do
    # Direct comparison can fail due to floating point precision
    result = 0.1 + 0.2  # Might not be exactly 0.3

    # Use a delta for approximate comparison
    assert_in_delta result, 0.3, 0.0001
  end

  test "assert_in_delta examples" do
    assert_in_delta 1.0, 1.001, 0.01   # Within 0.01
    assert_in_delta 100, 101, 2        # Works with integers too

    # Useful for calculations that may have small errors
    calculated = :math.sqrt(2) * :math.sqrt(2)
    assert_in_delta calculated, 2.0, 0.0000001
  end

  # refute_in_delta
  test "refute_in_delta" do
    refute_in_delta 1.0, 2.0, 0.5  # Not within 0.5 of each other
  end
end

# ==============================================================================
# Section 8: Collection Assertions
# ==============================================================================

defmodule CollectionAssertionsTest do
  use ExUnit.Case

  test "list equality" do
    assert [1, 2, 3] == [1, 2, 3]
    refute [1, 2, 3] == [3, 2, 1]  # Order matters
  end

  test "list subset checking" do
    list = [1, 2, 3, 4, 5]

    # Check all elements are present (regardless of order)
    assert Enum.all?([1, 3, 5], &(&1 in list))
  end

  # MapSet for order-independent comparison
  test "set equality for unordered comparison" do
    result = [3, 1, 2]
    expected = [1, 2, 3]

    assert MapSet.new(result) == MapSet.new(expected)
  end

  test "map assertions" do
    map = %{a: 1, b: 2, c: 3}

    # Full equality
    assert map == %{a: 1, b: 2, c: 3}

    # Partial match with pattern
    assert %{a: 1} = map  # Has at least :a => 1

    # Check specific keys
    assert Map.has_key?(map, :a)
    assert Map.get(map, :a) == 1
  end

  test "struct assertions" do
    defmodule User do
      defstruct [:name, :email]
    end

    user = %User{name: "Alice", email: "alice@test.com"}

    assert %User{} = user  # Is a User struct
    assert %User{name: "Alice"} = user  # Has specific field
    assert user.name == "Alice"
  end

  # Length assertions
  test "length assertions" do
    list = [1, 2, 3, 4, 5]

    assert length(list) == 5
    assert length(list) > 0
    refute Enum.empty?(list)
  end
end

# ==============================================================================
# Section 9: String Assertions
# ==============================================================================

defmodule StringAssertionsTest do
  use ExUnit.Case

  test "string equality" do
    assert "hello" == "hello"
    refute "hello" == "Hello"  # Case sensitive
  end

  test "string contains" do
    message = "Hello, World!"

    assert String.contains?(message, "World")
    assert String.contains?(message, ["Hello", "World"])  # Any of these
    refute String.contains?(message, "Goodbye")
  end

  test "string starts_with and ends_with" do
    path = "/users/alice/profile"

    assert String.starts_with?(path, "/users")
    assert String.ends_with?(path, "/profile")
  end

  test "string matching with regex" do
    email = "test@example.com"

    assert email =~ ~r/@/
    assert email =~ ~r/^[^@]+@[^@]+\.[^@]+$/
    refute email =~ ~r/invalid/
  end

  test "string length" do
    assert String.length("hello") == 5
    assert byte_size("hello") == 5  # Same for ASCII
  end
end

# ==============================================================================
# Section 10: Boolean and Nil Assertions
# ==============================================================================

defmodule BooleanNilAssertionsTest do
  use ExUnit.Case

  test "is_nil and not is_nil" do
    assert is_nil(nil)
    refute is_nil(false)  # false is not nil!
    refute is_nil(0)
    refute is_nil("")
  end

  test "boolean assertions" do
    assert is_boolean(true)
    assert is_boolean(false)
    refute is_boolean(nil)
    refute is_boolean(1)
  end

  test "explicit true/false checks" do
    value = true
    assert value == true
    assert value === true  # Strict equality

    falsy = false
    assert falsy == false
    refute falsy  # Also works
  end

  # Important: nil and false are different!
  test "nil vs false" do
    assert nil != false
    refute nil  # Both are falsy in conditionals
    refute false
  end
end

# ==============================================================================
# Section 11: Type Assertions
# ==============================================================================

defmodule TypeAssertionsTest do
  use ExUnit.Case

  test "type checking functions" do
    assert is_integer(42)
    assert is_float(3.14)
    assert is_number(42)
    assert is_number(3.14)

    assert is_binary("hello")  # Strings are binaries
    assert is_bitstring("hello")

    assert is_atom(:hello)
    assert is_boolean(true)

    assert is_list([1, 2, 3])
    assert is_tuple({1, 2, 3})
    assert is_map(%{a: 1})

    assert is_function(fn x -> x end)
    assert is_function(&String.length/1)

    assert is_pid(self())
    assert is_reference(make_ref())
  end

  test "struct type checking" do
    defmodule TestStruct do
      defstruct [:field]
    end

    struct = %TestStruct{field: "value"}

    assert is_struct(struct)
    assert is_struct(struct, TestStruct)
    refute is_struct(%{field: "value"})  # Plain maps are not structs
  end
end

# ==============================================================================
# Exercises
# ==============================================================================

defmodule Validator do
  @moduledoc "A validation module for testing exercises."

  def validate_email(email) when is_binary(email) do
    if email =~ ~r/^[^@\s]+@[^@\s]+\.[^@\s]+$/ do
      {:ok, email}
    else
      {:error, :invalid_format}
    end
  end
  def validate_email(_), do: {:error, :not_a_string}

  def validate_age(age) when is_integer(age) and age >= 0 and age <= 150 do
    {:ok, age}
  end
  def validate_age(age) when is_integer(age) do
    {:error, :out_of_range}
  end
  def validate_age(_), do: {:error, :not_an_integer}

  def validate_password(password) when is_binary(password) do
    cond do
      String.length(password) < 8 ->
        {:error, :too_short}
      not (password =~ ~r/[A-Z]/) ->
        {:error, :missing_uppercase}
      not (password =~ ~r/[0-9]/) ->
        {:error, :missing_number}
      true ->
        {:ok, password}
    end
  end
  def validate_password(_), do: {:error, :not_a_string}

  def validate!(field, value) do
    case apply(__MODULE__, :"validate_#{field}", [value]) do
      {:ok, value} -> value
      {:error, reason} -> raise ArgumentError, "Validation failed: #{reason}"
    end
  end
end

defmodule ValidatorTest do
  use ExUnit.Case

  describe "validate_email/1" do
    test "returns {:ok, email} for valid email" do
      assert {:ok, "test@example.com"} = Validator.validate_email("test@example.com")
      assert {:ok, _} = Validator.validate_email("user.name@domain.co.uk")
    end

    test "returns {:error, :invalid_format} for invalid email" do
      assert {:error, :invalid_format} = Validator.validate_email("invalid")
      assert {:error, :invalid_format} = Validator.validate_email("no@domain")
      assert {:error, :invalid_format} = Validator.validate_email("@nodomain.com")
    end

    test "returns {:error, :not_a_string} for non-string input" do
      assert {:error, :not_a_string} = Validator.validate_email(123)
      assert {:error, :not_a_string} = Validator.validate_email(nil)
      assert {:error, :not_a_string} = Validator.validate_email(:atom)
    end
  end

  describe "validate_age/1" do
    test "returns {:ok, age} for valid age" do
      assert {:ok, 25} = Validator.validate_age(25)
      assert {:ok, 0} = Validator.validate_age(0)
      assert {:ok, 150} = Validator.validate_age(150)
    end

    test "returns {:error, :out_of_range} for age outside valid range" do
      assert {:error, :out_of_range} = Validator.validate_age(-1)
      assert {:error, :out_of_range} = Validator.validate_age(151)
      assert {:error, :out_of_range} = Validator.validate_age(1000)
    end

    test "returns {:error, :not_an_integer} for non-integer input" do
      assert {:error, :not_an_integer} = Validator.validate_age("25")
      assert {:error, :not_an_integer} = Validator.validate_age(25.5)
      assert {:error, :not_an_integer} = Validator.validate_age(nil)
    end
  end

  describe "validate_password/1" do
    test "returns {:ok, password} for valid password" do
      assert {:ok, "Password1"} = Validator.validate_password("Password1")
      assert {:ok, _} = Validator.validate_password("MySecure123")
    end

    test "returns {:error, :too_short} for password under 8 chars" do
      assert {:error, :too_short} = Validator.validate_password("Pass1")
      assert {:error, :too_short} = Validator.validate_password("Ab1")
    end

    test "returns {:error, :missing_uppercase} without uppercase" do
      assert {:error, :missing_uppercase} = Validator.validate_password("password123")
    end

    test "returns {:error, :missing_number} without number" do
      assert {:error, :missing_number} = Validator.validate_password("PasswordOnly")
    end

    test "returns {:error, :not_a_string} for non-string input" do
      assert {:error, :not_a_string} = Validator.validate_password(12345678)
    end
  end

  describe "validate!/2" do
    test "returns validated value for valid input" do
      assert "test@example.com" = Validator.validate!(:email, "test@example.com")
      assert 25 = Validator.validate!(:age, 25)
      assert "Password1" = Validator.validate!(:password, "Password1")
    end

    test "raises ArgumentError for invalid email" do
      assert_raise ArgumentError, ~r/invalid_format/, fn ->
        Validator.validate!(:email, "invalid")
      end
    end

    test "raises ArgumentError for invalid age" do
      assert_raise ArgumentError, ~r/out_of_range/, fn ->
        Validator.validate!(:age, -5)
      end
    end

    test "raises ArgumentError for invalid password" do
      assert_raise ArgumentError, ~r/too_short/, fn ->
        Validator.validate!(:password, "short")
      end
    end
  end
end

# Additional exercise: Message passing tests
defmodule EventEmitter do
  def emit(pid, event, payload \\ %{}) do
    send(pid, {:event, event, payload, System.monotonic_time()})
    :ok
  end
end

defmodule EventEmitterTest do
  use ExUnit.Case

  test "emit/3 sends event to pid" do
    EventEmitter.emit(self(), :user_created, %{id: 1})

    assert_receive {:event, :user_created, %{id: 1}, timestamp}
    assert is_integer(timestamp)
  end

  test "emit/2 sends event with empty payload" do
    EventEmitter.emit(self(), :ping)

    assert_receive {:event, :ping, payload, _}
    assert payload == %{}
  end

  test "emit/3 returns :ok" do
    assert :ok = EventEmitter.emit(self(), :test)
  end

  test "multiple emits are received in order" do
    EventEmitter.emit(self(), :first)
    EventEmitter.emit(self(), :second)
    EventEmitter.emit(self(), :third)

    assert_receive {:event, :first, _, _}
    assert_receive {:event, :second, _, _}
    assert_receive {:event, :third, _, _}
    refute_receive {:event, _, _, _}, 10
  end
end

# ==============================================================================
# Summary
# ==============================================================================

# Key assertions covered:
#
# Basic:
# - assert/refute - Truthy/falsy checks
# - Custom messages for clearer failures
#
# Pattern Matching:
# - assert pattern = expression
# - match?/2 for boolean matching
#
# Exceptions:
# - assert_raise ExceptionType, fn -> ... end
# - assert_raise ExceptionType, message, fn -> ... end
# - catch_exit, catch_throw
#
# Messages:
# - assert_receive pattern, timeout
# - refute_receive pattern, timeout
# - assert_received / refute_received (no waiting)
#
# Comparisons:
# - assert_in_delta for floating point
# - Membership with `in`
#
# Best practices:
# - Use pattern matching for structured data
# - Add custom messages for complex assertions
# - Use assert_raise for exception testing
# - Use appropriate timeouts for message testing
# - Test both success and failure cases
#
# Next lesson: Testing Pure Functions
