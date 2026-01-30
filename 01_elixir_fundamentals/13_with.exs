# ============================================================================
# Lesson 13: With Expressions
# ============================================================================
#
# The 'with' expression is Elixir's elegant solution for handling chains
# of operations that might fail. It's perfect for the "happy path" pattern,
# where you want to proceed only if each step succeeds.
#
# Learning Objectives:
# - Understand the 'with' expression syntax
# - Chain operations that return {:ok, value}
# - Handle failures with 'else' clauses
# - Recognize when to use 'with' vs other constructs
#
# Prerequisites:
# - Lessons 09-12 completed (pattern matching, case, cond, if)
#
# ============================================================================

IO.puts("=" |> String.duplicate(60))
IO.puts("Lesson 13: With Expressions")
IO.puts("=" |> String.duplicate(60))

# -----------------------------------------------------------------------------
# Section 1: The Problem With Chained Operations
# -----------------------------------------------------------------------------

IO.puts("\n--- The Problem With Chained Operations ---")

# Imagine you need to: validate input -> parse data -> save to database
# Each step might fail. Without 'with', you might write:

defmodule WithoutWith do
  def process_user(params) do
    case validate(params) do
      {:ok, validated} ->
        case parse(validated) do
          {:ok, parsed} ->
            case save(parsed) do
              {:ok, result} -> {:ok, result}
              {:error, reason} -> {:error, reason}
            end
          {:error, reason} -> {:error, reason}
        end
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate(%{name: name}) when byte_size(name) > 0, do: {:ok, %{name: name}}
  defp validate(_), do: {:error, :invalid_name}

  defp parse(%{name: name}), do: {:ok, %{name: String.trim(name), parsed: true}}

  defp save(data), do: {:ok, Map.put(data, :saved, true)}
end

# This nested case structure is called "pyramid of doom" or "callback hell"
# It's hard to read and maintain!

result = WithoutWith.process_user(%{name: "Alice"})
IO.inspect(result, label: "Without with (success)")

result = WithoutWith.process_user(%{name: ""})
IO.inspect(result, label: "Without with (failure)")

# -----------------------------------------------------------------------------
# Section 2: Basic With Syntax
# -----------------------------------------------------------------------------

IO.puts("\n--- Basic With Syntax ---")

# 'with' flattens the nested structure beautifully!

defmodule WithWith do
  def process_user(params) do
    with {:ok, validated} <- validate(params),
         {:ok, parsed} <- parse(validated),
         {:ok, result} <- save(parsed) do
      {:ok, result}
    end
  end

  defp validate(%{name: name}) when byte_size(name) > 0, do: {:ok, %{name: name}}
  defp validate(_), do: {:error, :invalid_name}

  defp parse(%{name: name}), do: {:ok, %{name: String.trim(name), parsed: true}}

  defp save(data), do: {:ok, Map.put(data, :saved, true)}
end

result = WithWith.process_user(%{name: "  Bob  "})
IO.inspect(result, label: "With (success)")

result = WithWith.process_user(%{name: ""})
IO.inspect(result, label: "With (failure)")

# How it works:
# 1. Each <- clause pattern matches
# 2. If all match, the do block executes
# 3. If any fails to match, that value is returned immediately

# -----------------------------------------------------------------------------
# Section 3: The Else Clause
# -----------------------------------------------------------------------------

IO.puts("\n--- The Else Clause ---")

# Without else, non-matching values are returned as-is
# With else, you can transform error values

defmodule WithElse do
  def process(params) do
    with {:ok, a} <- step1(params),
         {:ok, b} <- step2(a),
         {:ok, c} <- step3(b) do
      {:ok, c}
    else
      {:error, :step1_failed} -> {:error, "First step failed"}
      {:error, :step2_failed} -> {:error, "Second step failed"}
      {:error, :step3_failed} -> {:error, "Third step failed"}
      error -> {:error, "Unknown error: #{inspect(error)}"}
    end
  end

  defp step1(%{valid: true} = p), do: {:ok, Map.put(p, :step1, true)}
  defp step1(_), do: {:error, :step1_failed}

  defp step2(%{continue: true} = p), do: {:ok, Map.put(p, :step2, true)}
  defp step2(_), do: {:error, :step2_failed}

  defp step3(%{finish: true} = p), do: {:ok, Map.put(p, :step3, true)}
  defp step3(_), do: {:error, :step3_failed}
