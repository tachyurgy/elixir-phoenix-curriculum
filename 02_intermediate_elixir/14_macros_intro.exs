# ============================================================================
# Lesson 14: Introduction to Macros
# ============================================================================
#
# Macros are one of Elixir's most powerful features, allowing you to extend
# the language itself. In this lesson, you'll learn how to write macros,
# understand macro hygiene, and know when (and when not) to use them.
#
# Topics covered:
# - What macros are and how they work
# - defmacro and macro definition
# - Writing simple macros
# - Macro hygiene and variable scope
# - When to use macros vs functions
#
# ============================================================================

IO.puts """
================================================================================
                    INTRODUCTION TO MACROS
================================================================================
"""

# ============================================================================
# Part 1: What Are Macros?
# ============================================================================

IO.puts """
--------------------------------------------------------------------------------
Part 1: What Are Macros?
--------------------------------------------------------------------------------

Macros are compile-time code transformations. Unlike functions that work with
values at runtime, macros work with code (AST) at compile time.

Key differences from functions:
  1. Macros receive AST (quoted expressions), not evaluated values
  2. Macros return AST that replaces the macro call
  3. Macros are expanded at compile time, not runtime
  4. Macros can generate any valid Elixir code

Think of macros as "code that writes code."
"""

# Simple comparison: Function vs Macro behavior
defmodule FunctionVsMacro do
  # A regular function - receives the VALUE of the argument
  def my_function(x) do
    IO.puts "Function received: #{inspect(x)}"
    x * 2
  end

  # A macro - receives the AST of the argument
  defmacro my_macro(x) do
    IO.puts "Macro received AST: #{inspect(x)}"
    quote do
      unquote(x) * 2
    end
  end
end

IO.puts "--- Function vs Macro ---"
require FunctionVsMacro
result_fn = FunctionVsMacro.my_function(5)
IO.puts "Function result: #{result_fn}\n"

# Note: The macro receives the AST at compile time
# You'll see the "Macro received AST" message during compilation
result_macro = FunctionVsMacro.my_macro(5)
IO.puts "Macro result: #{result_macro}"

# ============================================================================
# Part 2: Basic Macro Definition
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 2: Basic Macro Definition with defmacro
--------------------------------------------------------------------------------

Macros are defined using defmacro. They must return a quoted expression
that will replace the macro call in the code.
"""

defmodule BasicMacros do
  # The simplest macro - just returns a value
  defmacro say_hello do
    quote do
      IO.puts("Hello from a macro!")
    end
  end

  # A macro that takes an argument
  defmacro loud(message) do
    quote do
      String.upcase(unquote(message)) <> "!"
    end
  end

  # A macro that transforms code
  defmacro double_call(expression) do
    quote do
      unquote(expression)
      unquote(expression)
    end
  end

  # A macro showing what it generates
  defmacro debug_ast(expression) do
    string_repr = Macro.to_string(expression)
    quote do
      IO.puts("Expression: " <> unquote(string_repr))
      IO.puts("Result: #{inspect(unquote(expression))}")
    end
  end
end

IO.puts "--- Using Basic Macros ---"
require BasicMacros

BasicMacros.say_hello()

loud_result = BasicMacros.loud("hello world")
IO.puts "Loud: #{loud_result}"

IO.puts "\nDouble call macro:"
BasicMacros.double_call(IO.puts("This prints twice!"))

IO.puts "\nDebug AST macro:"
BasicMacros.debug_ast(Enum.sum([1, 2, 3, 4, 5]))

# ============================================================================
# Part 3: Practical Macro Examples
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 3: Practical Macro Examples
--------------------------------------------------------------------------------

Let's look at some practical macros that demonstrate real-world use cases.
"""

