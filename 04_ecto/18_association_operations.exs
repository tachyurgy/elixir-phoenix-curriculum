# ==============================================================================
# Lesson 18: Association Operations - build_assoc, put_assoc, cast_assoc, preload
# ==============================================================================
#
# Ecto provides several functions for working with associations. Understanding
# when to use each one is crucial for effectively managing related data.
#
# In this lesson, you will learn:
# - build_assoc: Building associated structs
# - put_assoc: Replacing associations with existing structs
# - cast_assoc: Casting nested parameters into associations
# - preload: Loading associated data from the database
# - The differences and use cases for each approach
#
# ==============================================================================

# ==============================================================================
# Section 1: Example Schemas
# ==============================================================================

defmodule MyApp.Schemas do
  @moduledoc """
  Example schemas for demonstrating association operations.
  """

  defmodule Author do
    use Ecto.Schema
    import Ecto.Changeset

    schema "authors" do
      field :name, :string
      field :email, :string

      has_many :posts, MyApp.Schemas.Post
      has_one :profile, MyApp.Schemas.Profile

      timestamps()
    end

    def changeset(author, attrs) do
      author
      |> cast(attrs, [:name, :email])
      |> validate_required([:name, :email])
      |> unique_constraint(:email)
    end
  end

  defmodule Profile do
    use Ecto.Schema
    import Ecto.Changeset

    schema "profiles" do
      field :bio, :string
      field :website, :string

      belongs_to :author, MyApp.Schemas.Author

      timestamps()
    end

    def changeset(profile, attrs) do
      profile
      |> cast(attrs, [:bio, :website, :author_id])
      |> validate_required([:author_id])
    end
  end

  defmodule Post do
    use Ecto.Schema
    import Ecto.Changeset

    schema "posts" do
      field :title, :string
      field :body, :string

      belongs_to :author, MyApp.Schemas.Author
      has_many :comments, MyApp.Schemas.Comment
      many_to_many :tags, MyApp.Schemas.Tag, join_through: "posts_tags", on_replace: :delete

      timestamps()
    end

    def changeset(post, attrs) do
      post
      |> cast(attrs, [:title, :body, :author_id])
      |> validate_required([:title, :body])
    end

    # Changeset that handles nested comments
    def changeset_with_comments(post, attrs) do
      post
      |> cast(attrs, [:title, :body, :author_id])
      |> validate_required([:title, :body])
      |> cast_assoc(:comments, with: &MyApp.Schemas.Comment.changeset/2)
    end

    # Changeset that handles tags
    def changeset_with_tags(post, attrs) do
      post
      |> cast(attrs, [:title, :body, :author_id])
      |> validate_required([:title, :body])
      |> put_assoc(:tags, attrs[:tags] || [])
    end
  end

  defmodule Comment do
    use Ecto.Schema
    import Ecto.Changeset

    schema "comments" do
      field :body, :string
      field :approved, :boolean, default: false

      belongs_to :post, MyApp.Schemas.Post

      timestamps()
    end

    def changeset(comment, attrs) do
      comment
      |> cast(attrs, [:body, :approved, :post_id])
      |> validate_required([:body])
    end
  end

  defmodule Tag do
    use Ecto.Schema
    import Ecto.Changeset

    schema "tags" do
      field :name, :string

      many_to_many :posts, MyApp.Schemas.Post, join_through: "posts_tags"

      timestamps()
    end

    def changeset(tag, attrs) do
      tag
      |> cast(attrs, [:name])
      |> validate_required([:name])
      |> unique_constraint(:name)
    end
  end
end

# ==============================================================================
# Section 2: build_assoc
# ==============================================================================