end

IO.inspect(WithElse.process(%{valid: true, continue: true, finish: true}), label: "All success")
IO.inspect(WithElse.process(%{valid: false}), label: "Step 1 fails")
IO.inspect(WithElse.process(%{valid: true, continue: false}), label: "Step 2 fails")
IO.inspect(WithElse.process(%{valid: true, continue: true, finish: false}), label: "Step 3 fails")

# -----------------------------------------------------------------------------
# Section 4: Using Bare Expressions
# -----------------------------------------------------------------------------

IO.puts("\n--- Bare Expressions in With ---")

# Not every line needs <-
# You can include regular expressions that don't pattern match

defmodule BareExpressions do
  def calculate(params) do
    with {:ok, a} <- get_number(params, :a),
         {:ok, b} <- get_number(params, :b),
         # Bare expression - always succeeds
         sum = a + b,
         # Another pattern match
         {:ok, multiplier} <- get_number(params, :multiplier),
         # More bare expressions
         result = sum * multiplier,
         formatted = "Result: #{result}" do
      {:ok, formatted, result}
    end
  end

  defp get_number(params, key) do
    case Map.fetch(params, key) do
      {:ok, n} when is_number(n) -> {:ok, n}
      :error -> {:error, {:missing, key}}
      {:ok, _} -> {:error, {:not_a_number, key}}
    end
  end
end

result = BareExpressions.calculate(%{a: 5, b: 3, multiplier: 2})
IO.inspect(result, label: "With bare expressions")

result = BareExpressions.calculate(%{a: 5, b: 3})
IO.inspect(result, label: "Missing multiplier")

# -----------------------------------------------------------------------------
# Section 5: Guards in With Clauses
# -----------------------------------------------------------------------------

IO.puts("\n--- Guards in With Clauses ---")

defmodule WithGuards do
  def validate_user(params) do
    with {:ok, name} when byte_size(name) >= 2 <- get_name(params),
         {:ok, age} when age >= 0 and age < 150 <- get_age(params),
         {:ok, email} when is_binary(email) <- get_email(params) do
      {:ok, %{name: name, age: age, email: email}}
    else
      {:ok, name} when is_binary(name) -> {:error, "Name too short: #{name}"}
      {:ok, age} when is_integer(age) -> {:error, "Invalid age: #{age}"}
      {:error, reason} -> {:error, reason}
      _ -> {:error, "Unknown validation error"}
    end
  end

  defp get_name(%{name: name}) when is_binary(name), do: {:ok, name}
  defp get_name(_), do: {:error, "Name required"}

  defp get_age(%{age: age}) when is_integer(age), do: {:ok, age}
  defp get_age(_), do: {:error, "Age required"}

  defp get_email(%{email: email}), do: {:ok, email}
  defp get_email(_), do: {:error, "Email required"}
end

IO.inspect(WithGuards.validate_user(%{name: "Alice", age: 30, email: "a@b.com"}))
IO.inspect(WithGuards.validate_user(%{name: "A", age: 30, email: "a@b.com"}))
IO.inspect(WithGuards.validate_user(%{name: "Bob", age: -5, email: "b@c.com"}))
IO.inspect(WithGuards.validate_user(%{name: "Charlie", age: 25}))

# -----------------------------------------------------------------------------
# Section 6: Real-World Example: User Registration
# -----------------------------------------------------------------------------

IO.puts("\n--- Real-World Example: User Registration ---")

defmodule Registration do
  def register(params) do
    with {:ok, email} <- validate_email(params[:email]),
         {:ok, password} <- validate_password(params[:password]),
         {:ok, _} <- check_email_available(email),
         {:ok, hashed} <- hash_password(password),
         {:ok, user} <- create_user(email, hashed) do
      {:ok, user}
    else
      {:error, :invalid_email} ->
        {:error, "Please provide a valid email address"}

      {:error, :password_too_short} ->
        {:error, "Password must be at least 8 characters"}

      {:error, :email_taken} ->
        {:error, "An account with this email already exists"}

      {:error, reason} ->
        {:error, "Registration failed: #{inspect(reason)}"}
    end
  end

  defp validate_email(nil), do: {:error, :invalid_email}
  defp validate_email(email) do
    if String.contains?(email, "@") do
      {:ok, String.downcase(email)}
    else
      {:error, :invalid_email}
    end
  end

  defp validate_password(nil), do: {:error, :password_too_short}
  defp validate_password(password) do
    if String.length(password) >= 8 do
      {:ok, password}
    else
      {:error, :password_too_short}
    end
  end

  # Simulated check - in real app, would query database
  defp check_email_available("taken@example.com"), do: {:error, :email_taken}
  defp check_email_available(_email), do: {:ok, :available}

  defp hash_password(password) do
    # In real app, use proper hashing like Bcrypt
    {:ok, "hashed_#{password}"}
  end

  defp create_user(email, password_hash) do
    {:ok, %{
      id: :rand.uniform(1000),
      email: email,
      password_hash: password_hash,
      created_at: DateTime.utc_now()
    }}
  end