defmodule PracticalMacros do
  # unless macro (similar to the built-in one)
  defmacro my_unless(condition, do: block) do
    quote do
      if !unquote(condition) do
        unquote(block)
      end
    end
  end

  # Timing macro - measures execution time
  defmacro time_it(description, do: block) do
    quote do
      start = System.monotonic_time(:microsecond)
      result = unquote(block)
      finish = System.monotonic_time(:microsecond)
      IO.puts("#{unquote(description)}: #{finish - start} microseconds")
      result
    end
  end

  # Assert macro for testing
  defmacro assert(expression) do
    string_repr = Macro.to_string(expression)
    quote do
      unless unquote(expression) do
        raise "Assertion failed: #{unquote(string_repr)}"
      end
      :ok
    end
  end

  # Log macro with file and line info
  defmacro log(message) do
    quote do
      IO.puts("[#{__MODULE__}:#{__ENV__.line}] #{unquote(message)}")
    end
  end
end

IO.puts "--- Practical Macros in Action ---"
require PracticalMacros

x = 10
PracticalMacros.my_unless x > 20 do
  IO.puts "x is not greater than 20"
end

IO.puts ""
result = PracticalMacros.time_it "List comprehension" do
  for i <- 1..1000, do: i * i
end
IO.puts "Result length: #{length(result)}"

IO.puts ""
PracticalMacros.assert(1 + 1 == 2)
IO.puts "Assertion passed!"

# ============================================================================
# Part 4: Macro Hygiene
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 4: Macro Hygiene
--------------------------------------------------------------------------------

Elixir macros are "hygienic" by default. This means variables defined inside
a macro don't leak into the caller's scope, and vice versa.

This prevents accidental variable shadowing and name collisions.
"""

defmodule HygieneExamples do
  # This macro defines its own 'x' - it won't affect caller's 'x'
  defmacro hygienic_example do
    quote do
      x = "I'm inside the macro"
      IO.puts("Macro's x: #{x}")
    end
  end

  # To intentionally access caller's variable, use var!/2
  defmacro unhygienic_example do
    quote do
      var!(x) = "Modified by macro"
    end
  end

  # Demonstrating hygiene with a counter macro
  defmacro increment do
    quote do
      # This 'counter' is isolated from caller's scope
      counter = 0
      counter + 1
    end
  end
end

IO.puts "--- Macro Hygiene Demo ---"
require HygieneExamples

x = "I'm in the caller's scope"
IO.puts "Before macro - caller's x: #{x}"

HygieneExamples.hygienic_example()
IO.puts "After macro - caller's x: #{x}"
IO.puts "(Notice: caller's x is unchanged!)"

IO.puts "\n--- Intentionally Breaking Hygiene with var! ---"
y = "original"
IO.puts "Before unhygienic macro: y = #{y}"

# Uncomment to see var! in action (it will modify y):
# y = "will be changed"
# HygieneExamples.unhygienic_example()
# IO.puts "After unhygienic macro: x = #{x}"

IO.puts """

Hygiene rules:
1. Variables in macros are scoped to the macro
2. Use var!/2 to access/modify caller's variables (use sparingly!)
3. Use Macro.var/2 to generate unique variable names
4. The __CALLER__ special form gives info about the calling context
"""

# ============================================================================
# Part 5: Working with __CALLER__ and Context
# ============================================================================

IO.puts """
--------------------------------------------------------------------------------
Part 5: Working with __CALLER__ and Context
--------------------------------------------------------------------------------

The __CALLER__ special form provides information about where a macro is called.
"""

defmodule CallerInfo do
  defmacro where_am_i do
    caller = __CALLER__
    quote do
      IO.puts """
      Called from:
        Module: #{unquote(caller.module)}
        Function: #{inspect(unquote(caller.function))}
        File: #{unquote(caller.file)}
        Line: #{unquote(caller.line)}
      """
    end
  end

  defmacro compile_time_info do
    now = DateTime.utc_now() |> DateTime.to_string()
    quote do
      IO.puts("This code was compiled at: #{unquote(now)}")
    end
  end
end

require CallerInfo
CallerInfo.where_am_i()
CallerInfo.compile_time_info()

# ============================================================================
# Part 6: When to Use Macros
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 6: When to Use Macros (and When Not To)
--------------------------------------------------------------------------------

The golden rule: "Don't write a macro when a function will do."

USE macros when you need to:
  1. Transform code at compile time
  2. Create new control flow structures
  3. Generate boilerplate code
  4. Access compile-time information (__CALLER__, __ENV__)
  5. Create DSLs (Domain Specific Languages)
  6. Delay evaluation of expressions

DON'T use macros when:
  1. A regular function can solve the problem
  2. You just want to abstract common code
  3. You're doing runtime computations
  4. The complexity outweighs the benefits
"""