defmodule BuildAssocExamples do
  @moduledoc """
  Ecto.build_assoc/3 builds a struct for an association with the foreign key set.

  Use build_assoc when:
  - Creating a new associated record for an existing parent
  - You want the foreign key automatically set
  - Building forms or preparing data for insertion
  """

  alias MyApp.Schemas.{Author, Post, Profile, Comment}

  # Basic usage: Build a post for an author
  def build_post_for_author(author) do
    # Creates %Post{author_id: author.id}
    Ecto.build_assoc(author, :posts)
  end

  # With default values
  def build_draft_post(author, title) do
    Ecto.build_assoc(author, :posts, %{title: title, body: "Draft content"})
  end

  # Building has_one association
  def build_profile(author) do
    # Creates %Profile{author_id: author.id}
    Ecto.build_assoc(author, :profile)
  end

  # Chain with changeset for validation
  def create_post(author, attrs) do
    author
    |> Ecto.build_assoc(:posts)
    |> Post.changeset(attrs)
    # |> Repo.insert()
  end

  # Building nested associations
  def build_comment_for_post(post) do
    Ecto.build_assoc(post, :comments)
  end

  # Complete example with repo
  def full_create_example(author, post_attrs) do
    changeset =
      author
      |> Ecto.build_assoc(:posts)
      |> Post.changeset(post_attrs)

    case changeset do
      %{valid?: true} = cs ->
        # Repo.insert(cs)
        {:ok, cs}
      cs ->
        {:error, cs}
    end
  end
end

# ==============================================================================
# Section 3: put_assoc
# ==============================================================================

defmodule PutAssocExamples do
  @moduledoc """
  Ecto.Changeset.put_assoc/4 puts an association in the changeset.

  Use put_assoc when:
  - You already have the associated struct(s) loaded
  - You want to replace an entire association
  - Managing many_to_many relationships
  - The associated data doesn't need validation (it's already validated)

  Important: The struct MUST be preloaded before using put_assoc!
  """

  import Ecto.Changeset
  alias MyApp.Schemas.{Post, Tag}

  # Replace all tags on a post
  def set_tags(post, tags) do
    # Post must have tags preloaded!
    post
    |> change()
    |> put_assoc(:tags, tags)
  end

  # Add a single tag (keeping existing)
  def add_tag(post, new_tag) do
    # Post must have tags preloaded!
    current_tags = post.tags
    post
    |> change()
    |> put_assoc(:tags, [new_tag | current_tags])
  end

  # Remove a tag
  def remove_tag(post, tag_to_remove) do
    current_tags = post.tags
    new_tags = Enum.reject(current_tags, &(&1.id == tag_to_remove.id))

    post
    |> change()
    |> put_assoc(:tags, new_tags)
  end

  # Setting a has_one association
  def set_profile(author, profile) do
    author
    |> change()
    |> put_assoc(:profile, profile)
  end

  # Setting has_many
  def set_comments(post, comments) do
    post
    |> change()
    |> put_assoc(:comments, comments)
  end

  # put_assoc with options
  # The third argument can include options
  def set_tags_with_options(post, tags) do
    post
    |> change()
    # :required option ensures at least one tag
    |> put_assoc(:tags, tags, required: true)
  end

  # Common pattern: fetch tags and set them
  def update_post_tags(post, tag_ids) do
    import Ecto.Query

    # Fetch the actual tag structs
    tags = from(t in Tag, where: t.id in ^tag_ids) |> MyApp.Repo.all()

    # Ensure post.tags is preloaded
    post = MyApp.Repo.preload(post, :tags)

    post
    |> change()
    |> put_assoc(:tags, tags)
    |> MyApp.Repo.update()
  end
end

# ==============================================================================
# Section 4: cast_assoc
# ==============================================================================

