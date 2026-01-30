# Section 5: Phoenix Fundamentals

Learn Phoenix, the productive web framework for Elixir. Build fast, maintainable web applications.

## What You'll Learn

- Phoenix project structure
- Routing and URL generation
- Controllers and actions
- Views and HEEx templates
- Contexts for business logic
- The Plug pipeline

## Prerequisites

- Sections 1-4 completed
- Ecto basics understood
- Basic web development concepts (HTTP, HTML)

## Setup

```bash
# Install Phoenix
mix archive.install hex phx_new

# Create a new Phoenix project
mix phx.new my_app

# Setup and start
cd my_app
mix setup
mix phx.server
```

## Lessons

### Getting Started
1. **[01_phoenix_new.md](01_phoenix_new.md)** - Creating a Phoenix project
2. **[02_project_structure.md](02_project_structure.md)** - Understanding the directory structure
3. **[03_phoenix_server.md](03_phoenix_server.md)** - Starting the server, configuration

### Routing
4. **[04_router_basics.exs](04_router_basics.exs)** - Routes, resources, path helpers
5. **[05_router_pipelines.exs](05_router_pipelines.exs)** - Pipelines, plugs in router
6. **[06_nested_routes.exs](06_nested_routes.exs)** - Scopes, nested resources

### Controllers
7. **[07_controller_basics.exs](07_controller_basics.exs)** - Actions, params, rendering
8. **[08_controller_plugs.exs](08_controller_plugs.exs)** - Plugs in controllers
9. **[09_controller_patterns.exs](09_controller_patterns.exs)** - Common controller patterns

### Views and Templates
10. **[10_views_basics.exs](10_views_basics.exs)** - View modules, helpers
11. **[11_templates_heex.exs](11_templates_heex.exs)** - HEEx templates, components
12. **[12_layouts.exs](12_layouts.exs)** - Application layouts, nested layouts

### Contexts
13. **[13_contexts_intro.exs](13_contexts_intro.exs)** - Designing bounded contexts
14. **[14_context_generators.exs](14_context_generators.exs)** - phx.gen.context, phx.gen.html
15. **[15_context_patterns.exs](15_context_patterns.exs)** - Context best practices

### The Plug Pipeline
16. **[16_plug_basics.exs](16_plug_basics.exs)** - Understanding Plug
17. **[17_custom_plugs.exs](17_custom_plugs.exs)** - Writing custom plugs
18. **[18_plug_builder.exs](18_plug_builder.exs)** - Plug.Builder, composing plugs

### Project
- **[project_blog/](project_blog/)** - Basic CRUD blog with Phoenix

## Phoenix Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Request Flow                              │
│                                                                  │
│  Browser ──► Endpoint ──► Router ──► Pipeline ──► Controller    │
│                                         │              │         │
│                                       Plugs          Action      │
│                                                        │         │
│                              Context ◄─────────────────┘         │
│                                 │                                │
│                              Schema                              │
│                                 │                                │
│                             Database                             │
└─────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
my_app/
├── lib/
│   ├── my_app/              # Business logic (Contexts)
│   │   ├── accounts.ex      # Accounts context
│   │   └── accounts/        # Accounts schemas
│   ├── my_app_web/          # Web layer
│   │   ├── controllers/     # Handle requests
│   │   ├── components/      # HEEx components
│   │   ├── router.ex        # Route definitions
│   │   └── endpoint.ex      # HTTP entry point
│   └── my_app.ex            # Application entry
├── priv/
│   ├── repo/migrations/     # Database migrations
│   └── static/              # Static assets
└── test/                    # Tests
```

## Key Concepts

- **Endpoint** - Entry point for HTTP requests
- **Router** - Maps URLs to controllers
- **Pipeline** - A series of plugs to process requests
- **Controller** - Handles requests, calls contexts
- **Context** - Business logic module
- **View/Component** - Renders responses

## Running Lessons

```bash
# Start Phoenix server
mix phx.server

# Start with IEx
iex -S mix phx.server

# Run generators
mix phx.gen.html Accounts User users name:string email:string
```

## Time Estimate

- Lessons: 10-14 hours
- Exercises: 5-7 hours
- Project: 6-8 hours
- **Total: 21-29 hours**

## Next Section

After completing this section, proceed to [06_phoenix_advanced](../06_phoenix_advanced/).
