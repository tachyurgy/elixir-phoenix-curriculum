# ============================================================================
# Lesson 16: File Operations
# ============================================================================
#
# Elixir provides comprehensive file handling capabilities through the File
# module. In this lesson, you'll learn how to read, write, and manipulate
# files safely and efficiently.
#
# Topics covered:
# - File.read and File.read!
# - File.write and File.write!
# - File.stream! for large files
# - File.stat for file information
# - File existence and permission checks
# - Safe file handling patterns
#
# ============================================================================

IO.puts """
================================================================================
                    FILE OPERATIONS IN ELIXIR
================================================================================
"""

# Create a temporary directory for our examples
tmp_dir = Path.join(System.tmp_dir!(), "elixir_file_lesson_#{:rand.uniform(10000)}")
File.mkdir_p!(tmp_dir)
IO.puts "Working in temporary directory: #{tmp_dir}\n"

# ============================================================================
# Part 1: Reading Files
# ============================================================================

IO.puts """
--------------------------------------------------------------------------------
Part 1: Reading Files
--------------------------------------------------------------------------------

Elixir provides two main functions for reading files:
- File.read/1 returns {:ok, content} or {:error, reason}
- File.read!/1 returns content directly or raises an error

The pattern with ! (bang) functions is common in Elixir:
- Without !: Returns tuple, allows graceful error handling
- With !: Returns value directly or raises exception
"""

# Create a sample file to read
sample_file = Path.join(tmp_dir, "sample.txt")
File.write!(sample_file, "Hello, Elixir!\nThis is line 2.\nThis is line 3.")

IO.puts "--- File.read/1 (Safe version) ---"

case File.read(sample_file) do
  {:ok, content} ->
    IO.puts "Successfully read file:"
    IO.puts content
  {:error, reason} ->
    IO.puts "Failed to read file: #{reason}"
end

IO.puts "\n--- File.read/1 with non-existent file ---"

case File.read("/nonexistent/file.txt") do
  {:ok, _content} ->
    IO.puts "File exists"
  {:error, :enoent} ->
    IO.puts "File not found (enoent = Error NO ENTry)"
  {:error, reason} ->
    IO.puts "Other error: #{reason}"
end

IO.puts "\n--- File.read!/1 (Bang version) ---"
content = File.read!(sample_file)
IO.puts "Content length: #{String.length(content)} characters"

IO.puts "\n--- Reading binary files ---"
# Create a file with binary data
binary_file = Path.join(tmp_dir, "data.bin")
File.write!(binary_file, <<0, 1, 2, 3, 255, 254, 253>>)

binary_content = File.read!(binary_file)
IO.puts "Binary content: #{inspect(binary_content)}"
IO.puts "Byte size: #{byte_size(binary_content)}"

# ============================================================================
# Part 2: Writing Files
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 2: Writing Files
--------------------------------------------------------------------------------

Writing files with File.write/2 and File.write!/2:
- By default, creates or overwrites the file
- Options allow appending, setting permissions, etc.
"""

IO.puts "--- Basic file writing ---"
output_file = Path.join(tmp_dir, "output.txt")

# Write with error handling
case File.write(output_file, "First line of content") do
  :ok ->
    IO.puts "File written successfully!"
  {:error, reason} ->
    IO.puts "Failed to write: #{reason}"
end

IO.puts "Content: #{File.read!(output_file)}"

IO.puts "\n--- Appending to files ---"
# Append mode
File.write!(output_file, "\nAppended line", [:append])
IO.puts "After append: #{File.read!(output_file)}"

IO.puts "\n--- Writing with modes ---"
modes_file = Path.join(tmp_dir, "modes.txt")

# Write with specific modes
File.write!(modes_file, "Binary mode", [:binary])
File.write!(modes_file, "\nSync write", [:append, :sync])

IO.puts "Content with modes: #{File.read!(modes_file)}"

IO.puts "\n--- Writing different data types ---"
data_file = Path.join(tmp_dir, "data.txt")

# Write iodata (list of strings/binaries/chars)
iodata = ["Part 1", " - ", "Part 2", ?\n, "Line 2"]
File.write!(data_file, iodata)
IO.puts "IOData content: #{File.read!(data_file)}"

# Write charlists
charlist_file = Path.join(tmp_dir, "charlist.txt")
File.write!(charlist_file, ~c"Hello from charlist")
IO.puts "Charlist content: #{File.read!(charlist_file)}"

# ============================================================================
# Part 3: File Streams for Large Files
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 3: File Streams for Large Files
--------------------------------------------------------------------------------

For large files, reading everything into memory is inefficient.
File.stream!/3 creates a lazy stream that reads the file on demand.

This is memory-efficient and works well with Enum and Stream functions.
"""

