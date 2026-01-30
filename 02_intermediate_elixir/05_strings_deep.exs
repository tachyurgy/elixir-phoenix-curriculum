# ============================================================================
# STRINGS IN DEPTH - Mastering Elixir's String Processing
# ============================================================================
#
# Elixir strings are UTF-8 encoded binaries. This lesson explores the String
# module in depth, covering Unicode handling, binary representation, and the
# crucial distinction between graphemes and codepoints.
#
# Run this file with: elixir 05_strings_deep.exs
# ============================================================================

IO.puts """
╔══════════════════════════════════════════════════════════════════════════════╗
║                        STRINGS IN DEPTH                                       ║
║                  Unicode, Binaries, and Text Processing                       ║
╚══════════════════════════════════════════════════════════════════════════════╝
"""

# ============================================================================
# PART 1: STRINGS AS BINARIES
# ============================================================================

IO.puts """
┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 1: STRINGS AS BINARIES                                                  │
└──────────────────────────────────────────────────────────────────────────────┘

In Elixir, strings are UTF-8 encoded BINARIES. A binary is a sequence of bytes.
Understanding this is crucial for efficient string processing.
"""

# Strings are binaries
string = "hello"
IO.puts "String: #{inspect(string)}"
IO.puts "Is binary? #{is_binary(string)}"
IO.puts "Byte size: #{byte_size(string)} bytes"
IO.puts "String length: #{String.length(string)} characters"

# For ASCII, byte size equals string length
IO.puts "\nFor ASCII text, byte_size == String.length"

# But not for Unicode!
unicode_string = "héllo"
IO.puts "\nString: #{inspect(unicode_string)}"
IO.puts "Byte size: #{byte_size(unicode_string)} bytes"
IO.puts "String length: #{String.length(unicode_string)} characters"

# More complex example
emoji_string = "hello 👋"
IO.puts "\nString: #{inspect(emoji_string)}"
IO.puts "Byte size: #{byte_size(emoji_string)} bytes"
IO.puts "String length: #{String.length(emoji_string)} characters"

# Binary representation
IO.puts "\n--- Binary Representation ---"
IO.puts "\"hello\" as binary: #{inspect("hello", binaries: :as_binaries)}"
IO.puts "\"é\" as binary: #{inspect("é", binaries: :as_binaries)}"

# Constructing binaries directly
binary = <<104, 101, 108, 108, 111>>  # "hello" in ASCII codes
IO.puts "\n<<104, 101, 108, 108, 111>> = #{inspect(binary)}"

# UTF-8 encoding in binaries
utf8_binary = <<195, 169>>  # "é" in UTF-8
IO.puts "<<195, 169>> = #{inspect(utf8_binary)}"

# Using codepoints in binaries
utf8_direct = <<233::utf8>>  # é is codepoint 233
IO.puts "<<233::utf8>> = #{inspect(utf8_direct)}"

# ============================================================================
# PART 2: GRAPHEMES VS CODEPOINTS
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 2: GRAPHEMES VS CODEPOINTS                                              │
└──────────────────────────────────────────────────────────────────────────────┘

This is one of the most important concepts in Unicode handling:

• CODEPOINT: A single Unicode code value (number assigned to a character)
• GRAPHEME: What humans perceive as a single character (may be multiple codepoints)

The letter "é" can be represented in TWO ways:
1. Single codepoint: U+00E9 (LATIN SMALL LETTER E WITH ACUTE)
2. Two codepoints: U+0065 (e) + U+0301 (COMBINING ACUTE ACCENT)

