# Elixir/Phoenix/Ecto Complete Curriculum

A comprehensive, hands-on curriculum for mastering Elixir, Phoenix, Ecto, and the BEAM ecosystem. Each lesson is a standalone, runnable file with extensive comments and practical exercises.

---

## Curriculum Overview

### Prerequisites
- Basic programming knowledge (any language)
- Command line familiarity
- Git basics
- A code editor (VS Code with ElixirLS recommended)

### What You'll Build
By the end of this curriculum, you'll have built:
- A CLI task management tool (Elixir fundamentals)
- A GenServer-based chat system (OTP)
- A database-backed inventory system (Ecto)
- A full-stack blog application (Phoenix)
- A real-time collaborative editor (LiveView)
- A production-ready API with authentication

---

## Section 1: Elixir Fundamentals (01_elixir_fundamentals/)

### 1.1 Getting Started
- **01_hello_elixir.exs** - Your first Elixir program, IEx basics
- **02_basic_types.exs** - Integers, floats, atoms, strings, booleans
- **03_operators.exs** - Arithmetic, comparison, boolean, string operators
- **README.md** - Section overview and setup instructions

### 1.2 Collections
- **04_lists.exs** - Lists, head/tail, list operators
- **05_tuples.exs** - Tuples, when to use tuples vs lists
- **06_keyword_lists.exs** - Keyword lists, options patterns
- **07_maps.exs** - Maps, accessing values, updating maps
- **08_structs.exs** - Defining and using structs

### 1.3 Control Flow
- **09_pattern_matching.exs** - The = operator, destructuring, pin operator
- **10_case.exs** - Case statements, guards
- **11_cond.exs** - Cond expressions
- **12_if_unless.exs** - If/unless, truthy/falsy values
- **13_with.exs** - With expressions for happy path

### 1.4 Functions
- **14_anonymous_functions.exs** - fn, &, capture operator
- **15_named_functions.exs** - def, defp, default arguments
- **16_function_clauses.exs** - Multiple function heads, guards
- **17_recursion.exs** - Recursive thinking, tail recursion
- **18_pipe_operator.exs** - |> and data transformation pipelines

### 1.5 Modules
- **19_modules_basics.exs** - defmodule, module attributes
- **20_import_alias_require.exs** - Code organization
- **21_module_behaviours.exs** - Defining and implementing behaviours
- **22_protocols.exs** - Polymorphism with protocols