defmodule CastAssocExamples do
  @moduledoc """
  Ecto.Changeset.cast_assoc/3 casts nested parameters into an association.

  Use cast_assoc when:
  - Handling nested form data (params with nested attributes)
  - You want to create/update/delete associations from raw params
  - The nested data needs to go through its own changeset for validation

  cast_assoc is powerful for handling complex nested forms!
  """

  import Ecto.Changeset
  alias MyApp.Schemas.{Post, Comment, Author}

  # Basic usage: Cast nested comments from params
  def create_post_with_comments(author, params) do
    # params might look like:
    # %{
    #   "title" => "My Post",
    #   "body" => "Content",
    #   "comments" => [
    #     %{"body" => "First comment"},
    #     %{"body" => "Second comment"}
    #   ]
    # }

    author
    |> Ecto.build_assoc(:posts)
    |> cast(params, [:title, :body])
    |> cast_assoc(:comments, with: &Comment.changeset/2)
  end

  # Update with nested associations
  def update_post_with_comments(post, params) do
    # post must be preloaded with :comments
    # If comments have an "id" field, they'll be updated
    # New comments (no id) will be inserted
    # Missing comments (in db but not in params) behavior depends on :on_replace

    post
    |> cast(params, [:title, :body])
    |> cast_assoc(:comments, with: &Comment.changeset/2)
  end

  # cast_assoc options
  def cast_with_options(post, params) do
    post
    |> cast(params, [:title, :body])
    |> cast_assoc(:comments,
      with: &Comment.changeset/2,
      # What to do when existing assoc is not in new params
      on_replace: :delete,  # or :update, :nilify, :mark_as_invalid
      # Sort function for determining matches
      sort_param: :position,
      # Custom constraint message
      invalid_message: "is invalid",
      # Require at least one
      required: false
    )
  end

  # on_replace options explained:
  #
  # :raise (default) - Raise if trying to replace
  # :mark_as_invalid - Add error to changeset
  # :nilify - Set foreign key to nil
  # :update - Update the existing record (for has_one)
  # :delete - Delete the existing record

  # Example: Author with profile (has_one)
  def update_author_with_profile(author, params) do
    author
    |> cast(params, [:name, :email])
    |> cast_assoc(:profile,
      with: &MyApp.Schemas.Profile.changeset/2,
      on_replace: :update  # Update existing profile instead of error
    )
  end

  # Nested params example for updating:
  #
  # When params include an "id" for an existing comment:
  # %{
  #   "title" => "Updated Title",
  #   "comments" => [
  #     %{"id" => "1", "body" => "Updated comment"},  # Updates existing
  #     %{"body" => "New comment"}                     # Creates new
  #   ]
  # }
  #
  # If comment with id=2 existed but is not in params:
  # - on_replace: :delete -> Deletes comment 2
  # - on_replace: :mark_as_invalid -> Adds error
  # - on_replace: :nilify -> Sets post_id to nil

  # Delete nested record by setting special param
  def handle_delete_in_params(post, params) do
    # Setting delete: true or _delete: true marks record for deletion
    # %{
    #   "comments" => [
    #     %{"id" => "1", "delete" => true}  # Will be deleted
    #   ]
    # }

    post
    |> cast(params, [:title, :body])
    |> cast_assoc(:comments, with: &Comment.changeset/2, on_replace: :delete)
  end

  # Custom changeset function with extra context
  def cast_with_context(post, params, current_user) do
    post
    |> cast(params, [:title, :body])
    |> cast_assoc(:comments, with: fn comment, attrs ->
      comment
      |> Comment.changeset(attrs)
      |> put_change(:approved, current_user.admin?)
    end)
  end
end

# ==============================================================================
# Section 5: preload
# ==============================================================================

