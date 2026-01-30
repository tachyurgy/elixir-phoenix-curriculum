# ==============================================================================
# ECTO SCHEMAS - MAPPING DATABASE TABLES TO ELIXIR STRUCTS
# ==============================================================================
#
# Ecto Schemas define how Elixir structs map to database tables. They specify:
# - The table name
# - Field names and their types
# - Primary keys
# - Timestamps
# - Relationships with other schemas
#
# Schemas provide type casting and struct generation, making it easy to work
# with database records in a type-safe way.
#
# ==============================================================================
# TABLE OF CONTENTS
# ==============================================================================
#
# 1. Basic Schema Definition
# 2. Field Types
# 3. Primary Keys
# 4. Timestamps
# 5. Schema Options
# 6. Virtual Fields
# 7. Source and Table Names
# 8. Schema Metadata
# 9. Exercises
#
# ==============================================================================

# ==============================================================================
# SECTION 1: BASIC SCHEMA DEFINITION
# ==============================================================================

defmodule BasicSchema do
  @moduledoc """
  The fundamental structure of an Ecto Schema.
  """

  # A minimal schema definition
  defmodule User do
    use Ecto.Schema

    # The schema macro defines the table mapping
    schema "users" do
      field :name, :string
      field :email, :string
      field :age, :integer
    end
  end

  # The schema above creates:
  # 1. A struct: %User{id: nil, name: nil, email: nil, age: nil}
  # 2. Type information for each field
  # 3. Mapping to the "users" database table

  def demonstrate_struct do
    # Create a new user struct
    user = %User{}
    IO.inspect(user)
    # => %User{id: nil, name: nil, email: nil, age: nil}

    # Populate fields
    user = %User{name: "Alice", email: "alice@example.com", age: 30}
    IO.inspect(user)
    # => %User{id: nil, name: "Alice", email: "alice@example.com", age: 30}

    # Access fields
    IO.puts("Name: #{user.name}")
    IO.puts("Email: #{user.email}")

    user
  end
end

# ==============================================================================
# SECTION 2: FIELD TYPES
# ==============================================================================

defmodule FieldTypes do
  @moduledoc """
  Ecto supports many field types for different data needs.
  """

  use Ecto.Schema

  # ---------------------------------------------------------------------------
  # Primitive Types
  # ---------------------------------------------------------------------------

  defmodule PrimitiveExample do
    use Ecto.Schema

    schema "examples" do
      # String types
      field :name, :string              # VARCHAR/TEXT
      field :bio, :string               # TEXT (handled the same)

      # Numeric types
      field :age, :integer              # INTEGER
      field :price, :float              # FLOAT/DOUBLE
      field :balance, :decimal          # DECIMAL (use for money!)

      # Boolean
      field :active, :boolean           # BOOLEAN

      # Binary
      field :avatar, :binary            # BLOB/BYTEA

      # UUID
      field :uuid, :binary_id           # UUID as binary
      field :public_id, Ecto.UUID       # UUID as string
    end
  end

  # ---------------------------------------------------------------------------
  # Date and Time Types
  # ---------------------------------------------------------------------------

  defmodule DateTimeExample do
    use Ecto.Schema

    schema "events" do
      # Date only (no time)
      field :birth_date, :date          # DATE

      # Time only (no date)
      field :start_time, :time          # TIME

      # Date and time without timezone
      field :scheduled_at, :naive_datetime          # TIMESTAMP without TZ
      field :scheduled_at_usec, :naive_datetime_usec # With microseconds

      # Date and time with timezone (preferred)
      field :published_at, :utc_datetime            # TIMESTAMP with TZ
      field :published_at_usec, :utc_datetime_usec  # With microseconds
    end
  end

  # ---------------------------------------------------------------------------
  # Collection Types
  # ---------------------------------------------------------------------------

  defmodule CollectionExample do
    use Ecto.Schema

    schema "posts" do
      # Array of strings (PostgreSQL array)
      field :tags, {:array, :string}

      # Array of integers
      field :scores, {:array, :integer}

      # Map (JSON/JSONB column)
      field :metadata, :map

      # Map with string keys
      field :settings, {:map, :string}
    end
  end

  # ---------------------------------------------------------------------------
  # Type Demonstration
  # ---------------------------------------------------------------------------

  def type_examples do
    """
    ECTO TYPE          | ELIXIR TYPE           | DATABASE TYPE
    -------------------|----------------------|---------------
    :string            | String.t()           | VARCHAR/TEXT
    :integer           | integer()            | INTEGER
    :float             | float()              | FLOAT/DOUBLE
    :decimal           | Decimal.t()          | DECIMAL/NUMERIC
    :boolean           | boolean()            | BOOLEAN
    :binary            | binary()             | BLOB/BYTEA
    :binary_id         | binary()             | UUID (as binary)
    Ecto.UUID          | String.t()           | UUID (as string)
    :date              | Date.t()             | DATE
    :time              | Time.t()             | TIME
    :naive_datetime    | NaiveDateTime.t()    | TIMESTAMP
    :utc_datetime      | DateTime.t()         | TIMESTAMPTZ
    {:array, :string}  | [String.t()]         | TEXT[] (array)
    :map               | map()                | JSON/JSONB
    """
  end