### Project: CLI Task Manager
- **project_task_manager/** - Complete CLI application

---

## Section 2: Intermediate Elixir (02_intermediate_elixir/)

### 2.1 Enumerables and Streams
- **01_enum_basics.exs** - map, filter, reduce fundamentals
- **02_enum_advanced.exs** - group_by, frequencies, zip, chunk
- **03_streams.exs** - Lazy evaluation, infinite streams
- **04_comprehensions.exs** - for comprehensions, filters, into

### 2.2 Working with Data
- **05_strings_deep.exs** - Unicode, binaries, String module
- **06_sigils.exs** - ~r, ~w, ~s, custom sigils
- **07_date_time.exs** - Date, Time, DateTime, NaiveDateTime
- **08_regex.exs** - Pattern matching with regex

### 2.3 Error Handling
- **09_try_rescue.exs** - Exceptions, try/rescue/after
- **10_throw_catch.exs** - throw/catch (and why to avoid)
- **11_error_tuples.exs** - {:ok, value} / {:error, reason} patterns
- **12_with_error_handling.exs** - Combining with and error handling

### 2.4 Metaprogramming Basics
- **13_quote_unquote.exs** - AST basics, quote and unquote
- **14_macros_intro.exs** - Writing simple macros
- **15_use_macro.exs** - The __using__ macro pattern

### 2.5 Working with Files and IO
- **16_file_operations.exs** - Reading, writing, streaming files
- **17_io_basics.exs** - IO.puts, IO.inspect, formatting
- **18_path_operations.exs** - Path module, file system navigation

### Project: Log File Analyzer
- **project_log_analyzer/** - Stream-based log processing tool

---

## Section 3: OTP and Concurrency (03_otp_concurrency/)

### 3.1 Processes
- **01_spawn_basics.exs** - spawn, spawn_link, process basics
- **02_message_passing.exs** - send, receive, mailboxes
- **03_process_state.exs** - Maintaining state with recursion
- **04_process_links.exs** - Links, monitors, trapping exits

### 3.2 GenServer
- **05_genserver_intro.exs** - Your first GenServer
- **06_genserver_callbacks.exs** - init, handle_call, handle_cast, handle_info
- **07_genserver_state.exs** - State management patterns
- **08_genserver_testing.exs** - Testing GenServers

### 3.3 Supervision
- **09_supervisor_basics.exs** - Supervisor behaviour, child specs
- **10_supervision_strategies.exs** - one_for_one, one_for_all, rest_for_one
- **11_dynamic_supervisors.exs** - DynamicSupervisor for runtime children
- **12_supervision_trees.exs** - Building supervision trees

### 3.4 Other OTP Behaviours
- **13_agent.exs** - Simple state with Agent
- **14_task.exs** - Async operations with Task
- **15_task_supervisor.exs** - Supervised async tasks
- **16_genstatem.exs** - State machines with GenStateMachine
- **17_registry.exs** - Process registration and discovery

### 3.5 Advanced Concurrency
- **18_ets_basics.exs** - ETS tables for shared state
- **19_ets_advanced.exs** - ETS patterns, concurrent access
- **20_distributed_basics.exs** - Connecting nodes, distributed Elixir

### Project: Chat System
- **project_chat_system/** - Multi-room chat with GenServers and supervision

---

## Section 4: Ecto Fundamentals (04_ecto/)

### 4.1 Setup and Basics
- **01_ecto_setup.exs** - Installing Ecto, repo configuration
- **02_repo_basics.exs** - Repo module, basic operations
- **README.md** - Database setup instructions (PostgreSQL)

### 4.2 Schemas and Changesets
- **03_schemas.exs** - Defining schemas, field types
- **04_embedded_schemas.exs** - Embedded schemas, schemaless operations
- **05_changesets_intro.exs** - Changesets, cast, validate
- **06_changeset_validations.exs** - Built-in validations
- **07_custom_validations.exs** - Writing custom validators

### 4.3 Migrations
- **08_migrations_basics.exs** - Creating tables, columns
- **09_migrations_advanced.exs** - Indexes, constraints, references
- **10_migrations_data.exs** - Data migrations, best practices

### 4.4 Queries
- **11_query_basics.exs** - from, select, where
- **12_query_composition.exs** - Composing queries, query functions
- **13_query_joins.exs** - Joins, preloading associations
- **14_query_aggregates.exs** - count, sum, avg, group_by
- **15_raw_sql.exs** - Ecto.Adapters.SQL, fragments

### 4.5 Associations
- **16_belongs_to_has.exs** - belongs_to, has_one, has_many
- **17_many_to_many.exs** - many_to_many, join tables
- **18_association_operations.exs** - Building, casting, preloading

### 4.6 Advanced Ecto
- **19_transactions.exs** - Repo.transaction, Multi
- **20_ecto_multi.exs** - Complex multi-step operations
- **21_upserts.exs** - on_conflict, upsert patterns
- **22_soft_deletes.exs** - Implementing soft deletes

### Project: Inventory System
- **project_inventory/** - Full Ecto application with complex relationships

---

## Section 5: Phoenix Fundamentals (05_phoenix_fundamentals/)

### 5.1 Getting Started
- **01_phoenix_new.md** - Creating a Phoenix project
- **02_project_structure.md** - Understanding the directory structure
- **03_phoenix_server.md** - Starting the server, configuration

### 5.2 Routing
- **04_router_basics.exs** - Routes, resources, path helpers
- **05_router_pipelines.exs** - Pipelines, plugs in router
- **06_nested_routes.exs** - Scopes, nested resources

### 5.3 Controllers
- **07_controller_basics.exs** - Actions, params, rendering
- **08_controller_plugs.exs** - Plugs in controllers
- **09_controller_patterns.exs** - Common controller patterns

### 5.4 Views and Templates
- **10_views_basics.exs** - View modules, helpers
- **11_templates_heex.exs** - HEEx templates, components
- **12_layouts.exs** - Application layouts, nested layouts

### 5.5 Contexts
- **13_contexts_intro.exs** - Designing bounded contexts
- **14_context_generators.exs** - phx.gen.context, phx.gen.html
- **15_context_patterns.exs** - Context best practices

### 5.6 The Plug Pipeline
- **16_plug_basics.exs** - Understanding Plug
- **17_custom_plugs.exs** - Writing custom plugs
- **18_plug_builder.exs** - Plug.Builder, composing plugs

### Project: Blog Application (Part 1)
- **project_blog/** - Basic CRUD blog with Phoenix

---

## Section 6: Phoenix Advanced (06_phoenix_advanced/)

### 6.1 Authentication
- **01_auth_overview.md** - Authentication strategies
- **02_phx_gen_auth.exs** - Using phx.gen.auth
- **03_session_auth.exs** - Session-based authentication
- **04_token_auth.exs** - Token/API authentication
- **05_oauth_basics.exs** - OAuth integration (Ueberauth)

### 6.2 Authorization
- **06_authorization_patterns.exs** - Role-based access control
- **07_policy_modules.exs** - Building authorization policies
- **08_bodyguard.exs** - Using Bodyguard library

### 6.3 JSON APIs
- **09_api_basics.exs** - JSON rendering, API pipelines
- **10_api_versioning.exs** - API versioning strategies
- **11_api_documentation.exs** - OpenAPI/Swagger docs
- **12_graphql_intro.exs** - Absinthe basics

### 6.4 Background Jobs
- **13_oban_setup.exs** - Setting up Oban
- **14_oban_workers.exs** - Creating workers
- **15_oban_scheduling.exs** - Scheduled jobs, cron
- **16_oban_testing.exs** - Testing Oban workers

### 6.5 Email
- **17_swoosh_setup.exs** - Configuring Swoosh
- **18_email_templates.exs** - Email layouts and templates
- **19_email_delivery.exs** - Sending emails, adapters

### 6.6 File Uploads
- **20_upload_basics.exs** - Handling file uploads
- **21_direct_uploads.exs** - Direct to S3 uploads
- **22_image_processing.exs** - Image manipulation

### Project: Blog Application (Part 2)
- **project_blog_advanced/** - Blog with auth, comments, admin

---

## Section 7: Phoenix LiveView (07_liveview/)

### 7.1 LiveView Basics
- **01_liveview_intro.exs** - Your first LiveView
- **02_lifecycle.exs** - mount, handle_event, handle_info
- **03_assigns.exs** - Managing assigns, socket state

### 7.2 Events and Interactivity
- **04_click_events.exs** - phx-click, phx-submit
- **05_form_events.exs** - phx-change, form handling
- **06_key_events.exs** - phx-keydown, phx-keyup
- **07_focus_blur.exs** - phx-focus, phx-blur

### 7.3 Components
- **08_function_components.exs** - Stateless function components
- **09_live_components.exs** - Stateful LiveComponents
- **10_component_slots.exs** - Slots, inner blocks

### 7.4 Navigation
- **11_live_navigation.exs** - live_patch, live_redirect
- **12_handle_params.exs** - URL params in LiveView
- **13_live_sessions.exs** - Sharing data across LiveViews

### 7.5 Real-time Features
- **14_pubsub_basics.exs** - Phoenix.PubSub integration
- **15_presence.exs** - Phoenix.Presence for tracking users
- **16_live_uploads.exs** - Drag-and-drop file uploads

### 7.6 Advanced LiveView
- **17_streams.exs** - Efficient large list handling
- **18_async_operations.exs** - assign_async, start_async
- **19_hooks.exs** - JavaScript hooks
- **20_testing_liveview.exs** - Testing LiveViews

### Project: Collaborative Editor
- **project_collab_editor/** - Real-time collaborative document editor

---

## Section 8: Testing (08_testing/)

### 8.1 ExUnit Basics
- **01_exunit_intro.exs** - Test modules, assertions
- **02_test_organization.exs** - describe, setup, tags
- **03_assertions.exs** - assert, refute, assert_raise

### 8.2 Testing Patterns
- **04_testing_functions.exs** - Unit testing pure functions
- **05_testing_genservers.exs** - Testing GenServers
- **06_testing_async.exs** - Testing async code

### 8.3 Testing with Ecto
- **07_ecto_sandbox.exs** - DataCase, async tests
- **08_factories.exs** - ExMachina factories
- **09_testing_queries.exs** - Testing Ecto queries

### 8.4 Testing Phoenix
- **10_conn_testing.exs** - ConnCase, controller tests
- **11_view_testing.exs** - Testing views and helpers
- **12_channel_testing.exs** - Testing Phoenix channels

### 8.5 Testing LiveView
- **13_liveview_testing.exs** - LiveViewTest basics
- **14_component_testing.exs** - Testing components
- **15_integration_tests.exs** - End-to-end LiveView tests

### 8.6 Advanced Testing
- **16_mocking.exs** - Mox, dependency injection
- **17_property_testing.exs** - StreamData, property-based testing
- **18_test_coverage.exs** - Coverage analysis

### Project: Test Suite
- **project_test_suite/** - Comprehensive test examples

---

## Section 9: Deployment and Production (09_deployment/)

### 9.1 Releases
- **01_mix_release.exs** - Building releases
- **02_release_config.exs** - Runtime configuration
- **03_release_commands.exs** - Running migrations, custom commands

### 9.2 Docker
- **04_dockerfile.md** - Multi-stage Dockerfile
- **05_docker_compose.md** - Local development with Docker
- **06_docker_production.md** - Production Docker setup

### 9.3 Cloud Deployment
- **07_fly_io.md** - Deploying to Fly.io
- **08_gigalixir.md** - Deploying to Gigalixir
- **09_aws_ecs.md** - AWS ECS deployment
- **10_kubernetes.md** - Kubernetes basics

### 9.4 Production Concerns
- **11_environment_config.md** - Managing configurations
- **12_logging.md** - Structured logging, Logger
- **13_monitoring.md** - Telemetry, metrics, dashboards
- **14_error_tracking.md** - Sentry, error reporting

### 9.5 Performance
- **15_profiling.exs** - Profiling tools, :observer
- **16_benchmarking.exs** - Benchee, performance testing
- **17_caching.exs** - Caching strategies, Cachex
- **18_database_performance.md** - Query optimization, indexes

### 9.6 Security
- **19_security_checklist.md** - OWASP top 10 for Phoenix
- **20_ssl_tls.md** - HTTPS configuration
- **21_secrets_management.md** - Managing secrets

### Project: Production Deployment
- **project_deployment/** - Complete deployment pipeline

---

## Appendices (appendices/)

### A. Development Environment
- **a1_install_elixir.md** - Installing Elixir and Erlang
- **a2_editor_setup.md** - VS Code, Neovim setup
- **a3_iex_tips.md** - IEx productivity tips

### B. Tools and Libraries
- **b1_mix_tasks.md** - Common mix tasks
- **b2_hex_packages.md** - Essential Hex packages
- **b3_debugging.md** - Debugging techniques

### C. Resources
- **c1_books.md** - Recommended books
- **c2_community.md** - Forums, Discord, conferences
- **c3_advanced_topics.md** - Topics for further study

---

## How to Use This Curriculum

### For Self-Study
1. Work through sections in order (1-9)
2. Run each `.exs` file to see concepts in action
3. Complete all exercises before moving on
4. Build each section's project
5. Estimated time: 8-12 weeks at 10-15 hours/week

### For Teaching
- Each section is ~1 week of material
- Projects can be homework assignments
- Exercises include varying difficulty levels
- All code is classroom-ready

### Running Examples
```bash
# Run a single lesson
elixir 01_elixir_fundamentals/01_hello_elixir.exs

# Run in IEx for experimentation
iex 01_elixir_fundamentals/01_hello_elixir.exs

# Run project tests
cd 03_otp_concurrency/project_chat_system
mix test
```

---

## Contributing

This curriculum is open source. Contributions welcome:
- Fix errors or typos
- Add exercises
- Improve explanations
- Translate to other languages

---

## License

MIT License - Use freely for learning and teaching.
