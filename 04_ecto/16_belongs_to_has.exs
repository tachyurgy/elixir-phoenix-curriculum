# ==============================================================================
# Lesson 16: belongs_to, has_one, has_many Relationships
# ==============================================================================
#
# Ecto provides powerful association macros for modeling relationships between
# database tables. Understanding these associations is fundamental to building
# real-world applications with relational data.
#
# In this lesson, you will learn:
# - The three primary association types: belongs_to, has_one, has_many
# - How to define associations in schemas
# - How foreign keys work with associations
# - Querying and loading associated data
# - The difference between loaded and unloaded associations
#
# ==============================================================================

# ==============================================================================
# Section 1: Understanding Associations
# ==============================================================================
#
# Associations in Ecto map directly to database relationships:
#
# - belongs_to: The current schema has a foreign key pointing to another table
# - has_one: Another table has a foreign key pointing to this table (1:1)
# - has_many: Another table has foreign keys pointing to this table (1:N)
#
# The "parent" in a relationship is typically the one being referenced,
# and the "child" is the one holding the foreign key.

# Example domain: A blog system with users, profiles, and posts

defmodule Blog.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :username, :string

    # has_one: A user has exactly one profile
    # The profiles table has a user_id foreign key
    has_one :profile, Blog.Profile

    # has_many: A user can have many posts
    # The posts table has a user_id foreign key
    has_many :posts, Blog.Post

    # has_many: A user can have many comments
    has_many :comments, Blog.Comment

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username])
    |> validate_required([:email, :username])
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end
end

defmodule Blog.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "profiles" do
    field :bio, :string
    field :avatar_url, :string
    field :website, :string

    # belongs_to: This profile belongs to a user
    # This adds a user_id field to the schema automatically
    belongs_to :user, Blog.User

    timestamps()
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:bio, :avatar_url, :website, :user_id])
    |> validate_required([:user_id])
    # Ensure the user exists
    |> foreign_key_constraint(:user_id)
  end
end

defmodule Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :body, :string
    field :published, :boolean, default: false

    # belongs_to: This post belongs to an author (user)
    # Using :author as the association name, referencing Blog.User
    belongs_to :author, Blog.User, foreign_key: :author_id

    # has_many: A post can have many comments
    has_many :comments, Blog.Comment

    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :published, :author_id])
    |> validate_required([:title, :body, :author_id])
    |> validate_length(:title, min: 3, max: 200)
    |> foreign_key_constraint(:author_id)
  end
end

defmodule Blog.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :body, :string

    # belongs_to: A comment belongs to a post
    belongs_to :post, Blog.Post

    # belongs_to: A comment belongs to a user (author)
    belongs_to :author, Blog.User, foreign_key: :author_id

    timestamps()
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :post_id, :author_id])
    |> validate_required([:body, :post_id, :author_id])
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:author_id)
  end
end

# ==============================================================================
# Section 2: Association Options
# ==============================================================================
#
# Each association macro accepts options to customize behavior:

defmodule AssociationOptions do
  @moduledoc """
  Demonstrates various association options available in Ecto.
  """

  # belongs_to options:
  #
  # - :foreign_key - The column name for the foreign key (default: #{assoc_name}_id)
  # - :references - The column in the parent table to reference (default: :id)
  # - :type - The type of the foreign key (default: :id which is :integer or :binary_id)
  # - :on_replace - What to do when association is replaced (:raise, :mark_as_invalid, :delete, :nilify)
  # - :defaults - Default values when building the association
  # - :where - A default where clause for the association

  # has_one/has_many options:
  #
  # - :foreign_key - Column in child table (default: #{parent}_id)
  # - :references - Column in parent table being referenced (default: :id)
  # - :on_delete - What happens when parent is deleted (:nothing, :nilify_all, :delete_all)
  # - :on_replace - What happens when association is replaced
  # - :where - Default where clause for the association
  # - :defaults - Default values when building associations

  # Example with custom options:
  defmodule Company do
    use Ecto.Schema

    schema "companies" do
      field :name, :string

      # Custom foreign key reference
      has_many :employees, Employee, foreign_key: :company_id

      # has_one with custom options
      has_one :headquarters, Office,
        where: [is_headquarters: true],
        foreign_key: :company_id

      # has_many with default where clause
      has_many :active_employees, Employee,
        where: [status: "active"],
        foreign_key: :company_id
    end
  end

  defmodule Employee do
    use Ecto.Schema

    schema "employees" do
      field :name, :string
      field :status, :string

      # belongs_to with custom type (UUID)
      belongs_to :company, Company, type: :binary_id

      # Self-referential association (manager is also an Employee)
      belongs_to :manager, Employee, foreign_key: :manager_id

      # Employees managed by this employee
      has_many :direct_reports, Employee, foreign_key: :manager_id
    end
  end

  defmodule Office do
    use Ecto.Schema

    schema "offices" do
      field :address, :string
      field :is_headquarters, :boolean

      belongs_to :company, Company
    end
  end
