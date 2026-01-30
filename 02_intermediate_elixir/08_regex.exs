# ============================================================================
# REGULAR EXPRESSIONS - Pattern Matching in Strings
# ============================================================================
#
# Elixir provides powerful regex support through the Regex module.
# Regex patterns are compiled at compile time when using sigils,
# making them efficient for repeated use.
#
# Run this file with: elixir 08_regex.exs
# ============================================================================

IO.puts """
╔══════════════════════════════════════════════════════════════════════════════╗
║                        REGULAR EXPRESSIONS                                    ║
║                    Pattern Matching in Strings                                ║
╚══════════════════════════════════════════════════════════════════════════════╝
"""

# ============================================================================
# PART 1: CREATING REGEX PATTERNS
# ============================================================================

IO.puts """
┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 1: CREATING REGEX PATTERNS                                              │
└──────────────────────────────────────────────────────────────────────────────┘

Regex patterns can be created using the ~r sigil or Regex.compile/2.
The sigil compiles at compile time; Regex.compile is for runtime patterns.
"""

# Using the ~r sigil (compiled at compile time)
regex1 = ~r/hello/
IO.puts "Using ~r sigil: #{inspect(regex1)}"

# Using Regex.compile/2 (compiled at runtime)
{:ok, regex2} = Regex.compile("hello")
IO.puts "Using Regex.compile: #{inspect(regex2)}"

# Regex.compile! raises on invalid patterns
regex3 = Regex.compile!("hello")
IO.puts "Using Regex.compile!: #{inspect(regex3)}"

# Modifiers
IO.puts "\n--- Regex Modifiers ---"
IO.puts "i - case insensitive"
IO.puts "m - multiline (^ and $ match line boundaries)"
IO.puts "s - dotall (. matches newlines)"
IO.puts "u - unicode"
IO.puts "x - extended (allows whitespace and comments)"
IO.puts "U - ungreedy (makes quantifiers lazy by default)"
IO.puts "f - firstline (match must start in first line)"

# Examples of modifiers
case_insensitive = ~r/hello/i
multiline = ~r/^start/m
unicode = ~r/\p{L}+/u
extended = ~r/
  ^           # start
  [a-z]+      # letters
  \d+         # digits
  $           # end
/x

IO.puts "\nCase insensitive pattern: #{inspect(case_insensitive)}"
IO.puts "Multiline pattern: #{inspect(multiline)}"
IO.puts "Unicode pattern: #{inspect(unicode)}"
IO.puts "Extended pattern: #{inspect(extended)}"

# ============================================================================
# PART 2: Regex.match?/2 - Testing for Matches
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 2: Regex.match?/2 - Testing for Matches                                 │
└──────────────────────────────────────────────────────────────────────────────┘

Regex.match?/2 returns true/false - use it for simple validation.
"""

# Basic matching
IO.puts "--- Basic Match Testing ---"
IO.puts "~r/hello/ matches 'hello world': #{Regex.match?(~r/hello/, "hello world")}"
IO.puts "~r/goodbye/ matches 'hello world': #{Regex.match?(~r/goodbye/, "hello world")}"

# Case sensitivity
IO.puts "\n--- Case Sensitivity ---"
IO.puts "~r/HELLO/ matches 'hello': #{Regex.match?(~r/HELLO/, "hello")}"
IO.puts "~r/HELLO/i matches 'hello': #{Regex.match?(~r/HELLO/i, "hello")}"

# Pattern examples
IO.puts "\n--- Common Patterns ---"

# Digits
IO.puts "Contains digits: #{Regex.match?(~r/\d+/, "Order #12345")}"
IO.puts "Only digits: #{Regex.match?(~r/^\d+$/, "12345")}"
IO.puts "Only digits: #{Regex.match?(~r/^\d+$/, "123a45")}"

# Word characters
IO.puts "\nWord characters: #{Regex.match?(~r/^\w+$/, "hello_world")}"
IO.puts "Word characters: #{Regex.match?(~r/^\w+$/, "hello world")}"

# Email-like pattern (simplified)
email_regex = ~r/^[\w.+-]+@[\w.-]+\.\w{2,}$/
IO.puts "\nEmail validation:"
IO.puts "user@example.com: #{Regex.match?(email_regex, "user@example.com")}"
IO.puts "invalid.email: #{Regex.match?(email_regex, "invalid.email")}"

# Using the =~ operator (shorthand for Regex.match?)
IO.puts "\n--- Using =~ Operator ---"
IO.puts "\"hello\" =~ ~r/ell/: #{"hello" =~ ~r/ell/}"
IO.puts "\"hello\" =~ ~r/xyz/: #{"hello" =~ ~r/xyz/}"

# ============================================================================
# PART 3: Regex.run/3 - Finding First Match
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 3: Regex.run/3 - Finding First Match                                    │
└──────────────────────────────────────────────────────────────────────────────┘

Regex.run/3 returns the first match and capture groups.
Returns nil if no match is found.
"""

