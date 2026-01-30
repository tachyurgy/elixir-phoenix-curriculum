# ==============================================================================
# EMBEDDED SCHEMAS - NESTED DATA STRUCTURES IN ECTO
# ==============================================================================
#
# Embedded schemas allow you to define nested data structures that are stored
# as JSON/JSONB in the database or used for validation without persistence.
#
# Key use cases:
# - Storing structured JSON data
# - Form validation without database persistence
# - Complex nested data within a single table
# - Schemaless changesets for dynamic forms
#
# ==============================================================================
# TABLE OF CONTENTS
# ==============================================================================
#
# 1. embedded_schema Basics
# 2. embeds_one - Single Embedded Record
# 3. embeds_many - Multiple Embedded Records
# 4. Changesets with Embedded Schemas
# 5. Schemaless Changesets
# 6. Practical Examples
# 7. Exercises
#
# ==============================================================================

# ==============================================================================
# SECTION 1: EMBEDDED_SCHEMA BASICS
# ==============================================================================

defmodule EmbeddedBasics do
  @moduledoc """
  Embedded schemas define structures that don't map to their own database table.
  They're typically stored as JSON within another table's column.
  """

  # ---------------------------------------------------------------------------
  # Basic Embedded Schema
  # ---------------------------------------------------------------------------

  defmodule Address do
    use Ecto.Schema
    import Ecto.Changeset

    # embedded_schema instead of schema
    # No table name needed - not stored in its own table
    embedded_schema do
      field :street, :string
      field :city, :string
      field :state, :string
      field :zip, :string
      field :country, :string, default: "US"
    end

    def changeset(address, attrs) do
      address
      |> cast(attrs, [:street, :city, :state, :zip, :country])
      |> validate_required([:street, :city, :state, :zip])
      |> validate_length(:zip, is: 5)
      |> validate_length(:state, is: 2)
    end
  end

  # Embedded schemas:
  # - Have an :id field by default (can be disabled)
  # - Don't have timestamps by default
  # - Are stored as JSON/JSONB in the parent table
  # - Can have their own changesets and validations

  def demonstrate_embedded_schema do
    # Create an address struct
    address = %Address{
      street: "123 Main St",
      city: "Springfield",
      state: "IL",
      zip: "62701"
    }

    IO.inspect(address)
    # => %Address{id: nil, street: "123 Main St", city: "Springfield", ...}

    # Create via changeset
    {:ok, address} =
      %Address{}
      |> Address.changeset(%{
        street: "456 Oak Ave",
        city: "Chicago",
        state: "IL",
        zip: "60601"
      })
      |> Ecto.Changeset.apply_action(:insert)

    address
  end
end

# ==============================================================================
# SECTION 2: EMBEDS_ONE - SINGLE EMBEDDED RECORD
# ==============================================================================