defmodule PreloadExamples do
  @moduledoc """
  Repo.preload/2,3 and query-time preloading for loading associations.

  There are multiple ways to preload:
  1. Repo.preload/2 - After fetching
  2. Query preload/2 - At query time
  3. Join-based preload - In a single query
  """

  import Ecto.Query
  alias MyApp.Schemas.{Author, Post, Comment}
  alias MyApp.Repo

  # ---------------------------------------------------------------------------
  # Repo.preload (after fetching)
  # ---------------------------------------------------------------------------

  # Basic preload
  def preload_posts(author) do
    Repo.preload(author, :posts)
  end

  # Multiple associations
  def preload_multiple(author) do
    Repo.preload(author, [:posts, :profile])
  end

  # Nested preloading
  def preload_nested(author) do
    # Load posts, and for each post, load its comments
    Repo.preload(author, posts: :comments)
  end

  # Deep nesting
  def preload_deep(author) do
    Repo.preload(author, [posts: [comments: :author]])
  end

  # Preload with custom query
  def preload_with_query(author) do
    recent_posts = from p in Post, order_by: [desc: p.inserted_at], limit: 5

    Repo.preload(author, posts: recent_posts)
  end

  # Preload with nested custom query
  def preload_complex(author) do
    approved_comments = from c in Comment, where: c.approved == true

    Repo.preload(author, posts: [comments: approved_comments])
  end

  # Force reload (ignore already loaded data)
  def force_reload(author) do
    Repo.preload(author, :posts, force: true)
  end

  # Preload a list of structs
  def preload_list(authors) do
    Repo.preload(authors, [:posts, :profile])
  end

  # ---------------------------------------------------------------------------
  # Query-time preload
  # ---------------------------------------------------------------------------

  # Basic query preload
  def get_author_with_posts(author_id) do
    from(a in Author,
      where: a.id == ^author_id,
      preload: [:posts]
    )
    |> Repo.one()
  end

  # Multiple preloads in query
  def get_author_full(author_id) do
    from(a in Author,
      where: a.id == ^author_id,
      preload: [:profile, posts: :comments]
    )
    |> Repo.one()
  end

  # Preload with subquery in query
  def get_author_recent_posts(author_id) do
    recent_posts = from p in Post, order_by: [desc: p.inserted_at], limit: 5

    from(a in Author,
      where: a.id == ^author_id,
      preload: [posts: ^recent_posts]
    )
    |> Repo.one()
  end

  # ---------------------------------------------------------------------------
  # Join-based preload (single query)
  # ---------------------------------------------------------------------------

  # Using join and preload together
  def get_with_join_preload(author_id) do
    from(a in Author,
      where: a.id == ^author_id,
      join: p in assoc(a, :posts),
      preload: [posts: p]
    )
    |> Repo.one()
  end

  # Join with conditions
  def get_published_posts(author_id) do
    from(a in Author,
      where: a.id == ^author_id,
      left_join: p in assoc(a, :posts),
      on: p.published == true,
      preload: [posts: p]
    )
    |> Repo.one()
  end

  # Multiple joins
  def get_full_with_joins(author_id) do
    from(a in Author,
      where: a.id == ^author_id,
      left_join: pr in assoc(a, :profile),
      left_join: p in assoc(a, :posts),
      left_join: c in assoc(p, :comments),
      preload: [profile: pr, posts: {p, comments: c}]
    )
    |> Repo.one()
  end
end

# ==============================================================================
# Section 6: Comparison Table
# ==============================================================================

comparison = """
+---------------+---------------------+------------------------+------------------------+
| Function      | Input               | Use Case               | Notes                  |
+---------------+---------------------+------------------------+------------------------+
| build_assoc   | Parent struct       | Create new child       | Sets foreign key       |
|               |                     | for existing parent    | automatically          |
+---------------+---------------------+------------------------+------------------------+
| put_assoc     | Changeset +         | Replace association    | Must preload first     |
|               | loaded structs      | with existing data     | No validation of data  |
+---------------+---------------------+------------------------+------------------------+
| cast_assoc    | Changeset +         | Handle nested form     | Runs child changeset   |
|               | raw params (maps)   | data with validation   | Supports CRUD          |
+---------------+---------------------+------------------------+------------------------+
| preload       | Struct or query     | Load associations      | Multiple strategies    |
|               |                     | from database          | available              |
+---------------+---------------------+------------------------+------------------------+

When to use each:

build_assoc:
  - Creating ONE new record
  - When you have the parent and need to create a child
  - Example: "Add a comment to this post"

put_assoc:
  - Replacing/setting associations with existing structs
  - Managing many_to_many where you have the tag/category objects
  - Example: "Set these tags on this post"

cast_assoc:
  - Handling nested form submissions
  - Creating/updating multiple nested records from params
  - When nested data needs validation
  - Example: "Update post and its comments from form data"

preload:
  - Any time you need to access associated data
  - Before using put_assoc
  - Avoiding N+1 queries
  - Example: "Get post with all comments"
"""

IO.puts(comparison)

# ==============================================================================
# Section 7: Common Patterns and Best Practices
# ==============================================================================

