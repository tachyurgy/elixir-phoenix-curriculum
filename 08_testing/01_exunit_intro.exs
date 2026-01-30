# ==============================================================================
# ExUnit Introduction - Elixir's Built-in Testing Framework
# ==============================================================================
#
# ExUnit is Elixir's built-in unit testing framework. It's powerful, flexible,
# and integrated into every Mix project by default. This lesson covers the
# fundamentals of writing and running tests in Elixir.
#
# Topics covered:
# - ExUnit basics and configuration
# - The test macro
# - Basic assertions
# - Running tests from the command line
# - Test structure and naming conventions
#
# ==============================================================================

# ==============================================================================
# Section 1: ExUnit Basics
# ==============================================================================

# ExUnit must be started before tests can run. In Mix projects, this is done
# automatically in test/test_helper.exs. For standalone scripts:

ExUnit.start()

# The autorun option (true by default) runs tests when the VM terminates.
# You can configure ExUnit with various options:
#
# ExUnit.start(
#   trace: true,           # Print each test as it runs
#   capture_log: true,     # Capture log messages during tests
#   max_failures: 1,       # Stop after first failure
#   seed: 12345,           # Set random seed for reproducibility
#   timeout: 60_000        # Default test timeout in milliseconds
# )

# ==============================================================================
# Section 2: Creating Test Modules with ExUnit.Case
# ==============================================================================

defmodule BasicMathTest do
  # use ExUnit.Case imports test macros and sets up the test module
  use ExUnit.Case

  # The `test` macro defines a test case
  # The string describes what the test verifies
  test "addition works correctly" do
    assert 1 + 1 == 2
    assert 5 + 3 == 8
    assert -1 + 1 == 0
  end

  test "subtraction works correctly" do
    assert 5 - 3 == 2
    assert 10 - 10 == 0
    assert 0 - 5 == -5
  end

  test "multiplication works correctly" do
    assert 3 * 4 == 12
    assert 0 * 100 == 0
    assert -2 * 3 == -6
  end

  test "division works correctly" do
    assert 10 / 2 == 5.0  # Note: / always returns float
    assert div(10, 3) == 3  # Integer division
    assert rem(10, 3) == 1  # Remainder
  end
end

# ==============================================================================
# Section 3: The test Macro in Detail
# ==============================================================================

defmodule TestMacroExamplesTest do
  use ExUnit.Case

  # Basic test with string description
  test "basic test example" do
    assert true
  end

  # Tests can use atoms as well (less common, but valid)
  test :atom_test_name do
    assert true
  end

  # Test with context - receives a map with test metadata
  test "test with context", context do
    # context contains metadata about the test
    assert is_map(context)
    assert Map.has_key?(context, :test)
    assert Map.has_key?(context, :module)

    # The test name is available
    assert context.test == :"test test with context"
  end

  # Tests should have descriptive names that explain the behavior
  # Good: "returns empty list when input is empty"
  # Bad: "test1" or "it works"

  test "returns empty list when input is empty" do
    assert Enum.filter([], fn x -> x > 0 end) == []
  end

  # Tests fail when assertions fail
  # Uncomment to see failure output:
  # test "this test will fail" do
  #   assert 1 == 2
  # end
end

# ==============================================================================
# Section 4: Basic Assertions
# ==============================================================================

defmodule BasicAssertionsTest do
  use ExUnit.Case

  # assert - passes if expression is truthy
  test "assert examples" do
    assert true
    assert 1  # Truthy
    assert "hello"  # Truthy
    assert [1, 2, 3]  # Truthy

    # assert with comparison
    assert 1 + 1 == 2
    assert String.length("hello") == 5
    assert length([1, 2, 3]) == 3
  end

  # refute - passes if expression is falsy
  test "refute examples" do
    refute false
    refute nil

    # refute with comparison
    refute 1 + 1 == 3
    refute String.length("hello") == 10
  end

  # assert with custom failure message
  test "assert with custom message" do
    value = 42
    assert value > 0, "Expected value to be positive, got: #{value}"
  end

  # Pattern matching in assertions
  test "assert with pattern matching" do
    result = {:ok, 42}

    # This asserts the pattern matches
    assert {:ok, value} = result
    assert value == 42

    # Works with lists too
    assert [head | _tail] = [1, 2, 3]
    assert head == 1
  end

  # Asserting equality with ==
  test "equality assertions" do
    assert [1, 2, 3] == [1, 2, 3]
    assert %{a: 1} == %{a: 1}
    assert "hello" == "hello"
  end

  # Asserting membership
  test "membership assertions" do
    list = [1, 2, 3, 4, 5]
    assert 3 in list
    refute 10 in list
  end
