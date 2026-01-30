# ============================================================================
# Lesson 13: Quote and Unquote - Understanding Elixir's AST
# ============================================================================
#
# In this lesson, you'll learn about one of Elixir's most powerful features:
# metaprogramming through code as data. We'll explore how Elixir represents
# code internally and how to manipulate it using quote and unquote.
#
# Topics covered:
# - The Abstract Syntax Tree (AST)
# - The quote macro
# - The unquote macro
# - Macro.to_string and other AST utilities
# - Understanding code as data (homoiconicity)
#
# ============================================================================

IO.puts """
================================================================================
                    QUOTE AND UNQUOTE - CODE AS DATA
================================================================================
"""

# ============================================================================
# Part 1: Introduction to the AST
# ============================================================================

IO.puts """
--------------------------------------------------------------------------------
Part 1: Introduction to the Abstract Syntax Tree (AST)
--------------------------------------------------------------------------------

Every piece of Elixir code is transformed into an Abstract Syntax Tree (AST)
before compilation. The AST is a tree representation of your code using
simple Elixir data structures: tuples, atoms, and lists.

The AST uses a simple three-element tuple format:
  {atom | tuple, metadata, arguments}

Where:
  - First element: the function/operator name (atom) or another tuple
  - Second element: metadata (like line numbers)
  - Third element: list of arguments

Let's see how different expressions are represented in the AST:
"""

# Simple expressions in the AST
IO.puts "\n--- Simple Values ---"
IO.puts "Atoms, numbers, and strings are literals (represent themselves):"

IO.inspect(quote do: :hello, label: "quote do: :hello")
IO.inspect(quote do: 42, label: "quote do: 42")
IO.inspect(quote do: "world", label: "quote do: \"world\"")
IO.inspect(quote do: [1, 2, 3], label: "quote do: [1, 2, 3]")
IO.inspect(quote do: {1, 2}, label: "quote do: {1, 2}")

IO.puts "\n--- Variables ---"
IO.puts "Variables are represented as 3-tuples:"

IO.inspect(quote do: x, label: "quote do: x")
IO.inspect(quote do: my_variable, label: "quote do: my_variable")

IO.puts "\n--- Function Calls ---"
IO.puts "Function calls show the tuple structure clearly:"

IO.inspect(quote do: sum(1, 2), label: "quote do: sum(1, 2)")
IO.inspect(quote do: Enum.map(list, func), label: "quote do: Enum.map(list, func)")

IO.puts "\n--- Operators ---"
IO.puts "Operators are just function calls:"

IO.inspect(quote do: 1 + 2, label: "quote do: 1 + 2")
IO.inspect(quote do: a && b, label: "quote do: a && b")
IO.inspect(quote do: not true, label: "quote do: not true")

# ============================================================================
# Part 2: The quote Macro
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 2: The quote Macro
--------------------------------------------------------------------------------

The 'quote' macro converts Elixir code into its AST representation.
It prevents code from being evaluated and instead returns the data structure.

Think of quote as "give me the code representation, don't execute it."
"""

IO.puts "--- Basic Quote Usage ---"

# Quote returns the AST, not the result
quoted_addition = quote do: 1 + 2
IO.inspect(quoted_addition, label: "Quoted 1 + 2")
IO.puts "Notice: We get {:+, [], [1, 2]}, not 3!"

# More complex expressions
quoted_if = quote do
  if x > 0 do
    :positive
  else
    :non_positive
  end
end
IO.inspect(quoted_if, label: "\nQuoted if expression", pretty: true)

# Quote preserves structure
quoted_pipeline = quote do
  list
  |> Enum.map(&(&1 * 2))
  |> Enum.sum()
end
IO.inspect(quoted_pipeline, label: "\nQuoted pipeline", pretty: true)

# ============================================================================
# Part 3: The unquote Macro
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 3: The unquote Macro
--------------------------------------------------------------------------------

The 'unquote' macro injects values INTO quoted expressions.
It's like string interpolation but for code.

While quote says "don't evaluate this", unquote says "evaluate this NOW
and insert the result into the quoted expression."
"""

IO.puts "--- Basic Unquote Usage ---"

# Inject a value into quoted code
value = 10
quoted_with_value = quote do
  1 + unquote(value)
end
IO.inspect(quoted_with_value, label: "quote do: 1 + unquote(10)")
IO.puts "The 10 is inserted directly into the AST!"

# Dynamic function names
func_name = :greet
quoted_call = quote do
  unquote(func_name)("Hello!")
end
IO.inspect(quoted_call, label: "\nDynamic function call")

# Building expressions dynamically
left = quote do: a
right = quote do: b
operation = :+

combined = quote do
  unquote(operation)(unquote(left), unquote(right))
end
IO.inspect(combined, label: "\nCombined expression (a + b)")