# Create a larger file for streaming
large_file = Path.join(tmp_dir, "large.txt")
lines = for i <- 1..100, do: "Line #{i}: #{String.duplicate("x", 50)}\n"
File.write!(large_file, lines)

IO.puts "--- Basic file streaming ---"

# Stream reads lines lazily
File.stream!(large_file)
|> Enum.take(3)
|> Enum.each(&IO.write/1)

IO.puts "\n--- Stream with line modes ---"

# By default, streams return lines with newlines
# Use :trim option to remove trailing newlines
File.stream!(large_file, :line)
|> Stream.map(&String.trim/1)
|> Enum.take(3)
|> Enum.each(&IO.puts/1)

IO.puts "\n--- Byte streaming ---"

# Stream in chunks of bytes
File.stream!(large_file, 100)  # 100 bytes at a time
|> Enum.take(2)
|> Enum.each(fn chunk ->
  IO.puts "Chunk (#{byte_size(chunk)} bytes): #{String.slice(chunk, 0, 40)}..."
end)

IO.puts "\n--- Processing streams ---"

# Count lines containing specific text
count = File.stream!(large_file)
|> Enum.count(&String.contains?(&1, "Line 5"))

IO.puts "Lines containing 'Line 5': #{count}"

# Sum of line numbers (extracting numbers from lines)
sum = File.stream!(large_file)
|> Stream.map(fn line ->
  case Regex.run(~r/Line (\d+):/, line) do
    [_, num] -> String.to_integer(num)
    nil -> 0
  end
end)
|> Enum.sum()

IO.puts "Sum of line numbers: #{sum}"

IO.puts "\n--- Writing with streams ---"

# Stream from one file to another (with transformation)
stream_output = Path.join(tmp_dir, "stream_output.txt")

File.stream!(large_file)
|> Stream.take(5)
|> Stream.map(&String.upcase/1)
|> Enum.into(File.stream!(stream_output))

IO.puts "Streamed and transformed content:"
IO.puts File.read!(stream_output)

# ============================================================================
# Part 4: File Information with File.stat
# ============================================================================

IO.puts """
--------------------------------------------------------------------------------
Part 4: File Information with File.stat
--------------------------------------------------------------------------------

File.stat/1 returns detailed information about a file:
- Size
- Type (regular, directory, symlink, etc.)
- Access time, modification time, creation time
- Permissions (mode)
- UID and GID
"""

IO.puts "--- File.stat example ---"

case File.stat(sample_file) do
  {:ok, stat} ->
    IO.puts "File: #{sample_file}"
    IO.puts "  Size: #{stat.size} bytes"
    IO.puts "  Type: #{stat.type}"
    IO.puts "  Access: #{stat.access}"
    IO.puts "  Mode: #{Integer.to_string(stat.mode, 8)}"
    IO.puts "  Modified: #{inspect(stat.mtime)}"
  {:error, reason} ->
    IO.puts "Error: #{reason}"
end

IO.puts "\n--- Checking directory stats ---"

{:ok, dir_stat} = File.stat(tmp_dir)
IO.puts "Directory type: #{dir_stat.type}"
IO.puts "Is directory: #{dir_stat.type == :directory}"

IO.puts "\n--- File.stat!/1 with options ---"

# Get time in POSIX format
{:ok, stat_posix} = File.stat(sample_file, time: :posix)
IO.puts "Modified (POSIX timestamp): #{stat_posix.mtime}"

