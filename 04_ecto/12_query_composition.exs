# ============================================================================
# Lesson 12: Query Composition
# ============================================================================
#
# One of Ecto's greatest strengths is query composability. Queries can be
# built incrementally, passed to functions, and combined in various ways.
#
# Learning Objectives:
# - Compose queries using pipe operators
# - Create reusable query functions
# - Use named bindings for complex queries
# - Build dynamic queries at runtime
# - Apply common composition patterns
#
# Prerequisites:
# - Lesson 11: Query Basics
# - Understanding of Elixir functions and pipes
#
# ============================================================================

IO.puts("=" |> String.duplicate(70))
IO.puts("Lesson 12: Query Composition")
IO.puts("=" |> String.duplicate(70))

# -----------------------------------------------------------------------------
# Section 1: Why Query Composition?
# -----------------------------------------------------------------------------
#
# Query composition allows building complex queries from simple, reusable parts.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 1: Why Query Composition? ---\n")

IO.puts("""
Benefits of query composition:

1. Reusability - Write common filters once, use everywhere
2. Readability - Break complex queries into named functions
3. Testability - Test individual query parts
4. Flexibility - Build queries based on runtime conditions
5. DRY - Don't Repeat Yourself

Example: Instead of duplicating "active users" filter everywhere,
create a reusable function:

    def active(query) do
      where(query, [u], u.active == true)
    end

    User |> active() |> Repo.all()
""")

# -----------------------------------------------------------------------------
# Section 2: Basic Query Composition with Pipes
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 2: Basic Query Composition with Pipes ---\n")

pipe_composition = """
import Ecto.Query

# Start with the schema, pipe through transformations
query =
  User
  |> where([u], u.active == true)
  |> where([u], u.role == "admin")
  |> order_by([u], desc: u.created_at)
  |> limit(10)
  |> select([u], %{name: u.name, email: u.email})

# Each step returns a new query (immutable)
# Original query is not modified

base_query = from(u in User, where: u.active == true)

# Build on top of base query
admin_query = base_query |> where([u], u.role == "admin")
recent_query = base_query |> order_by([u], desc: u.created_at)

# They're independent - base_query is unchanged
"""

IO.puts("Pipe-based composition:")
IO.puts(pipe_composition)

# -----------------------------------------------------------------------------
# Section 3: Creating Reusable Query Functions
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 3: Creating Reusable Query Functions ---\n")

reusable_functions = """
defmodule UserQueries do
  import Ecto.Query

  # Filter functions that take query as first argument
  def active(query) do
    where(query, [u], u.active == true)
  end

  def with_role(query, role) do
    where(query, [u], u.role == ^role)
  end

  def created_after(query, date) do
    where(query, [u], u.created_at >= ^date)
  end

  def created_before(query, date) do
    where(query, [u], u.created_at <= ^date)
  end

  def created_between(query, start_date, end_date) do
    query
    |> created_after(start_date)
    |> created_before(end_date)
  end

  def ordered_by_newest(query) do
    order_by(query, [u], desc: u.created_at)
  end

  def limit_results(query, count) do
    limit(query, ^count)
  end

  # Convenience function combining common operations
  def recent_active(query, limit \\\\ 10) do
    query
    |> active()
    |> ordered_by_newest()
    |> limit_results(limit)
  end
end

# Usage:
# User
# |> UserQueries.active()
# |> UserQueries.with_role("admin")
# |> UserQueries.ordered_by_newest()
# |> Repo.all()

# Or use the convenience function:
# User |> UserQueries.recent_active(5) |> Repo.all()
"""

IO.puts("Reusable query functions:")
IO.puts(reusable_functions)

# -----------------------------------------------------------------------------
# Section 4: Query Functions in Schema Modules
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 4: Query Functions in Schema Modules ---\n")

schema_queries = """
defmodule User do
  use Ecto.Schema
  import Ecto.Query

  schema "users" do
    field :name, :string
    field :email, :string
    field :role, :string
    field :active, :boolean, default: true
    timestamps()
  end

  # Query functions as part of the schema module
  def active(query \\\\ __MODULE__) do
    where(query, [u], u.active == true)
  end

  def admins(query \\\\ __MODULE__) do
    where(query, [u], u.role == "admin")
  end

  def by_email(query \\\\ __MODULE__, email) do
    where(query, [u], u.email == ^email)
  end

  def search(query \\\\ __MODULE__, term) do
    search_term = "%\#{term}%"
    where(query, [u], ilike(u.name, ^search_term) or ilike(u.email, ^search_term))
  end

  def ordered(query \\\\ __MODULE__) do
    order_by(query, [u], asc: u.name)
  end
end

# The default argument allows calling without a query:
# User.active() |> Repo.all()
# User.admins() |> User.active() |> Repo.all()

# Or pipe from another query:
# some_query |> User.active() |> Repo.all()
"""

