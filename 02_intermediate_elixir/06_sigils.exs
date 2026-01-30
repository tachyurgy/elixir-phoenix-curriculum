# ============================================================================
# SIGILS - Syntactic Sugar for Common Data Types
# ============================================================================
#
# Sigils are one of Elixir's mechanisms for working with textual representations.
# They start with a tilde (~) followed by a letter, then delimiters containing
# the content, and optional modifiers.
#
# Run this file with: elixir 06_sigils.exs
# ============================================================================

IO.puts """
╔══════════════════════════════════════════════════════════════════════════════╗
║                              SIGILS                                           ║
║                    Syntactic Sugar for Data Types                             ║
╚══════════════════════════════════════════════════════════════════════════════╝
"""

# ============================================================================
# PART 1: SIGIL BASICS
# ============================================================================

IO.puts """
┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 1: SIGIL BASICS                                                         │
└──────────────────────────────────────────────────────────────────────────────┘

Sigil syntax: ~LETTER{content}modifiers

Delimiters can be:
  ()  Parentheses
  {}  Curly braces
  []  Square brackets
  <>  Angle brackets
  ||  Pipes
  //  Slashes
  ""  Double quotes
  ''  Single quotes

Lowercase sigils allow interpolation and escape sequences.
Uppercase sigils are literal (no interpolation or escapes).
"""

name = "World"

# Lowercase ~s allows interpolation
IO.puts "Lowercase ~s: #{~s(Hello #{name}!)}"

# Uppercase ~S is literal
IO.puts "Uppercase ~S: #{~S(Hello #{name}!)}"

# Different delimiters - all equivalent
IO.puts "\n--- Different Delimiters ---"
IO.puts ~s(parentheses)
IO.puts ~s{curly braces}
IO.puts ~s[square brackets]
IO.puts ~s<angle brackets>
IO.puts ~s|pipes|
IO.puts ~s/slashes/
IO.puts ~s"double quotes"
IO.puts ~s'single quotes'

IO.puts "\nUseful when content contains the delimiter character:"
IO.puts ~s|Hello "World"!|
IO.puts ~s(Path: C:\Users\name)

# ============================================================================
# PART 2: ~s AND ~S - STRINGS
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 2: ~s AND ~S - STRING SIGILS                                            │
└──────────────────────────────────────────────────────────────────────────────┘

~s - String with interpolation and escape sequences
~S - Literal string (no interpolation or escapes)
"""

value = 42

# ~s with interpolation and escapes
IO.puts "~s example: #{~s(Value is #{value}\nNew line)}"

# ~S literal - shows #{value} literally
IO.puts "~S example: #{~S(Value is #{value}\nNew line)}"

# Multiline strings
multiline = ~s"""
This is a
multiline string
with interpolation: #{value}
"""
IO.puts "Multiline ~s:\n#{multiline}"

literal_multiline = ~S"""
This is a
literal multiline string
No interpolation: #{value}
Escapes shown: \n \t
"""
IO.puts "Multiline ~S:\n#{literal_multiline}"

# ============================================================================
# PART 3: ~c AND ~C - CHARLISTS
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 3: ~c AND ~C - CHARLIST SIGILS                                          │
└──────────────────────────────────────────────────────────────────────────────┘

~c - Charlist with interpolation (replaces 'single quotes')
~C - Literal charlist
"""

# ~c creates a charlist (list of codepoints)
charlist = ~c(hello)
IO.puts "~c(hello): #{inspect(charlist)}"
IO.puts "Is list? #{is_list(charlist)}"

# With interpolation
name = "Elixir"
IO.puts "~c(Hello #{name}): #{inspect(~c(Hello #{name}))}"

# ~C is literal
IO.puts "~C(Hello \#{name}): #{inspect(~C(Hello #{name}))}"

# Common use: Erlang interop
IO.puts "\nCharlist for Erlang functions:"
:io.format(~c"Number: ~p~n", [42])

# ============================================================================
# PART 4: ~w AND ~W - WORD LISTS
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 4: ~w AND ~W - WORD LIST SIGILS                                         │
└──────────────────────────────────────────────────────────────────────────────┘

~w - Creates a list of words (splits on whitespace)
~W - Literal word list

Modifiers:
  a - atoms (default)
  s - strings
  c - charlists