IO.puts "\n--- unquote_splicing for Lists ---"
IO.puts "Use unquote_splicing to inject list elements:"

args = [1, 2, 3]
quoted_call_with_args = quote do
  my_function(unquote_splicing(args))
end
IO.inspect(quoted_call_with_args, label: "my_function(1, 2, 3)")

# Difference between unquote and unquote_splicing
IO.puts "\n--- unquote vs unquote_splicing ---"
items = [1, 2, 3]

with_unquote = quote do
  [unquote(items)]
end
IO.inspect(with_unquote, label: "With unquote (nested)")

with_splicing = quote do
  [unquote_splicing(items)]
end
IO.inspect(with_splicing, label: "With unquote_splicing (flat)")

# ============================================================================
# Part 4: Macro.to_string and AST Utilities
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 4: Macro.to_string and AST Utilities
--------------------------------------------------------------------------------

Elixir provides utilities to work with the AST:
- Macro.to_string/1 - converts AST back to readable code string
- Macro.expand/2 - expands macros in the AST
- Macro.escape/1 - escapes a value to be inserted in the AST
- Macro.prewalk/2 and Macro.postwalk/2 - traverse the AST
"""

IO.puts "--- Macro.to_string ---"

quoted = quote do
  def hello(name) do
    IO.puts("Hello, #{name}!")
  end
end

code_string = Macro.to_string(quoted)
IO.puts "AST converted back to string:"
IO.puts code_string

IO.puts "\n--- Building and Converting Complex Expressions ---"

complex_quoted = quote do
  defmodule Calculator do
    def add(a, b), do: a + b
    def subtract(a, b), do: a - b

    def calculate(op, a, b) do
      case op do
        :add -> add(a, b)
        :subtract -> subtract(a, b)
      end
    end
  end
end

IO.puts "Complex module definition:"
IO.puts Macro.to_string(complex_quoted)

IO.puts "\n--- Macro.escape ---"
IO.puts "Macro.escape converts runtime values to their AST representation:"

map_value = %{name: "Alice", age: 30}
escaped = Macro.escape(map_value)
IO.inspect(escaped, label: "Escaped map")
IO.puts "This is useful when you need to inject complex values into macros."

IO.puts "\n--- Walking the AST ---"

simple_ast = quote do
  x + y * z
end

IO.puts "Original AST:"
IO.inspect(simple_ast)

# Transform the AST - replace all variables with :replaced
transformed = Macro.prewalk(simple_ast, fn
  {name, meta, context} when is_atom(name) and is_atom(context) ->
    {:replaced, meta, context}
  other ->
    other
end)

IO.puts "\nTransformed AST (variables replaced):"
IO.inspect(transformed)
IO.puts "As string: #{Macro.to_string(transformed)}"

# ============================================================================
# Part 5: Practical Examples
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 5: Practical Examples
--------------------------------------------------------------------------------

Let's see some practical applications of quote and unquote.
"""

IO.puts "--- Example 1: Building Conditional Logic ---"

defmodule ConditionalBuilder do
  def build_check(field, operator, value) do
    quote do
      unquote(field) |> unquote(operator)(unquote(value))
    end
  end
end

check_ast = ConditionalBuilder.build_check(:age, :>=, 18)
IO.puts "Generated check: #{Macro.to_string(check_ast)}"

IO.puts "\n--- Example 2: Code Templates ---"

defmodule TemplateExample do
  def generate_getter(field_name) do
    quote do
      def unquote(field_name)(struct) do
        Map.get(struct, unquote(field_name))
      end
    end
  end
end

getter_ast = TemplateExample.generate_getter(:email)
IO.puts "Generated getter:"
IO.puts Macro.to_string(getter_ast)

IO.puts "\n--- Example 3: Analyzing Code Structure ---"

defmodule ASTAnalyzer do
  def count_operations(ast) do
    {_new_ast, count} = Macro.prewalk(ast, 0, fn
      {:+, _, _} = node, acc -> {node, acc + 1}
      {:-, _, _} = node, acc -> {node, acc + 1}
      {:*, _, _} = node, acc -> {node, acc + 1}
      {:/, _, _} = node, acc -> {node, acc + 1}
      node, acc -> {node, acc}
    end)
    count
  end

  def list_variables(ast) do
    {_new_ast, vars} = Macro.prewalk(ast, [], fn
      {name, _meta, context} = node, acc when is_atom(name) and is_atom(context) ->
        {node, [name | acc]}
      node, acc ->
        {node, acc}
    end)
    Enum.uniq(vars)
  end
end

expression = quote do
  (a + b) * (c - d) / e + f
end

IO.puts "Expression: #{Macro.to_string(expression)}"
IO.puts "Number of arithmetic operations: #{ASTAnalyzer.count_operations(expression)}"
IO.inspect(ASTAnalyzer.list_variables(expression), label: "Variables used")

