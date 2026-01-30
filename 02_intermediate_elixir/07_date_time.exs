# ============================================================================
# DATE AND TIME - Working with Temporal Data in Elixir
# ============================================================================
#
# Elixir provides robust support for dates, times, and datetime handling.
# This lesson covers the Date, Time, DateTime, NaiveDateTime modules,
# the Calendar system, and timezone considerations.
#
# Run this file with: elixir 07_date_time.exs
# ============================================================================

IO.puts """
╔══════════════════════════════════════════════════════════════════════════════╗
║                          DATE AND TIME                                        ║
║                   Working with Temporal Data                                  ║
╚══════════════════════════════════════════════════════════════════════════════╝
"""

# ============================================================================
# PART 1: DATE - Working with Dates
# ============================================================================

IO.puts """
┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 1: DATE - Working with Dates                                            │
└──────────────────────────────────────────────────────────────────────────────┘

The Date struct represents a date without time information.
It stores year, month, and day in the ISO 8601 calendar.
"""

# Creating dates
IO.puts "--- Creating Dates ---"

# Using the sigil
date1 = ~D[2024-03-15]
IO.puts "Using sigil: #{inspect(date1)}"

# Using Date.new/3
{:ok, date2} = Date.new(2024, 3, 15)
IO.puts "Using Date.new: #{inspect(date2)}"

# Date.new!/3 raises on invalid dates
date3 = Date.new!(2024, 12, 25)
IO.puts "Using Date.new!: #{inspect(date3)}"

# Current date
today = Date.utc_today()
IO.puts "\nToday (UTC): #{inspect(today)}"

# Accessing components
IO.puts "\n--- Date Components ---"
IO.puts "Year: #{today.year}"
IO.puts "Month: #{today.month}"
IO.puts "Day: #{today.day}"
IO.puts "Day of week: #{Date.day_of_week(today)} (1=Monday, 7=Sunday)"
IO.puts "Day of year: #{Date.day_of_year(today)}"
IO.puts "Quarter: #{Date.quarter_of_year(today)}"
IO.puts "Days in month: #{Date.days_in_month(today)}"
IO.puts "Leap year? #{Date.leap_year?(today)}"

# Date arithmetic
IO.puts "\n--- Date Arithmetic ---"
next_week = Date.add(today, 7)
IO.puts "Today + 7 days: #{inspect(next_week)}"

last_month = Date.add(today, -30)
IO.puts "Today - 30 days: #{inspect(last_month)}"

# Difference between dates
diff = Date.diff(~D[2024-12-31], ~D[2024-01-01])
IO.puts "Days in 2024: #{diff}"

# Comparing dates
IO.puts "\n--- Date Comparison ---"
IO.puts "~D[2024-03-15] == ~D[2024-03-15]: #{~D[2024-03-15] == ~D[2024-03-15]}"
IO.puts "Date.compare(~D[2024-03-15], ~D[2024-03-14]): #{Date.compare(~D[2024-03-15], ~D[2024-03-14])}"

# Before/after checks
date_a = ~D[2024-03-15]
date_b = ~D[2024-03-20]
IO.puts "#{date_a} before #{date_b}? #{Date.compare(date_a, date_b) == :lt}"
IO.puts "#{date_a} after #{date_b}? #{Date.compare(date_a, date_b) == :gt}"

# Date ranges
IO.puts "\n--- Date Ranges ---"
range = Date.range(~D[2024-03-01], ~D[2024-03-05])
IO.puts "Date range: #{inspect(range)}"
IO.puts "Dates in range: #{inspect(Enum.to_list(range))}"
IO.puts "Contains ~D[2024-03-03]? #{~D[2024-03-03] in range}"

# Beginning and end of month/year
IO.puts "\n--- Date Boundaries ---"
IO.puts "Beginning of month: #{Date.beginning_of_month(today)}"
IO.puts "End of month: #{Date.end_of_month(today)}"

# ============================================================================
# PART 2: TIME - Working with Times
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 2: TIME - Working with Times                                            │
└──────────────────────────────────────────────────────────────────────────────┘

