# ==============================================================================
# Lesson 17: many_to_many Relationships
# ==============================================================================
#
# Many-to-many relationships are common in real-world applications:
# - Posts can have many tags, and tags can be on many posts
# - Students can enroll in many courses, and courses have many students
# - Users can belong to many teams, and teams have many users
#
# In this lesson, you will learn:
# - How many_to_many relationships work in databases
# - Using join tables vs join schemas
# - The many_to_many macro
# - Working with join schemas for additional data
# - Inserting, updating, and querying many_to_many associations
#
# ==============================================================================

# ==============================================================================
# Section 1: Understanding Many-to-Many
# ==============================================================================
#
# In a relational database, many-to-many relationships require a join table
# (also called a junction table or bridge table).
#
# For Posts <-> Tags:
#
#   posts          posts_tags         tags
#   +----+        +---------+--------+        +----+
#   | id |        | post_id | tag_id |        | id |
#   +----+        +---------+--------+        +----+
#
# The join table holds foreign keys to both tables, creating the relationship.

# ==============================================================================
# Section 2: Simple many_to_many with Join Table
# ==============================================================================
#
# For simple relationships where the join table only contains foreign keys,
# use many_to_many with a :join_through table name.

defmodule SimpleExample do
  @moduledoc """
  Simple many_to_many using just a join table (no join schema).
  """

  defmodule Post do
    use Ecto.Schema
    import Ecto.Changeset

    schema "posts" do
      field :title, :string
      field :body, :string

      # many_to_many with a join table
      many_to_many :tags, SimpleExample.Tag, join_through: "posts_tags"

      timestamps()
    end

    def changeset(post, attrs) do
      post
      |> cast(attrs, [:title, :body])
      |> validate_required([:title, :body])
    end
  end

  defmodule Tag do
    use Ecto.Schema
    import Ecto.Changeset

    schema "tags" do
      field :name, :string

      # The inverse relationship
      many_to_many :posts, SimpleExample.Post, join_through: "posts_tags"

      timestamps()
    end

    def changeset(tag, attrs) do
      tag
      |> cast(attrs, [:name])
      |> validate_required([:name])
      |> unique_constraint(:name)
    end
  end

  # Migration for this setup:
  @migration """
  defmodule MyApp.Repo.Migrations.CreatePostsAndTags do
    use Ecto.Migration

    def change do
      create table(:posts) do
        add :title, :string, null: false
        add :body, :text

        timestamps()
      end

      create table(:tags) do
        add :name, :string, null: false

        timestamps()
      end

      create unique_index(:tags, [:name])

      # Join table - no primary key needed for simple join tables
      create table(:posts_tags, primary_key: false) do
        add :post_id, references(:posts, on_delete: :delete_all), null: false
        add :tag_id, references(:tags, on_delete: :delete_all), null: false
      end

      create index(:posts_tags, [:post_id])
      create index(:posts_tags, [:tag_id])
      # Ensure no duplicate post-tag pairs
      create unique_index(:posts_tags, [:post_id, :tag_id])
    end
  end
  """

  def show_migration, do: IO.puts(@migration)
end

# ==============================================================================
# Section 3: many_to_many with Join Schema
# ==============================================================================
#
# When you need additional data on the relationship (e.g., enrollment date,
# role, or status), use a join schema instead of a plain join table.