end

# ==============================================================================
# Section 5: Testing Functions in Modules
# ==============================================================================

# Let's define a module with functions to test
defmodule Calculator do
  @moduledoc """
  A simple calculator module for demonstration.
  """

  def add(a, b), do: a + b
  def subtract(a, b), do: a - b
  def multiply(a, b), do: a * b

  def divide(_a, 0), do: {:error, :division_by_zero}
  def divide(a, b), do: {:ok, a / b}

  def factorial(0), do: 1
  def factorial(n) when n > 0, do: n * factorial(n - 1)
  def factorial(_), do: {:error, :negative_number}
end

defmodule CalculatorTest do
  use ExUnit.Case

  test "add/2 adds two numbers" do
    assert Calculator.add(2, 3) == 5
    assert Calculator.add(-1, 1) == 0
    assert Calculator.add(0, 0) == 0
  end

  test "subtract/2 subtracts second number from first" do
    assert Calculator.subtract(5, 3) == 2
    assert Calculator.subtract(3, 5) == -2
    assert Calculator.subtract(0, 0) == 0
  end

  test "multiply/2 multiplies two numbers" do
    assert Calculator.multiply(3, 4) == 12
    assert Calculator.multiply(0, 100) == 0
    assert Calculator.multiply(-2, 3) == -6
  end

  test "divide/2 returns {:ok, result} for valid division" do
    assert Calculator.divide(10, 2) == {:ok, 5.0}
    assert Calculator.divide(7, 2) == {:ok, 3.5}
  end

  test "divide/2 returns error tuple for division by zero" do
    assert Calculator.divide(10, 0) == {:error, :division_by_zero}
    assert Calculator.divide(0, 0) == {:error, :division_by_zero}
  end

  test "factorial/1 calculates factorial correctly" do
    assert Calculator.factorial(0) == 1
    assert Calculator.factorial(1) == 1
    assert Calculator.factorial(5) == 120
    assert Calculator.factorial(10) == 3_628_800
  end

  test "factorial/1 returns error for negative numbers" do
    assert Calculator.factorial(-1) == {:error, :negative_number}
    assert Calculator.factorial(-10) == {:error, :negative_number}
  end
end

# ==============================================================================
# Section 6: Running Tests
# ==============================================================================

# In a Mix project, tests are run with:
#
# mix test                    # Run all tests
# mix test test/file_test.exs # Run specific file
# mix test test/file_test.exs:10  # Run test at line 10
# mix test --trace            # Show test names as they run
# mix test --failed           # Re-run only failed tests
# mix test --seed 12345       # Run with specific seed
# mix test --max-failures 1   # Stop after first failure
#
# For standalone .exs files like this one:
# elixir 01_exunit_intro.exs

# ==============================================================================
# Section 7: Test Structure Conventions
# ==============================================================================

defmodule StringHelperTest do
  use ExUnit.Case

  # Convention: Test module name matches module name + "Test"
  # StringHelper -> StringHelperTest

  # Convention: Test file matches source file path
  # lib/string_helper.ex -> test/string_helper_test.exs

  # Convention: One test per behavior/edge case
  test "String.trim/1 removes leading whitespace" do
    assert String.trim("  hello") == "hello"
  end

  test "String.trim/1 removes trailing whitespace" do
    assert String.trim("hello  ") == "hello"
  end

  test "String.trim/1 removes both leading and trailing whitespace" do
    assert String.trim("  hello  ") == "hello"
  end

  test "String.trim/1 handles empty string" do
    assert String.trim("") == ""
  end

  test "String.trim/1 handles string with only whitespace" do
    assert String.trim("   ") == ""
  end
end

# ==============================================================================
# Section 8: doctest - Testing Documentation Examples
# ==============================================================================

defmodule Greeter do
  @moduledoc """
  A module for greeting people.
  """

  @doc """
  Greets a person by name.

  ## Examples

      iex> Greeter.hello("World")
      "Hello, World!"

      iex> Greeter.hello("Elixir")
      "Hello, Elixir!"

  """
  def hello(name) do
    "Hello, #{name}!"
  end

  @doc """
  Creates a formal greeting.

  ## Examples

      iex> Greeter.formal_hello("Dr. Smith")
      "Good day, Dr. Smith. How do you do?"

  """
  def formal_hello(name) do
    "Good day, #{name}. How do you do?"
  end