end

IO.inspect(Registration.register(%{email: "alice@example.com", password: "secure123"}))
IO.inspect(Registration.register(%{email: "invalid", password: "secure123"}))
IO.inspect(Registration.register(%{email: "bob@example.com", password: "short"}))
IO.inspect(Registration.register(%{email: "taken@example.com", password: "password123"}))

# -----------------------------------------------------------------------------
# Section 7: With vs Case vs Cond
# -----------------------------------------------------------------------------

IO.puts("\n--- With vs Case vs Cond ---")

IO.puts("""
USE WITH when:
  - Chaining operations that might fail
  - Each step returns {:ok, value} or {:error, reason}
  - You want the "happy path" to be clear
  - Early exit on first failure

USE CASE when:
  - Matching against a SINGLE value
  - Different behavior for different patterns
  - Not chaining multiple operations

USE COND when:
  - Multiple boolean conditions
  - No specific value to match
  - Range comparisons
""")

# Example showing when each is appropriate:

# CASE - single value, multiple patterns
defmodule ResponseHandler do
  def handle(response) do
    case response do
      {:ok, body} -> "Success: #{body}"
      {:error, 404} -> "Not found"
      {:error, 500} -> "Server error"
      {:error, code} -> "Error: #{code}"
    end
  end
end

# COND - multiple conditions
defmodule Classifier do
  def classify(score) do
    cond do
      score >= 90 -> "A"
      score >= 80 -> "B"
      score >= 70 -> "C"
      score >= 60 -> "D"
      true -> "F"
    end
  end
end

# WITH - chained operations
defmodule Pipeline do
  def process(input) do
    with {:ok, validated} <- validate(input),
         {:ok, transformed} <- transform(validated),
         {:ok, result} <- finalize(transformed) do
      {:ok, result}
    end
  end

  defp validate(x) when x > 0, do: {:ok, x}
  defp validate(_), do: {:error, :invalid}

  defp transform(x), do: {:ok, x * 2}

  defp finalize(x), do: {:ok, "Result: #{x}"}
end

IO.puts(ResponseHandler.handle({:ok, "data"}))
IO.puts(Classifier.classify(85))
IO.inspect(Pipeline.process(5))

# -----------------------------------------------------------------------------
# Section 8: Common Patterns with With
# -----------------------------------------------------------------------------

IO.puts("\n--- Common Patterns with With ---")

# Pattern 1: File operations
defmodule FileProcessor do
  def process_file(path) do
    with {:ok, content} <- File.read(path),
         {:ok, data} <- parse_content(content),
         {:ok, result} <- process_data(data) do
      {:ok, result}
    else
      {:error, :enoent} -> {:error, "File not found: #{path}"}
      {:error, :parse_error} -> {:error, "Invalid file format"}
      {:error, reason} -> {:error, "Processing failed: #{inspect(reason)}"}
    end
  end

  defp parse_content(content) do
    # Simulate parsing
    if String.contains?(content, "valid") do
      {:ok, %{content: content, parsed: true}}
    else
      {:error, :parse_error}
    end
  end

  defp process_data(data), do: {:ok, Map.put(data, :processed, true)}
end

# Create a temp file for testing
File.write!("/tmp/test_file.txt", "valid content here")
IO.inspect(FileProcessor.process_file("/tmp/test_file.txt"), label: "Valid file")
IO.inspect(FileProcessor.process_file("/tmp/nonexistent.txt"), label: "Missing file")