# Example: When NOT to use a macro
defmodule AvoidMacros do
  # BAD: Using a macro for what a function can do
  defmacro bad_double(x) do
    quote do
      unquote(x) * 2
    end
  end

  # GOOD: Use a regular function
  def good_double(x), do: x * 2
end

# Example: When macros ARE appropriate
defmodule GoodMacroUse do
  # GOOD: Control flow that can't be done with functions
  # (Functions evaluate all arguments, but we want short-circuit)
  defmacro and_then(condition, do: success, else: failure) do
    quote do
      case unquote(condition) do
        truthy when truthy not in [false, nil] -> unquote(success)
        _ -> unquote(failure)
      end
    end
  end

  # GOOD: Code generation based on compile-time data
  defmacro define_validators(fields) do
    validators = for {field, type} <- fields do
      func_name = String.to_atom("validate_#{field}")
      quote do
        def unquote(func_name)(value) do
          is_valid?(value, unquote(type))
        end
      end
    end

    quote do
      def is_valid?(value, :string), do: is_binary(value)
      def is_valid?(value, :integer), do: is_integer(value)
      def is_valid?(value, :float), do: is_float(value)
      unquote_splicing(validators)
    end
  end
end

IO.puts "--- Good Macro Use Examples ---"
require GoodMacroUse

# The and_then macro demonstrates control flow
result = GoodMacroUse.and_then true do
  "success branch"
else
  "failure branch"
end
IO.puts "and_then result: #{result}"

# ============================================================================
# Part 7: Common Macro Patterns
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 7: Common Macro Patterns
--------------------------------------------------------------------------------

Here are some patterns you'll see frequently in Elixir macros.
"""

defmodule MacroPatterns do
  # Pattern 1: Wrapping expressions (decoration pattern)
  defmacro with_logging(name, do: block) do
    quote do
      IO.puts("[START] #{unquote(name)}")
      result = unquote(block)
      IO.puts("[END] #{unquote(name)} -> #{inspect(result)}")
      result
    end
  end

  # Pattern 2: Conditional code generation
  defmacro if_dev(do: block) do
    if Mix.env() == :dev do
      block
    else
      nil
    end
  end

  # Pattern 3: Building block expressions
  defmacro pipe_debug(value, operations) when is_list(operations) do
    Enum.reduce(operations, value, fn op, acc ->
      quote do
        result = unquote(acc) |> unquote(op)
        IO.puts("After #{unquote(Macro.to_string(op))}: #{inspect(result)}")
        result
      end
    end)
  end

  # Pattern 4: Defining functions dynamically
  defmacro defstatus(name, code) do
    func_name = String.to_atom("status_#{name}")
    check_name = String.to_atom("is_#{name}?")

    quote do
      def unquote(func_name)(), do: {unquote(name), unquote(code)}
      def unquote(check_name)(status), do: status == unquote(name)
    end
  end
end

IO.puts "--- Macro Patterns Demo ---"
require MacroPatterns

MacroPatterns.with_logging "calculation" do
  Enum.sum(1..100)
end

# ============================================================================
# Exercises
# ============================================================================

IO.puts """

================================================================================
                              EXERCISES
================================================================================
"""

IO.puts """
--------------------------------------------------------------------------------
Exercise 1: Repeat Macro
--------------------------------------------------------------------------------
Create a macro called 'repeat' that executes a block n times.
Usage: repeat 3 do IO.puts("Hello") end
"""

# Exercise 1 Solution:
defmodule RepeatMacro do
  defmacro repeat(n, do: block) do
    quote do
      for _ <- 1..unquote(n) do
        unquote(block)
      end
      :ok
    end
  end
end

IO.puts "--- Exercise 1 Solution ---"
require RepeatMacro
RepeatMacro.repeat 3 do
  IO.puts("Hello!")
end

IO.puts """