defmodule BestPractices do
  @moduledoc """
  Common patterns and best practices for association operations.
  """

  import Ecto.Query
  import Ecto.Changeset

  # Pattern 1: Always preload before put_assoc
  def safe_put_assoc(post, new_tags) do
    post
    |> MyApp.Repo.preload(:tags)  # Always preload first!
    |> change()
    |> put_assoc(:tags, new_tags)
    |> MyApp.Repo.update()
  end

  # Pattern 2: Using cast_assoc with proper on_replace
  def define_cast_assoc_in_changeset do
    # In your schema module, define a changeset that handles associations:
    """
    def changeset_with_items(order, attrs) do
      order
      |> cast(attrs, [:status])
      |> cast_assoc(:line_items,
        with: &LineItem.changeset/2,
        on_replace: :delete  # Delete removed items
      )
    end
    """
  end

  # Pattern 3: Conditional preloading
  def maybe_preload(struct, assoc, should_load?) do
    if should_load? do
      MyApp.Repo.preload(struct, assoc)
    else
      struct
    end
  end

  # Pattern 4: Preload in context functions
  def get_post_for_editing(post_id) do
    MyApp.Schemas.Post
    |> where(id: ^post_id)
    |> preload([:tags, :comments])  # Preload what the edit form needs
    |> MyApp.Repo.one()
  end

  # Pattern 5: Build and insert in one go
  def create_comment_for_post(post, comment_attrs) do
    post
    |> Ecto.build_assoc(:comments)
    |> MyApp.Schemas.Comment.changeset(comment_attrs)
    |> MyApp.Repo.insert()
  end

  # Pattern 6: Avoid N+1 with preload
  def list_posts_bad do
    # Bad: N+1 query problem
    posts = MyApp.Repo.all(MyApp.Schemas.Post)
    Enum.map(posts, fn post ->
      # This makes a query for EACH post!
      author = MyApp.Repo.get(MyApp.Schemas.Author, post.author_id)
      {post, author}
    end)
  end

  def list_posts_good do
    # Good: Single query with preload
    MyApp.Schemas.Post
    |> preload(:author)
    |> MyApp.Repo.all()
  end

  # Pattern 7: Preload only what you need
  def list_posts_for_index do
    # Index page might only need author name, not full profile
    MyApp.Schemas.Post
    |> preload(:author)  # Preload author for display
    |> MyApp.Repo.all()
    # Don't preload comments if not showing them!
  end

  def get_post_for_show(id) do
    # Show page needs everything
    MyApp.Schemas.Post
    |> preload([:author, :tags, comments: :author])
    |> MyApp.Repo.get(id)
  end
end

# ==============================================================================
# Exercises
# ==============================================================================

defmodule Exercises do
  @moduledoc """
  Practice exercises for association operations.
  """

  # Exercise 1: build_assoc
  #
  # Write a function that creates a new comment for a post.
  # - Use build_assoc to set up the comment
  # - Apply the Comment changeset
  # - The function should NOT insert to database
  #
  # Your solution:
  def build_comment(post, body) do
    # TODO: Implement
  end

  # Exercise 2: put_assoc for many_to_many
  #
  # Write a function that updates a post's tags to exactly match
  # a given list of tag_ids. Remember to preload first!
  #
  # Your solution:
  def set_post_tags(post, tag_ids) do
    # TODO: Implement
    # 1. Fetch tags by id
    # 2. Preload post's current tags
    # 3. Use put_assoc to set the new tags
    # 4. Return the changeset (don't update)
  end

  # Exercise 3: cast_assoc
  #
  # Write a changeset function for Post that:
  # - Casts title and body
  # - Cast associated comments using cast_assoc
  # - Deletes comments not present in params
  # - Requires title and body
  #
  # Your solution:
  def post_changeset_with_comments(post, params) do
    import Ecto.Changeset
    # TODO: Implement
  end

  # Exercise 4: Preloading
  #
  # Write a function that:
  # - Fetches all posts by a given author_id
  # - Preloads comments (only approved ones)
  # - Preloads tags
  # - Orders posts by most recent first
  #
  # Your solution:
  def get_author_posts_full(author_id) do
    import Ecto.Query
    # TODO: Implement
  end

  # Exercise 5: Combined operations
  #
  # Write a function that:
  # - Takes a post and a list of tag names (strings)
  # - Finds or creates each tag by name
  # - Associates all tags with the post
  # - Returns {:ok, updated_post} or {:error, reason}
  #
  # Your solution:
  def sync_post_tags_by_name(post, tag_names) do
    # TODO: Implement
  end

  # Exercise 6: Nested cast_assoc
  #
  # Create a changeset function for Author that:
  # - Casts name and email
  # - Casts nested profile (has_one) with on_replace: :update
  # - Casts nested posts (has_many) with on_replace: :delete
  # - For posts, also cast their nested comments
  #
  # Your solution:
  def author_full_changeset(author, params) do
    import Ecto.Changeset
    # TODO: Implement
  end
