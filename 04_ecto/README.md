# Section 4: Ecto Fundamentals

Learn Ecto, Elixir's database wrapper and query generator. Ecto provides a powerful, composable way to work with databases.

## What You'll Learn

- Ecto repositories and configuration
- Schemas for mapping database tables
- Changesets for data validation
- Migrations for database changes
- Query composition and execution
- Associations between schemas
- Transactions and multi-step operations

## Prerequisites

- Sections 1-3 completed
- PostgreSQL installed and running
- Basic SQL knowledge helpful

## Setup

```bash
# Create a new Mix project with Ecto
mix new my_app --sup
cd my_app

# Add dependencies to mix.exs
# {:ecto_sql, "~> 3.11"}
# {:postgrex, "~> 0.17"}

mix deps.get
mix ecto.create
```

## Lessons

### Setup and Basics
1. **[01_ecto_setup.exs](01_ecto_setup.exs)** - Installing Ecto, repo configuration
2. **[02_repo_basics.exs](02_repo_basics.exs)** - Repo module, basic CRUD operations

### Schemas and Changesets
3. **[03_schemas.exs](03_schemas.exs)** - Defining schemas, field types
4. **[04_embedded_schemas.exs](04_embedded_schemas.exs)** - Embedded schemas, schemaless operations
5. **[05_changesets_intro.exs](05_changesets_intro.exs)** - Changesets, cast, validate
6. **[06_changeset_validations.exs](06_changeset_validations.exs)** - Built-in validations
7. **[07_custom_validations.exs](07_custom_validations.exs)** - Writing custom validators

### Migrations
8. **[08_migrations_basics.exs](08_migrations_basics.exs)** - Creating tables, columns
9. **[09_migrations_advanced.exs](09_migrations_advanced.exs)** - Indexes, constraints, references
10. **[10_migrations_data.exs](10_migrations_data.exs)** - Data migrations, best practices

### Queries
11. **[11_query_basics.exs](11_query_basics.exs)** - from, select, where
12. **[12_query_composition.exs](12_query_composition.exs)** - Composing queries, query functions
13. **[13_query_joins.exs](13_query_joins.exs)** - Joins, preloading associations
14. **[14_query_aggregates.exs](14_query_aggregates.exs)** - count, sum, avg, group_by
15. **[15_raw_sql.exs](15_raw_sql.exs)** - Ecto.Adapters.SQL, fragments

### Associations
16. **[16_belongs_to_has.exs](16_belongs_to_has.exs)** - belongs_to, has_one, has_many
17. **[17_many_to_many.exs](17_many_to_many.exs)** - many_to_many, join tables
18. **[18_association_operations.exs](18_association_operations.exs)** - Building, casting, preloading

### Advanced Ecto
19. **[19_transactions.exs](19_transactions.exs)** - Repo.transaction, Multi
20. **[20_ecto_multi.exs](20_ecto_multi.exs)** - Complex multi-step operations
21. **[21_upserts.exs](21_upserts.exs)** - on_conflict, upsert patterns
22. **[22_soft_deletes.exs](22_soft_deletes.exs)** - Implementing soft deletes

### Project
- **[project_inventory/](project_inventory/)** - Full Ecto application with complex relationships

## Ecto Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Your Application                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Schema ──────► Changeset ──────► Repo ──────► Database    │
│   (struct)       (validation)      (queries)    (PostgreSQL) │
│                                                              │
│   ┌─────────┐    ┌───────────┐    ┌──────┐    ┌──────────┐ │
│   │ User    │    │ Changeset │    │ Repo │    │ users    │ │
│   │ struct  │───►│ validate  │───►│.insert│───►│ table    │ │
│   └─────────┘    └───────────┘    └──────┘    └──────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Key Concepts

- **Repository** - The interface to your database
- **Schema** - Maps database tables to Elixir structs
- **Changeset** - Tracks and validates changes to data
- **Migration** - Version-controlled database changes
- **Query** - Composable database queries

## Running Lessons

Most Ecto lessons require a database. See individual lesson files for setup instructions.

```bash
# Create the database
mix ecto.create

# Run migrations
mix ecto.migrate

# Run in IEx with your app
iex -S mix
```

## Time Estimate

- Lessons: 12-16 hours
- Exercises: 6-8 hours
- Project: 6-8 hours
- **Total: 24-32 hours**

## Next Section

After completing this section, proceed to [05_phoenix_fundamentals](../05_phoenix_fundamentals/).
