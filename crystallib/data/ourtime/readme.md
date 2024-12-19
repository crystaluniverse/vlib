# OurTime Module

The OurTime module provides a flexible and user-friendly way to work with time in V. It supports both relative and absolute time formats, making it easy to handle various time-related operations.

## Features

- Create time objects from various string formats
- Support for relative time expressions
- Support for absolute time formats
- Unix timestamp handling
- Time formatting utilities
- Time warping capabilities

## Usage

### Basic Usage

```v
import freeflowuniverse.crystallib.data.ourtime

// Create time object for current time
mut t := ourtime.now()

// Create from string
t2 := ourtime.new('2022-12-05 20:14:35')!

// Get formatted string
println(t2.str()) // Output: 2022-12-05 20:14

// Get unix timestamp
println(t2.unix()) // Output: 1670271275
```

### Time Formats

#### Relative Time Format

Relative time expressions use the following period indicators:
- `s`: seconds
- `h`: hours
- `d`: days
- `w`: weeks
- `M`: months
- `Q`: quarters
- `Y`: years

Examples:
```v
// Create time object with relative time
mut t := ourtime.new('+1w +2d -4h')! // 1 week forward, 2 days forward, 4 hours back

// Warp existing time object
mut t2 := ourtime.now()
t2.warp('+1h')! // Move 1 hour forward
```

#### Absolute Time Format

Supported date formats:
- `YYYY-MM-DD HH:mm:ss`
- `YYYY-MM-DD HH:mm`
- `YYYY-MM-DD`
- `DD-MM-YYYY` (YYYY must be 4 digits)
- Also supports '/' instead of '-' for dates

Examples:
```v
// Various absolute time formats
t1 := ourtime.new('2022-12-05 20:14:35')!
t2 := ourtime.new('2022-12-05')! // Sets time to 00:00:00
t3 := ourtime.new('05-12-2022')! // DD-MM-YYYY format
```

### Methods

#### Creation Methods

```v
// Create for current time
now := ourtime.now()

// Create from string
t := ourtime.new('2022-12-05 20:14:35')!

// Create from unix timestamp
t2 := ourtime.new_from_epoch(1670271275)
```

#### Formatting Methods

```v
mut t := ourtime.now()

// Get as YYYY-MM-DD HH:mm format
println(t.str())

// Get as YYYY-MM-DD format
println(t.day())

// Get as formatted key (YYYY_MM_DD_HH_mm_ss)
println(t.key())

// Get as markdown formatted string
println(t.md())
```

#### Time Operations

```v
mut t := ourtime.now()

// Move time forward or backward
t.warp('+1h')! // 1 hour forward
t.warp('-30m')! // 30 minutes backward
t.warp('+1w +2d -4h')! // Complex time warp

// Get unix timestamp
unix := t.unix()

// Get as integer
i := t.int()

// Check if time is empty (zero)
is_empty := t.empty()
```

## Examples

### Working with Relative Time

```v
mut t := ourtime.now()

// Add time periods
t.warp('+1w')! // Add 1 week
t.warp('+2d')! // Add 2 days
t.warp('-4h')! // Subtract 4 hours

// Complex time warping
t.warp('+1Y -2Q +2M +4h -60s')! // Add 1 year, subtract 2 quarters, add 2 months, add 4 hours, subtract 60 seconds
```

### Working with Absolute Time

```v
// Create time from absolute format
t1 := ourtime.new('2022-12-05 20:14:35')!
println(t1.str()) // 2022-12-05 20:14

// Create time from date only
t2 := ourtime.new('2022-12-05')!
println(t2.str()) // 2022-12-05 00:00

// Get different formats
println(t1.day()) // 2022-12-05
println(t1.key()) // 2022_12_05_20_14_35
```

### Time Comparisons and Checks

```v
mut t := ourtime.now()

// Check if time is empty
if t.empty() {
    t.now() // Set to current time if empty
}

// Get unix timestamp for comparisons
unix := t.unix()
```

## Error Handling

All time parsing operations that can fail return a Result type, so they should be called with `!` or handled with `or` blocks:

```v
// Using ! operator (panics on error)
t1 := ourtime.new('2022-12-05')!

// Using or block for error handling
t2 := ourtime.new('invalid-date') or {
    println('Error parsing date: ${err}')
    ourtime.now() // fallback to current time
}
```