Both look identical but have different internal representations!
"""

# The two representations of "é"
e_acute_single = "é"           # Single codepoint (precomposed)
e_acute_combined = "e\u0301"   # e + combining acute accent (decomposed)

IO.puts "Single codepoint 'é': #{inspect(e_acute_single)}"
IO.puts "Combined 'e' + accent: #{inspect(e_acute_combined)}"
IO.puts "Look the same? #{e_acute_single} vs #{e_acute_combined}"
IO.puts "Equal? #{e_acute_single == e_acute_combined}"

IO.puts "\n--- Codepoint Analysis ---"
IO.puts "Single 'é' codepoints: #{inspect(String.codepoints(e_acute_single))}"
IO.puts "Combined 'é' codepoints: #{inspect(String.codepoints(e_acute_combined))}"

IO.puts "\n--- Grapheme Analysis ---"
IO.puts "Single 'é' graphemes: #{inspect(String.graphemes(e_acute_single))}"
IO.puts "Combined 'é' graphemes: #{inspect(String.graphemes(e_acute_combined))}"

# Emoji examples - even more complex!
IO.puts "\n--- Emoji Complexity ---"

# Simple emoji
wave = "👋"
IO.puts "\nWave emoji: #{wave}"
IO.puts "Codepoints: #{inspect(String.codepoints(wave))}"
IO.puts "Graphemes: #{inspect(String.graphemes(wave))}"
IO.puts "Length: #{String.length(wave)}"

# Emoji with skin tone (TWO codepoints, ONE grapheme)
wave_tone = "👋🏽"
IO.puts "\nWave with skin tone: #{wave_tone}"
IO.puts "Codepoints: #{inspect(String.codepoints(wave_tone))}"
IO.puts "Graphemes: #{inspect(String.graphemes(wave_tone))}"
IO.puts "Length: #{String.length(wave_tone)}"

# Family emoji (MANY codepoints, ONE grapheme)
family = "👨‍👩‍👧‍👦"
IO.puts "\nFamily emoji: #{family}"
IO.puts "Codepoints: #{inspect(String.codepoints(family))}"
IO.puts "Graphemes: #{inspect(String.graphemes(family))}"
IO.puts "Length: #{String.length(family)}"
IO.puts "Byte size: #{byte_size(family)}"

# Flag emoji (TWO codepoints, ONE grapheme)
flag = "🇺🇸"
IO.puts "\nUS Flag emoji: #{flag}"
IO.puts "Codepoints: #{inspect(String.codepoints(flag))}"
IO.puts "Length: #{String.length(flag)}"

# ============================================================================
# PART 3: STRING MODULE FUNCTIONS
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 3: STRING MODULE FUNCTIONS                                              │
└──────────────────────────────────────────────────────────────────────────────┘
"""

text = "  Hello, World! Welcome to Elixir.  "

IO.puts "--- Basic Operations ---"
IO.puts "Original: #{inspect(text)}"
IO.puts "Trimmed: #{inspect(String.trim(text))}"
IO.puts "Trim leading: #{inspect(String.trim_leading(text))}"
IO.puts "Trim trailing: #{inspect(String.trim_trailing(text))}"

IO.puts "\n--- Case Conversion ---"
sample = "Hello World"
IO.puts "Original: #{sample}"
IO.puts "Upcase: #{String.upcase(sample)}"
IO.puts "Downcase: #{String.downcase(sample)}"
IO.puts "Capitalize: #{String.capitalize(sample)}"

# Unicode-aware case conversion
unicode_sample = "ĤÉĹĹŐ"
IO.puts "\nUnicode: #{unicode_sample}"
IO.puts "Downcase: #{String.downcase(unicode_sample)}"

# Special case: German sharp S
german = "straße"
IO.puts "\nGerman: #{german}"
IO.puts "Upcase: #{String.upcase(german)}"  # ß becomes SS

IO.puts "\n--- Splitting and Joining ---"
sentence = "The quick brown fox"
IO.puts "Original: #{sentence}"
IO.puts "Split on space: #{inspect(String.split(sentence))}"
IO.puts "Split on 'o': #{inspect(String.split(sentence, "o"))}"
IO.puts "Split limit 2: #{inspect(String.split(sentence, " ", parts: 2))}"

words = ["Hello", "World", "!"]
IO.puts "\nWords: #{inspect(words)}"
IO.puts "Join with space: #{Enum.join(words, " ")}"
IO.puts "Join with comma: #{Enum.join(words, ", ")}"

IO.puts "\n--- Searching ---"
text = "Hello, Hello, World!"
IO.puts "Text: #{text}"
IO.puts "Contains 'Hello'? #{String.contains?(text, "Hello")}"
IO.puts "Contains 'Goodbye'? #{String.contains?(text, "Goodbye")}"
IO.puts "Contains any ['x', 'o']? #{String.contains?(text, ["x", "o"])}"
IO.puts "Starts with 'Hello'? #{String.starts_with?(text, "Hello")}"
IO.puts "Ends with '!'? #{String.ends_with?(text, "!")}"

IO.puts "\n--- Replacement ---"
IO.puts "Replace first 'Hello': #{String.replace(text, "Hello", "Hi", global: false)}"
IO.puts "Replace all 'Hello': #{String.replace(text, "Hello", "Hi")}"
IO.puts "Replace with regex: #{String.replace(text, ~r/[aeiou]/, "*")}"