--------------------------------------------------------------------------------
Exercise 2: Swap Macro
--------------------------------------------------------------------------------
Create a macro that swaps the values of two variables.
This requires breaking hygiene with var!
Usage: swap(a, b) - after this, a has b's value and vice versa
"""

# Exercise 2 Solution:
defmodule SwapMacro do
  defmacro swap({name_a, _, _} = var_a, {name_b, _, _} = var_b) do
    quote do
      temp = unquote(var_a)
      var!(unquote(name_a)) = unquote(var_b)
      var!(unquote(name_b)) = temp
    end
  end
end

IO.puts "--- Exercise 2 Solution ---"
require SwapMacro
a = 1
b = 2
IO.puts "Before swap: a=#{a}, b=#{b}"
SwapMacro.swap(a, b)
IO.puts "After swap: a=#{a}, b=#{b}"

IO.puts """

--------------------------------------------------------------------------------
Exercise 3: Benchmark Macro
--------------------------------------------------------------------------------
Create a macro that runs a block multiple times and reports statistics:
- Number of runs
- Total time
- Average time
- Min/Max time
"""

# Exercise 3 Solution:
defmodule BenchmarkMacro do
  defmacro benchmark(iterations, description, do: block) do
    quote do
      times = for _ <- 1..unquote(iterations) do
        start = System.monotonic_time(:microsecond)
        unquote(block)
        System.monotonic_time(:microsecond) - start
      end

      total = Enum.sum(times)
      avg = total / unquote(iterations)
      min = Enum.min(times)
      max = Enum.max(times)

      IO.puts """
      Benchmark: #{unquote(description)}
        Iterations: #{unquote(iterations)}
        Total time: #{total} microseconds
        Average:    #{Float.round(avg, 2)} microseconds
        Min:        #{min} microseconds
        Max:        #{max} microseconds
      """
    end
  end
end

IO.puts "--- Exercise 3 Solution ---"
require BenchmarkMacro
BenchmarkMacro.benchmark 100, "List generation" do
  Enum.to_list(1..1000)
end

IO.puts """

--------------------------------------------------------------------------------
Exercise 4: Memoization Macro
--------------------------------------------------------------------------------
Create a defmemo macro that defines a memoized function.
The function should cache results based on arguments.
(Hint: Use an ETS table or Agent for storage)
"""

# Exercise 4 Solution:
defmodule MemoMacro do
  defmacro defmemo(definition, do: body) do
    {func_name, args} = extract_function_info(definition)

    quote do
      def unquote(func_name)(unquote_splicing(args)) do
        cache_name = __MODULE__.MemoCache

        # Ensure cache exists
        unless :ets.whereis(cache_name) != :undefined do
          :ets.new(cache_name, [:set, :public, :named_table])
        end

        key = {unquote(func_name), {unquote_splicing(args)}}

        case :ets.lookup(cache_name, key) do
          [{^key, cached_value}] ->
            cached_value
          [] ->
            result = unquote(body)
            :ets.insert(cache_name, {key, result})
            result
        end
      end
    end
  end

  defp extract_function_info({func_name, _, args}) do
    args = args || []
    {func_name, args}
  end
end

defmodule FibMemo do
  require MemoMacro

  MemoMacro.defmemo fib(n) do
    if n <= 1 do
      n
    else
      fib(n - 1) + fib(n - 2)
    end
  end
end

IO.puts "--- Exercise 4 Solution ---"
IO.puts "Fibonacci(30) = #{FibMemo.fib(30)}"
IO.puts "Fibonacci(35) = #{FibMemo.fib(35)}"

IO.puts """

