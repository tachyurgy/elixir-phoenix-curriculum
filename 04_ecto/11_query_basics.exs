# ============================================================================
# Lesson 11: Query Basics
# ============================================================================
#
# Ecto.Query is a powerful DSL for building database queries in Elixir.
# Queries are composable, type-safe, and compile-time checked.
#
# Learning Objectives:
# - Understand Ecto.Query fundamentals
# - Use from/2 to start queries
# - Select specific fields with select/3
# - Filter results with where/3
# - Order and limit results
# - Execute queries with Repo
#
# Prerequisites:
# - Ecto repository configured
# - Understanding of Ecto schemas
#
# ============================================================================

IO.puts("=" |> String.duplicate(70))
IO.puts("Lesson 11: Query Basics")
IO.puts("=" |> String.duplicate(70))

# -----------------------------------------------------------------------------
# Section 1: Introduction to Ecto.Query
# -----------------------------------------------------------------------------
#
# Ecto.Query provides a DSL that compiles to SQL.
# Queries are data structures that can be composed and modified.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 1: Introduction to Ecto.Query ---\n")

IO.puts("""
Ecto.Query key concepts:

1. Queries are DATA - not executed until passed to Repo
2. Queries are COMPOSABLE - can be built up in steps
3. Queries are TYPE-SAFE - checked at compile time
4. Two syntaxes: keyword and macro (pipe-based)

Import Ecto.Query to use the query macros:

    import Ecto.Query

Or use fully qualified:

    Ecto.Query.from(u in User, select: u)
""")

query_basics = """
import Ecto.Query

# The query is just a data structure
query = from(u in User, select: u)
#=> #Ecto.Query<from u0 in User, select: u0>

# Not executed until passed to Repo
users = Repo.all(query)
"""

IO.puts("Basic query flow:")
IO.puts(query_basics)

# -----------------------------------------------------------------------------
# Section 2: The from/2 Macro
# -----------------------------------------------------------------------------
#
# from/2 is the foundation of all queries. It specifies the source table
# and creates a binding variable for referencing fields.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 2: The from/2 Macro ---\n")

from_examples = """
import Ecto.Query

# Basic from with schema module
query = from(u in User)

# From with string table name (schemaless)
query = from(u in "users")

# From with subquery
subquery = from(u in User, where: u.active == true)
query = from(u in subquery(subquery), select: u.email)

# The binding variable (u) is just a name you choose
query = from(user in User)
query = from(x in User)  # Any valid variable name

# Multiple from sources (implicit join)
query = from(u in User, from: p in Post, where: p.user_id == u.id)
"""

IO.puts("The from/2 macro:")
IO.puts(from_examples)

IO.puts("""
The binding variable (u in User):
- Creates a reference to the table
- Used in select, where, order_by, etc.
- Just an alias - choose meaningful names
""")

# -----------------------------------------------------------------------------
# Section 3: Select - Choosing What to Return
# -----------------------------------------------------------------------------
#
# select/3 specifies what data to return from the query.
# Without select, the entire schema struct is returned.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 3: Select - Choosing What to Return ---\n")

select_examples = """
import Ecto.Query

# Select entire struct (default if no select)
query = from(u in User, select: u)
# Returns: [%User{id: 1, name: "Alice", ...}, ...]

# Select single field
query = from(u in User, select: u.email)
# Returns: ["alice@example.com", "bob@example.com", ...]

# Select multiple fields as map
query = from(u in User, select: %{name: u.name, email: u.email})
# Returns: [%{name: "Alice", email: "alice@..."}, ...]

# Select as tuple
query = from(u in User, select: {u.id, u.name})
# Returns: [{1, "Alice"}, {2, "Bob"}, ...]

# Select as list
query = from(u in User, select: [u.id, u.name, u.email])
# Returns: [[1, "Alice", "alice@..."], ...]

# Select with renamed keys
query = from(u in User, select: %{user_name: u.name, user_email: u.email})

# Select with literal values
query = from(u in User, select: %{name: u.name, type: "user"})

# Select with struct (different from binding struct)
query = from(u in User, select: %UserDTO{name: u.name, email: u.email})

# Select all fields except some (using Map.take in Elixir after query)
query = from(u in User, select: map(u, [:id, :name, :email]))
# Returns maps with only those keys
"""

IO.puts("Select examples:")
IO.puts(select_examples)

# -----------------------------------------------------------------------------
# Section 4: Where - Filtering Results
# -----------------------------------------------------------------------------
#
# where/3 adds conditions to filter which rows are returned.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 4: Where - Filtering Results ---\n")