"""

# Default: list of strings
words = ~w(foo bar baz)
IO.puts "~w(foo bar baz): #{inspect(words)}"

# With 'a' modifier: atoms
atoms = ~w(foo bar baz)a
IO.puts "~w(foo bar baz)a: #{inspect(atoms)}"

# With 's' modifier: strings
strings = ~w(foo bar baz)s
IO.puts "~w(foo bar baz)s: #{inspect(strings)}"

# With 'c' modifier: charlists
charlists = ~w(foo bar baz)c
IO.puts "~w(foo bar baz)c: #{inspect(charlists)}"

# With interpolation
prefix = "user"
IO.puts "\nWith interpolation:"
IO.puts "~w(#{prefix}_1 #{prefix}_2): #{inspect(~w(#{prefix}_1 #{prefix}_2))}"

# ~W is literal (no interpolation)
IO.puts "~W(\#{prefix}_1 \#{prefix}_2): #{inspect(~W(#{prefix}_1 #{prefix}_2))}"

# Practical example: defining allowed values
allowed_methods = ~w(GET POST PUT DELETE)a
IO.puts "\nAllowed methods: #{inspect(allowed_methods)}"

allowed_status = ~w(pending active completed)a
IO.puts "Allowed status: #{inspect(allowed_status)}"

# ============================================================================
# PART 5: ~r AND ~R - REGULAR EXPRESSIONS
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 5: ~r AND ~R - REGEX SIGILS                                             │
└──────────────────────────────────────────────────────────────────────────────┘

~r - Regex with interpolation
~R - Literal regex

Modifiers:
  i - case insensitive
  m - multiline (^ and $ match line boundaries)
  s - dotall (. matches newlines)
  u - unicode (enables unicode patterns)
  x - extended (allows whitespace and comments)
"""

# Basic regex
regex = ~r/hello/
IO.puts "~r/hello/: #{inspect(regex)}"
IO.puts "Matches 'hello world'? #{Regex.match?(regex, "hello world")}"
IO.puts "Matches 'HELLO world'? #{Regex.match?(regex, "HELLO world")}"

# Case insensitive
regex_i = ~r/hello/i
IO.puts "\n~r/hello/i (case insensitive):"
IO.puts "Matches 'HELLO world'? #{Regex.match?(regex_i, "HELLO world")}"

# Unicode support
regex_u = ~r/\p{L}+/u
IO.puts "\n~r/\\p{L}+/u (unicode letters):"
IO.puts "Match in 'héllo': #{inspect(Regex.run(regex_u, "héllo"))}"

# Extended mode (allows comments and whitespace)
regex_x = ~r/
  ^                 # Start of string
  [a-z]+            # One or more letters
  \d{3,4}           # 3 or 4 digits
  $                 # End of string
/x

IO.puts "\nExtended mode regex:"
IO.puts "Matches 'abc123'? #{Regex.match?(regex_x, "abc123")}"
IO.puts "Matches 'xy9876'? #{Regex.match?(regex_x, "xy9876")}"

# With interpolation
pattern = "world"
regex_interpolated = ~r/hello #{pattern}/
IO.puts "\n~r/hello \#{pattern}/ where pattern = \"#{pattern}\":"
IO.puts "Matches 'hello world'? #{Regex.match?(regex_interpolated, "hello world")}"

# ~R is literal
regex_literal = ~R/hello #{pattern}/
IO.puts "\n~R/hello \#{pattern}/ (literal):"
IO.puts "Matches 'hello \#{pattern}'? #{Regex.match?(regex_literal, "hello \#{pattern}")}"