The Time struct represents a time of day without date or timezone.
It stores hour, minute, second, and microsecond.
"""

# Creating times
IO.puts "--- Creating Times ---"

# Using the sigil
time1 = ~T[14:30:00]
IO.puts "Using sigil: #{inspect(time1)}"

# With microseconds
time2 = ~T[14:30:00.123456]
IO.puts "With microseconds: #{inspect(time2)}"

# Using Time.new/4
{:ok, time3} = Time.new(14, 30, 0)
IO.puts "Using Time.new: #{inspect(time3)}"

# Current time
now = Time.utc_now()
IO.puts "\nCurrent time (UTC): #{inspect(now)}"

# Accessing components
IO.puts "\n--- Time Components ---"
IO.puts "Hour: #{now.hour}"
IO.puts "Minute: #{now.minute}"
IO.puts "Second: #{now.second}"
IO.puts "Microsecond: #{inspect(now.microsecond)}"

# Time arithmetic
IO.puts "\n--- Time Arithmetic ---"
time = ~T[10:00:00]
later = Time.add(time, 3600)  # Add 1 hour (in seconds)
IO.puts "10:00:00 + 1 hour: #{inspect(later)}"

earlier = Time.add(time, -1800)  # Subtract 30 minutes
IO.puts "10:00:00 - 30 min: #{inspect(earlier)}"

# Add with different units
time_plus_ms = Time.add(~T[10:00:00], 500_000, :microsecond)
IO.puts "10:00:00 + 500ms: #{inspect(time_plus_ms)}"

# Time difference
diff = Time.diff(~T[15:30:00], ~T[10:00:00])
IO.puts "\nDifference between 15:30 and 10:00: #{diff} seconds (#{div(diff, 3600)} hours)"

# Comparing times
IO.puts "\n--- Time Comparison ---"
IO.puts "Time.compare(~T[10:00:00], ~T[15:00:00]): #{Time.compare(~T[10:00:00], ~T[15:00:00])}"

# Truncating precision
IO.puts "\n--- Truncating Precision ---"
precise_time = ~T[14:30:15.123456]
IO.puts "Original: #{inspect(precise_time)}"
IO.puts "Truncated to second: #{inspect(Time.truncate(precise_time, :second))}"
IO.puts "Truncated to millisecond: #{inspect(Time.truncate(precise_time, :millisecond))}"

# ============================================================================
# PART 3: NAIVEDATETIME - Date + Time Without Timezone
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 3: NAIVEDATETIME - Date + Time Without Timezone                         │
└──────────────────────────────────────────────────────────────────────────────┘

NaiveDateTime combines date and time but has NO timezone information.
Use it when timezone is not relevant or is handled externally.
"""

# Creating NaiveDateTime
IO.puts "--- Creating NaiveDateTime ---"

# Using the sigil
ndt1 = ~N[2024-03-15 14:30:00]
IO.puts "Using sigil: #{inspect(ndt1)}"

# With microseconds
ndt2 = ~N[2024-03-15 14:30:00.123456]
IO.puts "With microseconds: #{inspect(ndt2)}"

# Using NaiveDateTime.new/2
{:ok, ndt3} = NaiveDateTime.new(~D[2024-03-15], ~T[14:30:00])
IO.puts "From Date + Time: #{inspect(ndt3)}"

# Current NaiveDateTime
now = NaiveDateTime.utc_now()
IO.puts "\nCurrent (UTC): #{inspect(now)}"

# Local time (no timezone info, just the clock time)
local = NaiveDateTime.local_now()
IO.puts "Local now: #{inspect(local)}"

# Accessing components
IO.puts "\n--- NaiveDateTime Components ---"
IO.puts "Year: #{now.year}, Month: #{now.month}, Day: #{now.day}"
IO.puts "Hour: #{now.hour}, Minute: #{now.minute}, Second: #{now.second}"

# Convert to Date and Time
IO.puts "\n--- Conversion ---"
IO.puts "To Date: #{inspect(NaiveDateTime.to_date(now))}"
IO.puts "To Time: #{inspect(NaiveDateTime.to_time(now))}"

# NaiveDateTime arithmetic
IO.puts "\n--- NaiveDateTime Arithmetic ---"
ndt = ~N[2024-03-15 14:30:00]
IO.puts "Original: #{inspect(ndt)}"
IO.puts "+ 1 day (86400 sec): #{inspect(NaiveDateTime.add(ndt, 86400))}"
IO.puts "+ 1 hour (3600 sec): #{inspect(NaiveDateTime.add(ndt, 3600))}"
IO.puts "- 30 minutes: #{inspect(NaiveDateTime.add(ndt, -1800))}"