# Get time as DateTime
{:ok, stat_datetime} = File.stat(sample_file, time: :datetime)
IO.puts "Modified (DateTime): #{inspect(stat_datetime.mtime)}"

# ============================================================================
# Part 5: File Existence and Permission Checks
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 5: File Existence and Permission Checks
--------------------------------------------------------------------------------

Quick checks without getting full stat information:
- File.exists?/1 - Does the file/directory exist?
- File.regular?/1 - Is it a regular file?
- File.dir?/1 - Is it a directory?
"""

IO.puts "--- Existence checks ---"

IO.puts "sample.txt exists? #{File.exists?(sample_file)}"
IO.puts "/nonexistent exists? #{File.exists?("/nonexistent")}"
IO.puts "tmp_dir exists? #{File.exists?(tmp_dir)}"

IO.puts "\n--- Type checks ---"

IO.puts "sample.txt is regular file? #{File.regular?(sample_file)}"
IO.puts "tmp_dir is regular file? #{File.regular?(tmp_dir)}"
IO.puts "tmp_dir is directory? #{File.dir?(tmp_dir)}"
IO.puts "sample.txt is directory? #{File.dir?(sample_file)}"

IO.puts "\n--- Safe file operations pattern ---"

defmodule SafeFileOps do
  def read_if_exists(path) do
    if File.exists?(path) and File.regular?(path) do
      {:ok, File.read!(path)}
    else
      {:error, :not_found}
    end
  end

  def write_if_not_exists(path, content) do
    if File.exists?(path) do
      {:error, :already_exists}
    else
      File.write(path, content)
    end
  end

  def ensure_write(path, content) do
    # Create parent directories if needed
    path |> Path.dirname() |> File.mkdir_p!()
    File.write(path, content)
  end
end

new_file = Path.join(tmp_dir, "new_file.txt")
IO.puts "\nSafe write to new file: #{inspect(SafeFileOps.write_if_not_exists(new_file, "content"))}"
IO.puts "Safe write again: #{inspect(SafeFileOps.write_if_not_exists(new_file, "content"))}"

# ============================================================================
# Part 6: Other File Operations
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 6: Other File Operations
--------------------------------------------------------------------------------

The File module provides many other useful operations:
- File.copy/2, File.copy!/2 - Copy files
- File.rename/2 - Move/rename files
- File.rm/1, File.rm!/1 - Remove files
- File.mkdir/1, File.mkdir_p/1 - Create directories
- File.ls/1, File.ls!/1 - List directory contents
"""

IO.puts "--- Copying files ---"
copy_src = Path.join(tmp_dir, "copy_source.txt")
copy_dst = Path.join(tmp_dir, "copy_dest.txt")

File.write!(copy_src, "Content to copy")
File.copy!(copy_src, copy_dst)
IO.puts "Copied content: #{File.read!(copy_dst)}"

IO.puts "\n--- Renaming/Moving files ---"
rename_src = Path.join(tmp_dir, "old_name.txt")
rename_dst = Path.join(tmp_dir, "new_name.txt")

File.write!(rename_src, "File to rename")
File.rename(rename_src, rename_dst)
IO.puts "old_name.txt exists? #{File.exists?(rename_src)}"
IO.puts "new_name.txt exists? #{File.exists?(rename_dst)}"

IO.puts "\n--- Creating directories ---"
nested_dir = Path.join(tmp_dir, "level1/level2/level3")
File.mkdir_p!(nested_dir)
IO.puts "Created nested directory: #{File.dir?(nested_dir)}"

IO.puts "\n--- Listing directory contents ---"
{:ok, contents} = File.ls(tmp_dir)
IO.puts "Directory contents:"
for item <- Enum.sort(contents) do
  full_path = Path.join(tmp_dir, item)
  type = if File.dir?(full_path), do: "[DIR]", else: "[FILE]"
  IO.puts "  #{type} #{item}"
end