# Different delimiters for regex with slashes
url_regex = ~r{https?://[\w./]+}
IO.puts "\nUsing {} delimiters for URLs:"
IO.puts "Match: #{inspect(Regex.run(url_regex, "Visit https://elixir-lang.org/docs"))}"

# ============================================================================
# PART 6: ~D, ~T, ~N, ~U - DATE/TIME SIGILS
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 6: ~D, ~T, ~N, ~U - DATE/TIME SIGILS                                    │
└──────────────────────────────────────────────────────────────────────────────┘

~D - Date
~T - Time
~N - NaiveDateTime (no timezone)
~U - DateTime (with UTC timezone)
"""

# Date sigil
date = ~D[2024-03-15]
IO.puts "~D[2024-03-15]: #{inspect(date)}"
IO.puts "Type: #{date.__struct__}"
IO.puts "Year: #{date.year}, Month: #{date.month}, Day: #{date.day}"

# Time sigil
time = ~T[14:30:00]
IO.puts "\n~T[14:30:00]: #{inspect(time)}"
IO.puts "Hour: #{time.hour}, Minute: #{time.minute}, Second: #{time.second}"

# Time with microseconds
time_precise = ~T[14:30:00.123456]
IO.puts "\n~T[14:30:00.123456]: #{inspect(time_precise)}"
IO.puts "Microsecond: #{inspect(time_precise.microsecond)}"

# NaiveDateTime sigil (no timezone info)
naive = ~N[2024-03-15 14:30:00]
IO.puts "\n~N[2024-03-15 14:30:00]: #{inspect(naive)}"
IO.puts "Type: NaiveDateTime (no timezone)"

# DateTime sigil (UTC timezone)
datetime = ~U[2024-03-15 14:30:00Z]
IO.puts "\n~U[2024-03-15 14:30:00Z]: #{inspect(datetime)}"
IO.puts "Type: DateTime with UTC timezone"
IO.puts "Timezone: #{datetime.time_zone}"

# Comparison
IO.puts "\n--- Comparison ---"
IO.puts "~D[2024-03-15] == ~D[2024-03-15]: #{~D[2024-03-15] == ~D[2024-03-15]}"
IO.puts "~D[2024-03-15] > ~D[2024-03-14]: #{Date.compare(~D[2024-03-15], ~D[2024-03-14]) == :gt}"

# ============================================================================
# PART 7: CUSTOM SIGILS
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 7: CUSTOM SIGILS                                                        │
└──────────────────────────────────────────────────────────────────────────────┘

You can define custom sigils by implementing sigil_X functions.
The function receives the content and modifiers.
"""

defmodule CustomSigils do
  @doc """
  ~i sigil for integers - parses a string as an integer
  """
  def sigil_i(string, []) do
    String.to_integer(string)
  end

  def sigil_i(string, ~c"h") do
    # 'h' modifier: parse as hexadecimal
    String.to_integer(string, 16)
  end

  def sigil_i(string, ~c"b") do
    # 'b' modifier: parse as binary
    String.to_integer(string, 2)
  end

  @doc """
  ~p sigil for paths - creates a proper file path
  """
  def sigil_p(string, []) do
    Path.expand(string)
  end

  def sigil_p(string, ~c"j") do
    # 'j' modifier: join path segments
    string
    |> String.split()
    |> Path.join()
    |> Path.expand()
  end

  @doc """
  ~j sigil for JSON-like maps (simplified)
  """
  def sigil_j(string, []) do
    # Simple key:value parser (not full JSON!)
    string
    |> String.split(",")
    |> Enum.map(fn pair ->
      [key, value] = String.split(String.trim(pair), ":")
      {String.trim(key) |> String.to_atom(), String.trim(value)}
    end)
    |> Map.new()
  end

  @doc """
  ~v sigil for version requirements
  """
  def sigil_v(string, []) do
    Version.parse!(string)
  end

  @doc """
  ~upper sigil (multi-character) - uppercase string
  """
  def sigil_upper(string, []) do
    String.upcase(string)
  end

  def sigil_upper(string, ~c"r") do
    # 'r' modifier: reverse after uppercasing
    string |> String.upcase() |> String.reverse()
  end
end

# Import to use the sigils
import CustomSigils

IO.puts "--- Custom Integer Sigil ---"
IO.puts "~i(42): #{~i(42)}"
IO.puts "~i(FF)h (hex): #{~i(FF)h}"
IO.puts "~i(1010)b (binary): #{~i(1010)b}"

IO.puts "\n--- Custom Path Sigil ---"
IO.puts "~p(~/documents): #{~p(~/documents)}"
IO.puts "~p(home docs files)j: #{~p(home docs files)j}"

IO.puts "\n--- Custom Map Sigil ---"
result = ~j(name: Alice, age: 30, city: NYC)
IO.puts "~j(name: Alice, age: 30, city: NYC): #{inspect(result)}"

IO.puts "\n--- Custom Version Sigil ---"
version = ~v(1.2.3)
IO.puts "~v(1.2.3): #{inspect(version)}"
IO.puts "Major: #{version.major}, Minor: #{version.minor}, Patch: #{version.patch}"

IO.puts "\n--- Multi-character Sigil ---"
IO.puts "~upper(hello world): #{~upper(hello world)}"
IO.puts "~upper(hello world)r: #{~upper(hello world)r}"

# ============================================================================
# PART 8: PRACTICAL SIGIL EXAMPLES
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 8: PRACTICAL SIGIL EXAMPLES                                             │
└──────────────────────────────────────────────────────────────────────────────┘
"""

# 1. Defining configuration with word lists
IO.puts "--- Configuration with ~w ---"
config = %{
  allowed_origins: ~w(localhost example.com api.example.com),
  allowed_methods: ~w(GET POST PUT DELETE)a,
  log_levels: ~w(debug info warn error)a
}
IO.puts "Config: #{inspect(config, pretty: true)}"

# 2. Pattern matching with regex
IO.puts "\n--- Email Validation ---"
email_regex = ~r/^[\w.+-]+@[\w.-]+\.\w{2,}$/i

emails = ["user@example.com", "invalid", "Test@Domain.COM", "a@b.c"]
for email <- emails do
  valid = Regex.match?(email_regex, email)
  IO.puts "#{email}: #{if valid, do: "valid", else: "invalid"}"
end

# 3. SQL queries (avoiding escaping)
IO.puts "\n--- SQL with ~S ---"
query = ~S"""
SELECT users.name, orders.total
FROM users
INNER JOIN orders ON users.id = orders.user_id
WHERE orders.total > $1
  AND users.created_at > $2
ORDER BY orders.total DESC
"""
IO.puts "SQL Query:\n#{query}"

# 4. File paths
IO.puts "--- File Paths ---"
files = ~w(
  config/config.exs
  lib/my_app.ex
  test/my_app_test.exs
)
IO.puts "Project files: #{inspect(files)}"

# 5. HTML/Template content
IO.puts "\n--- HTML Template ---"
html = ~S"""
<div class="container">
  <h1>Welcome, <%= @user.name %></h1>
  <p>Your balance: $<%= @balance %></p>
</div>
"""
IO.puts "HTML Template:\n#{html}"

# ============================================================================
# EXERCISES
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ EXERCISES                                                                    │
└──────────────────────────────────────────────────────────────────────────────┘
"""

defmodule SigilExercises do
  @doc """
  Exercise 1: Create a ~phone sigil that formats phone numbers.
  Input: "1234567890"
  Output: "(123) 456-7890"
  """
  def sigil_phone(<<area::binary-size(3), prefix::binary-size(3), line::binary-size(4)>>, []) do
    "(#{area}) #{prefix}-#{line}"
  end

  def sigil_phone(string, _) do
    # Handle other cases
    String.trim(string)
  end

  @doc """
  Exercise 2: Create a ~slug sigil that converts text to URL slugs.
  Input: "Hello World! This is a Test"
  Output: "hello-world-this-is-a-test"
  """
  def sigil_slug(string, []) do
    string
    |> String.downcase()
    |> String.replace(~r/[^\w\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end

  @doc """
  Exercise 3: Create a ~currency sigil that parses currency strings.
  Input: "$1,234.56"
  Output: 123456 (cents as integer)
  Modifier 'f': return as float instead
  """
  def sigil_currency(string, []) do
    string
    |> String.replace(~r/[$,]/, "")
    |> String.to_float()
    |> Kernel.*(100)
    |> round()
  end

  def sigil_currency(string, ~c"f") do
    string
    |> String.replace(~r/[$,]/, "")
    |> String.to_float()
  end

  @doc """
  Exercise 4: Create a ~rgb sigil that parses color codes.
  Input: "#FF5733" or "FF5733"
  Output: {255, 87, 51}
  """
  def sigil_rgb(string, []) do
    string = String.trim_leading(string, "#")
    <<r::binary-size(2), g::binary-size(2), b::binary-size(2)>> = string
    {
      String.to_integer(r, 16),
      String.to_integer(g, 16),
      String.to_integer(b, 16)
    }
  end
end

import SigilExercises

IO.puts "--- Testing Custom Sigils ---\n"

IO.puts "Exercise 1: Phone Formatter"
IO.puts "~phone(1234567890): #{~phone(1234567890)}"

IO.puts "\nExercise 2: Slug Generator"
IO.puts "~slug(Hello World! This is a Test): #{~slug(Hello World! This is a Test)}"

IO.puts "\nExercise 3: Currency Parser"
IO.puts "~currency($1,234.56) (cents): #{~currency($1,234.56)}"
IO.puts "~currency($1,234.56)f (float): #{~currency($1,234.56)f}"

IO.puts "\nExercise 4: RGB Parser"
IO.puts "~rgb(#FF5733): #{inspect(~rgb(#FF5733))}"
IO.puts "~rgb(00FF00): #{inspect(~rgb(00FF00))}"

IO.puts """

╔══════════════════════════════════════════════════════════════════════════════╗
║                         LESSON COMPLETE!                                      ║
║                                                                              ║
║  Key Takeaways:                                                              ║
║  • Sigils provide syntactic sugar for common data types                      ║
║  • Lowercase sigils allow interpolation; uppercase are literal               ║
║  • ~r for regex, ~w for word lists, ~s for strings, ~c for charlists         ║
║  • ~D, ~T, ~N, ~U for dates and times                                        ║
║  • Custom sigils extend the language for domain-specific needs               ║
║  • Choose delimiters wisely to avoid escaping                                ║
║                                                                              ║
║  Next: 07_date_time.exs - Working with Dates and Times                       ║
╚══════════════════════════════════════════════════════════════════════════════╝
"""