# Basic run
IO.puts "--- Basic Regex.run ---"
result = Regex.run(~r/\d+/, "Order 12345 and 67890")
IO.puts "First number in 'Order 12345 and 67890': #{inspect(result)}"

# No match returns nil
result = Regex.run(~r/\d+/, "No numbers here")
IO.puts "No match result: #{inspect(result)}"

# Capture groups
IO.puts "\n--- Capture Groups ---"
regex = ~r/(\d{4})-(\d{2})-(\d{2})/
result = Regex.run(regex, "Date: 2024-03-15")
IO.puts "Date pattern with groups: #{inspect(result)}"
IO.puts "Full match: #{Enum.at(result, 0)}"
IO.puts "Year: #{Enum.at(result, 1)}"
IO.puts "Month: #{Enum.at(result, 2)}"
IO.puts "Day: #{Enum.at(result, 3)}"

# Capture option
IO.puts "\n--- Capture Options ---"
regex = ~r/(\w+)@(\w+)\.(\w+)/

# :all (default) - returns full match and all groups
result_all = Regex.run(regex, "user@example.com", capture: :all)
IO.puts "capture: :all: #{inspect(result_all)}"

# :first - returns only full match
result_first = Regex.run(regex, "user@example.com", capture: :first)
IO.puts "capture: :first: #{inspect(result_first)}"

# :all_but_first - returns only groups, not full match
result_groups = Regex.run(regex, "user@example.com", capture: :all_but_first)
IO.puts "capture: :all_but_first: #{inspect(result_groups)}"

# Return option
IO.puts "\n--- Return Options ---"
regex = ~r/hello/

# :binary (default) - returns strings
result_binary = Regex.run(regex, "hello world", return: :binary)
IO.puts "return: :binary: #{inspect(result_binary)}"

# :index - returns {start, length} tuples
result_index = Regex.run(regex, "hello world", return: :index)
IO.puts "return: :index: #{inspect(result_index)}"

# ============================================================================
# PART 4: Regex.scan/3 - Finding All Matches
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 4: Regex.scan/3 - Finding All Matches                                   │
└──────────────────────────────────────────────────────────────────────────────┘

Regex.scan/3 returns ALL matches, not just the first one.
"""

# Basic scan
IO.puts "--- Basic Regex.scan ---"
text = "Order numbers: 12345, 67890, and 11111"
result = Regex.scan(~r/\d+/, text)
IO.puts "All numbers: #{inspect(result)}"

# Scan with capture groups
IO.puts "\n--- Scan with Capture Groups ---"
text = "Dates: 2024-03-15, 2024-04-20, 2024-05-25"
regex = ~r/(\d{4})-(\d{2})-(\d{2})/
result = Regex.scan(regex, text)
IO.puts "All dates with groups: #{inspect(result)}"

# Each element is [full_match, group1, group2, group3]
for [full, year, month, day] <- result do
  IO.puts "  #{full} -> Year: #{year}, Month: #{month}, Day: #{day}"
end

# Capture options with scan
IO.puts "\n--- Scan Capture Options ---"
result_groups = Regex.scan(regex, text, capture: :all_but_first)
IO.puts "Groups only: #{inspect(result_groups)}"

# Extract all email addresses
IO.puts "\n--- Practical Example: Extract Emails ---"
text = "Contact us at support@example.com or sales@company.org for help"
emails = Regex.scan(~r/[\w.+-]+@[\w.-]+\.\w+/, text)
IO.puts "Emails found: #{inspect(List.flatten(emails))}"

# ============================================================================
# PART 5: Regex.replace/4 - Search and Replace
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 5: Regex.replace/4 - Search and Replace                                 │
└──────────────────────────────────────────────────────────────────────────────┘

Regex.replace/4 replaces matches with a replacement string or function.
"""

# Basic replacement
IO.puts "--- Basic Replacement ---"
text = "Hello World"
result = Regex.replace(~r/World/, text, "Elixir")
IO.puts "Replace 'World' with 'Elixir': #{result}"

# Replace all occurrences
text = "one two one three one"
result = Regex.replace(~r/one/, text, "1")
IO.puts "Replace all 'one': #{result}"

# Replace first only
result = Regex.replace(~r/one/, text, "1", global: false)
IO.puts "Replace first 'one' only: #{result}"

