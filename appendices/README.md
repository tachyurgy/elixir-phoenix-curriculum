# Appendices

Supplementary materials, tools, and resources for your Elixir journey.

## Contents

### A. Development Environment
- **[a1_install_elixir.md](a1_install_elixir.md)** - Installing Elixir and Erlang
- **[a2_editor_setup.md](a2_editor_setup.md)** - VS Code, Neovim setup
- **[a3_iex_tips.md](a3_iex_tips.md)** - IEx productivity tips

### B. Tools and Libraries
- **[b1_mix_tasks.md](b1_mix_tasks.md)** - Common mix tasks
- **[b2_hex_packages.md](b2_hex_packages.md)** - Essential Hex packages
- **[b3_debugging.md](b3_debugging.md)** - Debugging techniques

### C. Resources
- **[c1_books.md](c1_books.md)** - Recommended books
- **[c2_community.md](c2_community.md)** - Forums, Discord, conferences
- **[c3_advanced_topics.md](c3_advanced_topics.md)** - Topics for further study

## Quick References

### Common Mix Tasks

```bash
# Project
mix new my_app          # Create new project
mix new my_app --sup    # With supervision tree
mix deps.get            # Fetch dependencies
mix compile             # Compile project
mix format              # Format code

# Testing
mix test                # Run tests
mix test --cover        # With coverage
mix test --trace        # Verbose output

# Ecto
mix ecto.create         # Create database
mix ecto.migrate        # Run migrations
mix ecto.rollback       # Rollback migration
mix ecto.reset          # Drop, create, migrate

# Phoenix
mix phx.new my_app      # New Phoenix project
mix phx.server          # Start server
mix phx.routes          # Show routes
mix phx.gen.html        # Generate HTML resource
mix phx.gen.json        # Generate JSON resource
mix phx.gen.live        # Generate LiveView
mix phx.gen.auth        # Generate authentication
```

### Essential Hex Packages

| Package | Purpose |
|---------|---------|
| `phoenix` | Web framework |
| `ecto_sql` | Database wrapper |
| `oban` | Background jobs |
| `swoosh` | Email |
| `ex_machina` | Test factories |
| `mox` | Mocking |
| `credo` | Code analysis |
| `dialyxir` | Type checking |
| `ex_doc` | Documentation |
| `benchee` | Benchmarking |

### IEx Helpers

```elixir
# Help
h()                     # General help
h(Enum)                 # Module help
h(Enum.map)             # Function help

# Information
i(value)                # Inspect value type
exports(Module)         # Module exports

# Compilation
c("file.ex")            # Compile file
r(Module)               # Recompile module
recompile()             # Recompile project

# History
v()                     # Last value
v(n)                    # Value from line n
```

### Debugging

```elixir
# IO inspection
IO.inspect(value, label: "debug")
value |> IO.inspect(label: "pipeline")

# IEx breakpoints
require IEx; IEx.pry()

# Debugger
:debugger.start()
:int.ni(Module)
:int.break(Module, line)

# Observer
:observer.start()
```

## Curriculum Statistics

| Section | Lessons | Estimated Hours |
|---------|---------|-----------------|
| 01 - Elixir Fundamentals | 22 | 16-24 |
| 02 - Intermediate Elixir | 18 | 19-27 |
| 03 - OTP & Concurrency | 20 | 26-34 |
| 04 - Ecto | 22 | 24-32 |
| 05 - Phoenix Fundamentals | 18 | 21-29 |
| 06 - Phoenix Advanced | 22 | 28-36 |
| 07 - LiveView | 20 | 28-36 |
| 08 - Testing | 18 | 19-27 |
| 09 - Deployment | 21 | 23-31 |
| **Total** | **181** | **204-276** |

## Learning Path Alternatives

### Fast Track (Essentials Only)
- 01: Lessons 1-13, 17-18
- 03: Lessons 1-8
- 04: Lessons 1-6, 11-13
- 05: Lessons 1-12
- 07: Lessons 1-10
- Estimated: 80-100 hours

### API Developer Focus
- 01: Complete
- 02: Lessons 1-4, 9-12
- 03: Lessons 1-12
- 04: Complete
- 05: Lessons 1-9
- 06: Lessons 9-12
- 08: Lessons 1-9
- 09: Lessons 1-6, 11-14
- Estimated: 150-180 hours

### Full-Stack Focus
- Complete all sections
- Extra emphasis on 05, 06, 07
- Estimated: 204-276 hours

## What's Next?

After completing this curriculum:

1. **Build Projects** - Apply your skills to real projects
2. **Contribute** - Participate in open source
3. **Specialize** - Deep dive into areas of interest
4. **Connect** - Join the Elixir community
5. **Keep Learning** - Explore advanced topics

## Advanced Topics for Further Study

- Distributed systems with libcluster
- NIFs (Native Implemented Functions)
- Nerves for embedded systems
- Broadway for data pipelines
- Membrane for multimedia
- Nx for machine learning
- LiveBook for interactive notebooks

Good luck on your Elixir journey!