end

# ==============================================================================
# Section 3: Working with Associations
# ==============================================================================

defmodule Blog.Examples do
  @moduledoc """
  Examples of working with associations in practice.
  """

  import Ecto.Query
  alias Blog.{User, Profile, Post, Comment, Repo}

  # ---------------------------------------------------------------------------
  # Creating records with associations
  # ---------------------------------------------------------------------------

  def create_user_with_profile do
    # First, create the user
    {:ok, user} = %User{}
    |> User.changeset(%{email: "alice@example.com", username: "alice"})
    |> Repo.insert()

    # Then create the profile with the user_id
    {:ok, profile} = %Profile{}
    |> Profile.changeset(%{bio: "Elixir developer", user_id: user.id})
    |> Repo.insert()

    {user, profile}
  end

  # Using Ecto.build_assoc for cleaner association creation
  def create_post_for_user(user, post_attrs) do
    user
    |> Ecto.build_assoc(:posts, %{})
    |> Post.changeset(post_attrs)
    |> Repo.insert()
  end

  # ---------------------------------------------------------------------------
  # Loading associations (Preloading)
  # ---------------------------------------------------------------------------

  # Associations are NOT loaded by default
  def get_user_without_preload(user_id) do
    user = Repo.get(User, user_id)
    # user.posts is #Ecto.Association.NotLoaded<...>
    # Accessing it directly would raise an error in strict mode
    user
  end

  # Preload at query time
  def get_user_with_posts(user_id) do
    User
    |> preload(:posts)
    |> Repo.get(user_id)
    # Now user.posts is a list of Post structs
  end

  # Preload after fetching
  def get_user_then_preload(user_id) do
    user = Repo.get(User, user_id)
    Repo.preload(user, :posts)
  end

  # Preload multiple associations
  def get_user_with_all_data(user_id) do
    User
    |> preload([:profile, :posts, :comments])
    |> Repo.get(user_id)
  end

  # Nested preloading
  def get_user_with_posts_and_comments(user_id) do
    User
    |> preload(posts: :comments)
    |> Repo.get(user_id)
    # user.posts[0].comments is now loaded
  end

  # Preload with custom query
  def get_user_with_recent_posts(user_id) do
    recent_posts_query =
      from p in Post,
        where: p.published == true,
        order_by: [desc: p.inserted_at],
        limit: 5

    User
    |> preload(posts: ^recent_posts_query)
    |> Repo.get(user_id)
  end

  # ---------------------------------------------------------------------------
  # Querying through associations
  # ---------------------------------------------------------------------------

  # Get all posts by a specific user
  def get_posts_by_user(user_id) do
    from p in Post,
      where: p.author_id == ^user_id,
      order_by: [desc: p.inserted_at]
    |> Repo.all()
  end

  # Using assoc to query through association
  def get_posts_via_assoc(user) do
    user
    |> Ecto.assoc(:posts)
    |> Repo.all()
  end

  # Join query to get posts with author info
  def get_posts_with_authors do
    from p in Post,
      join: a in assoc(p, :author),
      preload: [author: a],
      select: p
    |> Repo.all()
  end

  # Complex join: Posts with comment counts
  def get_posts_with_comment_counts do
    from p in Post,
      left_join: c in assoc(p, :comments),
      group_by: p.id,
      select: {p, count(c.id)}
    |> Repo.all()
  end

  # Filter based on association
  def get_users_with_published_posts do
    from u in User,
      join: p in assoc(u, :posts),
      where: p.published == true,
      distinct: true,
      select: u
    |> Repo.all()
  end
end

# ==============================================================================
# Section 4: Understanding NotLoaded
# ==============================================================================

defmodule NotLoadedDemo do
  @moduledoc """
  Understanding the Ecto.Association.NotLoaded struct.
  """

  # When you fetch a record, associations are not loaded by default.
  # They contain an Ecto.Association.NotLoaded struct:
  #
  #   %Ecto.Association.NotLoaded{
  #     __field__: :posts,
  #     __owner__: Blog.User,
  #     __cardinality__: :many
  #   }
  #
  # This is intentional - it prevents N+1 queries by making you
  # explicitly decide when to load associations.

  def check_if_loaded(struct, assoc_name) do
    case Map.get(struct, assoc_name) do
      %Ecto.Association.NotLoaded{} -> :not_loaded
      nil -> :no_association
      [] -> :empty
      _data -> :loaded
    end
  end

  # Using Ecto.assoc_loaded?/2 (Ecto 3.0+)
  def is_loaded?(struct, assoc_name) do
    Ecto.assoc_loaded?(struct, assoc_name)
  end