defmodule EmbedsOneExample do
  @moduledoc """
  embeds_one defines a one-to-one relationship with an embedded schema.
  The embedded data is stored as a JSON object in a single column.
  """

  # ---------------------------------------------------------------------------
  # Address Schema (Embedded)
  # ---------------------------------------------------------------------------

  defmodule Address do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false  # Often embedded schemas don't need IDs
    embedded_schema do
      field :street, :string
      field :city, :string
      field :state, :string
      field :zip, :string
    end

    def changeset(address, attrs) do
      address
      |> cast(attrs, [:street, :city, :state, :zip])
      |> validate_required([:street, :city, :state, :zip])
    end
  end

  # ---------------------------------------------------------------------------
  # User Schema with Embedded Address
  # ---------------------------------------------------------------------------

  defmodule User do
    use Ecto.Schema
    import Ecto.Changeset

    schema "users" do
      field :name, :string
      field :email, :string

      # Embed a single address
      # Stored as JSON in "address" column
      embeds_one :address, Address, on_replace: :update

      timestamps()
    end

    def changeset(user, attrs) do
      user
      |> cast(attrs, [:name, :email])
      |> validate_required([:name, :email])
      |> cast_embed(:address, required: true)
    end
  end

  # ---------------------------------------------------------------------------
  # Database Migration for embeds_one
  # ---------------------------------------------------------------------------

  def migration_example do
    """
    defmodule MyApp.Repo.Migrations.CreateUsers do
      use Ecto.Migration

      def change do
        create table(:users) do
          add :name, :string, null: false
          add :email, :string, null: false
          # JSON column for embedded address
          add :address, :map, null: false

          timestamps()
        end
      end
    end
    """
  end

  # ---------------------------------------------------------------------------
  # Usage Examples
  # ---------------------------------------------------------------------------

  def usage_examples do
    alias MyApp.Repo

    # Create user with embedded address
    attrs = %{
      name: "Alice",
      email: "alice@example.com",
      address: %{
        street: "123 Main St",
        city: "Springfield",
        state: "IL",
        zip: "62701"
      }
    }

    changeset = User.changeset(%User{}, attrs)
    {:ok, user} = Repo.insert(changeset)

    # Access embedded data
    IO.puts(user.address.street)  # => "123 Main St"
    IO.puts(user.address.city)    # => "Springfield"

    # Update embedded data
    update_attrs = %{
      address: %{
        street: "456 Oak Ave",
        city: "Chicago",
        state: "IL",
        zip: "60601"
      }
    }

    updated_changeset = User.changeset(user, update_attrs)
    {:ok, updated_user} = Repo.update(updated_changeset)

    updated_user
  end

  # ---------------------------------------------------------------------------
  # on_replace Option
  # ---------------------------------------------------------------------------

  def on_replace_options do
    """
    on_replace controls what happens when embedded data is replaced:

    :raise (default)
    ----------------
    Raises if you try to replace the embed. Must explicitly delete first.

    :update
    -------
    Updates the existing embed with new values.
    embeds_one :address, Address, on_replace: :update

    :delete
    -------
    Deletes the existing embed and creates a new one.
    embeds_one :address, Address, on_replace: :delete

    :mark_as_invalid
    ----------------
    Makes the changeset invalid when trying to replace.
    embeds_one :address, Address, on_replace: :mark_as_invalid
    """
  end
end

# ==============================================================================
# SECTION 3: EMBEDS_MANY - MULTIPLE EMBEDDED RECORDS
# ==============================================================================

defmodule EmbedsManyExample do
  @moduledoc """
  embeds_many defines a one-to-many relationship with embedded schemas.
  The embedded data is stored as a JSON array in a single column.
  """

  # ---------------------------------------------------------------------------
  # PhoneNumber Schema (Embedded)
  # ---------------------------------------------------------------------------

  defmodule PhoneNumber do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :label, :string  # "home", "work", "mobile"
      field :number, :string
      field :primary, :boolean, default: false
    end

    def changeset(phone, attrs) do
      phone
      |> cast(attrs, [:label, :number, :primary])
      |> validate_required([:label, :number])
      |> validate_inclusion(:label, ["home", "work", "mobile", "other"])
      |> validate_format(:number, ~r/^\+?[\d\s-]{10,}$/)
    end
  end

  # ---------------------------------------------------------------------------
  # Contact Schema with Multiple Phones
  # ---------------------------------------------------------------------------

  defmodule Contact do
    use Ecto.Schema
    import Ecto.Changeset

    schema "contacts" do
      field :name, :string
      field :email, :string

      # Embed multiple phone numbers
      # Stored as JSON array in "phone_numbers" column
      embeds_many :phone_numbers, PhoneNumber, on_replace: :delete

      timestamps()
    end

    def changeset(contact, attrs) do
      contact
      |> cast(attrs, [:name, :email])
      |> validate_required([:name])
      |> cast_embed(:phone_numbers, with: &PhoneNumber.changeset/2)
    end
  end

  # ---------------------------------------------------------------------------
  # Database Migration for embeds_many
  # ---------------------------------------------------------------------------

  def migration_example do
    """
    defmodule MyApp.Repo.Migrations.CreateContacts do
      use Ecto.Migration

      def change do
        create table(:contacts) do
          add :name, :string, null: false
          add :email, :string
          # JSON array for embedded phone numbers
          # Use {:array, :map} or just :map (JSONB in PostgreSQL)
          add :phone_numbers, {:array, :map}, default: []

          timestamps()
        end
      end
    end
    """
  end

  # ---------------------------------------------------------------------------
  # Usage Examples
  # ---------------------------------------------------------------------------

  def usage_examples do
    alias MyApp.Repo

    # Create contact with multiple phone numbers
    attrs = %{
      name: "Bob Smith",
      email: "bob@example.com",
      phone_numbers: [
        %{label: "home", number: "+1-555-123-4567", primary: true},
        %{label: "work", number: "+1-555-987-6543"},
        %{label: "mobile", number: "+1-555-555-5555"}
      ]
    }

    changeset = Contact.changeset(%Contact{}, attrs)
    {:ok, contact} = Repo.insert(changeset)

    # Access embedded data
    Enum.each(contact.phone_numbers, fn phone ->
      IO.puts("#{phone.label}: #{phone.number}")
    end)

    # Find primary phone
    primary = Enum.find(contact.phone_numbers, & &1.primary)
    IO.puts("Primary: #{primary.number}")

    contact
  end

  # ---------------------------------------------------------------------------
  # Managing embeds_many entries
  # ---------------------------------------------------------------------------

  def managing_entries do
    """
    Adding entries:
    --------------
    new_phone = %{label: "mobile", number: "+1-555-000-0000"}
    attrs = %{phone_numbers: contact.phone_numbers ++ [new_phone]}
    Contact.changeset(contact, attrs)

    Removing entries:
    -----------------
    # Remove by filtering
    remaining = Enum.reject(contact.phone_numbers, & &1.id == phone_id)
    attrs = %{phone_numbers: remaining}
    Contact.changeset(contact, attrs)

    Updating specific entry:
    ------------------------
    updated_phones = Enum.map(contact.phone_numbers, fn phone ->
      if phone.id == target_id do
        %{phone | number: "new-number"}
      else
        phone
      end
    end)
    attrs = %{phone_numbers: updated_phones}
    Contact.changeset(contact, attrs)
    """
  end