IO.puts "\n--- Slicing and Access ---"
text = "Hello, World!"
IO.puts "Text: #{text}"
IO.puts "First char: #{String.first(text)}"
IO.puts "Last char: #{String.last(text)}"
IO.puts "Char at index 7: #{String.at(text, 7)}"
IO.puts "Slice [0..4]: #{String.slice(text, 0..4)}"
IO.puts "Slice [7..11]: #{String.slice(text, 7..11)}"
IO.puts "Slice [-6..-2]: #{String.slice(text, -6..-2)}"

IO.puts "\n--- Padding and Alignment ---"
word = "hi"
IO.puts "Original: '#{word}'"
IO.puts "Pad leading (10): '#{String.pad_leading(word, 10)}'"
IO.puts "Pad leading (10, '0'): '#{String.pad_leading(word, 10, "0")}'"
IO.puts "Pad trailing (10): '#{String.pad_trailing(word, 10)}'"
IO.puts "Pad trailing (10, '-'): '#{String.pad_trailing(word, 10, "-")}'"

IO.puts "\n--- Reversing ---"
text = "Hello"
IO.puts "Original: #{text}"
IO.puts "Reversed: #{String.reverse(text)}"

# Unicode-aware reversing
unicode_text = "noël"  # Note: ë might be composed
IO.puts "\nUnicode: #{unicode_text}"
IO.puts "Reversed: #{String.reverse(unicode_text)}"

IO.puts "\n--- Duplication ---"
IO.puts "Duplicate 'ab' 5 times: #{String.duplicate("ab", 5)}"

# ============================================================================
# PART 4: UNICODE NORMALIZATION
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 4: UNICODE NORMALIZATION                                                │
└──────────────────────────────────────────────────────────────────────────────┘

Unicode normalization ensures consistent representation of characters.
There are four normalization forms: NFC, NFD, NFKC, NFKD

• NFC (Canonical Decomposition, then Canonical Composition) - Most common
• NFD (Canonical Decomposition)
• NFKC (Compatibility Decomposition, then Canonical Composition)
• NFKD (Compatibility Decomposition)
"""

# Two representations of café
cafe_nfc = "café"           # Precomposed
cafe_nfd = "cafe\u0301"     # Decomposed (e + combining accent)

IO.puts "Precomposed 'café': #{inspect(cafe_nfc)}"
IO.puts "Decomposed 'café': #{inspect(cafe_nfd)}"
IO.puts "Equal? #{cafe_nfc == cafe_nfd}"

# Normalize both to NFC
normalized_nfc = String.normalize(cafe_nfd, :nfc)
IO.puts "\nAfter NFC normalization:"
IO.puts "Normalized: #{inspect(normalized_nfc)}"
IO.puts "Equal to precomposed? #{normalized_nfc == cafe_nfc}"

# Normalize to NFD
normalized_nfd = String.normalize(cafe_nfc, :nfd)
IO.puts "\nAfter NFD normalization:"
IO.puts "Codepoints: #{inspect(String.codepoints(normalized_nfd))}"

# ============================================================================
# PART 5: BINARY PATTERN MATCHING
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 5: BINARY PATTERN MATCHING                                              │
└──────────────────────────────────────────────────────────────────────────────┘

Elixir allows powerful pattern matching on binaries, which is great for
parsing protocols, file formats, and string processing.
"""

# Basic pattern matching
<<first_byte, rest::binary>> = "hello"
IO.puts "First byte of 'hello': #{first_byte} (#{<<first_byte>>})"
IO.puts "Rest: #{rest}"

# Matching specific bytes
<<104, 101, rest::binary>> = "hello"
IO.puts "\nMatching 'he': rest = #{rest}"

# Extracting fixed-size segments
<<header::binary-size(3), body::binary>> = "GETINDEX"
IO.puts "\nHeader (3 bytes): #{header}"
IO.puts "Body: #{body}"

# Working with UTF-8
<<first_char::utf8, rest::binary>> = "élixir"
IO.puts "\nFirst UTF-8 char of 'élixir': #{<<first_char::utf8>>} (codepoint: #{first_char})"
IO.puts "Rest: #{rest}"

# Parsing a simple protocol
defmodule ProtocolParser do
  def parse(<<"MSG:", length::binary-size(2), ":", message::binary>>) do
    {:message, String.to_integer(length), message}
  end

  def parse(<<"ACK:", id::binary-size(4)>>) do
    {:ack, id}
  end

  def parse(<<"ERR:", code::binary>>) do
    {:error, code}
  end

  def parse(_) do
    {:unknown}
  end
end