where_examples = """
import Ecto.Query

# Simple equality
query = from(u in User, where: u.active == true)

# Multiple conditions (AND)
query = from(u in User,
  where: u.active == true,
  where: u.role == "admin"
)

# Or use 'and' explicitly
query = from(u in User,
  where: u.active == true and u.role == "admin"
)

# OR conditions
query = from(u in User,
  where: u.role == "admin" or u.role == "moderator"
)

# NOT conditions
query = from(u in User, where: not u.is_banned)
query = from(u in User, where: u.role != "guest")

# NULL checks
query = from(u in User, where: is_nil(u.deleted_at))
query = from(u in User, where: not is_nil(u.email))

# Comparison operators
query = from(p in Product, where: p.price > 100)
query = from(p in Product, where: p.price >= 50 and p.price <= 200)
query = from(u in User, where: u.age < 18)

# IN clause
query = from(u in User, where: u.role in ["admin", "moderator"])
query = from(u in User, where: u.id in [1, 2, 3, 4, 5])

# NOT IN
query = from(u in User, where: u.status not in ["banned", "suspended"])

# LIKE patterns (use ilike for case-insensitive)
query = from(u in User, where: like(u.name, "A%"))
query = from(u in User, where: ilike(u.email, "%@gmail.com"))

# Between (using comparison)
query = from(o in Order, where: o.total >= 100 and o.total <= 500)

# Date comparisons
query = from(u in User, where: u.created_at > ^~N[2024-01-01 00:00:00])
"""

IO.puts("Where clause examples:")
IO.puts(where_examples)

# -----------------------------------------------------------------------------
# Section 5: Pinning External Values
# -----------------------------------------------------------------------------
#
# Use the pin operator (^) to interpolate external values into queries.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 5: Pinning External Values ---\n")

pin_examples = """
import Ecto.Query

# Pin variable values
email = "alice@example.com"
query = from(u in User, where: u.email == ^email)

# Pin list values
ids = [1, 2, 3, 4, 5]
query = from(u in User, where: u.id in ^ids)

# Pin in select
fields = [:name, :email]
query = from(u in User, select: map(u, ^fields))

# Pin computed values
min_age = 18
max_age = 65
query = from(u in User, where: u.age >= ^min_age and u.age <= ^max_age)

# Pin function results
now = DateTime.utc_now()
query = from(s in Session, where: s.expires_at > ^now)

# Pin tuple for between-like queries
date_range = {~D[2024-01-01], ~D[2024-12-31]}
{start_date, end_date} = date_range
query = from(o in Order,
  where: o.created_at >= ^start_date and o.created_at <= ^end_date
)

# Cannot use unpinned variables!
# This will cause a compile error:
# query = from(u in User, where: u.email == email)  # ERROR!
"""

IO.puts("Pinning values:")
IO.puts(pin_examples)

IO.puts("""
Why pinning is required:
- Queries are compiled at compile time
- Runtime values need explicit interpolation
- Prevents SQL injection (values are parameterized)
- Makes query intent clear
""")

# -----------------------------------------------------------------------------
# Section 6: Order By - Sorting Results
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 6: Order By - Sorting Results ---\n")

order_examples = """
import Ecto.Query

# Simple ascending order (default)
query = from(u in User, order_by: u.name)

# Explicit ascending
query = from(u in User, order_by: [asc: u.name])

# Descending order
query = from(u in User, order_by: [desc: u.created_at])

# Multiple columns
query = from(u in User, order_by: [asc: u.role, desc: u.created_at])

# Nulls handling (PostgreSQL)
query = from(u in User, order_by: [asc_nulls_first: u.last_login])
query = from(u in User, order_by: [desc_nulls_last: u.deleted_at])

# Order by expression
query = from(p in Product, order_by: [desc: p.price * p.quantity])

# Order with pinned direction
direction = :desc
query = from(u in User, order_by: [{^direction, u.created_at}])
"""

IO.puts("Order by examples:")
IO.puts(order_examples)

# -----------------------------------------------------------------------------
# Section 7: Limit and Offset - Pagination
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 7: Limit and Offset - Pagination ---\n")

pagination_examples = """
import Ecto.Query

# Basic limit
query = from(u in User, limit: 10)

# Limit and offset for pagination
page = 2
per_page = 20
query = from(u in User,
  order_by: u.id,
  limit: ^per_page,
  offset: ^((page - 1) * per_page)
)

# First/last patterns
# Get first user
query = from(u in User, order_by: u.id, limit: 1)

# Get last user
query = from(u in User, order_by: [desc: u.id], limit: 1)

# Top N by some criteria
query = from(p in Product,
  order_by: [desc: p.sales_count],
  limit: 10
)

# Pagination helper function
defmodule Pagination do
  import Ecto.Query

  def paginate(query, page, per_page) do
    query
    |> limit(^per_page)
    |> offset(^((page - 1) * per_page))
  end
end

# Usage:
# User |> Pagination.paginate(3, 25) |> Repo.all()
"""

IO.puts("Pagination examples:")
IO.puts(pagination_examples)

