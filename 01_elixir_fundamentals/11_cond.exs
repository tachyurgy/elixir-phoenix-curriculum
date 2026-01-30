# ============================================================================
# Lesson 11: Cond Expressions
# ============================================================================
#
# Cond is Elixir's way of evaluating multiple conditions when you don't
# need pattern matching. It's like a series of if-else-if statements,
# checking conditions until one is truthy.
#
# Learning Objectives:
# - Use cond for multiple conditions
# - Understand when to use cond vs case
# - Handle default conditions properly
# - Apply cond in practical scenarios
#
# Prerequisites:
# - Lesson 10 (Case) completed
#
# ============================================================================

IO.puts("=" |> String.duplicate(60))
IO.puts("Lesson 11: Cond Expressions")
IO.puts("=" |> String.duplicate(60))

# -----------------------------------------------------------------------------
# Section 1: Basic Cond Syntax
# -----------------------------------------------------------------------------

IO.puts("\n--- Basic Cond Syntax ---")

# Cond evaluates conditions from top to bottom
# Returns the expression for the first truthy condition

x = 10

result = cond do
  x < 0 -> "Negative"
  x == 0 -> "Zero"
  x > 0 -> "Positive"
end

IO.inspect(result, label: "cond for #{x}")

# Unlike case, cond doesn't pattern match - it evaluates boolean expressions
age = 25

category = cond do
  age < 13 -> "child"
  age < 20 -> "teenager"
  age < 65 -> "adult"
  true -> "senior"  # Default case
end

IO.puts("Age #{age} is: #{category}")

# -----------------------------------------------------------------------------
# Section 2: The Default Condition
# -----------------------------------------------------------------------------

IO.puts("\n--- The Default Condition ---")

# Always include a default! Use 'true' as the last condition
# Without a default, you'll get a CondClauseError

score = 150  # Unusual value

grade = cond do
  score >= 90 and score <= 100 -> "A"
  score >= 80 -> "B"
  score >= 70 -> "C"
  score >= 60 -> "D"
  score >= 0 and score < 60 -> "F"
  true -> "Invalid score"  # Catch-all
end

IO.puts("Score #{score}: #{grade}")

# Without 'true', this would raise CondClauseError:
# cond do
#   score >= 90 -> "A"
#   score >= 80 -> "B"
# end  # CondClauseError if score is 70!

# Common default patterns
value = nil

result = cond do
  is_integer(value) and value > 0 -> "Positive integer"
  is_integer(value) and value < 0 -> "Negative integer"
  is_integer(value) -> "Zero"
  is_nil(value) -> "No value"
  true -> "Unknown"
end

IO.puts(result)

# -----------------------------------------------------------------------------
# Section 3: Complex Conditions
# -----------------------------------------------------------------------------

IO.puts("\n--- Complex Conditions ---")

# Cond can evaluate any expression that returns truthy/falsy

temperature = 72
humidity = 65
is_raining = false

weather = cond do
  is_raining and temperature < 40 ->
    "Cold and rainy - stay inside!"

  is_raining ->
    "Rainy - bring an umbrella"

  temperature > 85 and humidity > 80 ->
    "Hot and humid - seek AC"

  temperature > 85 ->
    "Hot but manageable"

  temperature < 32 ->
    "Freezing - bundle up!"

  temperature >= 60 and temperature <= 80 and humidity < 70 ->
    "Perfect weather!"

  true ->
    "Normal weather"
end

IO.puts("Weather advisory: #{weather}")

# Using function calls in conditions
name = "Alice"
items = [1, 2, 3, 4, 5]

description = cond do
  String.length(name) > 10 -> "Long name"
  length(items) == 0 -> "Empty cart"
  length(items) > 10 -> "Full cart"
  Enum.sum(items) > 100 -> "Expensive cart"
  true -> "Normal cart"
end

IO.puts(description)

# -----------------------------------------------------------------------------
# Section 4: Cond vs Case
# -----------------------------------------------------------------------------

IO.puts("\n--- Cond vs Case ---")

# Case: pattern matching
# Cond: boolean conditions

value = 42

# Using case (pattern matching)
result_case = case value do
  0 -> "zero"
  n when n > 0 -> "positive"
  n when n < 0 -> "negative"
end