end

# ==============================================================================
# Section 5: Database Migration Examples
# ==============================================================================
#
# For the schemas above, here are the corresponding migrations:

migration_example = """
# Migration for users table
defmodule Blog.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :username, :string, null: false

      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
  end
end

# Migration for profiles table (belongs_to users)
defmodule Blog.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    create table(:profiles) do
      add :bio, :text
      add :avatar_url, :string
      add :website, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    # Ensure each user has only one profile
    create unique_index(:profiles, [:user_id])
  end
end

# Migration for posts table (belongs_to users as author)
defmodule Blog.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string, null: false
      add :body, :text, null: false
      add :published, :boolean, default: false
      add :author_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:posts, [:author_id])
    create index(:posts, [:published])
  end
end

# Migration for comments table (belongs_to posts and users)
defmodule Blog.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :body, :text, null: false
      add :post_id, references(:posts, on_delete: :delete_all), null: false
      add :author_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:comments, [:post_id])
    create index(:comments, [:author_id])
  end
end
"""

IO.puts(migration_example)

# ==============================================================================
# Section 6: on_delete Behavior
# ==============================================================================
#
# When the parent record is deleted, what happens to children?
#
# Database level (in migration - RECOMMENDED):
# - :nothing - Do nothing (may cause foreign key constraint errors)
# - :delete_all - Delete all associated records
# - :nilify_all - Set the foreign key to NULL
# - :restrict - Prevent deletion if associated records exist
#
# Application level (in schema - use sparingly):
# - on_delete: :nothing (default)
# - on_delete: :nilify_all
# - on_delete: :delete_all

# Example showing on_delete options in migrations:
on_delete_example = """
# Different on_delete strategies:

# Delete all comments when post is deleted
add :post_id, references(:posts, on_delete: :delete_all), null: false

# Set author_id to NULL when user is deleted
add :author_id, references(:users, on_delete: :nilify_all)

# Prevent deletion of user if they have posts
add :author_id, references(:users, on_delete: :restrict), null: false

# No action (default) - will error if constraints violated
add :category_id, references(:categories, on_delete: :nothing)
"""

IO.puts(on_delete_example)

# ==============================================================================
# Exercises
# ==============================================================================

defmodule Exercises do
  @moduledoc """
  Exercises to practice association concepts.

  To complete these exercises, implement each function according to
  its documentation. Assume a Repo module exists and is configured.
  """

  # Exercise 1: Define a has_one relationship
  #
  # Create schemas for Order and Invoice where:
  # - An Order has one Invoice
  # - An Invoice belongs to an Order
  # - Invoice has fields: :number (string), :total (decimal), :paid (boolean)
  # - Order has fields: :reference (string), :status (string)
  #
  # Your solution:
  defmodule Order do
    use Ecto.Schema
    # TODO: Define the schema with has_one :invoice
  end

  defmodule Invoice do
    use Ecto.Schema
    # TODO: Define the schema with belongs_to :order
  end

  # Exercise 2: Define a self-referential association
  #
  # Create a Category schema where:
  # - A category can have a parent category (belongs_to)
  # - A category can have many subcategories (has_many)
  # - Fields: :name (string), :description (string)
  #
  # Your solution:
  defmodule Category do
    use Ecto.Schema
    # TODO: Define self-referential schema
  end

  # Exercise 3: Write a preload query
  #
  # Given the Blog schemas, write a function that:
  # - Fetches all posts that are published
  # - Preloads the author and comments
  # - Orders by most recent first
  #
  # Your solution:
  def get_published_posts_with_details do
    import Ecto.Query
    # TODO: Implement the query
    # from p in Blog.Post, ...
  end

  # Exercise 4: Write a join query
  #
  # Write a function that returns users who have written at least
  # one comment, along with their comment count.
  # Return a list of {user, count} tuples.
  #
  # Your solution:
  def users_with_comment_counts do
    import Ecto.Query
    # TODO: Implement the query
  end

  # Exercise 5: Custom foreign key
  #
  # Create schemas for Article and Revision where:
  # - Article has many Revisions
  # - Revision belongs to Article
  # - The foreign key is :article_ref instead of :article_id
  # - The reference is to Article's :ref field (not :id)
  #
  # Your solution:
  defmodule Article do
    use Ecto.Schema
    # TODO: Define schema with custom foreign key reference
  end

  defmodule Revision do
    use Ecto.Schema
    # TODO: Define schema with custom belongs_to
  end

  # Exercise 6: Conditional association loading
  #
  # Write a function that:
  # - Takes a user struct
  # - Returns the user with posts preloaded only if they have more than 5 posts
  # - Otherwise returns the user without preloading posts
  # - Hint: Use a subquery to count first
  #
  # Your solution:
  def maybe_preload_posts(user) do
    # TODO: Implement conditional preloading
  end