IO.puts("Schema module query functions:")
IO.puts(schema_queries)

# -----------------------------------------------------------------------------
# Section 5: Named Bindings
# -----------------------------------------------------------------------------
#
# Named bindings make it easier to reference specific tables in complex queries.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 5: Named Bindings ---\n")

named_bindings = """
import Ecto.Query

# Without named bindings - position-based
query = from(u in User,
  join: p in Post, on: p.user_id == u.id,
  where: u.active == true,
  where: p.published == true
)

# With named bindings - explicit names
query = from(u in User, as: :user,
  join: p in Post, as: :post, on: p.user_id == u.id,
  where: u.active == true,
  where: p.published == true
)

# Named bindings in pipe syntax
query =
  User
  |> from(as: :user)
  |> join(:inner, [user: u], p in Post, on: p.user_id == u.id, as: :post)
  |> where([user: u], u.active == true)
  |> where([post: p], p.published == true)

# Reference by name instead of position
query
|> where([user: u], u.role == "admin")
|> where([post: p], p.category == "tech")

# Check if binding exists
has_name?(query, :user)  # true
has_name?(query, :comment)  # false
"""

IO.puts("Named bindings:")
IO.puts(named_bindings)

IO.puts("""
Why use named bindings?

1. Clarity - Know exactly which table you're referencing
2. Order independence - Bindings don't depend on join order
3. Composability - Functions can reference specific bindings
4. Self-documenting - Code is more readable
""")

# -----------------------------------------------------------------------------
# Section 6: Composing with Named Bindings
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 6: Composing with Named Bindings ---\n")

composing_named = """
defmodule PostQueries do
  import Ecto.Query

  # Start query with named binding
  def base() do
    from(p in Post, as: :post)
  end

  # Add author join with named binding
  def with_author(query) do
    if has_named_binding?(query, :author) do
      query
    else
      join(query, :inner, [post: p], u in User,
        on: u.id == p.user_id,
        as: :author
      )
    end
  end

  # Filter by author's status
  def by_active_author(query) do
    query
    |> with_author()
    |> where([author: a], a.active == true)
  end

  # Filter by post's published status
  def published(query) do
    where(query, [post: p], p.published == true)
  end

  # Select post with author name
  def select_with_author(query) do
    query
    |> with_author()
    |> select([post: p, author: a], %{
      id: p.id,
      title: p.title,
      author_name: a.name
    })
  end
end

# Usage:
# PostQueries.base()
# |> PostQueries.published()
# |> PostQueries.by_active_author()
# |> PostQueries.select_with_author()
# |> Repo.all()
"""

IO.puts("Composing with named bindings:")
IO.puts(composing_named)

# -----------------------------------------------------------------------------
# Section 7: Dynamic Queries
# -----------------------------------------------------------------------------
#
# Build queries dynamically based on runtime conditions.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 7: Dynamic Queries ---\n")

dynamic_queries = """
import Ecto.Query

# Using dynamic/2 for runtime-constructed conditions
defmodule SearchQuery do
  import Ecto.Query

  def search(params) do
    User
    |> from(as: :user)
    |> apply_filters(params)
    |> apply_sorting(params)
  end

  defp apply_filters(query, params) do
    Enum.reduce(params, query, fn
      {:name, name}, query when is_binary(name) and name != "" ->
        where(query, [user: u], ilike(u.name, ^"%\#{name}%"))

      {:email, email}, query when is_binary(email) and email != "" ->
        where(query, [user: u], ilike(u.email, ^"%\#{email}%"))

      {:role, role}, query when is_binary(role) ->
        where(query, [user: u], u.role == ^role)

      {:active, active}, query when is_boolean(active) ->
        where(query, [user: u], u.active == ^active)

      {:min_age, min}, query when is_integer(min) ->
        where(query, [user: u], u.age >= ^min)

      {:max_age, max}, query when is_integer(max) ->
        where(query, [user: u], u.age <= ^max)

      _, query ->
        query  # Ignore unknown/nil filters
    end)
  end

  defp apply_sorting(query, %{sort_by: field, sort_dir: dir})
       when field in ~w(name email created_at)a and dir in [:asc, :desc] do
    order_by(query, [user: u], [{^dir, field(u, ^field)}])
  end

  defp apply_sorting(query, _), do: query
end

# Usage:
# SearchQuery.search(%{name: "john", active: true, sort_by: :name, sort_dir: :asc})
"""