# -----------------------------------------------------------------------------
# Section 8: Distinct - Removing Duplicates
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 8: Distinct - Removing Duplicates ---\n")

distinct_examples = """
import Ecto.Query

# Simple distinct
query = from(u in User, distinct: true, select: u.role)
# Returns: ["admin", "user", "moderator"]

# Distinct on specific columns (PostgreSQL)
query = from(p in Post,
  distinct: [p.category],
  order_by: [asc: p.category, desc: p.created_at],
  select: p
)
# Returns first post (by created_at) for each category

# Distinct with multiple columns
query = from(o in Order,
  distinct: [o.user_id, o.status],
  select: %{user_id: o.user_id, status: o.status}
)
"""

IO.puts("Distinct examples:")
IO.puts(distinct_examples)

# -----------------------------------------------------------------------------
# Section 9: Keyword vs Pipe Syntax
# -----------------------------------------------------------------------------
#
# Queries can be written in keyword or pipe (macro) syntax.
#
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 9: Keyword vs Pipe Syntax ---\n")

syntax_comparison = """
import Ecto.Query

# Keyword syntax - all in one from
query = from(u in User,
  where: u.active == true,
  where: u.role == "admin",
  order_by: [desc: u.created_at],
  limit: 10,
  select: %{name: u.name, email: u.email}
)

# Pipe (macro) syntax - composable
query =
  User
  |> where([u], u.active == true)
  |> where([u], u.role == "admin")
  |> order_by([u], desc: u.created_at)
  |> limit(10)
  |> select([u], %{name: u.name, email: u.email})

# Both produce the same SQL!

# Pipe syntax requires binding in brackets [u]
# This re-establishes the binding from from()

# You can mix them
query = from(u in User, where: u.active == true)
query = query |> where([u], u.role == "admin")
query = query |> order_by([u], desc: u.created_at)
"""

IO.puts("Syntax comparison:")
IO.puts(syntax_comparison)

IO.puts("""
When to use each:

Keyword syntax:
- Simple, complete queries
- All conditions known upfront
- More readable for straightforward queries

Pipe syntax:
- Building queries dynamically
- Conditional additions
- Reusable query functions
- Query composition
""")

# -----------------------------------------------------------------------------
# Section 10: Executing Queries with Repo
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 10: Executing Queries with Repo ---\n")

repo_execution = """
import Ecto.Query

query = from(u in User, where: u.active == true)

# Get all results as list
users = Repo.all(query)
# Returns: [%User{}, %User{}, ...]

# Get single result or nil
user = Repo.one(query |> limit(1))
# Returns: %User{} or nil

# Get single result or raise
user = Repo.one!(query |> where([u], u.id == 1))
# Returns: %User{} or raises Ecto.NoResultsError

# Check if any results exist
exists? = Repo.exists?(query)
# Returns: true or false

# Get first result by primary key ordering
user = Repo.get(User, 1)
# Returns: %User{id: 1, ...} or nil

# Get by specific field
user = Repo.get_by(User, email: "alice@example.com")
# Returns: %User{} or nil

# Get or raise
user = Repo.get!(User, 1)
user = Repo.get_by!(User, email: "alice@example.com")

# Aggregate functions directly
count = Repo.aggregate(User, :count)
max_age = Repo.aggregate(User, :max, :age)

# Execute and get raw results
{:ok, result} = Repo.query("SELECT * FROM users WHERE id = $1", [1])
"""

IO.puts("Repo execution methods:")
IO.puts(repo_execution)

# -----------------------------------------------------------------------------
# Section 11: Common Query Patterns
# -----------------------------------------------------------------------------

IO.puts("\n--- Section 11: Common Query Patterns ---\n")

common_patterns = """
import Ecto.Query

# Find by ID
def get_user(id) do
  Repo.get(User, id)
end

# Find by email with error handling
def get_user_by_email(email) do
  Repo.get_by(User, email: email)
end

# List with filters
def list_users(opts \\\\ []) do
  User
  |> maybe_filter_active(opts[:active])
  |> maybe_filter_role(opts[:role])
  |> order_by([u], desc: u.created_at)
  |> Repo.all()
end

defp maybe_filter_active(query, nil), do: query
defp maybe_filter_active(query, active) do
  where(query, [u], u.active == ^active)
end

defp maybe_filter_role(query, nil), do: query
defp maybe_filter_role(query, role) do
  where(query, [u], u.role == ^role)
end

# Search pattern
def search_users(search_term) do
  search = "%\#{search_term}%"

  from(u in User,
    where: ilike(u.name, ^search) or ilike(u.email, ^search),
    order_by: u.name
  )
  |> Repo.all()
end

# Recent items
def recent_posts(limit \\\\ 10) do
  from(p in Post,
    where: p.published == true,
    order_by: [desc: p.published_at],
    limit: ^limit
  )
  |> Repo.all()
end

# Count with condition
def count_active_users do
  from(u in User, where: u.active == true)
  |> Repo.aggregate(:count)
end
"""