defmodule JoinSchemaExample do
  @moduledoc """
  many_to_many using a join schema for additional relationship data.
  """

  # Example: Course enrollment system where we track enrollment date and grade

  defmodule Student do
    use Ecto.Schema
    import Ecto.Changeset

    schema "students" do
      field :name, :string
      field :email, :string

      # many_to_many through a join schema
      many_to_many :courses, JoinSchemaExample.Course,
        join_through: JoinSchemaExample.Enrollment

      # If you need to access the join schema directly
      has_many :enrollments, JoinSchemaExample.Enrollment

      timestamps()
    end

    def changeset(student, attrs) do
      student
      |> cast(attrs, [:name, :email])
      |> validate_required([:name, :email])
      |> unique_constraint(:email)
    end
  end

  defmodule Course do
    use Ecto.Schema
    import Ecto.Changeset

    schema "courses" do
      field :name, :string
      field :code, :string
      field :credits, :integer

      many_to_many :students, JoinSchemaExample.Student,
        join_through: JoinSchemaExample.Enrollment

      has_many :enrollments, JoinSchemaExample.Enrollment

      timestamps()
    end

    def changeset(course, attrs) do
      course
      |> cast(attrs, [:name, :code, :credits])
      |> validate_required([:name, :code])
      |> unique_constraint(:code)
    end
  end

  # The join schema with additional fields
  defmodule Enrollment do
    use Ecto.Schema
    import Ecto.Changeset

    schema "enrollments" do
      field :enrolled_at, :utc_datetime
      field :grade, :string
      field :status, :string, default: "active"

      belongs_to :student, JoinSchemaExample.Student
      belongs_to :course, JoinSchemaExample.Course

      timestamps()
    end

    def changeset(enrollment, attrs) do
      enrollment
      |> cast(attrs, [:enrolled_at, :grade, :status, :student_id, :course_id])
      |> validate_required([:student_id, :course_id])
      |> validate_inclusion(:status, ["active", "completed", "dropped", "failed"])
      |> foreign_key_constraint(:student_id)
      |> foreign_key_constraint(:course_id)
      |> unique_constraint([:student_id, :course_id], name: :enrollments_student_course_index)
    end
  end

  # Migration for join schema:
  @migration """
  defmodule MyApp.Repo.Migrations.CreateEnrollments do
    use Ecto.Migration

    def change do
      create table(:students) do
        add :name, :string, null: false
        add :email, :string, null: false

        timestamps()
      end

      create unique_index(:students, [:email])

      create table(:courses) do
        add :name, :string, null: false
        add :code, :string, null: false
        add :credits, :integer

        timestamps()
      end

      create unique_index(:courses, [:code])

      # Join table WITH its own id and additional fields
      create table(:enrollments) do
        add :student_id, references(:students, on_delete: :delete_all), null: false
        add :course_id, references(:courses, on_delete: :delete_all), null: false
        add :enrolled_at, :utc_datetime
        add :grade, :string
        add :status, :string, default: "active"

        timestamps()
      end

      create index(:enrollments, [:student_id])
      create index(:enrollments, [:course_id])
      create unique_index(:enrollments, [:student_id, :course_id],
        name: :enrollments_student_course_index)
    end
  end
  """

  def show_migration, do: IO.puts(@migration)
end

# ==============================================================================
# Section 4: many_to_many Options
# ==============================================================================

defmodule ManyToManyOptions do
  @moduledoc """
  Available options for many_to_many associations.
  """

  # many_to_many options:
  #
  # :join_through (required) - Either:
  #   - A string for a plain join table: "posts_tags"
  #   - A module for a join schema: MyApp.PostTag
  #
  # :join_keys - Customize the foreign key names in join table
  #   Default: [{:current_schema_id, :id}, {:other_schema_id, :id}]
  #
  # :on_replace - What to do when association is replaced
  #   - :raise (default) - Raise error
  #   - :mark_as_invalid - Add error to changeset
  #   - :delete - Delete the join table entries
  #
  # :on_delete - Action when parent is deleted (for join table entries)
  #   - :nothing (default)
  #   - :delete_all
  #
  # :where - Filter the association
  #
  # :unique - Whether entries should be unique (used with put_assoc)

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field :name, :string

      # Custom join keys example
      many_to_many :teams, Team,
        join_through: "team_memberships",
        join_keys: [member_id: :id, team_id: :id],
        on_replace: :delete

      # With on_delete
      many_to_many :projects, Project,
        join_through: "project_members",
        on_delete: :delete_all

      # With where clause - only active memberships
      many_to_many :active_teams, Team,
        join_through: TeamMembership,
        where: [active: true]
    end
  end

  defmodule Team do
    use Ecto.Schema
    schema "teams" do
      field :name, :string
    end
  end

  defmodule Project do
    use Ecto.Schema
    schema "projects" do
      field :name, :string
    end
  end

  defmodule TeamMembership do
    use Ecto.Schema
    schema "team_memberships" do
      field :active, :boolean
      belongs_to :user, User, foreign_key: :member_id
      belongs_to :team, Team
    end
  end