# Pattern 2: API request handling
defmodule APIClient do
  def fetch_user_posts(user_id) do
    with {:ok, user} <- fetch_user(user_id),
         {:ok, posts} <- fetch_posts(user.id),
         {:ok, enriched} <- enrich_posts(posts, user) do
      {:ok, enriched}
    else
      {:error, :user_not_found} -> {:error, "User #{user_id} not found"}
      {:error, :no_posts} -> {:ok, []}  # No posts is OK, return empty
      {:error, reason} -> {:error, reason}
    end
  end

  defp fetch_user(1), do: {:ok, %{id: 1, name: "Alice"}}
  defp fetch_user(_), do: {:error, :user_not_found}

  defp fetch_posts(1), do: {:ok, [%{title: "Post 1"}, %{title: "Post 2"}]}
  defp fetch_posts(_), do: {:error, :no_posts}

  defp enrich_posts(posts, user) do
    enriched = Enum.map(posts, &Map.put(&1, :author, user.name))
    {:ok, enriched}
  end
end

IO.inspect(APIClient.fetch_user_posts(1), label: "User 1 posts")
IO.inspect(APIClient.fetch_user_posts(999), label: "Unknown user")

# Pattern 3: Transaction-like operations
defmodule Transaction do
  def transfer(from_account, to_account, amount) do
    with {:ok, from} <- get_account(from_account),
         {:ok, to} <- get_account(to_account),
         :ok <- validate_balance(from, amount),
         {:ok, from_updated} <- debit(from, amount),
         {:ok, to_updated} <- credit(to, amount) do
      {:ok, %{from: from_updated, to: to_updated, amount: amount}}
    else
      {:error, :account_not_found} -> {:error, "Account not found"}
      {:error, :insufficient_funds} -> {:error, "Insufficient funds"}
      error -> {:error, "Transfer failed: #{inspect(error)}"}
    end
  end

  defp get_account("acc1"), do: {:ok, %{id: "acc1", balance: 1000}}
  defp get_account("acc2"), do: {:ok, %{id: "acc2", balance: 500}}
  defp get_account(_), do: {:error, :account_not_found}

  defp validate_balance(%{balance: balance}, amount) when balance >= amount, do: :ok
  defp validate_balance(_, _), do: {:error, :insufficient_funds}

  defp debit(account, amount), do: {:ok, %{account | balance: account.balance - amount}}
  defp credit(account, amount), do: {:ok, %{account | balance: account.balance + amount}}
end

IO.inspect(Transaction.transfer("acc1", "acc2", 200), label: "Valid transfer")
IO.inspect(Transaction.transfer("acc1", "acc2", 2000), label: "Insufficient funds")
IO.inspect(Transaction.transfer("acc1", "acc99", 100), label: "Unknown account")

# -----------------------------------------------------------------------------
# Section 9: Tips and Best Practices
# -----------------------------------------------------------------------------

IO.puts("\n--- Tips and Best Practices ---")

IO.puts("""
1. Keep with clauses focused on the happy path
   - Each clause should represent one step in the process
   - Use helper functions for complex logic

2. Use else to provide meaningful error messages
   - Transform internal errors to user-friendly messages
   - Handle all possible failure cases

3. Order matters in else clauses
   - More specific patterns first
   - Catch-all at the end

4. Don't overuse with
   - For simple if/else, just use if
   - For single case matching, use case
   - with shines with 3+ chained operations

5. Consider the alternative: Railway-oriented programming
   - Libraries like 'ok' or 'result' provide more tools
   - For complex pipelines, consider dedicated error handling

6. Bare expressions for intermediate values
   - Use = for values you need in the do block
   - These always succeed
""")

# Example of well-structured with
defmodule BestPractice do
  def create_order(params) do
    with {:ok, customer} <- fetch_customer(params.customer_id),
         {:ok, products} <- fetch_products(params.product_ids),
         {:ok, total} <- calculate_total(products),
         {:ok, payment} <- process_payment(customer, total),
         {:ok, order} <- save_order(customer, products, payment) do
      send_confirmation(customer, order)
      {:ok, order}
    else
      {:error, :customer_not_found} ->
        {:error, "Customer not found"}

      {:error, :product_not_found, id} ->
        {:error, "Product #{id} not found"}

      {:error, :payment_failed, reason} ->
        {:error, "Payment failed: #{reason}"}

      {:error, reason} ->
        {:error, "Order creation failed: #{inspect(reason)}"}
    end
  end

  # Stub implementations
  defp fetch_customer(_id), do: {:ok, %{id: 1, email: "test@example.com"}}
  defp fetch_products(_ids), do: {:ok, [%{id: 1, price: 100}]}
  defp calculate_total(products), do: {:ok, Enum.sum(Enum.map(products, & &1.price))}
  defp process_payment(_customer, _total), do: {:ok, %{id: "pay_123"}}
  defp save_order(_c, _p, _pay), do: {:ok, %{id: "order_456"}}
  defp send_confirmation(_customer, _order), do: :ok