# Using backreferences
IO.puts "\n--- Backreferences ---"
text = "hello world"
result = Regex.replace(~r/(\w+) (\w+)/, text, "\\2 \\1")
IO.puts "Swap words using \\\\1 and \\\\2: #{result}"

# Named backreferences
result = Regex.replace(~r/(?<first>\w+) (?<second>\w+)/, text, "\\g{second} \\g{first}")
IO.puts "Swap with named groups: #{result}"

# Using a function for replacement
IO.puts "\n--- Function Replacement ---"
text = "Prices: $10, $25, $100"

# Double all prices
result = Regex.replace(~r/\$(\d+)/, text, fn full_match, amount ->
  "$#{String.to_integer(amount) * 2}"
end)
IO.puts "Double prices: #{result}"

# More complex function
text = "user_name and other_thing"
result = Regex.replace(~r/_(\w)/, text, fn _, char ->
  String.upcase(char)
end)
IO.puts "snake_case to camelCase: #{result}"

# Case conversion
IO.puts "\n--- Case Manipulation ---"
text = "hello WORLD"

# \\U and \\L for case conversion
result = Regex.replace(~r/(\w+) (\w+)/, text, "\\U\\1\\E \\L\\2\\E")
IO.puts "Uppercase first, lowercase second: #{result}"

# ============================================================================
# PART 6: NAMED CAPTURES
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 6: NAMED CAPTURES                                                       │
└──────────────────────────────────────────────────────────────────────────────┘

Named captures use (?<name>...) syntax and return maps with Regex.named_captures/3.
"""

# Basic named captures
IO.puts "--- Basic Named Captures ---"
regex = ~r/(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/
text = "Event date: 2024-03-15"

result = Regex.named_captures(regex, text)
IO.puts "Named captures: #{inspect(result)}"
IO.puts "Year: #{result["year"]}"
IO.puts "Month: #{result["month"]}"
IO.puts "Day: #{result["day"]}"

# No match returns nil
result = Regex.named_captures(regex, "no date here")
IO.puts "\nNo match: #{inspect(result)}"

# Complex example: parsing URLs
IO.puts "\n--- Parsing URLs ---"
url_regex = ~r/(?<protocol>https?):\/\/(?<host>[\w.-]+)(?::(?<port>\d+))?(?<path>\/[\w\/.%-]*)?/

urls = [
  "https://example.com/path/to/page",
  "http://localhost:4000/api/users",
  "https://api.example.com:8080/v1/data"
]

for url <- urls do
  captures = Regex.named_captures(url_regex, url)
  IO.puts "\nURL: #{url}"
  IO.puts "  Protocol: #{captures["protocol"]}"
  IO.puts "  Host: #{captures["host"]}"
  IO.puts "  Port: #{captures["port"] || "default"}"
  IO.puts "  Path: #{captures["path"] || "/"}"
end

# Getting capture names
IO.puts "\n--- Capture Names ---"
IO.puts "Capture names in URL regex: #{inspect(Regex.names(url_regex))}"

# ============================================================================
# PART 7: Regex.split/3 - Splitting Strings
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 7: Regex.split/3 - Splitting Strings                                    │
└──────────────────────────────────────────────────────────────────────────────┘

Regex.split/3 splits a string on regex matches.
"""

# Basic split
IO.puts "--- Basic Split ---"
text = "one,two;three:four"
result = Regex.split(~r/[,;:]/, text)
IO.puts "Split on [,;:]: #{inspect(result)}"

# Split with trim
text = "  one  two  three  "
result = Regex.split(~r/\s+/, text, trim: true)
IO.puts "Split on whitespace (trimmed): #{inspect(result)}"

# Split with limit
text = "a-b-c-d-e"
result = Regex.split(~r/-/, text, parts: 3)
IO.puts "Split with parts: 3: #{inspect(result)}"

# Include captures in result
IO.puts "\n--- Include Captures ---"
text = "one1two2three3four"
result = Regex.split(~r/(\d)/, text, include_captures: true)
IO.puts "Include captures: #{inspect(result)}"

# Keep the separators
text = "Section 1. Introduction. Content. Section 2. More content."
result = Regex.split(~r/\. /, text, trim: true)
IO.puts "\nSplit on '. ': #{inspect(result)}"