end

# ==============================================================================
# SECTION 4: CHANGESETS WITH EMBEDDED SCHEMAS
# ==============================================================================

defmodule EmbeddedChangesets do
  @moduledoc """
  Working with changesets for embedded schemas.
  """

  defmodule Address do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :street, :string
      field :city, :string
      field :state, :string
      field :zip, :string
    end

    def changeset(address, attrs) do
      address
      |> cast(attrs, [:street, :city, :state, :zip])
      |> validate_required([:city, :state])
    end
  end

  defmodule Order do
    use Ecto.Schema
    import Ecto.Changeset

    schema "orders" do
      field :order_number, :string
      field :total, :decimal

      embeds_one :shipping_address, Address, on_replace: :update
      embeds_one :billing_address, Address, on_replace: :update

      timestamps()
    end

    # ---------------------------------------------------------------------------
    # Basic cast_embed
    # ---------------------------------------------------------------------------

    def changeset(order, attrs) do
      order
      |> cast(attrs, [:order_number, :total])
      |> validate_required([:order_number])
      # cast_embed uses the embedded schema's changeset function
      |> cast_embed(:shipping_address, required: true)
      |> cast_embed(:billing_address)
    end

    # ---------------------------------------------------------------------------
    # cast_embed with custom changeset
    # ---------------------------------------------------------------------------

    def changeset_with_custom(order, attrs) do
      order
      |> cast(attrs, [:order_number, :total])
      |> cast_embed(:shipping_address, with: &Address.changeset/2)
      |> cast_embed(:billing_address, with: &custom_billing_changeset/2)
    end

    defp custom_billing_changeset(address, attrs) do
      address
      |> cast(attrs, [:street, :city, :state, :zip])
      |> validate_required([:street, :city, :state, :zip])
      # Additional validations for billing
    end

    # ---------------------------------------------------------------------------
    # cast_embed options
    # ---------------------------------------------------------------------------

    def changeset_with_options(order, attrs) do
      order
      |> cast(attrs, [:order_number, :total])
      |> cast_embed(:shipping_address,
        required: true,                    # The embed is required
        with: &Address.changeset/2,        # Custom changeset function
        force_update_on_change: [:zip]     # Force update if zip changes
      )
    end
  end

  # ---------------------------------------------------------------------------
  # Validating Embedded Data
  # ---------------------------------------------------------------------------

  def validate_embedded_example do
    import Ecto.Changeset

    attrs = %{
      order_number: "ORD-001",
      total: Decimal.new("99.99"),
      shipping_address: %{
        # Missing required fields
        city: "Chicago"
      }
    }

    changeset = Order.changeset(%Order{}, attrs)

    # Check if valid
    IO.inspect(changeset.valid?)  # => false

    # Errors are nested
    IO.inspect(changeset.changes.shipping_address.errors)
    # => [state: {"can't be blank", [validation: :required]}]

    changeset
  end