end

IO.inspect(BestPractice.create_order(%{customer_id: 1, product_ids: [1, 2]}))

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 60))

# Exercise 1: Simple Pipeline
# Difficulty: Easy
#
# Create a function parse_and_double/1 that:
# 1. Parses a string to integer (use Integer.parse)
# 2. Validates it's positive
# 3. Doubles it
#
# Return {:ok, result} or {:error, reason}
# Use 'with' to chain these operations.
#
# Your code here:

IO.puts("\nExercise 1: Parse and double")

# Exercise 2: Config Loader
# Difficulty: Easy
#
# Create a function load_config/1 that takes a map and extracts:
# - :host (required)
# - :port (required, must be integer)
# - :timeout (optional, default 5000)
#
# Return {:ok, config} or {:error, reason}
#
# Your code here:

IO.puts("\nExercise 2: Config loader")

# Exercise 3: Form Validation
# Difficulty: Medium
#
# Create a function validate_signup/1 that validates:
# - :email (required, must contain @)
# - :password (required, min 8 chars)
# - :password_confirmation (must match password)
# - :age (required, must be >= 13)
#
# Return {:ok, validated_data} or {:error, message}
#
# Your code here:

IO.puts("\nExercise 3: Signup form validation")

# Exercise 4: Sequential API Calls
# Difficulty: Medium
#
# Create a function get_user_dashboard/1 that:
# 1. Fetches user by ID
# 2. Fetches user's preferences
# 3. Fetches user's recent activity
# 4. Combines all into a dashboard map
#
# Simulate API calls with functions that may fail.
# Handle each failure case with appropriate error messages.
#
# Your code here:

IO.puts("\nExercise 4: User dashboard")

# Exercise 5: Order Processing
# Difficulty: Hard
#
# Create a complete order processing pipeline:
# 1. Validate order items (check stock)
# 2. Calculate total with tax
# 3. Apply discount code (if provided)
# 4. Process payment
# 5. Update inventory
# 6. Create order record
#
# Handle all failure cases appropriately.
# Return {:ok, order_confirmation} or {:error, reason}
#
# Your code here:

IO.puts("\nExercise 5: Order processing pipeline")

# Exercise 6: Data Import
# Difficulty: Hard
#
# Create a function import_csv/1 that:
# 1. Reads file content
# 2. Parses CSV headers
# 3. Validates headers match expected format
# 4. Parses each row into a map
# 5. Validates all rows
# 6. Returns {:ok, [records]} or {:error, reason}
#
# Headers should be: name,email,age
# Validate: name not empty, email has @, age is integer >= 0
#
# Your code here:

IO.puts("\nExercise 6: CSV data import")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 60))

IO.puts("""

Key takeaways from this lesson:

1. With syntax:
   with {:ok, a} <- step1(),
        {:ok, b} <- step2(a),
        {:ok, c} <- step3(b) do
     {:ok, c}
   else
     {:error, reason} -> {:error, reason}
   end

2. How with works:
   - Each <- pattern matches
   - On match failure, returns non-matching value
   - On success, executes do block

3. The else clause:
   - Transforms non-matching values
   - Pattern matches on failures
   - Order matters (specific first)

4. Bare expressions:
   - Use = for intermediate values
   - Always succeed
   - Available in later clauses and do block

5. When to use with:
   - Chaining 3+ operations that might fail
   - {:ok, value} / {:error, reason} patterns
   - Flattening nested case statements

6. Best practices:
   - Keep clauses focused
   - Use helper functions
   - Provide meaningful error messages
   - Don't overuse for simple logic

7. Alternatives:
   - case for single value matching
   - cond for boolean conditions
   - if for simple branching

This concludes Section 1: Elixir Fundamentals!
You now have a solid foundation in Elixir's core concepts.
""")