# Difference
diff = NaiveDateTime.diff(~N[2024-03-15 15:30:00], ~N[2024-03-15 14:00:00])
IO.puts "\nDifference: #{diff} seconds"

# Beginning and end of day
IO.puts "\n--- Day Boundaries ---"
IO.puts "Beginning of day: #{inspect(NaiveDateTime.beginning_of_day(ndt))}"
IO.puts "End of day: #{inspect(NaiveDateTime.end_of_day(ndt))}"

# ============================================================================
# PART 4: DATETIME - Date + Time WITH Timezone
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 4: DATETIME - Date + Time WITH Timezone                                 │
└──────────────────────────────────────────────────────────────────────────────┘

DateTime includes full timezone information. The built-in Calendar.ISO
only supports UTC. For other timezones, use a library like `tzdata`.
"""

# Creating DateTime (UTC)
IO.puts "--- Creating DateTime (UTC) ---"

# Using the sigil
dt1 = ~U[2024-03-15 14:30:00Z]
IO.puts "Using sigil: #{inspect(dt1)}"

# With microseconds
dt2 = ~U[2024-03-15 14:30:00.123456Z]
IO.puts "With microseconds: #{inspect(dt2)}"

# Current DateTime
now = DateTime.utc_now()
IO.puts "\nCurrent UTC: #{inspect(now)}"

# From Unix timestamp
from_unix = DateTime.from_unix!(1710512400)
IO.puts "From Unix timestamp: #{inspect(from_unix)}"

# Accessing components
IO.puts "\n--- DateTime Components ---"
IO.puts "Year: #{now.year}, Month: #{now.month}, Day: #{now.day}"
IO.puts "Hour: #{now.hour}, Minute: #{now.minute}, Second: #{now.second}"
IO.puts "Timezone: #{now.time_zone}"
IO.puts "UTC offset: #{now.utc_offset}"
IO.puts "STD offset: #{now.std_offset}"

# DateTime arithmetic
IO.puts "\n--- DateTime Arithmetic ---"
dt = ~U[2024-03-15 14:30:00Z]
IO.puts "Original: #{inspect(dt)}"
IO.puts "+ 1 hour: #{inspect(DateTime.add(dt, 3600))}"
IO.puts "+ 1 day: #{inspect(DateTime.add(dt, 86400))}"

# Difference
diff = DateTime.diff(~U[2024-03-15 15:30:00Z], ~U[2024-03-15 14:00:00Z])
IO.puts "\nDifference: #{diff} seconds"

# Unix timestamps
IO.puts "\n--- Unix Timestamps ---"
IO.puts "To Unix: #{DateTime.to_unix(now)}"
IO.puts "To Unix (milliseconds): #{DateTime.to_unix(now, :millisecond)}"

# Comparing DateTimes
IO.puts "\n--- DateTime Comparison ---"
dt1 = ~U[2024-03-15 14:00:00Z]
dt2 = ~U[2024-03-15 15:00:00Z]
IO.puts "#{dt1} before #{dt2}? #{DateTime.compare(dt1, dt2) == :lt}"

# Conversion between NaiveDateTime and DateTime
IO.puts "\n--- NaiveDateTime <-> DateTime Conversion ---"
naive = ~N[2024-03-15 14:30:00]
{:ok, datetime} = DateTime.from_naive(naive, "Etc/UTC")
IO.puts "NaiveDateTime to DateTime: #{inspect(datetime)}"

back_to_naive = DateTime.to_naive(datetime)
IO.puts "DateTime to NaiveDateTime: #{inspect(back_to_naive)}"

# ============================================================================
# PART 5: THE CALENDAR MODULE
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 5: THE CALENDAR MODULE                                                  │
└──────────────────────────────────────────────────────────────────────────────┘

The Calendar behaviour defines the interface for calendar implementations.
Calendar.ISO is the default, implementing the proleptic Gregorian calendar.
"""

# Calendar.ISO functions
IO.puts "--- Calendar.ISO Functions ---"

# Days in month
IO.puts "Days in February 2024: #{Calendar.ISO.days_in_month(2024, 2)}"
IO.puts "Days in February 2023: #{Calendar.ISO.days_in_month(2023, 2)}"

# Leap year check
IO.puts "\n2024 is leap year? #{Calendar.ISO.leap_year?(2024)}"
IO.puts "2023 is leap year? #{Calendar.ISO.leap_year?(2023)}"

