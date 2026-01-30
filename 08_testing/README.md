# Section 8: Testing

Master testing in Elixir with ExUnit. Learn to write reliable, maintainable tests for all parts of your application.

## What You'll Learn

- ExUnit fundamentals
- Testing pure functions
- Testing GenServers and processes
- Testing Ecto queries
- Testing Phoenix controllers and views
- Testing LiveView
- Advanced testing techniques

## Prerequisites

- Sections 1-7 completed
- Understanding of the code being tested
- Basic testing concepts

## Lessons

### ExUnit Basics
1. **[01_exunit_intro.exs](01_exunit_intro.exs)** - Test modules, assertions
2. **[02_test_organization.exs](02_test_organization.exs)** - describe, setup, tags
3. **[03_assertions.exs](03_assertions.exs)** - assert, refute, assert_raise

### Testing Patterns
4. **[04_testing_functions.exs](04_testing_functions.exs)** - Unit testing pure functions
5. **[05_testing_genservers.exs](05_testing_genservers.exs)** - Testing GenServers
6. **[06_testing_async.exs](06_testing_async.exs)** - Testing async code

### Testing with Ecto
7. **[07_ecto_sandbox.exs](07_ecto_sandbox.exs)** - DataCase, async tests
8. **[08_factories.exs](08_factories.exs)** - ExMachina factories
9. **[09_testing_queries.exs](09_testing_queries.exs)** - Testing Ecto queries

### Testing Phoenix
10. **[10_conn_testing.exs](10_conn_testing.exs)** - ConnCase, controller tests
11. **[11_view_testing.exs](11_view_testing.exs)** - Testing views and helpers
12. **[12_channel_testing.exs](12_channel_testing.exs)** - Testing Phoenix channels

### Testing LiveView
13. **[13_liveview_testing.exs](13_liveview_testing.exs)** - LiveViewTest basics
14. **[14_component_testing.exs](14_component_testing.exs)** - Testing components
15. **[15_integration_tests.exs](15_integration_tests.exs)** - End-to-end LiveView tests

### Advanced Testing
16. **[16_mocking.exs](16_mocking.exs)** - Mox, dependency injection
17. **[17_property_testing.exs](17_property_testing.exs)** - StreamData, property-based testing
18. **[18_test_coverage.exs](18_test_coverage.exs)** - Coverage analysis

### Project
- **[project_test_suite/](project_test_suite/)** - Comprehensive test examples

## Test Organization

```
test/
├── support/
│   ├── conn_case.ex        # ConnCase for controller tests
│   ├── data_case.ex        # DataCase for database tests
│   ├── fixtures/           # Test fixtures
│   └── factory.ex          # ExMachina factories
├── my_app/
│   ├── accounts_test.exs   # Context tests
│   └── repo_test.exs       # Repo tests
├── my_app_web/
│   ├── controllers/        # Controller tests
│   ├── live/               # LiveView tests
│   └── views/              # View tests
└── test_helper.exs         # Test configuration
```

## Test Types

```
┌─────────────────────────────────────────────────────────────┐
│                    Testing Pyramid                           │
│                                                              │
│                        ▲                                    │
│                       /│\         E2E Tests                 │
│                      / │ \        (Few, Slow)               │
│                     /  │  \                                 │
│                    /───┼───\                                │
│                   /    │    \     Integration Tests         │
│                  /     │     \    (Some, Medium)            │
│                 /──────┼──────\                             │
│                /       │       \   Unit Tests               │
│               /        │        \  (Many, Fast)             │
│              /─────────┼─────────\                          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Key Concepts

- **Unit Tests** - Test individual functions
- **Integration Tests** - Test components together
- **DataCase** - Tests that touch the database
- **ConnCase** - Tests that use HTTP connections
- **Factories** - Generate test data
- **Mocks** - Replace dependencies

## Common Assertions

```elixir
# Basic assertions
assert value
refute value
assert value == expected
assert value =~ "pattern"

# Exception assertions
assert_raise RuntimeError, fn -> ... end
assert_raise RuntimeError, "message", fn -> ... end

# Receive assertions (for processes)
assert_receive message, timeout
assert_received message
refute_receive message, timeout
```

## Running Tests

```bash
# Run all tests
mix test

# Run specific file
mix test test/my_app/accounts_test.exs

# Run specific test
mix test test/my_app/accounts_test.exs:42

# Run with tag
mix test --only integration

# Run with coverage
mix test --cover
```

## Time Estimate

- Lessons: 10-14 hours
- Exercises: 5-7 hours
- Project: 4-6 hours
- **Total: 19-27 hours**

## Next Section

After completing this section, proceed to [09_deployment](../09_deployment/).
