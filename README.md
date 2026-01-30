# Elixir/Phoenix/Ecto Complete Curriculum

A comprehensive, hands-on curriculum for mastering Elixir, Phoenix, Ecto, and the BEAM ecosystem. From first steps to production deployment.

## What You'll Learn

- **Elixir Fundamentals** - Functional programming, pattern matching, processes
- **OTP & Concurrency** - GenServers, Supervisors, fault-tolerant systems
- **Ecto** - Database layer, schemas, queries, migrations
- **Phoenix** - Web framework, MVC, routing, controllers
- **LiveView** - Real-time, interactive UIs without JavaScript
- **Testing** - ExUnit, property testing, comprehensive test strategies
- **Deployment** - Releases, Docker, cloud deployment, production concerns

## Quick Start

### Prerequisites

1. **Install Elixir** (1.15+)
   ```bash
   # macOS with Homebrew
   brew install elixir

   # Or use asdf for version management
   asdf install elixir 1.16.0
   ```

2. **Install PostgreSQL** (for Ecto and Phoenix sections)
   ```bash
   brew install postgresql@16
   brew services start postgresql@16
   ```

3. **Clone this repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/elixir-phoenix-curriculum.git
   cd elixir-phoenix-curriculum
   ```

### Running Your First Lesson

```bash
# Run a lesson file
elixir 01_elixir_fundamentals/01_hello_elixir.exs

# Or use IEx for interactive exploration
iex 01_elixir_fundamentals/01_hello_elixir.exs
```

## Curriculum Structure

| Section | Topics | Time Estimate |
|---------|--------|---------------|
| **01 - Elixir Fundamentals** | Types, pattern matching, functions, modules | Week 1-2 |
| **02 - Intermediate Elixir** | Enumerables, streams, error handling, metaprogramming | Week 2-3 |
| **03 - OTP & Concurrency** | Processes, GenServer, Supervisors, ETS | Week 3-4 |
| **04 - Ecto** | Schemas, queries, migrations, associations | Week 4-5 |
| **05 - Phoenix Fundamentals** | Routing, controllers, views, contexts | Week 5-6 |
| **06 - Phoenix Advanced** | Auth, APIs, background jobs, email | Week 6-7 |
| **07 - LiveView** | Real-time UIs, components, PubSub | Week 7-8 |
| **08 - Testing** | ExUnit, Ecto tests, Phoenix tests, mocking | Week 8-9 |
| **09 - Deployment** | Releases, Docker, cloud, monitoring | Week 9-10 |

See [CURRICULUM.md](CURRICULUM.md) for the complete detailed curriculum.

## How to Use This Curriculum

### Each Lesson File (.exs)

- **Self-contained**: Run independently with `elixir filename.exs`
- **Heavily commented**: Every concept is explained
- **Produces output**: See results as you learn
- **Includes exercises**: Practice what you've learned

### Each Section

- **README.md**: Overview and learning path
- **Numbered lessons**: Follow in order
- **Project**: Capstone project applying section concepts

### Recommended Approach

1. Read through the lesson file
2. Run it and observe the output
3. Experiment in IEx
4. Complete the exercises
5. Move to the next lesson
6. Build the section project

## Projects You'll Build

Throughout the curriculum, you'll build progressively complex projects:

1. **CLI Task Manager** (Elixir) - Command-line todo app
2. **Log Analyzer** (Streams) - Process large log files efficiently
3. **Chat System** (OTP) - Multi-room chat with GenServers
4. **Inventory System** (Ecto) - Database-backed inventory management
5. **Blog Application** (Phoenix) - Full-stack web app
6. **Collaborative Editor** (LiveView) - Real-time document editing
7. **Production API** (Deployment) - Deployed, monitored application

## Development Environment

### Recommended Setup

- **Editor**: VS Code with [ElixirLS](https://github.com/elixir-lsp/elixir-ls) extension
- **Terminal**: Any modern terminal (iTerm2, Warp, Alacritty)
- **Database**: PostgreSQL 14+
- **Version Manager**: asdf for Elixir/Erlang versions

### Helpful Tools

```bash
# Format all Elixir code
mix format

# Run IEx with history
iex --erl "-kernel shell_history enabled"

# Get mix help
mix help
```

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

- Report issues or errors
- Suggest improvements
- Add exercises
- Improve explanations
- Translate content

## Resources

### Official Documentation
- [Elixir Guides](https://elixir-lang.org/getting-started/introduction.html)
- [Phoenix Documentation](https://hexdocs.pm/phoenix)
- [Ecto Documentation](https://hexdocs.pm/ecto)
- [LiveView Documentation](https://hexdocs.pm/phoenix_live_view)

### Community
- [Elixir Forum](https://elixirforum.com)
- [Elixir Discord](https://discord.gg/elixir)
- [Elixir Slack](https://elixir-slackin.herokuapp.com)

### Books
- *Programming Elixir* by Dave Thomas
- *Elixir in Action* by Saša Jurić
- *Programming Phoenix LiveView* by Bruce Tate & Sophie DeBenedetto

## License

MIT License - Use freely for learning and teaching.

---

**Start learning**: [01_elixir_fundamentals/README.md](01_elixir_fundamentals/README.md)