end

# ==============================================================================
# Section 5: Working with many_to_many Associations
# ==============================================================================

defmodule ManyToManyOperations do
  @moduledoc """
  Common operations with many_to_many associations.
  """

  import Ecto.Query
  alias JoinSchemaExample.{Student, Course, Enrollment, Repo}

  # ---------------------------------------------------------------------------
  # Creating associations
  # ---------------------------------------------------------------------------

  # Method 1: Using the join schema directly
  def enroll_student(student, course) do
    %Enrollment{}
    |> Enrollment.changeset(%{
      student_id: student.id,
      course_id: course.id,
      enrolled_at: DateTime.utc_now()
    })
    |> Repo.insert()
  end

  # Method 2: Using put_assoc (for simple join tables)
  def add_tags_to_post(post, tags) do
    post
    |> Repo.preload(:tags)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> Repo.update()
  end

  # Method 3: Using build_assoc through the join schema
  def build_enrollment(student, course_id) do
    student
    |> Ecto.build_assoc(:enrollments, %{course_id: course_id})
    |> Enrollment.changeset(%{enrolled_at: DateTime.utc_now()})
    |> Repo.insert()
  end

  # ---------------------------------------------------------------------------
  # Querying many_to_many
  # ---------------------------------------------------------------------------

  # Get student with their courses preloaded
  def get_student_with_courses(student_id) do
    Student
    |> preload(:courses)
    |> Repo.get(student_id)
  end

  # Get courses with enrollment details
  def get_student_enrollments(student_id) do
    from e in Enrollment,
      where: e.student_id == ^student_id,
      preload: [:course],
      order_by: [desc: e.enrolled_at]
    |> Repo.all()
  end

  # Find all students enrolled in a specific course
  def get_students_in_course(course_id) do
    from s in Student,
      join: e in Enrollment,
      on: e.student_id == s.id,
      where: e.course_id == ^course_id,
      where: e.status == "active",
      select: s
    |> Repo.all()
  end

  # Get courses with their student counts
  def courses_with_student_counts do
    from c in Course,
      left_join: e in Enrollment,
      on: e.course_id == c.id and e.status == "active",
      group_by: c.id,
      select: {c, count(e.id)}
    |> Repo.all()
  end

  # ---------------------------------------------------------------------------
  # Updating many_to_many
  # ---------------------------------------------------------------------------

  # Update enrollment (e.g., add grade)
  def update_enrollment(student_id, course_id, attrs) do
    from(e in Enrollment,
      where: e.student_id == ^student_id and e.course_id == ^course_id
    )
    |> Repo.one()
    |> Enrollment.changeset(attrs)
    |> Repo.update()
  end

  # Replace all tags on a post
  def replace_tags(post, new_tag_ids) do
    tags = from(t in SimpleExample.Tag, where: t.id in ^new_tag_ids) |> Repo.all()

    post
    |> Repo.preload(:tags)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> Repo.update()
  end

  # ---------------------------------------------------------------------------
  # Removing associations
  # ---------------------------------------------------------------------------

  # Remove a specific enrollment
  def drop_course(student_id, course_id) do
    from(e in Enrollment,
      where: e.student_id == ^student_id and e.course_id == ^course_id
    )
    |> Repo.delete_all()
  end

  # Or update status instead of deleting
  def drop_course_soft(student_id, course_id) do
    from(e in Enrollment,
      where: e.student_id == ^student_id and e.course_id == ^course_id
    )
    |> Repo.update_all(set: [status: "dropped"])
  end

  # Remove a tag from a post (for simple join tables)
  def remove_tag_from_post(post, tag) do
    current_tags = Repo.preload(post, :tags).tags
    new_tags = Enum.reject(current_tags, &(&1.id == tag.id))

    post
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:tags, new_tags)
    |> Repo.update()
  end