end

# ==============================================================================
# SECTION 3: PRIMARY KEYS
# ==============================================================================

defmodule PrimaryKeys do
  @moduledoc """
  Configuring primary keys in schemas.
  """

  # ---------------------------------------------------------------------------
  # Default: Auto-incrementing Integer ID
  # ---------------------------------------------------------------------------

  defmodule DefaultPK do
    use Ecto.Schema

    # By default, Ecto assumes an auto-incrementing :id field
    schema "users" do
      field :name, :string
      # Implicitly has: field :id, :id (auto-generated integer)
    end
  end

  # ---------------------------------------------------------------------------
  # UUID Primary Key
  # ---------------------------------------------------------------------------

  defmodule UuidPK do
    use Ecto.Schema

    # Configure the primary key before the schema block
    @primary_key {:id, :binary_id, autogenerate: true}

    schema "users" do
      field :name, :string
    end
  end

  # ---------------------------------------------------------------------------
  # UUID as String
  # ---------------------------------------------------------------------------

  defmodule UuidStringPK do
    use Ecto.Schema

    @primary_key {:id, Ecto.UUID, autogenerate: true}

    schema "users" do
      field :name, :string
    end
  end

  # ---------------------------------------------------------------------------
  # Custom Primary Key Name
  # ---------------------------------------------------------------------------

  defmodule CustomPKName do
    use Ecto.Schema

    @primary_key {:user_id, :id, autogenerate: true}

    schema "users" do
      field :name, :string
      # Primary key is :user_id, not :id
    end
  end

  # ---------------------------------------------------------------------------
  # Composite Primary Key
  # ---------------------------------------------------------------------------

  defmodule CompositePK do
    use Ecto.Schema

    # Disable auto-generated primary key
    @primary_key false

    schema "user_roles" do
      field :user_id, :integer, primary_key: true
      field :role_id, :integer, primary_key: true
      field :assigned_at, :utc_datetime
    end
  end

  # ---------------------------------------------------------------------------
  # No Primary Key
  # ---------------------------------------------------------------------------

  defmodule NoPK do
    use Ecto.Schema

    @primary_key false

    schema "logs" do
      field :message, :string
      field :level, :string
      field :timestamp, :utc_datetime
    end
  end

  # ---------------------------------------------------------------------------
  # Global Primary Key Configuration
  # ---------------------------------------------------------------------------

  # You can set defaults for all schemas in a module:
  defmodule MyApp.Schema do
    defmacro __using__(_opts) do
      quote do
        use Ecto.Schema

        # All schemas using MyApp.Schema will have UUID primary keys
        @primary_key {:id, :binary_id, autogenerate: true}
        @foreign_key_type :binary_id
      end
    end
  end

  # Then use it:
  defmodule UserWithUuid do
    use MyApp.Schema  # Instead of use Ecto.Schema

    schema "users" do
      field :name, :string
    end
  end
end

# ==============================================================================
# SECTION 4: TIMESTAMPS
# ==============================================================================