# ============================================================================
# Part 6: The bind_quoted Option
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 6: The bind_quoted Option
--------------------------------------------------------------------------------

When writing macros, you often want to ensure values are only evaluated once.
The bind_quoted option provides a cleaner way to do this.
"""

IO.puts "--- Without bind_quoted (potential multiple evaluation) ---"

value = 42
ast_without = quote do
  IO.puts("Value is: #{unquote(value)}")
  IO.puts("Doubled: #{unquote(value) * 2}")
end
IO.puts Macro.to_string(ast_without)

IO.puts "\n--- With bind_quoted (guaranteed single evaluation) ---"

ast_with = quote bind_quoted: [value: value] do
  IO.puts("Value is: #{value}")
  IO.puts("Doubled: #{value * 2}")
end
IO.puts Macro.to_string(ast_with)

IO.puts """

The bind_quoted version ensures that if 'value' were an expression with
side effects, it would only be evaluated once.
"""

# ============================================================================
# Exercises
# ============================================================================

IO.puts """

================================================================================
                              EXERCISES
================================================================================

Complete these exercises to practice working with quote and unquote.
Uncomment each exercise and implement the solution.
"""

IO.puts """
--------------------------------------------------------------------------------
Exercise 1: Quote Explorer
--------------------------------------------------------------------------------
Explore how different Elixir constructs are represented in the AST.
Write code that quotes each of the following and prints the result:
  a) A map literal: %{a: 1, b: 2}
  b) A function with a guard: fn x when x > 0 -> x end
  c) A comprehension: for x <- list, do: x * 2
  d) A try/rescue block
"""

# Exercise 1 Solution:
IO.puts "--- Exercise 1 Solution ---"

# a) Map literal
map_ast = quote do: %{a: 1, b: 2}
IO.inspect(map_ast, label: "Map literal AST")

# b) Function with guard
fn_guard_ast = quote do: fn x when x > 0 -> x end
IO.inspect(fn_guard_ast, label: "Function with guard AST", pretty: true)

# c) Comprehension
comprehension_ast = quote do: (for x <- list, do: x * 2)
IO.inspect(comprehension_ast, label: "Comprehension AST", pretty: true)

# d) Try/rescue
try_ast = quote do
  try do
    risky_operation()
  rescue
    e -> handle_error(e)
  end
end
IO.inspect(try_ast, label: "Try/rescue AST", pretty: true)

IO.puts """

--------------------------------------------------------------------------------
Exercise 2: AST Builder
--------------------------------------------------------------------------------
Create a function that takes an operator (:+, :-, :*, :/) and two numbers,
and returns the quoted expression for that operation.
Then convert it back to a string to verify.
"""

# Exercise 2 Solution:
IO.puts "--- Exercise 2 Solution ---"

defmodule ASTBuilder do
  def build_operation(operator, left, right) do
    quote do
      unquote(operator)(unquote(left), unquote(right))
    end
  end
end

for {op, a, b} <- [{:+, 10, 5}, {:-, 10, 5}, {:*, 10, 5}, {:/, 10, 5}] do
  ast = ASTBuilder.build_operation(op, a, b)
  IO.puts "#{Macro.to_string(ast)}"
end

IO.puts """

--------------------------------------------------------------------------------
Exercise 3: Variable Renamer
--------------------------------------------------------------------------------
Create a function that takes a quoted expression and a map of old_name => new_name,
and returns a new AST with all specified variables renamed.
"""

# Exercise 3 Solution:
IO.puts "--- Exercise 3 Solution ---"

defmodule VariableRenamer do
  def rename(ast, renames) do
    Macro.prewalk(ast, fn
      {name, meta, context} when is_atom(name) and is_atom(context) ->
        new_name = Map.get(renames, name, name)
        {new_name, meta, context}
      other ->
        other
    end)
  end
end

original = quote do: x + y * z
renamed = VariableRenamer.rename(original, %{x: :a, y: :b, z: :c})

IO.puts "Original: #{Macro.to_string(original)}"
IO.puts "Renamed:  #{Macro.to_string(renamed)}"

IO.puts """