IO.puts "\n--- Removing files ---"
to_remove = Path.join(tmp_dir, "to_remove.txt")
File.write!(to_remove, "Delete me")
IO.puts "Before rm: exists? #{File.exists?(to_remove)}"
File.rm!(to_remove)
IO.puts "After rm: exists? #{File.exists?(to_remove)}"

IO.puts "\n--- Removing directories ---"
# File.rmdir only removes empty directories
# File.rm_rf removes directories recursively
subdir = Path.join(tmp_dir, "subdir_to_remove")
File.mkdir_p!(Path.join(subdir, "nested"))
File.write!(Path.join(subdir, "file.txt"), "content")

IO.puts "Before rm_rf: exists? #{File.exists?(subdir)}"
File.rm_rf!(subdir)
IO.puts "After rm_rf: exists? #{File.exists?(subdir)}"

# ============================================================================
# Part 7: Working with File Handles
# ============================================================================

IO.puts """

--------------------------------------------------------------------------------
Part 7: Working with File Handles (Low-level Operations)
--------------------------------------------------------------------------------

For more control, use File.open/2 with a function or manage handles manually.
This is useful for:
- Random access (seeking)
- Multiple read/write operations
- Binary file manipulation
"""

IO.puts "--- Using File.open with a function ---"

handle_file = Path.join(tmp_dir, "handle.txt")

# File is automatically closed after the function
File.open(handle_file, [:write], fn file ->
  IO.write(file, "Line 1\n")
  IO.write(file, "Line 2\n")
  IO.write(file, "Line 3\n")
end)

IO.puts "Content written via handle:"
IO.puts File.read!(handle_file)

IO.puts "\n--- Manual file handle management ---"

{:ok, file} = File.open(handle_file, [:read])

# Read specific amounts
{:ok, first_line} = IO.read(file, :line)
IO.puts "First line: #{String.trim(first_line)}"

{:ok, rest} = IO.read(file, :all)
IO.puts "Rest: #{String.trim(rest)}"

File.close(file)

IO.puts "\n--- Random access with :file module ---"

random_file = Path.join(tmp_dir, "random.bin")
File.write!(random_file, "ABCDEFGHIJ")

{:ok, fd} = :file.open(random_file, [:read, :binary])

# Seek to position 5 and read
{:ok, _} = :file.position(fd, 5)
{:ok, data} = :file.read(fd, 3)
IO.puts "Read from position 5: #{data}"

:file.close(fd)

# ============================================================================
# Exercises
# ============================================================================

IO.puts """

================================================================================
                              EXERCISES
================================================================================
"""

IO.puts """
--------------------------------------------------------------------------------
Exercise 1: Log File Analyzer
--------------------------------------------------------------------------------
Create a module that analyzes a log file and returns:
- Total number of lines
- Number of error lines (containing "ERROR")
- Number of warning lines (containing "WARN")
- Most common log level
"""

# Create a sample log file for the exercise
log_file = Path.join(tmp_dir, "app.log")
log_content = """
2024-01-15 10:00:01 INFO Application started
2024-01-15 10:00:02 DEBUG Loading configuration
2024-01-15 10:00:03 INFO Configuration loaded
2024-01-15 10:00:04 WARN Deprecated feature used
2024-01-15 10:00:05 ERROR Database connection failed
2024-01-15 10:00:06 INFO Retrying connection
2024-01-15 10:00:07 ERROR Retry failed
2024-01-15 10:00:08 INFO Using fallback database
2024-01-15 10:00:09 DEBUG Query executed
2024-01-15 10:00:10 WARN Slow query detected
2024-01-15 10:00:11 INFO Request processed
2024-01-15 10:00:12 ERROR Timeout occurred
"""
File.write!(log_file, log_content)