defmodule Timestamps do
  @moduledoc """
  Automatic timestamp fields for tracking record creation and updates.
  """

  # ---------------------------------------------------------------------------
  # Default Timestamps
  # ---------------------------------------------------------------------------

  defmodule DefaultTimestamps do
    use Ecto.Schema

    schema "posts" do
      field :title, :string
      field :body, :string

      # Adds :inserted_at and :updated_at fields
      timestamps()
    end
  end

  # ---------------------------------------------------------------------------
  # Custom Timestamp Names
  # ---------------------------------------------------------------------------

  defmodule CustomTimestampNames do
    use Ecto.Schema

    schema "posts" do
      field :title, :string

      # Use created_at instead of inserted_at
      timestamps(inserted_at: :created_at, updated_at: :modified_at)
    end
  end

  # ---------------------------------------------------------------------------
  # Timestamp Types
  # ---------------------------------------------------------------------------

  defmodule TimestampTypes do
    use Ecto.Schema

    schema "posts" do
      field :title, :string

      # Use DateTime with microseconds instead of NaiveDateTime
      timestamps(type: :utc_datetime_usec)
    end
  end

  # ---------------------------------------------------------------------------
  # Disable One Timestamp
  # ---------------------------------------------------------------------------

  defmodule SingleTimestamp do
    use Ecto.Schema

    schema "events" do
      field :name, :string

      # Only track creation, not updates
      timestamps(updated_at: false)
    end
  end

  # ---------------------------------------------------------------------------
  # No Timestamps
  # ---------------------------------------------------------------------------

  defmodule NoTimestamps do
    use Ecto.Schema

    schema "logs" do
      field :message, :string
      # No timestamps() call - no automatic timestamp fields
    end
  end

  # ---------------------------------------------------------------------------
  # Global Timestamp Configuration
  # ---------------------------------------------------------------------------

  defmodule MyApp.SchemaWithTimestamps do
    defmacro __using__(_opts) do
      quote do
        use Ecto.Schema

        @primary_key {:id, :binary_id, autogenerate: true}
        @foreign_key_type :binary_id
        @timestamps_opts [type: :utc_datetime_usec]
      end
    end
  end
end

# ==============================================================================
# SECTION 5: SCHEMA OPTIONS
# ==============================================================================

defmodule SchemaOptions do
  @moduledoc """
  Additional configuration options for schemas.
  """

  # ---------------------------------------------------------------------------
  # Field Options
  # ---------------------------------------------------------------------------

  defmodule FieldOptions do
    use Ecto.Schema

    schema "products" do
      # Default value
      field :status, :string, default: "draft"
      field :quantity, :integer, default: 0

      # Read after writes (for database-generated values)
      field :slug, :string, read_after_writes: true

      # Autogenerate (for fields set on insert)
      field :token, :string, autogenerate: {__MODULE__, :generate_token, []}

      # Source (different database column name)
      field :email_address, :string, source: :email

      # Load in query (default: true)
      # Set to false for large fields you don't always need
      field :content, :string, load_in_query: false

      # Redact (hide in inspect output)
      field :password_hash, :string, redact: true

      timestamps()
    end

    def generate_token do
      :crypto.strong_rand_bytes(32) |> Base.url_encode64()
    end
  end

  # ---------------------------------------------------------------------------
  # Demonstrating Field Options
  # ---------------------------------------------------------------------------

  def demonstrate_options do
    # Default values are applied when creating structs
    product = %FieldOptions{name: "Widget"}
    IO.inspect(product.status)    # => "draft"
    IO.inspect(product.quantity)  # => 0

    # Source maps field names to different column names
    # Useful for legacy databases or naming conventions
    # field :email_address maps to "email" column in database
  end

  # ---------------------------------------------------------------------------
  # Redacted Fields in Inspect
  # ---------------------------------------------------------------------------

  defmodule SecureUser do
    use Ecto.Schema

    schema "users" do
      field :email, :string
      field :password_hash, :string, redact: true
      field :ssn, :string, redact: true
    end
  end

  def demonstrate_redaction do
    user = %SecureUser{
      email: "test@example.com",
      password_hash: "hashed_password",
      ssn: "123-45-6789"
    }

    # When inspected, redacted fields show **redacted**
    IO.inspect(user)
    # => %SecureUser{
    #      email: "test@example.com",
    #      password_hash: **redacted**,
    #      ssn: **redacted**
    #    }
  end
end

# ==============================================================================
# SECTION 6: VIRTUAL FIELDS
# ==============================================================================