end

defmodule GreeterTest do
  use ExUnit.Case

  # doctest automatically tests all iex> examples in the module's docs
  doctest Greeter

  # You can also add additional tests alongside doctests
  test "hello/1 handles empty string" do
    assert Greeter.hello("") == "Hello, !"
  end
end

# ==============================================================================
# Section 9: Test Timeouts
# ==============================================================================

defmodule TimeoutExamplesTest do
  use ExUnit.Case

  # Default timeout is 60 seconds
  # You can set a custom timeout for slow tests

  @tag timeout: 120_000  # 2 minutes
  test "slow test with custom timeout" do
    # Simulating slow operation
    :timer.sleep(100)
    assert true
  end

  # Or set timeout for the entire module
  # @moduletag timeout: 120_000
end

# ==============================================================================
# Exercises
# ==============================================================================

defmodule Exercises do
  @moduledoc """
  Exercises for ExUnit Introduction.
  Complete the implementations and tests below.
  """

  # Exercise 1: Implement the functions and write tests

  defmodule StringUtils do
    @doc """
    Reverses a string.

    ## Examples
        iex> Exercises.StringUtils.reverse("hello")
        "olleh"
    """
    def reverse(string) do
      # Your implementation here
      String.reverse(string)
    end

    @doc """
    Checks if a string is a palindrome (reads same forwards and backwards).

    ## Examples
        iex> Exercises.StringUtils.palindrome?("racecar")
        true

        iex> Exercises.StringUtils.palindrome?("hello")
        false
    """
    def palindrome?(string) do
      # Your implementation here
      clean = String.downcase(string) |> String.replace(~r/[^a-z0-9]/, "")
      clean == String.reverse(clean)
    end

    @doc """
    Counts the number of words in a string.

    ## Examples
        iex> Exercises.StringUtils.word_count("hello world")
        2
    """
    def word_count(string) do
      # Your implementation here
      string
      |> String.split(~r/\s+/, trim: true)
      |> length()
    end
  end

  # Exercise 2: Write comprehensive tests for StringUtils
  # Include edge cases like empty strings, single words, multiple spaces, etc.
end

defmodule StringUtilsTest do
  use ExUnit.Case

  # Test reverse/1
  test "reverse/1 reverses a string" do
    assert Exercises.StringUtils.reverse("hello") == "olleh"
  end

  test "reverse/1 handles empty string" do
    assert Exercises.StringUtils.reverse("") == ""
  end

  test "reverse/1 handles single character" do
    assert Exercises.StringUtils.reverse("a") == "a"
  end

  # Test palindrome?/1
  test "palindrome?/1 returns true for palindromes" do
    assert Exercises.StringUtils.palindrome?("racecar")
    assert Exercises.StringUtils.palindrome?("A man a plan a canal Panama")
    assert Exercises.StringUtils.palindrome?("Was it a car or a cat I saw")
  end

  test "palindrome?/1 returns false for non-palindromes" do
    refute Exercises.StringUtils.palindrome?("hello")
    refute Exercises.StringUtils.palindrome?("world")
  end

  test "palindrome?/1 handles empty string" do
    assert Exercises.StringUtils.palindrome?("")
  end

  # Test word_count/1
  test "word_count/1 counts words correctly" do
    assert Exercises.StringUtils.word_count("hello world") == 2
    assert Exercises.StringUtils.word_count("one two three four") == 4
  end

  test "word_count/1 handles multiple spaces" do
    assert Exercises.StringUtils.word_count("hello    world") == 2
  end

  test "word_count/1 handles empty string" do
    assert Exercises.StringUtils.word_count("") == 0
  end

  test "word_count/1 handles single word" do
    assert Exercises.StringUtils.word_count("hello") == 1
  end

  # Enable doctest
  doctest Exercises.StringUtils
end

# ==============================================================================
# Summary
# ==============================================================================

# Key concepts covered:
#
# 1. ExUnit.start() - Must be called before tests run
# 2. use ExUnit.Case - Sets up a test module
# 3. test "description" do ... end - Defines a test case
# 4. assert/refute - Basic assertion macros
# 5. Pattern matching in assertions
# 6. doctest - Test documentation examples
# 7. Test naming conventions
# 8. Running tests with mix test
#
# Best practices:
# - One assertion concept per test
# - Descriptive test names
# - Test edge cases
# - Keep tests independent
# - Use doctests for documentation examples
#
# Next lesson: Test Organization with describe blocks and setup