end

# ==============================================================================
# Section 6: Common Patterns
# ==============================================================================

defmodule ManyToManyPatterns do
  @moduledoc """
  Common patterns when working with many_to_many relationships.
  """

  import Ecto.Query

  # Pattern 1: Find or create tag, then associate
  def add_tag_by_name(post, tag_name) do
    # Find existing tag or create new one
    tag = case Repo.get_by(SimpleExample.Tag, name: tag_name) do
      nil ->
        {:ok, tag} = %SimpleExample.Tag{}
        |> SimpleExample.Tag.changeset(%{name: tag_name})
        |> Repo.insert()
        tag
      existing ->
        existing
    end

    # Add to post
    post = Repo.preload(post, :tags)
    unless Enum.any?(post.tags, &(&1.id == tag.id)) do
      post
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:tags, [tag | post.tags])
      |> Repo.update()
    else
      {:ok, post}
    end
  end

  # Pattern 2: Sync tags (add new, remove old)
  def sync_tags(post, tag_names) do
    # Get or create all tags
    tags = Enum.map(tag_names, fn name ->
      case Repo.get_by(SimpleExample.Tag, name: name) do
        nil ->
          {:ok, tag} = %SimpleExample.Tag{}
          |> SimpleExample.Tag.changeset(%{name: name})
          |> Repo.insert()
          tag
        existing ->
          existing
      end
    end)

    # Replace all tags
    post
    |> Repo.preload(:tags)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> Repo.update()
  end

  # Pattern 3: Check if association exists
  def enrolled?(student_id, course_id) do
    from(e in JoinSchemaExample.Enrollment,
      where: e.student_id == ^student_id and e.course_id == ^course_id
    )
    |> Repo.exists?()
  end

  # Pattern 4: Toggle association
  def toggle_tag(post, tag) do
    post = Repo.preload(post, :tags)

    new_tags = if Enum.any?(post.tags, &(&1.id == tag.id)) do
      Enum.reject(post.tags, &(&1.id == tag.id))
    else
      [tag | post.tags]
    end

    post
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:tags, new_tags)
    |> Repo.update()
  end

  # Pattern 5: Eager loading with join schema data
  def get_student_with_enrollment_details(student_id) do
    enrollment_query =
      from e in JoinSchemaExample.Enrollment,
        preload: [:course]

    from(s in JoinSchemaExample.Student,
      where: s.id == ^student_id,
      preload: [enrollments: ^enrollment_query]
    )
    |> Repo.one()
  end
end

# ==============================================================================
# Section 7: Comparison - Join Table vs Join Schema
# ==============================================================================

comparison = """
+----------------------+----------------------------------+----------------------------------+
| Aspect               | Join Table                       | Join Schema                      |
+----------------------+----------------------------------+----------------------------------+
| Definition           | join_through: "table_name"       | join_through: Module             |
+----------------------+----------------------------------+----------------------------------+
| Use case             | Simple associations              | Need extra fields on relation    |
+----------------------+----------------------------------+----------------------------------+
| Additional data      | No                               | Yes (dates, status, etc.)        |
+----------------------+----------------------------------+----------------------------------+
| Direct querying      | Limited                          | Full Ecto queries                |
+----------------------+----------------------------------+----------------------------------+
| Validation           | None on join                     | Changeset validations            |
+----------------------+----------------------------------+----------------------------------+
| Primary key          | Usually none needed              | Has its own id                   |
+----------------------+----------------------------------+----------------------------------+
| Timestamps           | Optional                         | Recommended                      |
+----------------------+----------------------------------+----------------------------------+
| Migration            | Simple                           | Standard schema migration        |
+----------------------+----------------------------------+----------------------------------+

Recommendation:
- Use join table for simple tagging, categorization
- Use join schema when you need any metadata about the relationship
"""

IO.puts(comparison)

# ==============================================================================
# Exercises
# ==============================================================================