defmodule VirtualFields do
  @moduledoc """
  Virtual fields exist only in the struct, not in the database.
  Useful for temporary data, computed values, or form inputs.
  """

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field :name, :string
      field :email, :string
      field :password_hash, :string

      # Virtual fields - not persisted to database
      field :password, :string, virtual: true
      field :password_confirmation, :string, virtual: true
      field :full_name, :string, virtual: true

      timestamps()
    end
  end

  # ---------------------------------------------------------------------------
  # Use Cases for Virtual Fields
  # ---------------------------------------------------------------------------

  def virtual_field_examples do
    """
    COMMON VIRTUAL FIELD USE CASES:
    ================================

    1. PASSWORD HANDLING
       - Accept :password from forms
       - Hash it and store in :password_hash
       - Never persist plain password

    2. FORM CONFIRMATIONS
       - :password_confirmation
       - :email_confirmation
       - Validate they match, but don't store

    3. COMPUTED VALUES
       - :full_name (from first_name + last_name)
       - :age (computed from birth_date)
       - Calculated in application, not stored

    4. TEMPORARY DATA
       - :terms_accepted (for registration)
       - :newsletter_opt_in (for forms)
       - Process but don't persist

    5. AGGREGATED DATA
       - :posts_count (loaded via query)
       - :total_orders (computed in query)
    """
  end

  # Example: Password handling with virtual field
  defmodule SecureUser do
    use Ecto.Schema
    import Ecto.Changeset

    schema "users" do
      field :email, :string
      field :password_hash, :string, redact: true

      # Virtual fields for password handling
      field :password, :string, virtual: true, redact: true
      field :password_confirmation, :string, virtual: true, redact: true

      timestamps()
    end

    def registration_changeset(user, attrs) do
      user
      |> cast(attrs, [:email, :password, :password_confirmation])
      |> validate_required([:email, :password, :password_confirmation])
      |> validate_confirmation(:password)
      |> hash_password()
    end

    defp hash_password(changeset) do
      case get_change(changeset, :password) do
        nil ->
          changeset
        password ->
          # In real code, use Argon2 or Bcrypt
          hashed = Base.encode64(password)
          put_change(changeset, :password_hash, hashed)
      end
    end
  end
end

# ==============================================================================
# SECTION 7: SOURCE AND TABLE NAMES
# ==============================================================================

defmodule SourceAndTableNames do
  @moduledoc """
  Customizing the database table name for a schema.
  """

  # ---------------------------------------------------------------------------
  # Default Table Name
  # ---------------------------------------------------------------------------

  defmodule User do
    use Ecto.Schema

    # Table name matches the string in schema/2
    schema "users" do
      field :name, :string
    end
  end

  # ---------------------------------------------------------------------------
  # Schema with Different Module and Table Names
  # ---------------------------------------------------------------------------

  defmodule Admin.User do
    use Ecto.Schema

    # Module is Admin.User, but table is still "users"
    schema "users" do
      field :name, :string
      field :role, :string
    end
  end

  # ---------------------------------------------------------------------------
  # Prefixed Table (Multi-tenancy)
  # ---------------------------------------------------------------------------

  defmodule Tenant.User do
    use Ecto.Schema

    # Use a prefix for multi-tenant schemas
    @schema_prefix "tenant_"

    schema "users" do
      field :name, :string
    end
    # Actual table: tenant_users
  end

  # ---------------------------------------------------------------------------
  # Getting Schema Information
  # ---------------------------------------------------------------------------

  def schema_information do
    # Get the table name
    User.__schema__(:source)  # => "users"

    # Get all field names
    User.__schema__(:fields)  # => [:id, :name]

    # Get the type of a field
    User.__schema__(:type, :name)  # => :string

    # Get primary key fields
    User.__schema__(:primary_key)  # => [:id]

    # Get all associations (covered later)
    User.__schema__(:associations)  # => []
  end
end

# ==============================================================================
# SECTION 8: SCHEMA METADATA
# ==============================================================================

defmodule SchemaMetadata do
  @moduledoc """
  Ecto structs contain metadata about their state.
  """

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field :name, :string
      field :email, :string
      timestamps()
    end
  end

  def demonstrate_metadata do
    # New struct (not loaded from database)
    user = %User{name: "Alice", email: "alice@example.com"}

    # Check metadata
    IO.inspect(user.__meta__)
    # => %Ecto.Schema.Metadata{
    #      state: :built,
    #      source: "users",
    #      prefix: nil,
    #      ...
    #    }

    # Metadata states:
    # - :built    - Created in memory, not yet persisted
    # - :loaded   - Loaded from database
    # - :deleted  - Deleted from database
  end

  def metadata_states do
    """
    SCHEMA METADATA STATES:
    =======================

    :built
    ------
    Created with %User{} or struct(), not loaded from DB.
    Example: %User{name: "Alice"}

    :loaded
    -------
    Fetched from database via Repo.get/all/etc.
    Example: Repo.get!(User, 1)

    :deleted
    --------
    Was loaded, then deleted via Repo.delete.
    Example: Repo.delete!(user)

    Checking state:
    ---------------
    user.__meta__.state
    Ecto.get_meta(user, :state)
    """
  end