# Exercise 1 Solution:
defmodule LogAnalyzer do
  def analyze(path) do
    lines = File.stream!(path) |> Enum.to_list()

    levels = Enum.map(lines, fn line ->
      cond do
        String.contains?(line, "ERROR") -> :error
        String.contains?(line, "WARN") -> :warn
        String.contains?(line, "INFO") -> :info
        String.contains?(line, "DEBUG") -> :debug
        true -> :unknown
      end
    end)

    level_counts = Enum.frequencies(levels)
    {most_common, _count} = Enum.max_by(level_counts, fn {_level, count} -> count end)

    %{
      total_lines: length(lines),
      errors: Map.get(level_counts, :error, 0),
      warnings: Map.get(level_counts, :warn, 0),
      most_common_level: most_common,
      level_breakdown: level_counts
    }
  end
end

IO.puts "--- Exercise 1 Solution ---"
analysis = LogAnalyzer.analyze(log_file)
IO.inspect(analysis, label: "Log Analysis")

IO.puts """

--------------------------------------------------------------------------------
Exercise 2: CSV File Handler
--------------------------------------------------------------------------------
Create a module that can:
- Read a CSV file into a list of maps
- Write a list of maps to a CSV file
- Handle headers automatically
"""

# Create sample CSV
csv_file = Path.join(tmp_dir, "data.csv")
File.write!(csv_file, """
name,age,city
Alice,30,New York
Bob,25,San Francisco
Carol,35,Chicago
""")

# Exercise 2 Solution:
defmodule CSVHandler do
  def read(path) do
    [header | rows] = File.stream!(path)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.to_list()

    headers = String.split(header, ",") |> Enum.map(&String.to_atom/1)

    Enum.map(rows, fn row ->
      values = String.split(row, ",")
      Enum.zip(headers, values) |> Map.new()
    end)
  end

  def write(path, data) when is_list(data) do
    if data == [] do
      File.write(path, "")
    else
      headers = Map.keys(hd(data))
      header_line = Enum.join(headers, ",")

      rows = Enum.map(data, fn map ->
        Enum.map(headers, &Map.get(map, &1, ""))
        |> Enum.join(",")
      end)

      content = [header_line | rows] |> Enum.join("\n")
      File.write(path, content <> "\n")
    end
  end
end

IO.puts "--- Exercise 2 Solution ---"
data = CSVHandler.read(csv_file)
IO.inspect(data, label: "CSV Data")

# Write new CSV
new_data = [
  %{name: "Dave", age: "28", city: "Boston"},
  %{name: "Eve", age: "32", city: "Seattle"}
]
output_csv = Path.join(tmp_dir, "output.csv")
CSVHandler.write(output_csv, new_data)
IO.puts "\nWritten CSV:"
IO.puts File.read!(output_csv)

IO.puts """

--------------------------------------------------------------------------------
Exercise 3: File Backup System
--------------------------------------------------------------------------------
Create a module that:
- Creates timestamped backups of files
- Restores from the latest backup
- Lists available backups
- Cleans up old backups (keep only N most recent)
"""

