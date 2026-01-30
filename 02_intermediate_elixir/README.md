# Section 2: Intermediate Elixir

Build on your fundamentals with more advanced Elixir concepts and techniques.

## What You'll Learn

- The Enum module for collection processing
- Streams for lazy evaluation
- Comprehensive error handling
- Metaprogramming basics
- File and IO operations

## Prerequisites

- Section 1 (Elixir Fundamentals) completed
- Comfortable with pattern matching and functions

## Lessons

### Enumerables and Streams
1. **[01_enum_basics.exs](01_enum_basics.exs)** - map, filter, reduce fundamentals
2. **[02_enum_advanced.exs](02_enum_advanced.exs)** - group_by, frequencies, zip, chunk
3. **[03_streams.exs](03_streams.exs)** - Lazy evaluation, infinite streams
4. **[04_comprehensions.exs](04_comprehensions.exs)** - for comprehensions, filters, into

### Working with Data
5. **[05_strings_deep.exs](05_strings_deep.exs)** - Unicode, binaries, String module
6. **[06_sigils.exs](06_sigils.exs)** - ~r, ~w, ~s, custom sigils
7. **[07_date_time.exs](07_date_time.exs)** - Date, Time, DateTime, NaiveDateTime
8. **[08_regex.exs](08_regex.exs)** - Pattern matching with regex

### Error Handling
9. **[09_try_rescue.exs](09_try_rescue.exs)** - Exceptions, try/rescue/after
10. **[10_throw_catch.exs](10_throw_catch.exs)** - throw/catch (and why to avoid)
11. **[11_error_tuples.exs](11_error_tuples.exs)** - {:ok, value} / {:error, reason} patterns
12. **[12_with_error_handling.exs](12_with_error_handling.exs)** - Combining with and error handling

### Metaprogramming Basics
13. **[13_quote_unquote.exs](13_quote_unquote.exs)** - AST basics, quote and unquote
14. **[14_macros_intro.exs](14_macros_intro.exs)** - Writing simple macros
15. **[15_use_macro.exs](15_use_macro.exs)** - The __using__ macro pattern

### Working with Files and IO
16. **[16_file_operations.exs](16_file_operations.exs)** - Reading, writing, streaming files
17. **[17_io_basics.exs](17_io_basics.exs)** - IO.puts, IO.inspect, formatting
18. **[18_path_operations.exs](18_path_operations.exs)** - Path module, file system navigation

### Project
- **[project_log_analyzer/](project_log_analyzer/)** - Stream-based log processing tool

## Running Lessons

```bash
# Run a lesson
elixir 01_enum_basics.exs

# Run interactively
iex 01_enum_basics.exs
```

## Key Concepts

This section focuses on practical skills you'll use daily:

- **Enum** - You'll use this module constantly
- **Streams** - Essential for large data processing
- **Error handling** - Critical for robust applications
- **File operations** - Common in scripts and applications

## Time Estimate

- Lessons: 10-14 hours
- Exercises: 5-7 hours
- Project: 4-6 hours
- **Total: 19-27 hours**

## Next Section

After completing this section, proceed to [03_otp_concurrency](../03_otp_concurrency/).