--------------------------------------------------------------------------------
Exercise 4: Expression Counter
--------------------------------------------------------------------------------
Create a module that analyzes an AST and returns statistics:
- Total number of function calls
- Total number of operators
- List of all function names called
"""

# Exercise 4 Solution:
IO.puts "--- Exercise 4 Solution ---"

defmodule ExpressionAnalyzer do
  @operators [:+, :-, :*, :/, :==, :!=, :>, :<, :>=, :<=, :and, :or, :not]

  def analyze(ast) do
    {_ast, stats} = Macro.prewalk(ast, %{calls: 0, operators: 0, functions: []}, fn
      {op, _meta, args} = node, acc when op in @operators and is_list(args) ->
        {node, %{acc | operators: acc.operators + 1}}

      {name, _meta, args} = node, acc when is_atom(name) and is_list(args) ->
        {node, %{acc | calls: acc.calls + 1, functions: [name | acc.functions]}}

      {{:., _, _}, _meta, args} = node, acc when is_list(args) ->
        {node, %{acc | calls: acc.calls + 1}}

      node, acc ->
        {node, acc}
    end)

    %{stats | functions: Enum.uniq(stats.functions)}
  end
end

complex_expr = quote do
  result = calculate(a + b) |> process() |> Enum.map(fn x -> x * 2 end)
  if result > 0, do: success(result), else: failure()
end

stats = ExpressionAnalyzer.analyze(complex_expr)
IO.puts "Expression: #{Macro.to_string(complex_expr)}"
IO.inspect(stats, label: "Statistics")

IO.puts """

--------------------------------------------------------------------------------
Exercise 5: Code Generator
--------------------------------------------------------------------------------
Create a function that generates a quoted module definition with getter and setter
functions for a list of field names.
"""

# Exercise 5 Solution:
IO.puts "--- Exercise 5 Solution ---"

defmodule CodeGenerator do
  def generate_accessors(module_name, fields) do
    functions = Enum.flat_map(fields, fn field ->
      getter = quote do
        def unquote(field)(data) do
          Map.get(data, unquote(field))
        end
      end

      setter_name = String.to_atom("set_#{field}")
      setter = quote do
        def unquote(setter_name)(data, value) do
          Map.put(data, unquote(field), value)
        end
      end

      [getter, setter]
    end)

    quote do
      defmodule unquote(module_name) do
        unquote_splicing(functions)
      end
    end
  end
end

module_ast = CodeGenerator.generate_accessors(Person, [:name, :age, :email])
IO.puts "Generated module:"
IO.puts Macro.to_string(module_ast)

IO.puts """

--------------------------------------------------------------------------------
Exercise 6: AST Simplifier
--------------------------------------------------------------------------------
Create a function that simplifies arithmetic expressions in an AST by
evaluating constant sub-expressions at compile time.
For example: quote do: 2 + 3 + x should become quote do: 5 + x
"""

# Exercise 6 Solution:
IO.puts "--- Exercise 6 Solution ---"

defmodule ASTSimplifier do
  def simplify(ast) do
    Macro.prewalk(ast, fn
      # Addition of two numbers
      {:+, _meta, [left, right]} when is_number(left) and is_number(right) ->
        left + right

      # Subtraction of two numbers
      {:-, _meta, [left, right]} when is_number(left) and is_number(right) ->
        left - right

      # Multiplication of two numbers
      {:*, _meta, [left, right]} when is_number(left) and is_number(right) ->
        left * right

      # Division of two numbers (only if cleanly divisible)
      {:/, _meta, [left, right]} when is_number(left) and is_number(right) and right != 0 ->
        left / right

      # Identity operations
      {:+, _meta, [0, right]} -> right
      {:+, _meta, [left, 0]} -> left
      {:*, _meta, [1, right]} -> right
      {:*, _meta, [left, 1]} -> left
      {:*, _meta, [0, _right]} -> 0
      {:*, _meta, [_left, 0]} -> 0

      # Keep everything else
      other -> other
    end)
  end
end

# Test cases
test_expressions = [
  quote(do: 2 + 3),
  quote(do: 2 + 3 + x),
  quote(do: x * 1),
  quote(do: 0 + y),
  quote(do: (2 * 3) + (4 - 1)),
  quote(do: x * 0 + y)
]

IO.puts "Simplification results:"
for expr <- test_expressions do
  simplified = ASTSimplifier.simplify(expr)
  IO.puts "  #{Macro.to_string(expr)} => #{Macro.to_string(simplified)}"
end

IO.puts """

================================================================================
                              SUMMARY
================================================================================

Key concepts from this lesson:

1. AST Structure: Elixir code is represented as tuples: {name, metadata, args}
   - Literals (atoms, numbers, strings, lists, 2-tuples) represent themselves
   - Variables are 3-tuples: {name, metadata, context}
   - Function calls are 3-tuples with a list of arguments

2. quote: Converts code to its AST representation without evaluating it
   - quote do: 1 + 2 returns {:+, [], [1, 2]}, not 3

3. unquote: Injects values into quoted code
   - Works like string interpolation for code
   - unquote_splicing injects list elements

4. AST Utilities:
   - Macro.to_string/1: Convert AST back to code string
   - Macro.escape/1: Convert values to AST representation
   - Macro.prewalk/postwalk: Traverse and transform AST

5. bind_quoted: Ensures values are evaluated once in macro definitions

Understanding quote and unquote is essential for writing macros,
which we'll explore in the next lesson!

================================================================================
"""