end

# ==============================================================================
# SECTION 9: COMPLETE SCHEMA EXAMPLE
# ==============================================================================

defmodule CompleteSchemaExample do
  @moduledoc """
  A complete, production-ready schema example.
  """

  defmodule MyApp.Accounts.User do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id

    schema "users" do
      # Basic fields
      field :email, :string
      field :name, :string
      field :username, :string

      # Sensitive field (redacted in logs)
      field :password_hash, :string, redact: true

      # Virtual fields
      field :password, :string, virtual: true, redact: true
      field :password_confirmation, :string, virtual: true, redact: true

      # Status and settings
      field :status, Ecto.Enum, values: [:pending, :active, :suspended], default: :pending
      field :role, Ecto.Enum, values: [:user, :admin, :moderator], default: :user
      field :settings, :map, default: %{}

      # Dates
      field :confirmed_at, :utc_datetime
      field :last_login_at, :utc_datetime

      # Automatic timestamps
      timestamps(type: :utc_datetime_usec)
    end

    @doc """
    Changeset for user registration.
    """
    def registration_changeset(user, attrs) do
      user
      |> cast(attrs, [:email, :name, :username, :password, :password_confirmation])
      |> validate_required([:email, :name, :username, :password])
      |> validate_email()
      |> validate_password()
      |> hash_password()
    end

    @doc """
    Changeset for profile updates.
    """
    def profile_changeset(user, attrs) do
      user
      |> cast(attrs, [:name, :username, :settings])
      |> validate_required([:name])
      |> validate_length(:name, min: 2, max: 100)
      |> validate_length(:username, min: 3, max: 30)
    end

    defp validate_email(changeset) do
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
      |> validate_length(:email, max: 160)
      |> unsafe_validate_unique(:email, MyApp.Repo)
      |> unique_constraint(:email)
    end

    defp validate_password(changeset) do
      changeset
      |> validate_length(:password, min: 8, max: 72)
      |> validate_confirmation(:password, message: "passwords do not match")
    end

    defp hash_password(changeset) do
      case get_change(changeset, :password) do
        nil -> changeset
        password ->
          # Use Argon2 in production: Argon2.hash_pwd_salt(password)
          put_change(changeset, :password_hash, Base.encode64(password))
      end
    end
  end
end

# ==============================================================================
# EXERCISES
# ==============================================================================