defmodule Exercises do
  @moduledoc """
  Exercises to practice many_to_many associations.
  """

  # Exercise 1: Simple many_to_many
  #
  # Create schemas for Book and Author where:
  # - A book can have multiple authors
  # - An author can write multiple books
  # - Use a simple join table "books_authors"
  #
  # Your solution:
  defmodule Book do
    use Ecto.Schema
    # TODO: Define schema with many_to_many :authors
  end

  defmodule Author do
    use Ecto.Schema
    # TODO: Define schema with many_to_many :books
  end

  # Exercise 2: many_to_many with join schema
  #
  # Create schemas for User, Role, and UserRole where:
  # - Users can have multiple roles
  # - The UserRole join schema tracks:
  #   - assigned_at (when the role was assigned)
  #   - assigned_by (who assigned it - another user's id)
  #   - expires_at (optional expiration date)
  #
  # Your solution:
  defmodule User do
    use Ecto.Schema
    # TODO: Define schema
  end

  defmodule Role do
    use Ecto.Schema
    # TODO: Define schema
  end

  defmodule UserRole do
    use Ecto.Schema
    # TODO: Define join schema
  end

  # Exercise 3: Write a query function
  #
  # Write a function that finds all books that have at least 2 authors.
  # Return the books with their authors preloaded.
  #
  # Your solution:
  def books_with_multiple_authors do
    import Ecto.Query
    # TODO: Implement query
  end

  # Exercise 4: Implement sync function
  #
  # Write a function that synchronizes a user's roles.
  # Given a user and a list of role names:
  # - Add any roles not currently assigned
  # - Remove any roles not in the list
  # - Don't modify roles that are already correct
  # Use the UserRole join schema from Exercise 2.
  #
  # Your solution:
  def sync_user_roles(user, role_names, assigned_by_id) do
    # TODO: Implement role synchronization
  end

  # Exercise 5: Complex query
  #
  # Using the Student/Course/Enrollment example from this lesson:
  # Write a function that returns the top N courses by:
  # - Number of active enrollments
  # - Include only courses with at least 10 students
  # - Return {course, count} tuples
  #
  # Your solution:
  def top_courses_by_enrollment(limit) do
    import Ecto.Query
    # TODO: Implement query
  end

  # Exercise 6: Check and create association
  #
  # Write a function that:
  # - Checks if a student is already enrolled in a course
  # - If not, creates the enrollment
  # - If yes, returns {:error, :already_enrolled}
  # - Returns {:ok, enrollment} on success
  #
  # Your solution:
  def ensure_enrollment(student_id, course_id) do
    # TODO: Implement
  end
end

# ==============================================================================
# Exercise Solutions
# ==============================================================================