IO.puts("Common query patterns:")
IO.puts(common_patterns)

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("EXERCISES")
IO.puts(String.duplicate("=", 70))

IO.puts("""

Exercise 1: Basic Queries
Difficulty: Easy

Given a products table with columns: name, price, category, in_stock (boolean),
write queries to:

1. Select all products
2. Select only name and price of all products
3. Select products where price > 100
4. Select products that are in stock

Write your queries:
""")

# import Ecto.Query
#
# # 1. All products
# query1 = ...
#
# # 2. Name and price only
# query2 = ...
#
# # 3. Price > 100
# query3 = ...
#
# # 4. In stock
# query4 = ...

IO.puts("""

Exercise 2: Combining Conditions
Difficulty: Easy

Write queries for an orders table with columns: user_id, status, total, created_at

1. Orders with status "completed" OR "shipped"
2. Orders where total is between 50 and 200
3. Orders from the last 7 days with total > 100
4. Orders that are NOT cancelled or refunded

Write your queries:
""")

# import Ecto.Query
#
# # 1. Status completed or shipped
# query1 = ...
#
# # 2. Total between 50 and 200
# query2 = ...
#
# # 3. Last 7 days, total > 100
# query3 = ...
#
# # 4. Not cancelled or refunded
# query4 = ...

IO.puts("""

Exercise 3: Selecting Different Formats
Difficulty: Medium

Given a users table, write queries that return:

1. A list of just email strings
2. A list of maps with :full_name and :contact_email keys
3. A list of tuples {id, name, role}
4. A list of maps with only :id, :name, :email (using map/2)

Write your queries:
""")

# import Ecto.Query
#
# # 1. List of emails
# query1 = ...
#
# # 2. Maps with renamed keys
# query2 = ...
#
# # 3. Tuples
# query3 = ...
#
# # 4. Using map/2
# query4 = ...

IO.puts("""

Exercise 4: Pagination and Sorting
Difficulty: Medium

Create a function that returns paginated, sorted products:
- Takes page number, per_page, and sort_field as arguments
- Supports sorting by :name, :price, or :created_at
- Returns products as maps with :id, :name, :price

Write your function:
""")

# defmodule ProductQueries do
#   import Ecto.Query
#
#   def list_products(page, per_page, sort_field) do
#     # Your code here
#   end
# end

IO.puts("""

Exercise 5: Search with Multiple Fields
Difficulty: Medium

Create a search function for a blog posts table that:
- Searches in title, body, and author_name fields
- Is case-insensitive
- Returns only published posts
- Orders by relevance (exact title match first, then others)
- Limits to 20 results

Write your query:
""")

# defmodule PostSearch do
#   import Ecto.Query
#
#   def search(term) do
#     # Your code here
#   end
# end

IO.puts("""

Exercise 6: Dynamic Query Builder
Difficulty: Hard

Create a query builder that accepts a map of filters and builds a query:

  filters = %{
    active: true,
    role: "admin",
    min_age: 18,
    max_age: 65,
    search: "john"
  }

  build_query(User, filters)

The function should:
- Only apply filters that are present (not nil)
- Handle search across name and email
- Support any combination of filters

Write your function:
""")

# defmodule QueryBuilder do
#   import Ecto.Query
#
#   def build_query(schema, filters) do
#     # Your code here
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

1. Ecto.Query basics:
   - Queries are data structures, not executed until Repo
   - Use `import Ecto.Query` for convenience
   - Queries are composable and type-safe

2. Building queries:
   - from(u in User) - start a query with binding
   - select: - choose what to return
   - where: - filter results
   - order_by: - sort results
   - limit:/offset: - pagination

3. Select formats:
   - u - entire struct
   - u.field - single field
   - %{key: u.field} - map
   - {u.a, u.b} - tuple
   - map(u, [:a, :b]) - map with selected keys

4. Where conditions:
   - ==, !=, >, <, >=, <=
   - and, or, not
   - in, not in
   - is_nil(), not is_nil()
   - like(), ilike()

5. Pin operator (^):
   - Required for runtime values
   - ^variable, ^list, ^(expression)
   - Prevents SQL injection

6. Two syntaxes:
   - Keyword: from(u in User, where: ..., select: ...)
   - Pipe: User |> where([u], ...) |> select([u], ...)

7. Repo execution:
   - Repo.all/1 - all results
   - Repo.one/1 - single or nil
   - Repo.one!/1 - single or raise
   - Repo.exists?/1 - boolean
   - Repo.get/2, Repo.get_by/2 - by key

Next: 12_query_composition.exs - Composing and reusing queries
""")