# ============================================================================
# PART 8: COMMON REGEX PATTERNS
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 8: COMMON REGEX PATTERNS                                                │
└──────────────────────────────────────────────────────────────────────────────┘
"""

defmodule CommonPatterns do
  # Email (simplified - real email validation is complex!)
  def email_pattern, do: ~r/^[\w.+-]+@[\w.-]+\.\w{2,}$/i

  # URL
  def url_pattern, do: ~r/^https?:\/\/[\w.-]+(?:\/[\w\/.%-]*)?$/

  # Phone (US format)
  def phone_pattern, do: ~r/^(?:\+1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}$/

  # Date (YYYY-MM-DD)
  def date_pattern, do: ~r/^\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01])$/

  # Time (HH:MM or HH:MM:SS)
  def time_pattern, do: ~r/^(?:[01]\d|2[0-3]):[0-5]\d(?::[0-5]\d)?$/

  # IP Address (IPv4)
  def ipv4_pattern, do: ~r/^(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)$/

  # Hex color
  def hex_color_pattern, do: ~r/^#?(?:[0-9a-fA-F]{3}){1,2}$/

  # UUID
  def uuid_pattern, do: ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

  # Slug (URL-friendly string)
  def slug_pattern, do: ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/

  # Username (alphanumeric, underscores, 3-16 chars)
  def username_pattern, do: ~r/^[a-zA-Z0-9_]{3,16}$/

  # Strong password (8+ chars, upper, lower, digit, special)
  def strong_password_pattern do
    ~r/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/
  end
end

IO.puts "--- Testing Common Patterns ---\n"

# Email
IO.puts "Email validation:"
IO.puts "  user@example.com: #{Regex.match?(CommonPatterns.email_pattern(), "user@example.com")}"
IO.puts "  invalid@: #{Regex.match?(CommonPatterns.email_pattern(), "invalid@")}"

# Phone
IO.puts "\nPhone validation:"
IO.puts "  (123) 456-7890: #{Regex.match?(CommonPatterns.phone_pattern(), "(123) 456-7890")}"
IO.puts "  123-456-7890: #{Regex.match?(CommonPatterns.phone_pattern(), "123-456-7890")}"

# IP Address
IO.puts "\nIPv4 validation:"
IO.puts "  192.168.1.1: #{Regex.match?(CommonPatterns.ipv4_pattern(), "192.168.1.1")}"
IO.puts "  256.1.1.1: #{Regex.match?(CommonPatterns.ipv4_pattern(), "256.1.1.1")}"

# UUID
IO.puts "\nUUID validation:"
IO.puts "  550e8400-e29b-41d4-a716-446655440000: #{Regex.match?(CommonPatterns.uuid_pattern(), "550e8400-e29b-41d4-a716-446655440000")}"

# Hex color
IO.puts "\nHex color validation:"
IO.puts "  #FF5733: #{Regex.match?(CommonPatterns.hex_color_pattern(), "#FF5733")}"
IO.puts "  #fff: #{Regex.match?(CommonPatterns.hex_color_pattern(), "#fff")}"

# ============================================================================
# PART 9: PERFORMANCE CONSIDERATIONS
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 9: PERFORMANCE CONSIDERATIONS                                           │
└──────────────────────────────────────────────────────────────────────────────┘
"""

IO.puts """
1. Use ~r sigil when pattern is known at compile time
   - Compiled once at compile time
   - Much faster for repeated use

2. Avoid catastrophic backtracking
   - Patterns like (a+)+ on "aaaaaaaaaaaaaaaaX" can be very slow
   - Use possessive quantifiers or atomic groups when possible

3. Be specific with character classes
   - [a-z] is faster than .
   - \\d is faster than [0-9] (optimized)

4. Anchor patterns when possible
   - ^pattern$ is faster than pattern alone
   - Regex engine can fail fast

5. Use non-capturing groups when you don't need captures
   - (?:...) instead of (...)
   - Slightly faster, less memory

6. Consider String functions for simple cases
   - String.contains?/2 is faster than Regex for literal strings
   - String.split/2 is faster than Regex.split for simple delimiters
"""

# Example: String vs Regex for simple operations
IO.puts "--- Simple Operations: String vs Regex ---"

text = "Hello, World!"

# For simple literal matching, String functions are faster
IO.puts "Contains 'World':"
IO.puts "  String.contains?: #{String.contains?(text, "World")}"
IO.puts "  Regex.match?: #{Regex.match?(~r/World/, text)}"

# For complex patterns, Regex is necessary
IO.puts "\nComplex patterns require Regex:"
IO.puts "  Email in text: #{Regex.match?(~r/[\w.]+@[\w.]+/, "Email: test@example.com")}"