IO.puts "\n--- Protocol Parsing Example ---"
IO.puts "Parse 'MSG:05:Hello': #{inspect(ProtocolParser.parse("MSG:05:Hello"))}"
IO.puts "Parse 'ACK:1234': #{inspect(ProtocolParser.parse("ACK:1234"))}"
IO.puts "Parse 'ERR:404': #{inspect(ProtocolParser.parse("ERR:404"))}"

# ============================================================================
# PART 6: CHARLISTS VS STRINGS
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 6: CHARLISTS VS STRINGS                                                 │
└──────────────────────────────────────────────────────────────────────────────┘

Elixir has TWO text representations:
• Strings (double quotes): UTF-8 encoded binaries - PREFERRED
• Charlists (single quotes): Lists of codepoints - For Erlang interop
"""

string = "hello"
charlist = ~c"hello"

IO.puts "String: #{inspect(string)}"
IO.puts "Charlist: #{inspect(charlist)}"
IO.puts ""
IO.puts "String is binary? #{is_binary(string)}"
IO.puts "Charlist is list? #{is_list(charlist)}"

IO.puts "\n--- Conversion ---"
IO.puts "String to charlist: #{inspect(String.to_charlist(string))}"
IO.puts "Charlist to string: #{inspect(List.to_string(charlist))}"

IO.puts "\n--- When to Use Charlists ---"
IO.puts "Charlists are mainly for Erlang interoperability."
IO.puts "Most Erlang functions expect charlists, not strings."

# Example: Erlang's :io.format
IO.puts "\nErlang :io.format example:"
:io.format(~c"Hello ~s!~n", [~c"World"])

# ============================================================================
# PART 7: STRING PERFORMANCE TIPS
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 7: STRING PERFORMANCE TIPS                                              │
└──────────────────────────────────────────────────────────────────────────────┘
"""

IO.puts """
1. Use byte_size/1 instead of String.length/1 when possible
   - byte_size is O(1), String.length is O(n)

2. Use IO lists for building strings
   - More efficient than repeated concatenation

3. Use String.valid?/1 to check UTF-8 validity

4. Use :binary.match for simple byte searches
   - Faster than String functions for ASCII

5. Prefer pattern matching over String.at/2 for first/last chars
"""

# IO lists example
IO.puts "--- IO Lists for Efficient String Building ---"

# Inefficient: repeated concatenation
# result = ""
# result = result <> "Hello"
# result = result <> ", "
# result = result <> "World"
# result = result <> "!"

# Efficient: IO list
io_list = ["Hello", ", ", "World", "!"]
result = IO.iodata_to_binary(io_list)
IO.puts "IO list: #{inspect(io_list)}"
IO.puts "As binary: #{result}"

# Nested IO lists work too!
nested = [["Hello", [", "]], ["World", "!"]]
IO.puts "Nested IO list: #{inspect(nested)}"
IO.puts "As binary: #{IO.iodata_to_binary(nested)}"

# String validity
IO.puts "\n--- String Validity ---"
IO.puts "Is 'hello' valid UTF-8? #{String.valid?("hello")}"
IO.puts "Is <<255>> valid UTF-8? #{String.valid?(<<255>>)}"