# Day of week (1 = Monday, 7 = Sunday)
IO.puts "\nDay of week for 2024-03-15: #{Calendar.ISO.day_of_week(2024, 3, 15)}"

# Valid date check
IO.puts "\n2024-02-29 valid? #{Calendar.ISO.valid_date?(2024, 2, 29)}"
IO.puts "2023-02-29 valid? #{Calendar.ISO.valid_date?(2023, 2, 29)}"

# ISO week number
{year, week} = Calendar.ISO.iso_week_number(2024, 3, 15)
IO.puts "\nISO week for 2024-03-15: Week #{week} of #{year}"

# ============================================================================
# PART 6: FORMATTING AND PARSING
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 6: FORMATTING AND PARSING                                               │
└──────────────────────────────────────────────────────────────────────────────┘

Converting dates/times to and from strings.
For complex formatting, consider the `Calendar` library on Hex.
"""

# Converting to string
IO.puts "--- Converting to String ---"
date = ~D[2024-03-15]
time = ~T[14:30:00]
ndt = ~N[2024-03-15 14:30:00]
dt = ~U[2024-03-15 14:30:00Z]

IO.puts "Date.to_string: #{Date.to_string(date)}"
IO.puts "Time.to_string: #{Time.to_string(time)}"
IO.puts "NaiveDateTime.to_string: #{NaiveDateTime.to_string(ndt)}"
IO.puts "DateTime.to_string: #{DateTime.to_string(dt)}"

# ISO 8601 format
IO.puts "\n--- ISO 8601 Format ---"
IO.puts "Date.to_iso8601: #{Date.to_iso8601(date)}"
IO.puts "Time.to_iso8601: #{Time.to_iso8601(time)}"
IO.puts "DateTime.to_iso8601: #{DateTime.to_iso8601(dt)}"

# Parsing from string
IO.puts "\n--- Parsing from String ---"
{:ok, parsed_date} = Date.from_iso8601("2024-03-15")
IO.puts "Date.from_iso8601(\"2024-03-15\"): #{inspect(parsed_date)}"

{:ok, parsed_time} = Time.from_iso8601("14:30:00")
IO.puts "Time.from_iso8601(\"14:30:00\"): #{inspect(parsed_time)}"

{:ok, parsed_dt, offset} = DateTime.from_iso8601("2024-03-15T14:30:00Z")
IO.puts "DateTime.from_iso8601: #{inspect(parsed_dt)} (offset: #{offset})"

# With offset
{:ok, parsed_offset, _} = DateTime.from_iso8601("2024-03-15T14:30:00+05:30")
IO.puts "With +05:30 offset: #{inspect(parsed_offset)}"

# Custom formatting
IO.puts "\n--- Custom Formatting ---"
dt = ~U[2024-03-15 14:30:45Z]

# Manual formatting
formatted = "#{dt.year}-#{String.pad_leading(to_string(dt.month), 2, "0")}-#{String.pad_leading(to_string(dt.day), 2, "0")}"
IO.puts "Manual format (YYYY-MM-DD): #{formatted}"

# Using Calendar.strftime (Elixir 1.11+)
IO.puts "Calendar.strftime: #{Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S")}"
IO.puts "Full date: #{Calendar.strftime(dt, "%A, %B %d, %Y")}"
IO.puts "Time only: #{Calendar.strftime(dt, "%I:%M %p")}"

# strftime format codes:
# %Y - 4-digit year
# %m - 2-digit month
# %d - 2-digit day
# %H - 24-hour
# %M - minute
# %S - second
# %A - full weekday name
# %B - full month name
# %I - 12-hour
# %p - AM/PM

# ============================================================================
# PART 7: TIMEZONE HANDLING
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 7: TIMEZONE HANDLING                                                    │
└──────────────────────────────────────────────────────────────────────────────┘

Elixir's built-in Calendar.ISO only supports UTC. For full timezone support,
you need a timezone database like `tzdata` and use DateTime.shift_zone/2.

Note: The examples below show the API, but require tzdata to work.
"""