# ============================================================================
# EXERCISES
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ EXERCISES                                                                    │
└──────────────────────────────────────────────────────────────────────────────┘
"""

defmodule RegexExercises do
  @doc """
  Exercise 1: Extract Hashtags
  Extract all hashtags from a social media post.
  Hashtags start with # followed by word characters.
  """
  def extract_hashtags(text) do
    Regex.scan(~r/#\w+/, text)
    |> List.flatten()
  end

  @doc """
  Exercise 2: Parse Log Entry
  Parse a log entry in format: "[LEVEL] TIMESTAMP: MESSAGE"
  Return a map with :level, :timestamp, and :message keys.
  """
  def parse_log_entry(line) do
    regex = ~r/\[(?<level>\w+)\]\s+(?<timestamp>[\d-]+\s+[\d:]+):\s+(?<message>.+)/
    Regex.named_captures(regex, line)
  end

  @doc """
  Exercise 3: Mask Credit Card
  Replace all but last 4 digits of credit card numbers with *.
  Credit card format: XXXX-XXXX-XXXX-XXXX or XXXXXXXXXXXXXXXX
  """
  def mask_credit_card(text) do
    # Handle format with dashes
    text = Regex.replace(~r/\d{4}-\d{4}-\d{4}-(\d{4})/, text, "****-****-****-\\1")
    # Handle format without dashes
    Regex.replace(~r/\d{12}(\d{4})/, text, "************\\1")
  end

  @doc """
  Exercise 4: Convert snake_case to camelCase
  Convert all snake_case identifiers in text to camelCase.
  """
  def snake_to_camel(text) do
    Regex.replace(~r/_([a-z])/, text, fn _, char ->
      String.upcase(char)
    end)
  end

  @doc """
  Exercise 5: Validate Password Strength
  Check if password meets requirements:
  - At least 8 characters
  - At least one uppercase letter
  - At least one lowercase letter
  - At least one digit
  - At least one special character (@$!%*?&)
  Return {:ok, password} or {:error, reasons} with list of failed requirements.
  """
  def validate_password(password) do
    checks = [
      {~r/.{8,}/, "at least 8 characters"},
      {~r/[A-Z]/, "at least one uppercase letter"},
      {~r/[a-z]/, "at least one lowercase letter"},
      {~r/\d/, "at least one digit"},
      {~r/[@$!%*?&]/, "at least one special character (@$!%*?&)"}
    ]

    failures =
      checks
      |> Enum.reject(fn {regex, _} -> Regex.match?(regex, password) end)
      |> Enum.map(fn {_, reason} -> reason end)

    if failures == [] do
      {:ok, password}
    else
      {:error, failures}
    end
  end
end

IO.puts "--- Testing Exercises ---\n"

IO.puts "Exercise 1: Extract Hashtags"
text = "Loving #Elixir and #FunctionalProgramming! #coding"
IO.puts "Text: #{text}"
IO.puts "Hashtags: #{inspect(RegexExercises.extract_hashtags(text))}"

IO.puts "\nExercise 2: Parse Log Entry"
log = "[ERROR] 2024-03-15 14:30:25: Database connection failed"
IO.puts "Log: #{log}"
IO.puts "Parsed: #{inspect(RegexExercises.parse_log_entry(log))}"

IO.puts "\nExercise 3: Mask Credit Card"
text = "Card: 1234-5678-9012-3456 or 1234567890123456"
IO.puts "Original: #{text}"
IO.puts "Masked: #{RegexExercises.mask_credit_card(text)}"

IO.puts "\nExercise 4: Snake to Camel"
text = "user_name and created_at and last_login_time"
IO.puts "Original: #{text}"
IO.puts "Converted: #{RegexExercises.snake_to_camel(text)}"

IO.puts "\nExercise 5: Validate Password"
passwords = ["weak", "StrongPass1!", "NoSpecial1"]
for password <- passwords do
  result = RegexExercises.validate_password(password)
  IO.puts "#{password}: #{inspect(result)}"
end

IO.puts """

╔══════════════════════════════════════════════════════════════════════════════╗
║                         LESSON COMPLETE!                                      ║
║                                                                              ║
║  Key Takeaways:                                                              ║
║  • Use ~r sigil for compile-time regex compilation                           ║
║  • Regex.match?/2 for simple validation                                      ║
║  • Regex.run/3 for first match with captures                                 ║
║  • Regex.scan/3 for all matches                                              ║
║  • Regex.replace/4 for search and replace (supports functions)               ║
║  • Regex.named_captures/3 returns maps with named groups                     ║
║  • Consider String functions for simple operations (faster)                  ║
║                                                                              ║
║  Next: 09_try_rescue.exs - Exception Handling                                ║
╚══════════════════════════════════════════════════════════════════════════════╝
"""