# Exercise 3 Solution:
defmodule FileBackup do
  def backup(path, backup_dir \\ nil) do
    backup_dir = backup_dir || Path.dirname(path)
    basename = Path.basename(path)
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601(:basic)
    backup_name = "#{basename}.#{timestamp}.backup"
    backup_path = Path.join(backup_dir, backup_name)

    File.mkdir_p!(backup_dir)
    File.copy!(path, backup_path)
    {:ok, backup_path}
  end

  def list_backups(path, backup_dir \\ nil) do
    backup_dir = backup_dir || Path.dirname(path)
    basename = Path.basename(path)
    pattern = "#{basename}.*.backup"

    case File.ls(backup_dir) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.match?(&1, ~r/^#{Regex.escape(basename)}\..+\.backup$/))
        |> Enum.sort(:desc)
        |> Enum.map(&Path.join(backup_dir, &1))
      {:error, _} ->
        []
    end
  end

  def restore_latest(path, backup_dir \\ nil) do
    case list_backups(path, backup_dir) do
      [latest | _] ->
        File.copy!(latest, path)
        {:ok, latest}
      [] ->
        {:error, :no_backups}
    end
  end

  def cleanup(path, keep_count, backup_dir \\ nil) do
    backups = list_backups(path, backup_dir)
    to_delete = Enum.drop(backups, keep_count)

    Enum.each(to_delete, &File.rm!/1)
    length(to_delete)
  end
end

IO.puts "--- Exercise 3 Solution ---"
backup_test_file = Path.join(tmp_dir, "important.txt")
File.write!(backup_test_file, "Original content")

# Create some backups
{:ok, b1} = FileBackup.backup(backup_test_file)
:timer.sleep(100)
File.write!(backup_test_file, "Modified content 1")
{:ok, b2} = FileBackup.backup(backup_test_file)
:timer.sleep(100)
File.write!(backup_test_file, "Modified content 2")
{:ok, b3} = FileBackup.backup(backup_test_file)

IO.puts "Created backups:"
for backup <- FileBackup.list_backups(backup_test_file) do
  IO.puts "  #{Path.basename(backup)}"
end

# Modify and restore
File.write!(backup_test_file, "Corrupted!")
{:ok, restored_from} = FileBackup.restore_latest(backup_test_file)
IO.puts "\nRestored from: #{Path.basename(restored_from)}"
IO.puts "Restored content: #{File.read!(backup_test_file)}"

# Cleanup
deleted = FileBackup.cleanup(backup_test_file, 2)
IO.puts "\nDeleted #{deleted} old backup(s)"
IO.puts "Remaining backups: #{length(FileBackup.list_backups(backup_test_file))}"

IO.puts """

--------------------------------------------------------------------------------
Exercise 4: Configuration File Manager
--------------------------------------------------------------------------------
Create a module that:
- Reads configuration from various formats (detect by extension)
- Supports .txt (key=value), .json (if Jason available), .exs (Elixir terms)
- Provides get/set/delete operations
- Writes changes back to the file
"""

# Exercise 4 Solution:
defmodule ConfigManager do
  def load(path) do
    content = File.read!(path)
    ext = Path.extname(path)

    case ext do
      ".txt" -> parse_txt(content)
      ".exs" -> parse_exs(content)
      _ -> {:error, "Unsupported format: #{ext}"}
    end
  end

  defp parse_txt(content) do
    content
    |> String.split("\n")
    |> Enum.reject(&(String.trim(&1) == "" or String.starts_with?(String.trim(&1), "#")))
    |> Enum.map(fn line ->
      case String.split(line, "=", parts: 2) do
        [key, value] -> {String.trim(key), String.trim(value)}
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
  end

  defp parse_exs(content) do
    {result, _} = Code.eval_string(content)
    result
  end

  def save(path, config) do
    ext = Path.extname(path)

    content = case ext do
      ".txt" -> serialize_txt(config)
      ".exs" -> serialize_exs(config)
      _ -> raise "Unsupported format: #{ext}"
    end

    File.write!(path, content)
  end

  defp serialize_txt(config) do
    Enum.map(config, fn {k, v} -> "#{k}=#{v}" end)
    |> Enum.join("\n")
  end

  defp serialize_exs(config) do
    inspect(config, pretty: true, limit: :infinity)
  end

  def get(config, key, default \\ nil) do
    Map.get(config, key, default)
  end

  def set(config, key, value) do
    Map.put(config, key, value)
  end

  def delete(config, key) do
    Map.delete(config, key)
  end
end

IO.puts "--- Exercise 4 Solution ---"

# Test with .txt config
txt_config = Path.join(tmp_dir, "config.txt")
File.write!(txt_config, """
# Application config
host=localhost
port=8080
debug=true
""")

config = ConfigManager.load(txt_config)
IO.puts "Loaded config: #{inspect(config)}"

config = ConfigManager.set(config, "timeout", "30")
config = ConfigManager.delete(config, "debug")
IO.puts "Modified config: #{inspect(config)}"

ConfigManager.save(txt_config, config)
IO.puts "Saved config file:"
IO.puts File.read!(txt_config)

# Test with .exs config
exs_config = Path.join(tmp_dir, "config.exs")
File.write!(exs_config, ~s|%{app_name: "MyApp", version: "1.0.0", features: [:auth, :api]}|)

exs_data = ConfigManager.load(exs_config)
IO.puts "\nLoaded .exs config: #{inspect(exs_data)}"

IO.puts """

--------------------------------------------------------------------------------
Exercise 5: Directory Synchronizer
--------------------------------------------------------------------------------
Create a module that:
- Compares two directories
- Reports files that are only in source, only in dest, or different
- Can sync (copy new/changed files from source to dest)
"""

# Exercise 5 Solution:
defmodule DirectorySynchronizer do
  def compare(source, dest) do
    source_files = list_files_recursive(source, source)
    dest_files = list_files_recursive(dest, dest)

    source_set = MapSet.new(Map.keys(source_files))
    dest_set = MapSet.new(Map.keys(dest_files))

    only_in_source = MapSet.difference(source_set, dest_set) |> MapSet.to_list()
    only_in_dest = MapSet.difference(dest_set, source_set) |> MapSet.to_list()

    in_both = MapSet.intersection(source_set, dest_set) |> MapSet.to_list()

    different = Enum.filter(in_both, fn file ->
      source_files[file] != dest_files[file]
    end)

    %{
      only_in_source: only_in_source,
      only_in_dest: only_in_dest,
      different: different,
      identical: length(in_both) - length(different)
    }
  end

  defp list_files_recursive(dir, base) do
    case File.ls(dir) do
      {:ok, entries} ->
        Enum.flat_map(entries, fn entry ->
          path = Path.join(dir, entry)
          relative = Path.relative_to(path, base)

          if File.dir?(path) do
            list_files_recursive(path, base) |> Map.to_list()
          else
            [{relative, file_hash(path)}]
          end
        end)
        |> Map.new()
      {:error, _} ->
        %{}
    end
  end

  defp file_hash(path) do
    # Simple hash based on content
    content = File.read!(path)
    :erlang.phash2(content)
  end

  def sync(source, dest) do
    comparison = compare(source, dest)

    # Copy files only in source
    for file <- comparison.only_in_source do
      source_path = Path.join(source, file)
      dest_path = Path.join(dest, file)
      File.mkdir_p!(Path.dirname(dest_path))
      File.copy!(source_path, dest_path)
    end

    # Copy different files
    for file <- comparison.different do
      source_path = Path.join(source, file)
      dest_path = Path.join(dest, file)
      File.copy!(source_path, dest_path)
    end

    %{
      copied: length(comparison.only_in_source),
      updated: length(comparison.different)
    }
  end
end

IO.puts "--- Exercise 5 Solution ---"

# Setup test directories
source_dir = Path.join(tmp_dir, "source")
dest_dir = Path.join(tmp_dir, "dest")
File.mkdir_p!(source_dir)
File.mkdir_p!(dest_dir)

# Create files in source
File.write!(Path.join(source_dir, "file1.txt"), "Content 1")
File.write!(Path.join(source_dir, "file2.txt"), "Content 2")
File.mkdir_p!(Path.join(source_dir, "subdir"))
File.write!(Path.join(source_dir, "subdir/file3.txt"), "Content 3")

# Create some files in dest (one same, one different)
File.write!(Path.join(dest_dir, "file1.txt"), "Content 1")  # Same
File.write!(Path.join(dest_dir, "file2.txt"), "Different!")  # Different
File.write!(Path.join(dest_dir, "extra.txt"), "Extra file")  # Only in dest

comparison = DirectorySynchronizer.compare(source_dir, dest_dir)
IO.puts "Comparison result:"
IO.inspect(comparison, pretty: true)

result = DirectorySynchronizer.sync(source_dir, dest_dir)
IO.puts "\nSync result: #{inspect(result)}"

# Verify
IO.puts "After sync, dest/subdir/file3.txt exists: #{File.exists?(Path.join(dest_dir, "subdir/file3.txt"))}"

IO.puts """

--------------------------------------------------------------------------------
Exercise 6: File Watcher (Polling-based)
--------------------------------------------------------------------------------
Create a module that:
- Monitors a directory for changes
- Detects new files, modified files, and deleted files
- Calls callbacks for each type of change
(Note: This is a polling-based implementation for learning purposes)
"""

# Exercise 6 Solution:
defmodule FileWatcher do
  def get_state(dir) do
    case File.ls(dir) do
      {:ok, entries} ->
        Enum.flat_map(entries, fn entry ->
          path = Path.join(dir, entry)
          if File.regular?(path) do
            {:ok, stat} = File.stat(path)
            [{entry, stat.mtime}]
          else
            []
          end
        end)
        |> Map.new()
      {:error, _} ->
        %{}
    end
  end

  def detect_changes(old_state, new_state) do
    old_keys = MapSet.new(Map.keys(old_state))
    new_keys = MapSet.new(Map.keys(new_state))

    created = MapSet.difference(new_keys, old_keys) |> MapSet.to_list()
    deleted = MapSet.difference(old_keys, new_keys) |> MapSet.to_list()

    common = MapSet.intersection(old_keys, new_keys) |> MapSet.to_list()
    modified = Enum.filter(common, fn file ->
      old_state[file] != new_state[file]
    end)

    %{created: created, modified: modified, deleted: deleted}
  end

  def watch_once(dir, old_state \\ %{}) do
    new_state = get_state(dir)
    changes = detect_changes(old_state, new_state)
    {changes, new_state}
  end

  # Simulate watching with a manual check
  def demo_watch(dir, iterations, interval_ms) do
    IO.puts "Starting file watcher on #{dir}"

    Enum.reduce(1..iterations, get_state(dir), fn i, state ->
      :timer.sleep(interval_ms)
      {changes, new_state} = watch_once(dir, state)

      if changes.created != [] or changes.modified != [] or changes.deleted != [] do
        IO.puts "\n[Iteration #{i}] Changes detected:"
        for file <- changes.created, do: IO.puts("  + Created: #{file}")
        for file <- changes.modified, do: IO.puts("  ~ Modified: #{file}")
        for file <- changes.deleted, do: IO.puts("  - Deleted: #{file}")
      end

      new_state
    end)

    IO.puts "\nWatcher finished."
  end
end

IO.puts "--- Exercise 6 Solution ---"
watch_dir = Path.join(tmp_dir, "watched")
File.mkdir_p!(watch_dir)
File.write!(Path.join(watch_dir, "initial.txt"), "Initial content")

# Get initial state
state1 = FileWatcher.get_state(watch_dir)
IO.puts "Initial state: #{inspect(state1)}"

# Make some changes
File.write!(Path.join(watch_dir, "new_file.txt"), "New content")
File.write!(Path.join(watch_dir, "initial.txt"), "Modified content")
:timer.sleep(1000)  # Ensure different mtime

# Check changes
{changes, _state2} = FileWatcher.watch_once(watch_dir, state1)
IO.puts "\nDetected changes:"
IO.inspect(changes, pretty: true)

# Cleanup temporary directory
IO.puts "\n--- Cleaning up ---"
File.rm_rf!(tmp_dir)
IO.puts "Temporary directory cleaned up."

IO.puts """

================================================================================
                              SUMMARY
================================================================================

Key concepts from this lesson:

1. Reading files:
   - File.read/1 returns {:ok, content} or {:error, reason}
   - File.read!/1 returns content or raises
   - Use File.stream!/1 for large files

2. Writing files:
   - File.write/2 and File.write!/2 with options
   - [:append] mode to add to existing file
   - iodata support for efficient writing

3. File streams:
   - Memory-efficient lazy reading
   - Works with Enum and Stream
   - Good for processing large files line by line

4. File information:
   - File.stat/1 for detailed info (size, mtime, type)
   - File.exists?/1, File.regular?/1, File.dir?/1

5. Other operations:
   - File.copy/2, File.rename/2, File.rm/1
   - File.mkdir_p/1, File.ls/1
   - File.rm_rf/1 for recursive deletion

6. Best practices:
   - Use bang (!) functions when errors are unexpected
   - Always handle errors with non-bang functions
   - Use streams for large files
   - Create parent directories with mkdir_p

================================================================================
"""