IO.puts """
To add timezone support, add to mix.exs:

  {:tzdata, "~> 1.1"}

And configure in config.exs:

  config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

Then you can use:

  # Convert UTC to a timezone
  utc_dt = ~U[2024-03-15 14:30:00Z]
  {:ok, ny_dt} = DateTime.shift_zone(utc_dt, "America/New_York")
  # => ~U[2024-03-15 10:30:00-04:00] (during DST)

  # Create a DateTime in a specific timezone
  {:ok, tokyo_dt} = DateTime.new(~D[2024-03-15], ~T[14:30:00], "Asia/Tokyo")
"""

# Without tzdata, we can still work with UTC
IO.puts "\n--- Working with UTC ---"
utc_now = DateTime.utc_now()
IO.puts "UTC now: #{DateTime.to_string(utc_now)}"

# Timezone information in DateTime
IO.puts "\nDateTime timezone fields:"
IO.puts "time_zone: #{utc_now.time_zone}"
IO.puts "zone_abbr: #{utc_now.zone_abbr}"
IO.puts "utc_offset: #{utc_now.utc_offset} seconds"
IO.puts "std_offset: #{utc_now.std_offset} seconds"

# ============================================================================
# PART 8: PRACTICAL EXAMPLES
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ PART 8: PRACTICAL EXAMPLES                                                   │
└──────────────────────────────────────────────────────────────────────────────┘
"""

defmodule DateTimeExamples do
  @doc """
  Calculate age from birthdate
  """
  def age(birthdate) do
    today = Date.utc_today()
    years = today.year - birthdate.year

    # Adjust if birthday hasn't occurred this year
    if Date.compare(
      %{birthdate | year: today.year},
      today
    ) == :gt do
      years - 1
    else
      years
    end
  end

  @doc """
  Check if a datetime is within business hours (9 AM - 5 PM UTC)
  """
  def business_hours?(datetime) do
    time = DateTime.to_time(datetime)
    time.hour >= 9 and time.hour < 17
  end

  @doc """
  Get the next occurrence of a specific day of week
  """
  def next_weekday(from_date, target_day) when target_day in 1..7 do
    current_day = Date.day_of_week(from_date)
    days_until = rem(target_day - current_day + 7, 7)
    days_until = if days_until == 0, do: 7, else: days_until
    Date.add(from_date, days_until)
  end

  @doc """
  Calculate working days between two dates (Mon-Fri)
  """
  def working_days_between(start_date, end_date) do
    Date.range(start_date, end_date)
    |> Enum.filter(fn date ->
      day = Date.day_of_week(date)
      day >= 1 and day <= 5
    end)
    |> length()
  end

  @doc """
  Format a datetime as relative time (e.g., "2 hours ago")
  """
  def relative_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)} minutes ago"
      diff < 86400 -> "#{div(diff, 3600)} hours ago"
      diff < 604800 -> "#{div(diff, 86400)} days ago"
      diff < 2592000 -> "#{div(diff, 604800)} weeks ago"
      true -> "#{div(diff, 2592000)} months ago"
    end
  end

  @doc """
  Get all Mondays in a given month
  """
  def mondays_in_month(year, month) do
    {:ok, start_date} = Date.new(year, month, 1)
    end_date = Date.end_of_month(start_date)

    Date.range(start_date, end_date)
    |> Enum.filter(fn date -> Date.day_of_week(date) == 1 end)
  end
end

IO.puts "--- Age Calculator ---"
birthdate = ~D[1990-05-15]
IO.puts "Birthdate: #{birthdate}"
IO.puts "Age: #{DateTimeExamples.age(birthdate)} years"

IO.puts "\n--- Business Hours Check ---"
dt1 = ~U[2024-03-15 10:30:00Z]
dt2 = ~U[2024-03-15 20:30:00Z]
IO.puts "#{DateTime.to_string(dt1)} in business hours? #{DateTimeExamples.business_hours?(dt1)}"
IO.puts "#{DateTime.to_string(dt2)} in business hours? #{DateTimeExamples.business_hours?(dt2)}"

IO.puts "\n--- Next Weekday ---"
today = Date.utc_today()
next_monday = DateTimeExamples.next_weekday(today, 1)
next_friday = DateTimeExamples.next_weekday(today, 5)
IO.puts "Today: #{today}"
IO.puts "Next Monday: #{next_monday}"
IO.puts "Next Friday: #{next_friday}"

IO.puts "\n--- Working Days ---"
start_d = ~D[2024-03-01]
end_d = ~D[2024-03-31]
IO.puts "Working days in March 2024: #{DateTimeExamples.working_days_between(start_d, end_d)}"

IO.puts "\n--- Mondays in Month ---"
mondays = DateTimeExamples.mondays_in_month(2024, 3)
IO.puts "Mondays in March 2024: #{inspect(mondays)}"

# ============================================================================
# EXERCISES
# ============================================================================

IO.puts """

