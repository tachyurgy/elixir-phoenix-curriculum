# CLAUDE.md - AI Assistant Guidelines for Elixir Curriculum

This file provides context and guidelines for AI assistants (like Claude) working on this repository.

## Project Overview

This is a comprehensive, hands-on curriculum for learning Elixir, Phoenix, Ecto, and the BEAM ecosystem. The curriculum is designed to take learners from zero to production-ready.

### Repository Structure

```
elixir-phoenix-curriculum/
├── CLAUDE.md                    # This file - AI assistant guidelines
├── CURRICULUM.md                # Complete curriculum overview
├── README.md                    # Project introduction
├── 01_elixir_fundamentals/      # Section 1: Elixir basics
├── 02_intermediate_elixir/      # Section 2: Intermediate concepts
├── 03_otp_concurrency/          # Section 3: OTP and concurrency
├── 04_ecto/                     # Section 4: Ecto database layer
├── 05_phoenix_fundamentals/     # Section 5: Phoenix basics
├── 06_phoenix_advanced/         # Section 6: Advanced Phoenix
├── 07_liveview/                 # Section 7: Phoenix LiveView
├── 08_testing/                  # Section 8: Testing strategies
├── 09_deployment/               # Section 9: Production deployment
└── appendices/                  # Additional resources
```

## File Conventions

### Lesson Files (.exs)

Each `.exs` lesson file follows this structure:

```elixir
# ============================================================================
# Lesson Title
# ============================================================================
#
# Learning Objectives:
# - Objective 1
# - Objective 2
#
# Prerequisites:
# - Previous lesson or concept
#
# ============================================================================

# -----------------------------------------------------------------------------
# Section 1: Introduction
# -----------------------------------------------------------------------------

# Explanation of the concept...

# Code example
example = "value"
IO.puts(example)

# -----------------------------------------------------------------------------
# Section 2: Core Concepts
# -----------------------------------------------------------------------------

# More detailed explanation...

# Interactive example that produces output
defmodule Example do
  def demo do
    # Implementation
  end
end

Example.demo()

# -----------------------------------------------------------------------------
# Exercises
# -----------------------------------------------------------------------------

# Exercise 1: [Description]
# Difficulty: Easy/Medium/Hard
#
# Instructions:
# ...
#
# Your code here:


# Exercise 2: [Description]
# ...

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
#
# Key takeaways:
# - Point 1
# - Point 2
#
# Next: Link to next lesson
# -----------------------------------------------------------------------------
```

### Key Requirements for Lesson Files

1. **Self-contained**: Each file must run independently with `elixir filename.exs`
2. **Heavily commented**: Every concept needs explanation comments
3. **Produces output**: Running the file should show results to the learner
4. **Includes exercises**: 2-5 exercises per lesson with varying difficulty
5. **Clear structure**: Use comment dividers to separate sections

### README Files

Each section directory contains a README.md with:
- Section overview
- List of lessons with descriptions
- Setup instructions (if needed)
- Learning path through the section

### Project Directories

Projects follow standard Mix project structure:
```
project_name/
├── lib/
│   └── project_name.ex
├── test/
│   └── project_name_test.exs
├── mix.exs
└── README.md
```

## Writing Guidelines

### Code Style

- Use 2-space indentation (Elixir standard)
- Follow Elixir formatter conventions (`mix format`)
- Use descriptive variable and function names for teaching clarity
- Prefer explicit over implicit for educational purposes

### Comment Style

```elixir
# Single line comments for brief explanations

# Multi-line comments for longer explanations
# should use multiple single-line comment markers
# like this, for consistency.

# Use blank comment lines for visual separation:
#
# New paragraph here
#

# CODE SECTIONS use uppercase headers:
# -----------------------------------------------------------------------------
# SECTION NAME
# -----------------------------------------------------------------------------
```

### Teaching Approach

1. **Concept → Example → Practice**
   - Explain the concept first
   - Show a working example
   - Provide exercises to practice

2. **Progressive Complexity**
   - Start simple, add complexity gradually
   - Reference previous lessons when building on concepts
   - Mark prerequisites clearly

3. **Practical Focus**
   - Use real-world examples
   - Avoid contrived scenarios
   - Connect concepts to professional development

4. **Error Awareness**
   - Show common mistakes
   - Explain error messages
   - Demonstrate debugging approaches

## Common Commands

### Running Lessons
```bash
# Run a single lesson
elixir 01_elixir_fundamentals/01_hello_elixir.exs

# Run in IEx for experimentation
iex 01_elixir_fundamentals/01_hello_elixir.exs
```

### Working with Projects
```bash
# Navigate to project
cd 03_otp_concurrency/project_chat_system

# Get dependencies
mix deps.get

# Run tests
mix test

# Run the project
iex -S mix
```

### Formatting
```bash
# Format all Elixir files
mix format

# Check formatting
mix format --check-formatted
```

## AI Assistant Tasks

When working on this curriculum, common tasks include:

### Adding New Lessons
1. Create the `.exs` file following the lesson template
2. Update the section README.md
3. Update CURRICULUM.md if adding new topics
4. Ensure the lesson runs without errors

### Fixing Issues
1. Run the file to reproduce the issue
2. Fix the code
3. Run again to verify the fix
4. Check that output is educational

### Adding Exercises
1. Add exercises at the end of the lesson
2. Include difficulty level (Easy/Medium/Hard)
3. Provide clear instructions
4. Consider adding a solutions section (commented out)

### Creating Projects
1. Use `mix new project_name` as the base
2. Add comprehensive README
3. Include tests for all functionality
4. Add step-by-step instructions for building it

## Technology Versions

This curriculum targets:
- **Elixir**: 1.15+ (1.16 preferred)
- **Erlang/OTP**: 26+
- **Phoenix**: 1.7+
- **Phoenix LiveView**: 0.20+
- **Ecto**: 3.11+

Mention version requirements when using version-specific features.

## Quality Checklist

Before committing changes, verify:

- [ ] All `.exs` files run without errors
- [ ] Code follows Elixir formatting conventions
- [ ] Comments are clear and educational
- [ ] Exercises have clear instructions
- [ ] Prerequisites are listed
- [ ] File follows the lesson template structure
- [ ] README files are updated if needed
- [ ] CURRICULUM.md reflects any structural changes

## Notes for Claude

When helping with this curriculum:

1. **Prioritize clarity over cleverness** - This is educational content
2. **Test all code** - Every example should run successfully
3. **Be explicit** - Don't assume knowledge not yet covered
4. **Use consistent terminology** - Check existing lessons for terms used
5. **Include output** - Show what learners should expect to see
6. **Reference other lessons** - Build connections across the curriculum
7. **Consider beginners** - Explain things that might seem obvious
8. **Keep it practical** - Focus on skills used in real projects

## Getting Help

If you encounter issues with the curriculum:
- Check the issue tracker for known problems
- Review related lessons for context
- Test code in a fresh IEx session
- Consult official Elixir/Phoenix documentation

---

*This file should be updated as the curriculum evolves.*