# Using cond (boolean evaluation)
result_cond = cond do
  value == 0 -> "zero"
  value > 0 -> "positive"
  value < 0 -> "negative"
end

IO.inspect(result_case, label: "case result")
IO.inspect(result_cond, label: "cond result")

# Guidelines:
IO.puts("""

When to use case:
  - Matching on structure (tuples, maps, lists)
  - Matching against specific values
  - When patterns are clearer than conditions

When to use cond:
  - Multiple boolean conditions
  - Range comparisons
  - No specific value to match against
  - Complex logical expressions
""")

# Example where cond is better
x = 5
y = 10

quadrant = cond do
  x > 0 and y > 0 -> "Quadrant I"
  x < 0 and y > 0 -> "Quadrant II"
  x < 0 and y < 0 -> "Quadrant III"
  x > 0 and y < 0 -> "Quadrant IV"
  x == 0 and y == 0 -> "Origin"
  x == 0 -> "Y-axis"
  y == 0 -> "X-axis"
  true -> "Unknown"
end

IO.puts("Point (#{x}, #{y}) is in #{quadrant}")

# -----------------------------------------------------------------------------
# Section 5: Cond with Variables
# -----------------------------------------------------------------------------

IO.puts("\n--- Cond with Variables ---")

# Variables in cond conditions are evaluated, not matched

threshold = 50
value = 75

status = cond do
  value > threshold * 2 -> "Way above threshold"
  value > threshold -> "Above threshold"
  value == threshold -> "At threshold"
  value < threshold -> "Below threshold"
end

IO.puts("Value #{value} with threshold #{threshold}: #{status}")

# Using captured values (calculate once, use in condition)
list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
list_sum = Enum.sum(list)
list_avg = list_sum / length(list)

analysis = cond do
  list_sum > 100 -> "High sum: #{list_sum}"
  list_avg > 10 -> "High average: #{list_avg}"
  length(list) > 10 -> "Long list"
  true -> "Normal list (sum: #{list_sum}, avg: #{list_avg})"
end

IO.puts(analysis)

# -----------------------------------------------------------------------------
# Section 6: Cond in Functions
# -----------------------------------------------------------------------------

IO.puts("\n--- Cond in Functions ---")

defmodule Classifier do
  def classify_number(n) do
    cond do
      not is_number(n) -> {:error, :not_a_number}
      n == 0 -> {:ok, :zero}
      n > 0 and n == trunc(n) -> {:ok, :positive_integer}
      n < 0 and n == trunc(n) -> {:ok, :negative_integer}
      n > 0 -> {:ok, :positive_float}
      n < 0 -> {:ok, :negative_float}
    end
  end

  def describe_list(list) when is_list(list) do
    cond do
      list == [] -> "Empty list"
      length(list) == 1 -> "Single element"
      Enum.all?(list, &is_integer/1) -> "List of integers"
      Enum.all?(list, &is_binary/1) -> "List of strings"
      Enum.all?(list, &is_atom/1) -> "List of atoms"
      true -> "Mixed list"
    end
  end

  def describe_list(_), do: "Not a list"
end

IO.inspect(Classifier.classify_number(42))
IO.inspect(Classifier.classify_number(-3.14))
IO.inspect(Classifier.classify_number(0))
IO.inspect(Classifier.classify_number("hello"))

IO.puts(Classifier.describe_list([]))
IO.puts(Classifier.describe_list([42]))
IO.puts(Classifier.describe_list([1, 2, 3]))
IO.puts(Classifier.describe_list(["a", "b", "c"]))
IO.puts(Classifier.describe_list([1, "two", :three]))

# -----------------------------------------------------------------------------
# Section 7: Practical Examples
# -----------------------------------------------------------------------------

IO.puts("\n--- Practical Examples ---")

# Example 1: Pricing calculator
defmodule Pricing do
  def calculate_discount(quantity, unit_price) do
    discount_rate = cond do
      quantity >= 100 -> 0.20  # 20% off for 100+
      quantity >= 50 -> 0.15   # 15% off for 50+
      quantity >= 25 -> 0.10   # 10% off for 25+
      quantity >= 10 -> 0.05   # 5% off for 10+
      true -> 0.0              # No discount
    end

    total = quantity * unit_price
    discount = total * discount_rate
    {total, discount, total - discount}
  end