end

# ==============================================================================
# SECTION 5: SCHEMALESS CHANGESETS
# ==============================================================================

defmodule SchemalessChangesets do
  @moduledoc """
  Schemaless changesets allow validation without a database-backed schema.
  Useful for forms, API parameters, and temporary data structures.
  """

  import Ecto.Changeset

  # ---------------------------------------------------------------------------
  # Basic Schemaless Changeset
  # ---------------------------------------------------------------------------

  def validate_login_params(params) do
    # Define the data types
    types = %{
      email: :string,
      password: :string,
      remember_me: :boolean
    }

    # Create changeset from empty map
    {%{}, types}
    |> cast(params, Map.keys(types))
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 8)
  end

  def demonstrate_schemaless do
    # Valid params
    valid_params = %{
      "email" => "user@example.com",
      "password" => "secretpassword",
      "remember_me" => "true"
    }

    changeset = validate_login_params(valid_params)
    IO.inspect(changeset.valid?)  # => true

    # Get the validated data
    {:ok, data} = apply_action(changeset, :validate)
    IO.inspect(data)
    # => %{email: "user@example.com", password: "secretpassword", remember_me: true}

    # Invalid params
    invalid_params = %{
      "email" => "invalid-email",
      "password" => "short"
    }

    changeset = validate_login_params(invalid_params)
    IO.inspect(changeset.valid?)  # => false
    IO.inspect(changeset.errors)
    # => [email: {"has invalid format", ...}, password: {"should be at least 8 character(s)", ...}]

    changeset
  end

  # ---------------------------------------------------------------------------
  # Contact Form Example
  # ---------------------------------------------------------------------------

  def validate_contact_form(params) do
    types = %{
      name: :string,
      email: :string,
      subject: :string,
      message: :string,
      urgency: :string
    }

    {%{}, types}
    |> cast(params, Map.keys(types))
    |> validate_required([:name, :email, :message])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:message, min: 10, max: 5000)
    |> validate_inclusion(:urgency, ["low", "medium", "high"])
  end

  # ---------------------------------------------------------------------------
  # Search Parameters Example
  # ---------------------------------------------------------------------------

  def validate_search_params(params) do
    types = %{
      query: :string,
      page: :integer,
      per_page: :integer,
      sort_by: :string,
      sort_order: :string,
      filters: {:array, :string}
    }

    defaults = %{
      page: 1,
      per_page: 20,
      sort_order: "asc"
    }

    {defaults, types}
    |> cast(params, Map.keys(types))
    |> validate_required([:query])
    |> validate_length(:query, min: 2)
    |> validate_number(:page, greater_than: 0)
    |> validate_number(:per_page, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_inclusion(:sort_order, ["asc", "desc"])
  end

  # ---------------------------------------------------------------------------
  # Nested Schemaless Changeset
  # ---------------------------------------------------------------------------

  def validate_registration(params) do
    # Main registration types
    types = %{
      email: :string,
      password: :string,
      password_confirmation: :string,
      profile: :map  # Nested data
    }

    profile_types = %{
      first_name: :string,
      last_name: :string,
      phone: :string
    }

    # Validate main form
    main_changeset =
      {%{}, types}
      |> cast(params, [:email, :password, :password_confirmation])
      |> validate_required([:email, :password, :password_confirmation])
      |> validate_format(:email, ~r/@/)
      |> validate_length(:password, min: 8)
      |> validate_confirmation(:password)

    # Validate nested profile
    profile_params = params["profile"] || %{}
    profile_changeset =
      {%{}, profile_types}
      |> cast(profile_params, Map.keys(profile_types))
      |> validate_required([:first_name, :last_name])

    # Combine results
    if main_changeset.valid? and profile_changeset.valid? do
      {:ok, main_data} = apply_action(main_changeset, :validate)
      {:ok, profile_data} = apply_action(profile_changeset, :validate)
      {:ok, Map.put(main_data, :profile, profile_data)}
    else
      {:error, %{main: main_changeset, profile: profile_changeset}}
    end
  end

  # ---------------------------------------------------------------------------
  # Using Embedded Schema for Schemaless Validation
  # ---------------------------------------------------------------------------

  defmodule ContactFormSchema do
    use Ecto.Schema
    import Ecto.Changeset

    # embedded_schema can be used purely for validation
    # without ever being stored in a database
    embedded_schema do
      field :name, :string
      field :email, :string
      field :message, :string
      field :priority, :string
    end

    def changeset(form, attrs) do
      form
      |> cast(attrs, [:name, :email, :message, :priority])
      |> validate_required([:name, :email, :message])
      |> validate_format(:email, ~r/@/)
      |> validate_length(:message, min: 10)
      |> validate_inclusion(:priority, ["low", "normal", "high"])
    end
  end

  def validate_with_embedded_schema(params) do
    changeset = ContactFormSchema.changeset(%ContactFormSchema{}, params)

    case apply_action(changeset, :validate) do
      {:ok, data} -> {:ok, Map.from_struct(data)}
      {:error, changeset} -> {:error, changeset}
    end
  end
end

# ==============================================================================
# SECTION 6: PRACTICAL EXAMPLES
# ==============================================================================

defmodule PracticalExamples do
  @moduledoc """
  Real-world examples of embedded schemas.
  """

  # ---------------------------------------------------------------------------
  # Example 1: Order with Line Items
  # ---------------------------------------------------------------------------

  defmodule LineItem do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :product_id, :integer
      field :product_name, :string
      field :quantity, :integer
      field :unit_price, :decimal
      field :total, :decimal
    end

    def changeset(item, attrs) do
      item
      |> cast(attrs, [:product_id, :product_name, :quantity, :unit_price])
      |> validate_required([:product_id, :product_name, :quantity, :unit_price])
      |> validate_number(:quantity, greater_than: 0)
      |> validate_number(:unit_price, greater_than_or_equal_to: 0)
      |> calculate_total()
    end

    defp calculate_total(changeset) do
      quantity = get_field(changeset, :quantity)
      unit_price = get_field(changeset, :unit_price)

      if quantity && unit_price do
        total = Decimal.mult(Decimal.new(quantity), unit_price)
        put_change(changeset, :total, total)
      else
        changeset
      end
    end
  end

  defmodule Order do
    use Ecto.Schema
    import Ecto.Changeset

    schema "orders" do
      field :order_number, :string
      field :customer_email, :string
      field :subtotal, :decimal
      field :tax, :decimal
      field :total, :decimal
      field :status, :string, default: "pending"

      embeds_many :line_items, LineItem, on_replace: :delete

      timestamps()
    end

    def changeset(order, attrs) do
      order
      |> cast(attrs, [:order_number, :customer_email, :status])
      |> validate_required([:order_number, :customer_email])
      |> cast_embed(:line_items, required: true)
      |> validate_length(:line_items, min: 1)
      |> calculate_totals()
    end

    defp calculate_totals(changeset) do
      line_items = get_field(changeset, :line_items) || []

      subtotal = Enum.reduce(line_items, Decimal.new(0), fn item, acc ->
        Decimal.add(acc, item.total || Decimal.new(0))
      end)

      tax = Decimal.mult(subtotal, Decimal.new("0.08"))  # 8% tax
      total = Decimal.add(subtotal, tax)

      changeset
      |> put_change(:subtotal, subtotal)
      |> put_change(:tax, tax)
      |> put_change(:total, total)
    end
  end

  # ---------------------------------------------------------------------------
  # Example 2: User with Settings
  # ---------------------------------------------------------------------------

  defmodule NotificationSettings do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :email_notifications, :boolean, default: true
      field :push_notifications, :boolean, default: true
      field :sms_notifications, :boolean, default: false
      field :weekly_digest, :boolean, default: true
      field :notification_frequency, :string, default: "instant"
    end

    def changeset(settings, attrs) do
      settings
      |> cast(attrs, [:email_notifications, :push_notifications, :sms_notifications,
                      :weekly_digest, :notification_frequency])
      |> validate_inclusion(:notification_frequency, ["instant", "hourly", "daily"])
    end
  end

  defmodule PrivacySettings do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :profile_visible, :boolean, default: true
      field :show_email, :boolean, default: false
      field :show_activity, :boolean, default: true
      field :allow_indexing, :boolean, default: true
    end

    def changeset(settings, attrs) do
      settings
      |> cast(attrs, [:profile_visible, :show_email, :show_activity, :allow_indexing])
    end
  end

  defmodule UserSettings do
    use Ecto.Schema
    import Ecto.Changeset

    schema "user_settings" do
      field :user_id, :integer

      embeds_one :notifications, NotificationSettings, on_replace: :update
      embeds_one :privacy, PrivacySettings, on_replace: :update

      timestamps()
    end

    def changeset(settings, attrs) do
      settings
      |> cast(attrs, [:user_id])
      |> cast_embed(:notifications)
      |> cast_embed(:privacy)
    end
  end

  # ---------------------------------------------------------------------------
  # Example 3: Product with Variants
  # ---------------------------------------------------------------------------

  defmodule ProductVariant do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :sku, :string
      field :name, :string
      field :price, :decimal
      field :stock, :integer, default: 0
      field :attributes, :map, default: %{}  # e.g., %{"size" => "L", "color" => "red"}
    end

    def changeset(variant, attrs) do
      variant
      |> cast(attrs, [:sku, :name, :price, :stock, :attributes])
      |> validate_required([:sku, :name, :price])
      |> validate_number(:price, greater_than: 0)
      |> validate_number(:stock, greater_than_or_equal_to: 0)
    end
  end

  defmodule Product do
    use Ecto.Schema
    import Ecto.Changeset

    schema "products" do
      field :name, :string
      field :description, :string
      field :base_price, :decimal
      field :active, :boolean, default: true

      embeds_many :variants, ProductVariant, on_replace: :delete

      timestamps()
    end

    def changeset(product, attrs) do
      product
      |> cast(attrs, [:name, :description, :base_price, :active])
      |> validate_required([:name, :base_price])
      |> cast_embed(:variants)
    end
  end
end

# ==============================================================================
# EXERCISES
# ==============================================================================

defmodule Exercises do
  @moduledoc """
  Practice exercises for embedded schemas and schemaless changesets.
  """

  import Ecto.Changeset

  # ---------------------------------------------------------------------------
  # Exercise 1: Simple Embedded Schema
  # ---------------------------------------------------------------------------
  # Create an embedded schema for a person's name with:
  # - first_name (required)
  # - middle_name (optional)
  # - last_name (required)
  # - suffix (optional, e.g., "Jr.", "III")
  # Include a changeset function with appropriate validations.

  defmodule PersonName do
    use Ecto.Schema

    # Your embedded_schema here
  end

  # ---------------------------------------------------------------------------
  # Exercise 2: embeds_one Usage
  # ---------------------------------------------------------------------------
  # Create a Company schema that embeds a HeadquartersAddress.
  # The address should have: street, city, state, zip, country.
  # The company should have: name, founded_year, and the embedded address.

  defmodule HeadquartersAddress do
    use Ecto.Schema

    # Your embedded_schema here
  end

  defmodule Company do
    use Ecto.Schema

    # Your schema here
  end

  # ---------------------------------------------------------------------------
  # Exercise 3: embeds_many Usage
  # ---------------------------------------------------------------------------
  # Create a Recipe schema that embeds multiple Ingredient schemas.
  # Ingredient should have: name, amount (decimal), unit (string).
  # Recipe should have: name, description, prep_time (integer, minutes),
  #                     and the embedded ingredients.

  defmodule Ingredient do
    use Ecto.Schema

    # Your embedded_schema here
  end

  defmodule Recipe do
    use Ecto.Schema

    # Your schema here
  end

  # ---------------------------------------------------------------------------
  # Exercise 4: Schemaless Changeset
  # ---------------------------------------------------------------------------
  # Create a function to validate newsletter subscription params:
  # - email (required, must be valid email format)
  # - name (optional, max 100 characters)
  # - topics (array of strings, at least one required)
  # - frequency (required, must be "daily", "weekly", or "monthly")

  def validate_newsletter_subscription(params) do
    # Your code here
  end

  # ---------------------------------------------------------------------------
  # Exercise 5: Complex Embedded Structure
  # ---------------------------------------------------------------------------
  # Create a BlogPost schema with:
  # - title (string)
  # - body (string)
  # - author (embedded: name, email, bio)
  # - tags (array of strings, stored directly)
  # - metadata (embedded: view_count, reading_time, seo_keywords list)

  defmodule Author do
    use Ecto.Schema
    # Your embedded_schema here
  end

  defmodule PostMetadata do
    use Ecto.Schema
    # Your embedded_schema here
  end

  defmodule BlogPost do
    use Ecto.Schema
    # Your schema here
  end

  # ---------------------------------------------------------------------------
  # Exercise 6: Nested Schemaless Validation
  # ---------------------------------------------------------------------------
  # Create a function to validate a job application with:
  # - applicant: name, email, phone
  # - position: title, department
  # - experience_years (integer, >= 0)
  # - cover_letter (string, min 100 characters)

  def validate_job_application(params) do
    # Your code here
    # Hint: Validate nested structures separately then combine
  end

  # ---------------------------------------------------------------------------
  # EXERCISE SOLUTIONS
  # ---------------------------------------------------------------------------

  def solutions do
    """
    Exercise 1 Solution:
    --------------------
    defmodule PersonName do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key false
      embedded_schema do
        field :first_name, :string
        field :middle_name, :string
        field :last_name, :string
        field :suffix, :string
      end

      def changeset(name, attrs) do
        name
        |> cast(attrs, [:first_name, :middle_name, :last_name, :suffix])
        |> validate_required([:first_name, :last_name])
        |> validate_length(:first_name, min: 1, max: 50)
        |> validate_length(:last_name, min: 1, max: 50)
        |> validate_inclusion(:suffix, ["Jr.", "Sr.", "II", "III", "IV", nil])
      end
    end

    Exercise 2 Solution:
    --------------------
    defmodule HeadquartersAddress do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key false
      embedded_schema do
        field :street, :string
        field :city, :string
        field :state, :string
        field :zip, :string
        field :country, :string, default: "US"
      end

      def changeset(address, attrs) do
        address
        |> cast(attrs, [:street, :city, :state, :zip, :country])
        |> validate_required([:street, :city, :state, :zip])
      end
    end

    defmodule Company do
      use Ecto.Schema
      import Ecto.Changeset

      schema "companies" do
        field :name, :string
        field :founded_year, :integer
        embeds_one :headquarters, HeadquartersAddress, on_replace: :update
        timestamps()
      end

      def changeset(company, attrs) do
        company
        |> cast(attrs, [:name, :founded_year])
        |> validate_required([:name])
        |> cast_embed(:headquarters, required: true)
      end
    end

    Exercise 3 Solution:
    --------------------
    defmodule Ingredient do
      use Ecto.Schema
      import Ecto.Changeset

      embedded_schema do
        field :name, :string
        field :amount, :decimal
        field :unit, :string
      end

      def changeset(ingredient, attrs) do
        ingredient
        |> cast(attrs, [:name, :amount, :unit])
        |> validate_required([:name, :amount, :unit])
        |> validate_number(:amount, greater_than: 0)
      end
    end

    defmodule Recipe do
      use Ecto.Schema
      import Ecto.Changeset

      schema "recipes" do
        field :name, :string
        field :description, :string
        field :prep_time, :integer
        embeds_many :ingredients, Ingredient, on_replace: :delete
        timestamps()
      end

      def changeset(recipe, attrs) do
        recipe
        |> cast(attrs, [:name, :description, :prep_time])
        |> validate_required([:name, :prep_time])
        |> validate_number(:prep_time, greater_than: 0)
        |> cast_embed(:ingredients, required: true)
        |> validate_length(:ingredients, min: 1)
      end
    end

    Exercise 4 Solution:
    --------------------
    def validate_newsletter_subscription(params) do
      types = %{
        email: :string,
        name: :string,
        topics: {:array, :string},
        frequency: :string
      }

      {%{}, types}
      |> cast(params, Map.keys(types))
      |> validate_required([:email, :topics, :frequency])
      |> validate_format(:email, ~r/^[^\\s]+@[^\\s]+$/)
      |> validate_length(:name, max: 100)
      |> validate_length(:topics, min: 1)
      |> validate_inclusion(:frequency, ["daily", "weekly", "monthly"])
    end

    Exercise 5 Solution:
    --------------------
    defmodule Author do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key false
      embedded_schema do
        field :name, :string
        field :email, :string
        field :bio, :string
      end

      def changeset(author, attrs) do
        author
        |> cast(attrs, [:name, :email, :bio])
        |> validate_required([:name, :email])
        |> validate_format(:email, ~r/@/)
      end
    end

    defmodule PostMetadata do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key false
      embedded_schema do
        field :view_count, :integer, default: 0
        field :reading_time, :integer
        field :seo_keywords, {:array, :string}, default: []
      end

      def changeset(metadata, attrs) do
        metadata
        |> cast(attrs, [:view_count, :reading_time, :seo_keywords])
        |> validate_number(:view_count, greater_than_or_equal_to: 0)
        |> validate_number(:reading_time, greater_than: 0)
      end
    end

    defmodule BlogPost do
      use Ecto.Schema
      import Ecto.Changeset

      schema "blog_posts" do
        field :title, :string
        field :body, :string
        field :tags, {:array, :string}, default: []
        embeds_one :author, Author, on_replace: :update
        embeds_one :metadata, PostMetadata, on_replace: :update
        timestamps()
      end

      def changeset(post, attrs) do
        post
        |> cast(attrs, [:title, :body, :tags])
        |> validate_required([:title, :body])
        |> cast_embed(:author, required: true)
        |> cast_embed(:metadata)
      end
    end

    Exercise 6 Solution:
    --------------------
    def validate_job_application(params) do
      applicant_types = %{name: :string, email: :string, phone: :string}
      position_types = %{title: :string, department: :string}
      main_types = %{experience_years: :integer, cover_letter: :string}

      applicant_params = params["applicant"] || %{}
      position_params = params["position"] || %{}

      applicant_changeset =
        {%{}, applicant_types}
        |> cast(applicant_params, Map.keys(applicant_types))
        |> validate_required([:name, :email])
        |> validate_format(:email, ~r/@/)

      position_changeset =
        {%{}, position_types}
        |> cast(position_params, Map.keys(position_types))
        |> validate_required([:title, :department])

      main_changeset =
        {%{}, main_types}
        |> cast(params, Map.keys(main_types))
        |> validate_required([:experience_years, :cover_letter])
        |> validate_number(:experience_years, greater_than_or_equal_to: 0)
        |> validate_length(:cover_letter, min: 100)

      if applicant_changeset.valid? and position_changeset.valid? and main_changeset.valid? do
        {:ok, applicant} = apply_action(applicant_changeset, :validate)
        {:ok, position} = apply_action(position_changeset, :validate)
        {:ok, main} = apply_action(main_changeset, :validate)

        {:ok, Map.merge(main, %{applicant: applicant, position: position})}
      else
        {:error, %{
          applicant: applicant_changeset,
          position: position_changeset,
          main: main_changeset
        }}
      end
    end
    """
  end
end

# ==============================================================================
# KEY TAKEAWAYS
# ==============================================================================
#
# 1. EMBEDDED SCHEMAS:
#    - Use `embedded_schema` instead of `schema "table_name"`
#    - Stored as JSON in parent table's column
#    - Have their own changesets and validations
#    - No separate database table
#
# 2. EMBEDS_ONE:
#    - Single embedded record
#    - Stored as JSON object
#    - Use `cast_embed/3` in changesets
#    - Configure `on_replace` for update behavior
#
# 3. EMBEDS_MANY:
#    - Multiple embedded records
#    - Stored as JSON array
#    - Use `cast_embed/3` with list handling
#    - Each item has its own ID (by default)
#
# 4. SCHEMALESS CHANGESETS:
#    - Validate data without a schema
#    - Use `{data, types}` tuple instead of struct
#    - Great for forms, API params, temporary data
#    - Use `apply_action/2` to get validated data
#
# 5. BEST PRACTICES:
#    - Use embedded schemas for structured JSON data
#    - Use schemaless changesets for form validation
#    - Keep embedded schemas focused and small
#    - Consider database query limitations (can't easily JOIN)
#
# ==============================================================================
# NEXT LESSON: 05_changesets_intro.exs - Learn about Ecto Changesets
# ==============================================================================
