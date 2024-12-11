module performance

import arrays
import time
import sync
import term // For color coding
import freeflowuniverse.crystallib.clients.redisclient

// Struct to represent a timer for measuring process performance
@[noinit]
pub struct ProcessTimer {
pub:
	name string // Name of the timer instance
}

// Create a new ProcessTimer instance with a unique name including thread ID
pub fn new(name string) ProcessTimer {
	return ProcessTimer{
		name: '${name}_${sync.thread_id()}'
	}
}

// Add a new timestamp to the current epoch for a specific name or event
pub fn (p ProcessTimer) new_timestamp(name_ string) {
	mut name := name_
	mut redis := redisclient.core_get() or { panic(err) } // Get a Redis client
	epoch := redis.get('${p.name}_epoch') or { '0' } // Fetch the current epoch value, default to '0'
	all := redis.hgetall('${p.name}_${epoch}') or {
		map[string]string{}
	} // Get all timestamps for the current epoch

	// If a timestamp with the same name exists, make it unique
	if name in all.keys() {
		i := all.keys().filter(it.starts_with(name)).len
		name = '${name}_${i}'
	}
	// Store the new timestamp in Redis
	redis.hset('${p.name}_${epoch}', name, time.now().unix_micro().str()) or { panic(err) }
}

// Increment the epoch value, effectively starting a new measurement phase
pub fn (p ProcessTimer) epoch() {
	mut redis := redisclient.core_get() or { panic(err) }
	redis.incr('${p.name}_epoch') or { panic(err) }
}

// Increment the epoch value to signify the end of a measurement phase
pub fn (p ProcessTimer) epoch_end() {
	mut redis := redisclient.core_get() or { panic(err) }
	redis.incr('${p.name}_epoch') or { panic(err) }
}

// Generate and display a timeline of events and their durations for each epoch
pub fn (p ProcessTimer) timeline() {
	mut redis := redisclient.core_get() or { panic(err) } // Get a Redis client
	epoch := redis.get('${p.name}_epoch') or { '0' } // Fetch the current epoch value
	println(term.cyan('\nTimelines:\n')) // Print header

	// Loop through all epochs
	for e in 0 .. epoch.int() {
		result := redis.hgetall('${p.name}_${e}') or { continue } // Get all timestamps for the epoch

		if result.len == 0 {
			// No data for this epoch
			println(term.yellow('No timeline data found for process: ${p.name}_${e}'))
			continue
		}

		// Parse the results into a map of event names to timestamps
		mut timestamps := map[string]i64{}
		for key, value in result {
			timestamps[key] = value.i64()
		}

		// Calculate the durations between consecutive timestamps
		mut durations := []i64{}
		for i, timestamp in timestamps.values() {
			prev_timestamp := if i == 0 {
				timestamp
			} else {
				timestamps.values()[i - 1]
			}
			durations << timestamp - prev_timestamp
		}

		// Find the maximum duration for normalization
		max_duration := arrays.max(durations) or { 1 }
		scale := 40.0 / f64(max_duration) // Scale for the timeline bar

		// Print the timeline for the epoch
		println(term.cyan('\nProcess Timeline:\n'))
		mut i := 0
		for key, timestamp in timestamps {
			// Print event name and formatted timestamp
			println('${key}: ${time.unix_micro(timestamp).format_rfc3339_micro()[10..]}')

			// Calculate and display the duration bar
			prev_timestamp := if i == 0 {
				0
			} else {
				timestamps.values()[i - 1]
			}
			if i == timestamps.len - 1 {
				continue
			}
			duration := durations[i + 1]

			// Determine bar length and color based on duration
			bar_length := int(duration * scale)
			color := if duration < max_duration / 3 {
				term.green
			} else if duration < 2 * max_duration / 3 {
				term.yellow
			} else {
				term.red
			}

			// Create the bar visualization
			bar := if duration == 0 {
				''
			} else {
				color('|') + color('-'.repeat(bar_length)) + color(' '.repeat(40 - bar_length)) +
					color('|')
			}
			println('${bar} (${duration}μs)')
			i++
		}
	}
	println('\n') // End with a newline
}