end

{total, discount, final} = Pricing.calculate_discount(75, 10.0)
IO.puts("Total: $#{total}, Discount: $#{discount}, Final: $#{final}")

# Example 2: Input validation
defmodule Validator do
  def validate_password(password) do
    cond do
      not is_binary(password) ->
        {:error, "Password must be a string"}

      String.length(password) < 8 ->
        {:error, "Password must be at least 8 characters"}

      not String.match?(password, ~r/[A-Z]/) ->
        {:error, "Password must contain an uppercase letter"}

      not String.match?(password, ~r/[a-z]/) ->
        {:error, "Password must contain a lowercase letter"}

      not String.match?(password, ~r/[0-9]/) ->
        {:error, "Password must contain a digit"}

      true ->
        {:ok, "Password is valid"}
    end
  end
end

passwords = ["abc", "abcdefgh", "ABCDEFGH", "Abcdefgh", "Abcdefg1"]
for p <- passwords do
  IO.inspect(Validator.validate_password(p), label: "\"#{p}\"")
end

# Example 3: Game state
defmodule Game do
  def evaluate_hand(cards) do
    score = Enum.sum(cards)

    cond do
      score > 21 -> {:bust, score}
      score == 21 and length(cards) == 2 -> {:blackjack, score}
      score == 21 -> {:twenty_one, score}
      score >= 17 -> {:stand, score}
      score >= 12 -> {:decide, score}  # Could hit or stand
      true -> {:hit, score}  # Should definitely hit
    end
  end
end

hands = [[10, 11], [10, 5, 7], [10, 5, 2], [10, 5], [5, 3]]
for hand <- hands do
  IO.inspect(Game.evaluate_hand(hand), label: "Hand #{inspect(hand)}")
end

# -----------------------------------------------------------------------------
# Section 8: Cond vs Multiple Function Clauses
# -----------------------------------------------------------------------------

IO.puts("\n--- Cond vs Multiple Function Clauses ---")

# Sometimes you can replace cond with function clauses
# Here's the same logic both ways:

# Using cond
defmodule FizzBuzzCond do
  def convert(n) do
    cond do
      rem(n, 15) == 0 -> "FizzBuzz"
      rem(n, 3) == 0 -> "Fizz"
      rem(n, 5) == 0 -> "Buzz"
      true -> to_string(n)
    end
  end
end

# Using function clauses with guards
defmodule FizzBuzzClauses do
  def convert(n) when rem(n, 15) == 0, do: "FizzBuzz"
  def convert(n) when rem(n, 3) == 0, do: "Fizz"
  def convert(n) when rem(n, 5) == 0, do: "Buzz"
  def convert(n), do: to_string(n)
end

for n <- 1..15 do
  result1 = FizzBuzzCond.convert(n)
  result2 = FizzBuzzClauses.convert(n)
  IO.puts("#{n}: #{result1} (cond) / #{result2} (clauses)")
end

IO.puts("""

Guidelines:
  - Function clauses: better for different "types" of input
  - Cond: better for complex conditions on same input type
  - Function clauses: more testable, self-documenting
  - Cond: keeps logic together, easier to see all conditions
""")

# -----------------------------------------------------------------------------
# Section 9: Cond with Expressions as Values
# -----------------------------------------------------------------------------

IO.puts("\n--- Cond Returns Values ---")

# Remember: cond is an expression that returns a value

status = :pending
priority = :high

# Can be used directly in function calls
IO.puts(cond do
  status == :completed -> "Task is done"
  status == :pending and priority == :high -> "Urgent pending task"
  status == :pending -> "Regular pending task"
  true -> "Unknown status"
end)

# Can be used in data structures
user_role = :admin
permissions_level = 5

config = %{
  role: user_role,
  access: cond do
    user_role == :admin -> :full
    user_role == :moderator and permissions_level >= 3 -> :elevated
    user_role == :user -> :basic
    true -> :none
  end,
  visible_sections: cond do
    user_role == :admin -> [:dashboard, :users, :settings, :logs]
    user_role == :moderator -> [:dashboard, :users]
    true -> [:dashboard]
  end
}