end

# ==============================================================================
# Exercise Solutions (For reference - try to solve them first!)
# ==============================================================================

defmodule ExerciseSolutions do
  @moduledoc false

  # Solution 1: Order and Invoice
  defmodule Order do
    use Ecto.Schema
    import Ecto.Changeset

    schema "orders" do
      field :reference, :string
      field :status, :string

      has_one :invoice, ExerciseSolutions.Invoice

      timestamps()
    end

    def changeset(order, attrs) do
      order
      |> cast(attrs, [:reference, :status])
      |> validate_required([:reference, :status])
    end
  end

  defmodule Invoice do
    use Ecto.Schema
    import Ecto.Changeset

    schema "invoices" do
      field :number, :string
      field :total, :decimal
      field :paid, :boolean, default: false

      belongs_to :order, ExerciseSolutions.Order

      timestamps()
    end

    def changeset(invoice, attrs) do
      invoice
      |> cast(attrs, [:number, :total, :paid, :order_id])
      |> validate_required([:number, :total, :order_id])
      |> foreign_key_constraint(:order_id)
    end
  end

  # Solution 2: Self-referential Category
  defmodule Category do
    use Ecto.Schema
    import Ecto.Changeset

    schema "categories" do
      field :name, :string
      field :description, :string

      belongs_to :parent, __MODULE__, foreign_key: :parent_id
      has_many :subcategories, __MODULE__, foreign_key: :parent_id

      timestamps()
    end

    def changeset(category, attrs) do
      category
      |> cast(attrs, [:name, :description, :parent_id])
      |> validate_required([:name])
      |> foreign_key_constraint(:parent_id)
    end
  end

  # Solution 3: Published posts with details
  def get_published_posts_with_details do
    import Ecto.Query

    from p in Blog.Post,
      where: p.published == true,
      preload: [:author, :comments],
      order_by: [desc: p.inserted_at]
    # |> Repo.all()
  end

  # Solution 4: Users with comment counts
  def users_with_comment_counts do
    import Ecto.Query

    from u in Blog.User,
      join: c in Blog.Comment,
      on: c.author_id == u.id,
      group_by: u.id,
      select: {u, count(c.id)}
    # |> Repo.all()
  end

  # Solution 5: Custom foreign key
  defmodule Article do
    use Ecto.Schema

    schema "articles" do
      field :title, :string
      field :ref, :string

      has_many :revisions, ExerciseSolutions.Revision,
        foreign_key: :article_ref,
        references: :ref

      timestamps()
    end
  end

  defmodule Revision do
    use Ecto.Schema

    schema "revisions" do
      field :content, :string
      field :version, :integer

      belongs_to :article, ExerciseSolutions.Article,
        foreign_key: :article_ref,
        references: :ref,
        type: :string

      timestamps()
    end
  end

  # Solution 6: Conditional preloading
  def maybe_preload_posts(user) do
    import Ecto.Query

    post_count =
      from(p in Blog.Post, where: p.author_id == ^user.id, select: count(p.id))
      # |> Repo.one()

    if post_count > 5 do
      # Repo.preload(user, :posts)
      user
    else
      user
    end
  end
end

# ==============================================================================
# Key Takeaways
# ==============================================================================
#
# 1. Association types map to database relationships:
#    - belongs_to: Has the foreign key
#    - has_one: Other table has FK, 1:1 relationship
#    - has_many: Other table has FK, 1:N relationship
#
# 2. Associations are NOT loaded by default - use preload explicitly
#
# 3. You can customize associations with options:
#    - :foreign_key, :references, :where, :on_delete, :on_replace
#
# 4. Preloading can be done:
#    - At query time: preload(query, [:assoc])
#    - After fetching: Repo.preload(struct, [:assoc])
#    - With custom queries: preload(posts: ^custom_query)
#
# 5. Use joins for filtering and aggregating across associations
#
# 6. Define on_delete behavior in migrations, not schemas
#
# ==============================================================================