end

# ==============================================================================
# Exercise Solutions
# ==============================================================================

defmodule ExerciseSolutions do
  @moduledoc false

  import Ecto.Query
  import Ecto.Changeset
  alias MyApp.Schemas.{Author, Post, Comment, Tag, Profile}
  alias MyApp.Repo

  # Solution 1
  def build_comment(post, body) do
    post
    |> Ecto.build_assoc(:comments)
    |> Comment.changeset(%{body: body})
  end

  # Solution 2
  def set_post_tags(post, tag_ids) do
    # Fetch tags
    tags = from(t in Tag, where: t.id in ^tag_ids) |> Repo.all()

    # Preload current tags
    post = Repo.preload(post, :tags)

    # Set new tags
    post
    |> change()
    |> put_assoc(:tags, tags)
  end

  # Solution 3
  def post_changeset_with_comments(post, params) do
    post
    |> cast(params, [:title, :body])
    |> validate_required([:title, :body])
    |> cast_assoc(:comments,
      with: &Comment.changeset/2,
      on_replace: :delete
    )
  end

  # Solution 4
  def get_author_posts_full(author_id) do
    approved_comments = from(c in Comment, where: c.approved == true)

    from(p in Post,
      where: p.author_id == ^author_id,
      order_by: [desc: p.inserted_at],
      preload: [comments: ^approved_comments, tags: []]
    )
    |> Repo.all()
  end

  # Solution 5
  def sync_post_tags_by_name(post, tag_names) do
    # Find or create tags
    tags = Enum.map(tag_names, fn name ->
      case Repo.get_by(Tag, name: name) do
        nil ->
          {:ok, tag} = %Tag{}
          |> Tag.changeset(%{name: name})
          |> Repo.insert()
          tag
        tag ->
          tag
      end
    end)

    # Preload and set tags
    post = Repo.preload(post, :tags)

    post
    |> change()
    |> put_assoc(:tags, tags)
    |> Repo.update()
  end

  # Solution 6
  def author_full_changeset(author, params) do
    author
    |> cast(params, [:name, :email])
    |> validate_required([:name, :email])
    |> cast_assoc(:profile,
      with: &Profile.changeset/2,
      on_replace: :update
    )
    |> cast_assoc(:posts,
      with: &post_with_nested_comments/2,
      on_replace: :delete
    )
  end

  defp post_with_nested_comments(post, attrs) do
    post
    |> Post.changeset(attrs)
    |> cast_assoc(:comments,
      with: &Comment.changeset/2,
      on_replace: :delete
    )
  end
end

# ==============================================================================
# Key Takeaways
# ==============================================================================
#
# 1. build_assoc: Creates a new struct with the foreign key set
#    - Use when creating ONE new child record
#    - Works with has_one, has_many
#
# 2. put_assoc: Puts existing structs into a changeset
#    - MUST preload the association first
#    - Use for replacing entire associations
#    - Great for many_to_many with existing records
#
# 3. cast_assoc: Casts nested params through a changeset
#    - Use for nested form data
#    - Handles create/update/delete through on_replace
#    - Runs validation on nested data
#
# 4. preload: Loads associated data from database
#    - Multiple strategies: Repo.preload, query preload, join preload
#    - Use custom queries for filtering/ordering
#    - Essential for avoiding N+1 queries
#
# 5. Always preload before modifying associations
#
# 6. Choose the right tool for the job:
#    - Single new record -> build_assoc
#    - Replace with existing structs -> put_assoc
#    - Nested form params -> cast_assoc
#
# ==============================================================================