IO.puts("Dynamic queries:")
IO.puts(dynamic_queries)

# -----------------------------------------------------------------------------
# Section 8: The dynamic/2 Macro
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 8: The dynamic/2 Macro ---\n")

dynamic_macro = """
import Ecto.Query

# dynamic/2 creates a condition that can be combined
defmodule AdvancedSearch do
  import Ecto.Query

  def build_query(params) do
    conditions = build_conditions(params)

    from(u in User,
      where: ^conditions,
      order_by: u.name
    )
  end

  defp build_conditions(params) do
    # Start with a "true" condition
    Enum.reduce(params, dynamic(true), fn
      {:name, name}, conditions when is_binary(name) and name != "" ->
        dynamic([u], ^conditions and ilike(u.name, ^"%\#{name}%"))

      {:email, email}, conditions when is_binary(email) and email != "" ->
        dynamic([u], ^conditions and ilike(u.email, ^"%\#{email}%"))

      {:active, true}, conditions ->
        dynamic([u], ^conditions and u.active == true)

      {:active, false}, conditions ->
        dynamic([u], ^conditions and u.active == false)

      {:roles, roles}, conditions when is_list(roles) and roles != [] ->
        dynamic([u], ^conditions and u.role in ^roles)

      _, conditions ->
        conditions
    end)
  end
end

# OR conditions with dynamic
defmodule OrSearch do
  import Ecto.Query

  def search(terms) when is_list(terms) do
    conditions =
      Enum.reduce(terms, dynamic(false), fn term, acc ->
        dynamic([u], ^acc or ilike(u.name, ^"%\#{term}%"))
      end)

    from(u in User, where: ^conditions)
  end
end

# OrSearch.search(["alice", "bob", "charlie"])
# Generates: WHERE name ILIKE '%alice%' OR name ILIKE '%bob%' OR ...
"""

IO.puts("The dynamic/2 macro:")
IO.puts(dynamic_macro)

# -----------------------------------------------------------------------------
# Section 9: Conditional Query Building
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 9: Conditional Query Building ---\n")

conditional_building = """
import Ecto.Query

defmodule ProductQueries do
  import Ecto.Query

  def list_products(opts \\\\ []) do
    Product
    |> maybe_filter_category(opts[:category])
    |> maybe_filter_price_range(opts[:min_price], opts[:max_price])
    |> maybe_filter_in_stock(opts[:in_stock])
    |> maybe_search(opts[:search])
    |> apply_sort(opts[:sort] || :newest)
    |> apply_pagination(opts[:page] || 1, opts[:per_page] || 20)
  end

  # Filter functions return query unchanged if condition is nil/false
  defp maybe_filter_category(query, nil), do: query
  defp maybe_filter_category(query, category) do
    where(query, [p], p.category == ^category)
  end

  defp maybe_filter_price_range(query, nil, nil), do: query
  defp maybe_filter_price_range(query, min, nil) do
    where(query, [p], p.price >= ^min)
  end
  defp maybe_filter_price_range(query, nil, max) do
    where(query, [p], p.price <= ^max)
  end
  defp maybe_filter_price_range(query, min, max) do
    where(query, [p], p.price >= ^min and p.price <= ^max)
  end

  defp maybe_filter_in_stock(query, nil), do: query
  defp maybe_filter_in_stock(query, true) do
    where(query, [p], p.quantity > 0)
  end
  defp maybe_filter_in_stock(query, false) do
    where(query, [p], p.quantity == 0)
  end

  defp maybe_search(query, nil), do: query
  defp maybe_search(query, ""), do: query
  defp maybe_search(query, term) do
    search_term = "%\#{term}%"
    where(query, [p], ilike(p.name, ^search_term) or ilike(p.description, ^search_term))
  end

  defp apply_sort(query, :newest), do: order_by(query, [p], desc: p.inserted_at)
  defp apply_sort(query, :oldest), do: order_by(query, [p], asc: p.inserted_at)
  defp apply_sort(query, :price_low), do: order_by(query, [p], asc: p.price)
  defp apply_sort(query, :price_high), do: order_by(query, [p], desc: p.price)
  defp apply_sort(query, :name), do: order_by(query, [p], asc: p.name)
  defp apply_sort(query, _), do: query

  defp apply_pagination(query, page, per_page) do
    offset = (page - 1) * per_page
    query |> limit(^per_page) |> offset(^offset)
  end
end

# Usage:
# ProductQueries.list_products(
#   category: "electronics",
#   min_price: 100,
#   in_stock: true,
#   sort: :price_low,
#   page: 2
# )
"""