┌──────────────────────────────────────────────────────────────────────────────┐
│ EXERCISES                                                                    │
└──────────────────────────────────────────────────────────────────────────────┘
"""

defmodule DateTimeExercises do
  @doc """
  Exercise 1: Days Until
  Calculate the number of days until a target date.
  Return negative if date is in the past.
  """
  def days_until(target_date) do
    Date.diff(target_date, Date.utc_today())
  end

  @doc """
  Exercise 2: Is Weekend?
  Check if a date falls on a weekend (Saturday or Sunday).
  """
  def weekend?(date) do
    Date.day_of_week(date) in [6, 7]
  end

  @doc """
  Exercise 3: Add Business Days
  Add N business days (Mon-Fri) to a date.
  """
  def add_business_days(date, 0), do: date
  def add_business_days(date, days) when days > 0 do
    next = Date.add(date, 1)
    if weekend?(next) do
      add_business_days(next, days)
    else
      add_business_days(next, days - 1)
    end
  end

  @doc """
  Exercise 4: Time Until Midnight
  Calculate hours, minutes, and seconds until midnight UTC.
  """
  def time_until_midnight do
    now = Time.utc_now()
    midnight = ~T[23:59:59.999999]
    seconds_left = Time.diff(midnight, now)

    hours = div(seconds_left, 3600)
    minutes = div(rem(seconds_left, 3600), 60)
    seconds = rem(seconds_left, 60)

    {hours, minutes, seconds}
  end

  @doc """
  Exercise 5: Format Duration
  Format a number of seconds into "Xh Ym Zs" format.
  """
  def format_duration(total_seconds) when total_seconds >= 0 do
    hours = div(total_seconds, 3600)
    minutes = div(rem(total_seconds, 3600), 60)
    seconds = rem(total_seconds, 60)

    cond do
      hours > 0 -> "#{hours}h #{minutes}m #{seconds}s"
      minutes > 0 -> "#{minutes}m #{seconds}s"
      true -> "#{seconds}s"
    end
  end
end

IO.puts "--- Testing Exercises ---\n"

IO.puts "Exercise 1: Days Until"
new_years = ~D[2025-01-01]
IO.puts "Days until #{new_years}: #{DateTimeExercises.days_until(new_years)}"

IO.puts "\nExercise 2: Weekend Check"
IO.puts "~D[2024-03-16] (Saturday) weekend? #{DateTimeExercises.weekend?(~D[2024-03-16])}"
IO.puts "~D[2024-03-15] (Friday) weekend? #{DateTimeExercises.weekend?(~D[2024-03-15])}"

IO.puts "\nExercise 3: Add Business Days"
start = ~D[2024-03-15]  # Friday
IO.puts "#{start} + 3 business days: #{DateTimeExercises.add_business_days(start, 3)}"

IO.puts "\nExercise 4: Time Until Midnight"
{h, m, s} = DateTimeExercises.time_until_midnight()
IO.puts "Time until midnight: #{h}h #{m}m #{s}s"

IO.puts "\nExercise 5: Format Duration"
IO.puts "3661 seconds: #{DateTimeExercises.format_duration(3661)}"
IO.puts "125 seconds: #{DateTimeExercises.format_duration(125)}"
IO.puts "45 seconds: #{DateTimeExercises.format_duration(45)}"

IO.puts """

╔══════════════════════════════════════════════════════════════════════════════╗
║                         LESSON COMPLETE!                                      ║
║                                                                              ║
║  Key Takeaways:                                                              ║
║  • Date: year, month, day only                                               ║
║  • Time: hour, minute, second, microsecond only                              ║
║  • NaiveDateTime: date + time, NO timezone                                   ║
║  • DateTime: date + time WITH timezone (UTC by default)                      ║
║  • Use sigils (~D, ~T, ~N, ~U) for literals                                  ║
║  • Calendar.strftime for custom formatting                                   ║
║  • For timezone support beyond UTC, use the tzdata library                   ║
║                                                                              ║
║  Next: 08_regex.exs - Regular Expressions in Depth                           ║
╚══════════════════════════════════════════════════════════════════════════════╝
"""