defmodule Exercises do
  @moduledoc """
  Practice exercises for Ecto Schemas.
  """

  # ---------------------------------------------------------------------------
  # Exercise 1: Basic Schema
  # ---------------------------------------------------------------------------
  # Create a schema for a "products" table with:
  # - name (string, required)
  # - description (string)
  # - price (decimal)
  # - quantity (integer, default 0)
  # - active (boolean, default true)
  # - timestamps

  defmodule Product do
    use Ecto.Schema

    # Your schema here
  end

  # ---------------------------------------------------------------------------
  # Exercise 2: UUID Primary Key
  # ---------------------------------------------------------------------------
  # Create a schema for an "orders" table with:
  # - UUID primary key
  # - customer_name (string)
  # - total (decimal)
  # - status (string, default "pending")
  # - timestamps with UTC datetime

  defmodule Order do
    use Ecto.Schema

    # Your schema here
  end

  # ---------------------------------------------------------------------------
  # Exercise 3: Virtual Fields
  # ---------------------------------------------------------------------------
  # Create a schema for an "accounts" table with:
  # - email (string)
  # - password_hash (string, redacted)
  # - password (virtual, redacted)
  # - terms_accepted (virtual, boolean)
  # - timestamps

  defmodule Account do
    use Ecto.Schema

    # Your schema here
  end

  # ---------------------------------------------------------------------------
  # Exercise 4: Custom Field Names
  # ---------------------------------------------------------------------------
  # Create a schema for a legacy "CUSTOMERS" table where:
  # - The database column is "CUST_EMAIL" but you want to use :email
  # - The database column is "CUST_NAME" but you want to use :name
  # - The database uses "CREATED_DATE" instead of inserted_at
  # - No updated_at column exists

  defmodule Customer do
    use Ecto.Schema

    # Your schema here
  end

  # ---------------------------------------------------------------------------
  # Exercise 5: Collection Types
  # ---------------------------------------------------------------------------
  # Create a schema for a "blog_posts" table with:
  # - title (string)
  # - body (string)
  # - tags (array of strings)
  # - metadata (map)
  # - view_count (integer, default 0)
  # - published_at (UTC datetime, nullable)
  # - timestamps

  defmodule BlogPost do
    use Ecto.Schema

    # Your schema here
  end

  # ---------------------------------------------------------------------------
  # Exercise 6: Schema Introspection
  # ---------------------------------------------------------------------------
  # Write a function that takes a schema module and returns a map with:
  # - :table - the table name
  # - :fields - list of field names
  # - :primary_key - the primary key field(s)
  # - :field_types - map of field name to type

  def schema_info(_schema_module) do
    # Your code here
  end

  # ---------------------------------------------------------------------------
  # EXERCISE SOLUTIONS
  # ---------------------------------------------------------------------------

  def solutions do
    """
    Exercise 1 Solution:
    --------------------
    defmodule Product do
      use Ecto.Schema

      schema "products" do
        field :name, :string
        field :description, :string
        field :price, :decimal
        field :quantity, :integer, default: 0
        field :active, :boolean, default: true

        timestamps()
      end
    end

    Exercise 2 Solution:
    --------------------
    defmodule Order do
      use Ecto.Schema

      @primary_key {:id, :binary_id, autogenerate: true}

      schema "orders" do
        field :customer_name, :string
        field :total, :decimal
        field :status, :string, default: "pending"

        timestamps(type: :utc_datetime)
      end
    end

    Exercise 3 Solution:
    --------------------
    defmodule Account do
      use Ecto.Schema

      schema "accounts" do
        field :email, :string
        field :password_hash, :string, redact: true
        field :password, :string, virtual: true, redact: true
        field :terms_accepted, :boolean, virtual: true

        timestamps()
      end
    end

    Exercise 4 Solution:
    --------------------
    defmodule Customer do
      use Ecto.Schema

      schema "CUSTOMERS" do
        field :email, :string, source: :CUST_EMAIL
        field :name, :string, source: :CUST_NAME

        timestamps(
          inserted_at: :created_date,
          inserted_at_source: :CREATED_DATE,
          updated_at: false
        )
      end
    end

    Exercise 5 Solution:
    --------------------
    defmodule BlogPost do
      use Ecto.Schema

      schema "blog_posts" do
        field :title, :string
        field :body, :string
        field :tags, {:array, :string}
        field :metadata, :map
        field :view_count, :integer, default: 0
        field :published_at, :utc_datetime

        timestamps()
      end
    end

    Exercise 6 Solution:
    --------------------
    def schema_info(schema_module) do
      %{
        table: schema_module.__schema__(:source),
        fields: schema_module.__schema__(:fields),
        primary_key: schema_module.__schema__(:primary_key),
        field_types: schema_module.__schema__(:fields)
          |> Enum.map(fn field ->
            {field, schema_module.__schema__(:type, field)}
          end)
          |> Map.new()
      }
    end
    """
  end
end

# ==============================================================================
# KEY TAKEAWAYS
# ==============================================================================
#
# 1. SCHEMA BASICS:
#    - Schemas map Elixir structs to database tables
#    - Use `schema "table_name" do ... end` to define
#    - Fields define the struct and type information
#
# 2. FIELD TYPES:
#    - Primitives: :string, :integer, :float, :decimal, :boolean
#    - Date/Time: :date, :time, :naive_datetime, :utc_datetime
#    - Collections: {:array, type}, :map
#    - Binary: :binary, :binary_id, Ecto.UUID
#
# 3. PRIMARY KEYS:
#    - Default: auto-incrementing :id
#    - UUID: @primary_key {:id, :binary_id, autogenerate: true}
#    - Composite: @primary_key false, then multiple primary_key: true fields
#
# 4. TIMESTAMPS:
#    - timestamps() adds :inserted_at and :updated_at
#    - Customize names and types with options
#    - Can be disabled or have only one timestamp
#
# 5. VIRTUAL FIELDS:
#    - Not persisted to database
#    - Useful for temporary data, passwords, computed values
#    - field :name, :type, virtual: true
#
# 6. FIELD OPTIONS:
#    - default: value - Default value for struct
#    - source: :column - Map to different column name
#    - redact: true - Hide in inspect output
#    - virtual: true - Not persisted
#
# ==============================================================================
# NEXT LESSON: 04_embedded_schemas.exs - Learn about Embedded Schemas
# ==============================================================================