--------------------------------------------------------------------------------
Exercise 5: Pipeline Logger
--------------------------------------------------------------------------------
Create a macro that wraps a pipeline and logs each step.
Usage: debug_pipe do value |> step1() |> step2() |> step3() end
Output should show the result after each step.
"""

# Exercise 5 Solution:
defmodule PipelineLogger do
  defmacro debug_pipe(do: {:"|>", _, _} = pipeline) do
    steps = flatten_pipeline(pipeline)

    {initial, rest} = List.pop_at(steps, 0)

    Enum.reduce(rest, initial, fn step, acc ->
      step_string = Macro.to_string(step)
      quote do
        result = unquote(acc) |> unquote(step)
        IO.puts("  |> #{unquote(step_string)} => #{inspect(result)}")
        result
      end
    end)
  end

  defp flatten_pipeline({:"|>", _, [left, right]}) do
    flatten_pipeline(left) ++ [right]
  end
  defp flatten_pipeline(other), do: [other]
end

IO.puts "--- Exercise 5 Solution ---"
require PipelineLogger
IO.puts "Pipeline steps:"
PipelineLogger.debug_pipe do
  [1, 2, 3, 4, 5]
  |> Enum.map(&(&1 * 2))
  |> Enum.filter(&(&1 > 4))
  |> Enum.sum()
end

IO.puts """

--------------------------------------------------------------------------------
Exercise 6: Struct Validator Macro
--------------------------------------------------------------------------------
Create a macro that generates validation functions for struct fields.
It should generate:
- A validate/1 function that checks all fields
- Individual validate_<field>/1 functions
"""

# Exercise 6 Solution:
defmodule StructValidator do
  defmacro defvalidations(validations) do
    individual_validators = for {field, validator} <- validations do
      func_name = String.to_atom("validate_#{field}")
      quote do
        def unquote(func_name)(value) do
          unquote(validator).(value)
        end
      end
    end

    field_checks = for {field, _validator} <- validations do
      func_name = String.to_atom("validate_#{field}")
      quote do
        {unquote(field), unquote(func_name)(Map.get(data, unquote(field)))}
      end
    end

    quote do
      unquote_splicing(individual_validators)

      def validate(data) do
        results = [unquote_splicing(field_checks)]

        errors = results
        |> Enum.filter(fn {_field, result} -> result != :ok end)
        |> Enum.map(fn {field, {:error, msg}} -> {field, msg} end)

        if errors == [] do
          :ok
        else
          {:error, errors}
        end
      end
    end
  end
end

defmodule UserValidator do
  require StructValidator

  StructValidator.defvalidations [
    name: fn
      name when is_binary(name) and byte_size(name) > 0 -> :ok
      _ -> {:error, "name must be a non-empty string"}
    end,
    age: fn
      age when is_integer(age) and age >= 0 and age < 150 -> :ok
      _ -> {:error, "age must be an integer between 0 and 150"}
    end,
    email: fn
      email when is_binary(email) ->
        if String.contains?(email, "@"), do: :ok, else: {:error, "invalid email format"}
      _ ->
        {:error, "email must be a string"}
    end
  ]
end

IO.puts "--- Exercise 6 Solution ---"
valid_user = %{name: "Alice", age: 30, email: "alice@example.com"}
invalid_user = %{name: "", age: -5, email: "invalid"}

IO.puts "Validating valid user:"
IO.inspect(UserValidator.validate(valid_user))

IO.puts "\nValidating invalid user:"
IO.inspect(UserValidator.validate(invalid_user))

IO.puts "\nIndividual validation:"
IO.inspect(UserValidator.validate_name("Bob"), label: "validate_name(\"Bob\")")
IO.inspect(UserValidator.validate_age(25), label: "validate_age(25)")

IO.puts """

================================================================================
                              SUMMARY
================================================================================

Key concepts from this lesson:

1. Macros are compile-time code transformations
   - They receive AST, not evaluated values
   - They return AST that replaces the macro call
   - They are expanded before the code runs

2. defmacro syntax:
   defmacro name(args) do
     quote do
       # code to generate
     end
   end

3. Macro hygiene:
   - Variables in macros are isolated by default
   - Use var!/2 to break hygiene when necessary
   - Use __CALLER__ for call-site information

4. When to use macros:
   - New control flow structures
   - Code generation
   - DSLs
   - Compile-time transformations

5. When NOT to use macros:
   - When a function would work
   - For simple abstractions
   - When complexity outweighs benefits

6. Common patterns:
   - Wrapping/decoration
   - Conditional code generation
   - Dynamic function definition
   - DSL building

Remember: "Write macros responsibly!"

================================================================================
"""