IO.puts("Conditional query building:")
IO.puts(conditional_building)

# -----------------------------------------------------------------------------
# Section 10: Subqueries
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 10: Subqueries ---\n")

subqueries = """
import Ecto.Query

# Subquery in FROM clause
active_users = from(u in User, where: u.active == true)

query = from(u in subquery(active_users),
  where: u.role == "admin",
  select: u.email
)

# Subquery in WHERE clause
top_sellers = from(p in Product,
  order_by: [desc: p.sales_count],
  limit: 10,
  select: p.id
)

query = from(o in Order,
  where: o.product_id in subquery(top_sellers),
  select: o
)

# Subquery with aggregation
user_order_totals = from(o in Order,
  group_by: o.user_id,
  select: %{user_id: o.user_id, total: sum(o.amount)}
)

query = from(u in User,
  join: s in subquery(user_order_totals), on: s.user_id == u.id,
  where: s.total > 1000,
  select: %{name: u.name, total_spent: s.total}
)

# EXISTS subquery
query = from(u in User,
  where: exists(from(o in Order, where: o.user_id == parent_as(:user).id)),
  select: u
) |> from(as: :user)

# NOT EXISTS
query = from(u in User, as: :user,
  where: not exists(
    from(o in Order,
      where: o.user_id == parent_as(:user).id
    )
  )
)
"""

IO.puts("Subqueries:")
IO.puts(subqueries)

# -----------------------------------------------------------------------------
# Section 11: Query Composition Patterns
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 11: Query Composition Patterns ---\n")

composition_patterns = """
# Pattern 1: Base Query Pattern
defmodule OrderContext do
  import Ecto.Query

  # Always start from base query
  def base_query do
    from(o in Order, as: :order)
  end

  # All functions build on base or take query as first arg
  def for_user(query \\\\ base_query(), user_id) do
    where(query, [order: o], o.user_id == ^user_id)
  end

  def completed(query \\\\ base_query()) do
    where(query, [order: o], o.status == "completed")
  end
end

# Pattern 2: Scope Pattern (similar to Rails)
defmodule Order do
  use Ecto.Schema
  import Ecto.Query

  # Scopes are class methods that return queries
  def recent(query \\\\ __MODULE__, days \\\\ 7) do
    cutoff = DateTime.add(DateTime.utc_now(), -days * 86400)
    where(query, [o], o.inserted_at >= ^cutoff)
  end

  def expensive(query \\\\ __MODULE__, threshold \\\\ 100) do
    where(query, [o], o.total >= ^threshold)
  end

  def pending(query \\\\ __MODULE__) do
    where(query, [o], o.status == "pending")
  end
end

# Order.recent() |> Order.expensive(50) |> Repo.all()

# Pattern 3: Query Builder with Struct
defmodule QueryBuilder do
  defstruct [:query, :filters, :sort, :page, :per_page]

  def new(schema) do
    %__MODULE__{
      query: from(x in schema),
      filters: %{},
      sort: nil,
      page: 1,
      per_page: 20
    }
  end

  def filter(builder, key, value) do
    %{builder | filters: Map.put(builder.filters, key, value)}
  end

  def sort(builder, field, direction \\\\ :asc) do
    %{builder | sort: {field, direction}}
  end

  def paginate(builder, page, per_page) do
    %{builder | page: page, per_page: per_page}
  end

  def build(builder) do
    builder.query
    |> apply_filters(builder.filters)
    |> apply_sort(builder.sort)
    |> apply_pagination(builder.page, builder.per_page)
  end

  defp apply_filters(query, filters) do
    # Implementation details...
    query
  end

  defp apply_sort(query, nil), do: query
  defp apply_sort(query, {field, dir}) do
    order_by(query, [x], [{^dir, ^field}])
  end

  defp apply_pagination(query, page, per_page) do
    import Ecto.Query
    offset = (page - 1) * per_page
    query |> limit(^per_page) |> offset(^offset)
  end
end

# QueryBuilder.new(User)
# |> QueryBuilder.filter(:active, true)
# |> QueryBuilder.sort(:name)
# |> QueryBuilder.paginate(2, 25)
# |> QueryBuilder.build()
# |> Repo.all()
"""

IO.puts("Query composition patterns:")
IO.puts(composition_patterns)

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Exercise 1: Basic Query Functions
Difficulty: Easy

Create a module with reusable query functions for a Product schema:
- active(query) - products where active == true
- in_category(query, category) - products in given category
- priced_under(query, max_price) - products under max price
- in_stock(query) - products with quantity > 0