IO.inspect(config, label: "Generated config")

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: Grade Calculator
# Difficulty: Easy
#
# Create a function letter_grade/1 that takes a score (0-100) and returns:
# - "A+" for 97-100
# - "A" for 93-96
# - "A-" for 90-92
# - "B+" for 87-89
# - "B" for 83-86
# - "B-" for 80-82
# - "C" for 70-79
# - "D" for 60-69
# - "F" for below 60
# - "Invalid" for scores outside 0-100
#
# Your code here:

IO.puts("\nExercise 1: Detailed grade calculator")

# Exercise 2: Time Period
# Difficulty: Easy
#
# Create a function time_of_day/1 that takes an hour (0-23) and returns:
# - "Night" for 0-5
# - "Morning" for 6-11
# - "Afternoon" for 12-17
# - "Evening" for 18-23
# - "Invalid" for other values
#
# Your code here:

IO.puts("\nExercise 2: Time of day classifier")

# Exercise 3: BMI Calculator
# Difficulty: Medium
#
# Create a function bmi_category/2 that takes weight (kg) and height (m)
# and returns the BMI category:
# - "Underweight" for BMI < 18.5
# - "Normal" for BMI 18.5-24.9
# - "Overweight" for BMI 25-29.9
# - "Obese" for BMI >= 30
#
# BMI = weight / (height * height)
# Also return the actual BMI value: {category, bmi}
#
# Your code here:

IO.puts("\nExercise 3: BMI calculator")

# Exercise 4: Shipping Cost
# Difficulty: Medium
#
# Create a function shipping_cost/2 that takes weight (kg) and distance (km)
# and returns the shipping cost based on:
# - Local (< 50km): $5 flat
# - Regional (50-200km): $10 + $0.05/kg
# - National (200-1000km): $20 + $0.10/kg
# - International (> 1000km): $50 + $0.25/kg
# - Heavy items (> 30kg) add 50% surcharge
#
# Your code here:

IO.puts("\nExercise 4: Shipping cost calculator")

# Exercise 5: Triangle Classifier
# Difficulty: Medium
#
# Create a function classify_triangle/3 that takes three side lengths
# and returns:
# - {:invalid, reason} if not a valid triangle
# - {:equilateral, area} if all sides equal
# - {:isosceles, area} if two sides equal
# - {:scalene, area} if no sides equal
#
# A triangle is valid if sum of any two sides > third side
# Area = sqrt(s(s-a)(s-b)(s-c)) where s = (a+b+c)/2 (Heron's formula)
#
# Your code here:

IO.puts("\nExercise 5: Triangle classifier")

# Exercise 6: Loan Eligibility
# Difficulty: Hard
#
# Create a function check_eligibility/1 that takes a map with:
# - :income (annual)
# - :credit_score
# - :debt_ratio (0-1)
# - :employment_years
#
# Return eligibility status based on:
# - Premium: income >= 100000, credit >= 750, debt < 0.3, employed >= 3
# - Standard: income >= 50000, credit >= 650, debt < 0.4, employed >= 2
# - Basic: income >= 30000, credit >= 600, debt < 0.5, employed >= 1
# - Denied: otherwise
#
# Return {status, max_loan_amount} where max_loan_amount is:
# - Premium: 5x income
# - Standard: 3x income
# - Basic: 1x income
# - Denied: 0
#
# Your code here:

IO.puts("\nExercise 6: Loan eligibility checker")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

1. Cond syntax:
   cond do
     condition1 -> expression1
     condition2 -> expression2
     true -> default
   end

2. Always include a default (true ->):
   - Prevents CondClauseError
   - Handles unexpected cases

3. Cond vs Case:
   - Cond: boolean conditions
   - Case: pattern matching
   - Use cond for ranges, complex logic
   - Use case for structure matching

4. Conditions are any truthy expression:
   - Comparisons: <, >, ==, etc.
   - Boolean operations: and, or, not
   - Function calls
   - Variable references

5. Cond is an expression:
   - Returns a value
   - Can be used in assignments
   - Can be embedded in data structures

6. Common uses:
   - Range classification
   - Validation with multiple rules
   - Business logic with many conditions
   - Scoring/rating systems

7. Alternatives to consider:
   - Function clauses with guards
   - Case with guards
   - If/else for simple binary choices

Next: 12_if_unless.exs - Simple conditionals
""")