defmodule ExerciseSolutions do
  @moduledoc false

  # Solution 1: Book and Author
  defmodule Book do
    use Ecto.Schema
    import Ecto.Changeset

    schema "books" do
      field :title, :string
      field :isbn, :string

      many_to_many :authors, ExerciseSolutions.Author, join_through: "books_authors"

      timestamps()
    end

    def changeset(book, attrs) do
      book
      |> cast(attrs, [:title, :isbn])
      |> validate_required([:title])
    end
  end

  defmodule Author do
    use Ecto.Schema
    import Ecto.Changeset

    schema "authors" do
      field :name, :string

      many_to_many :books, ExerciseSolutions.Book, join_through: "books_authors"

      timestamps()
    end

    def changeset(author, attrs) do
      author
      |> cast(attrs, [:name])
      |> validate_required([:name])
    end
  end

  # Solution 2: User, Role, UserRole
  defmodule User do
    use Ecto.Schema

    schema "users" do
      field :name, :string

      many_to_many :roles, ExerciseSolutions.Role,
        join_through: ExerciseSolutions.UserRole

      has_many :user_roles, ExerciseSolutions.UserRole

      timestamps()
    end
  end

  defmodule Role do
    use Ecto.Schema

    schema "roles" do
      field :name, :string
      field :description, :string

      many_to_many :users, ExerciseSolutions.User,
        join_through: ExerciseSolutions.UserRole

      timestamps()
    end
  end

  defmodule UserRole do
    use Ecto.Schema
    import Ecto.Changeset

    schema "user_roles" do
      belongs_to :user, ExerciseSolutions.User
      belongs_to :role, ExerciseSolutions.Role
      belongs_to :assigned_by_user, ExerciseSolutions.User, foreign_key: :assigned_by

      field :assigned_at, :utc_datetime
      field :expires_at, :utc_datetime

      timestamps()
    end

    def changeset(user_role, attrs) do
      user_role
      |> cast(attrs, [:user_id, :role_id, :assigned_by, :assigned_at, :expires_at])
      |> validate_required([:user_id, :role_id, :assigned_at])
      |> foreign_key_constraint(:user_id)
      |> foreign_key_constraint(:role_id)
      |> unique_constraint([:user_id, :role_id])
    end
  end

  # Solution 3: Books with multiple authors
  def books_with_multiple_authors do
    import Ecto.Query

    from b in Book,
      join: a in assoc(b, :authors),
      group_by: b.id,
      having: count(a.id) >= 2,
      preload: [:authors]
    # |> Repo.all()
  end

  # Solution 4: Sync user roles
  def sync_user_roles(user, role_names, assigned_by_id) do
    import Ecto.Query

    # Get current role ids
    current_roles = Repo.preload(user, :roles).roles
    current_role_names = MapSet.new(current_roles, & &1.name)
    desired_role_names = MapSet.new(role_names)

    # Roles to add
    to_add = MapSet.difference(desired_role_names, current_role_names)
    # Roles to remove
    to_remove = MapSet.difference(current_role_names, desired_role_names)

    # Remove unwanted roles
    unless MapSet.size(to_remove) == 0 do
      role_ids_to_remove =
        from(r in Role, where: r.name in ^MapSet.to_list(to_remove), select: r.id)
        |> Repo.all()

      from(ur in UserRole,
        where: ur.user_id == ^user.id and ur.role_id in ^role_ids_to_remove
      )
      |> Repo.delete_all()
    end

    # Add new roles
    for role_name <- to_add do
      role = Repo.get_by!(Role, name: role_name)

      %UserRole{}
      |> UserRole.changeset(%{
        user_id: user.id,
        role_id: role.id,
        assigned_by: assigned_by_id,
        assigned_at: DateTime.utc_now()
      })
      |> Repo.insert!()
    end

    {:ok, Repo.preload(user, :roles, force: true)}
  end

  # Solution 5: Top courses by enrollment
  def top_courses_by_enrollment(limit) do
    import Ecto.Query
    alias JoinSchemaExample.{Course, Enrollment}

    from c in Course,
      join: e in Enrollment,
      on: e.course_id == c.id and e.status == "active",
      group_by: c.id,
      having: count(e.id) >= 10,
      order_by: [desc: count(e.id)],
      limit: ^limit,
      select: {c, count(e.id)}
    # |> Repo.all()
  end

  # Solution 6: Ensure enrollment
  def ensure_enrollment(student_id, course_id) do
    import Ecto.Query
    alias JoinSchemaExample.Enrollment

    case Repo.get_by(Enrollment, student_id: student_id, course_id: course_id) do
      nil ->
        %Enrollment{}
        |> Enrollment.changeset(%{
          student_id: student_id,
          course_id: course_id,
          enrolled_at: DateTime.utc_now(),
          status: "active"
        })
        |> Repo.insert()

      _existing ->
        {:error, :already_enrolled}
    end
  end
end

# ==============================================================================
# Key Takeaways
# ==============================================================================
#
# 1. many_to_many requires a join table in the database
#
# 2. Use join_through: "table_name" for simple relationships
#
# 3. Use join_through: Module for relationships needing extra data
#
# 4. Join schemas give you:
#    - Additional fields on the relationship
#    - Changeset validations
#    - Direct queryability
#    - Timestamps on the relationship
#
# 5. Remember to preload associations before modifying them with put_assoc
#
# 6. Use put_assoc to replace entire association, direct inserts for adding
#
# 7. The on_replace: :delete option is useful for replacing associations
#
# ==============================================================================