Each function should take query as first argument and be pipeable.

Write your module:
""")

# defmodule ProductFilters do
#   import Ecto.Query
#
#   def active(query) do
#     # Your code
#   end
#
#   def in_category(query, category) do
#     # Your code
#   end
#
#   # ... etc
# end

IO.puts("""

Exercise 2: Named Bindings
Difficulty: Medium

Create queries for an e-commerce system with:
- Orders (belongs_to User)
- OrderItems (belongs_to Order, belongs_to Product)

Write a query module that:
1. Uses named bindings for all tables
2. Can filter by user's email domain
3. Can filter by product category
4. Returns order total, user name, and item count

Write your module:
""")

# defmodule OrderReport do
#   import Ecto.Query
#
#   def base_query do
#     # Setup with named bindings
#   end
#
#   def by_email_domain(query, domain) do
#     # Filter where user email ends with domain
#   end
#
#   # ... etc
# end

IO.puts("""

Exercise 3: Dynamic Search Builder
Difficulty: Medium

Create a search function that builds a query from a map of params:

    search_users(%{
      name: "john",
      roles: ["admin", "moderator"],
      created_after: ~D[2024-01-01],
      active: true
    })

Use Enum.reduce with pattern matching to handle each filter type.

Write your function:
""")

# defmodule UserSearch do
#   import Ecto.Query
#
#   def search(params) do
#     # Your code
#   end
# end

IO.puts("""

Exercise 4: Conditional Query Composition
Difficulty: Medium

Build a blog post listing function with these optional features:
- Filter by author_id
- Filter by published status
- Filter by category
- Search in title and body
- Sort by: newest, oldest, popular (by view_count)
- Pagination (page, per_page)

All filters should be optional - nil means don't filter.

Write your function:
""")

# defmodule BlogQueries do
#   import Ecto.Query
#
#   def list_posts(opts \\\\ []) do
#     # Your code
#   end
# end

IO.puts("""

Exercise 5: Complex Dynamic Conditions
Difficulty: Hard

Create a search that supports OR conditions using dynamic/2:

    search_products(%{
      name_contains: ["phone", "tablet", "laptop"],
      categories: ["electronics", "computers"],
      price_ranges: [{0, 100}, {500, 1000}]
    })

This should find products where:
- Name contains ANY of the given terms (OR)
- AND category is ANY of given categories (OR within, AND with name)
- AND price is in ANY of the ranges (OR within, AND with others)

Write your function:
""")

# defmodule ComplexSearch do
#   import Ecto.Query
#
#   def search_products(params) do
#     # Your code using dynamic/2
#   end
# end

IO.puts("""

Exercise 6: Reusable Query Module Pattern
Difficulty: Hard

Create a reusable query module that can be "used" by schemas:

    defmodule User do
      use Ecto.Schema
      use QueryHelpers, fields: [:name, :email, :role]

      schema "users" do
        # ...
      end
    end

    # Automatically provides:
    User.filter_by(:name, "john")
    User.filter_by(:role, ["admin", "mod"])
    User.search([:name, :email], "john")
    User.order_by_field(:name, :asc)

Write the QueryHelpers module using __using__ macro:
""")

# defmodule QueryHelpers do
#   defmacro __using__(opts) do
#     # Your macro code
#   end
# end

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("SUMMARY")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Key takeaways from this lesson:

1. Query composition benefits:
   - Reusable filter functions
   - Readable, testable query building
   - Dynamic runtime query construction

2. Composable query functions:
   - Take query as first argument
   - Return modified query
   - Chain with |> operator

3. Schema module queries:
   - def active(query \\\\ __MODULE__)
   - Can be called with or without existing query
   - Keep queries close to schema

4. Named bindings:
   - from(u in User, as: :user)
   - Reference with [user: u] in subsequent calls
   - Check with has_named_binding?/2

5. Dynamic queries with dynamic/2:
   - Build conditions at runtime
   - Combine with AND/OR logic
   - Start with dynamic(true) for AND chains
   - Start with dynamic(false) for OR chains

6. Conditional building pattern:
   - maybe_filter_x(query, nil) -> query
   - maybe_filter_x(query, value) -> filtered query
   - Apply filters only when values present

7. Subqueries:
   - subquery(query) wraps query for use in FROM/JOIN
   - parent_as(:name) references outer query binding
   - exists() for subquery conditions

8. Common patterns:
   - Base query pattern
   - Scope pattern (like Rails)
   - Builder struct pattern

Next: 13_query_joins.exs - Joins and preloading associations
""")