# ============================================================================
# EXERCISES
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ EXERCISES                                                                    │
└──────────────────────────────────────────────────────────────────────────────┘
"""

defmodule StringExercises do
  @moduledoc """
  Complete these exercises to practice string handling.
  """

  @doc """
  Exercise 1: Count Graphemes
  Count the number of graphemes (perceived characters) in a string.
  Handle emoji and combining characters correctly.

  Examples:
    count_graphemes("hello") => 5
    count_graphemes("👨‍👩‍👧") => 1
    count_graphemes("café") => 4
  """
  def count_graphemes(string) do
    # Your implementation here
    String.length(string)
  end

  @doc """
  Exercise 2: Truncate String
  Truncate a string to a maximum number of graphemes, adding "..." if truncated.
  Preserve complete graphemes (don't split emoji or combined characters).

  Examples:
    truncate("Hello, World!", 5) => "Hello..."
    truncate("Hi", 5) => "Hi"
    truncate("👋🏽👋🏽👋🏽", 2) => "👋🏽👋🏽..."
  """
  def truncate(string, max_length) do
    if String.length(string) <= max_length do
      string
    else
      string
      |> String.graphemes()
      |> Enum.take(max_length)
      |> Enum.join()
      |> Kernel.<>("...")
    end
  end

  @doc """
  Exercise 3: Word Count
  Count words in a string. Words are separated by whitespace.
  Handle multiple spaces and leading/trailing whitespace.

  Examples:
    word_count("Hello World") => 2
    word_count("  multiple   spaces  ") => 2
    word_count("") => 0
  """
  def word_count(string) do
    string
    |> String.split(~r/\s+/, trim: true)
    |> length()
  end

  @doc """
  Exercise 4: Parse CSV Line
  Parse a simple CSV line into a list of fields.
  Handle quoted fields that may contain commas.

  Examples:
    parse_csv("a,b,c") => ["a", "b", "c"]
    parse_csv("\"a,b\",c") => ["a,b", "c"]
    parse_csv("") => []
  """
  def parse_csv(""), do: []
  def parse_csv(line) do
    # Simple implementation - for full CSV parsing, use a library!
    # This handles basic cases
    parse_csv_fields(line, [], "")
  end

  defp parse_csv_fields("", acc, current) do
    Enum.reverse([current | acc])
  end

  defp parse_csv_fields("," <> rest, acc, current) do
    parse_csv_fields(rest, [current | acc], "")
  end

  defp parse_csv_fields("\"" <> rest, acc, "") do
    # Start of quoted field
    parse_quoted_field(rest, acc, "")
  end

  defp parse_csv_fields(<<char::utf8, rest::binary>>, acc, current) do
    parse_csv_fields(rest, acc, current <> <<char::utf8>>)
  end

  defp parse_quoted_field("\"," <> rest, acc, current) do
    parse_csv_fields(rest, [current | acc], "")
  end

  defp parse_quoted_field("\"", acc, current) do
    Enum.reverse([current | acc])
  end

  defp parse_quoted_field(<<char::utf8, rest::binary>>, acc, current) do
    parse_quoted_field(rest, acc, current <> <<char::utf8>>)
  end

  @doc """
  Exercise 5: Extract Emails
  Extract all email addresses from a text string.
  Use a simple pattern: word@word.word

  Examples:
    extract_emails("Contact us at hello@example.com") => ["hello@example.com"]
    extract_emails("No emails here") => []
  """
  def extract_emails(text) do
    Regex.scan(~r/[\w.+-]+@[\w.-]+\.\w+/, text)
    |> List.flatten()
  end
end

# Test the exercises
IO.puts "--- Testing Exercises ---\n"

IO.puts "Exercise 1: Count Graphemes"
IO.puts "count_graphemes(\"hello\"): #{StringExercises.count_graphemes("hello")}"
IO.puts "count_graphemes(\"👨‍👩‍👧\"): #{StringExercises.count_graphemes("👨‍👩‍👧")}"
IO.puts "count_graphemes(\"café\"): #{StringExercises.count_graphemes("café")}"

IO.puts "\nExercise 2: Truncate"
IO.puts "truncate(\"Hello, World!\", 5): #{StringExercises.truncate("Hello, World!", 5)}"
IO.puts "truncate(\"Hi\", 5): #{StringExercises.truncate("Hi", 5)}"

IO.puts "\nExercise 3: Word Count"
IO.puts "word_count(\"Hello World\"): #{StringExercises.word_count("Hello World")}"
IO.puts "word_count(\"  multiple   spaces  \"): #{StringExercises.word_count("  multiple   spaces  ")}"

IO.puts "\nExercise 4: Parse CSV"
IO.puts "parse_csv(\"a,b,c\"): #{inspect(StringExercises.parse_csv("a,b,c"))}"
IO.puts "parse_csv(\"\\\"a,b\\\",c\"): #{inspect(StringExercises.parse_csv("\"a,b\",c"))}"

IO.puts "\nExercise 5: Extract Emails"
IO.puts "extract_emails(\"Contact hello@example.com or test@test.org\"): #{inspect(StringExercises.extract_emails("Contact hello@example.com or test@test.org"))}"

IO.puts """

╔══════════════════════════════════════════════════════════════════════════════╗
║                         LESSON COMPLETE!                                      ║
║                                                                              ║
║  Key Takeaways:                                                              ║
║  • Strings are UTF-8 encoded binaries                                        ║
║  • Graphemes != Codepoints (especially with emoji and accents)               ║
║  • Use String.length/1 for character count, byte_size/1 for bytes            ║
║  • Binary pattern matching is powerful for parsing                           ║
║  • Prefer IO lists for building strings efficiently                          ║
║  • Use charlists mainly for Erlang interop                                   ║
║                                                                              ║
║  Next: 06_sigils.exs - Sigils for Common Data Types                          ║
╚══════════════════════════════════════════════════════════════════════════════╝
"""
