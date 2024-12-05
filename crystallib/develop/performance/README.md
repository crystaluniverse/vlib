# Performance Module

A simple V module for measuring and visualizing process performance using Redis for data storage.

## Features

- **Timestamp Management**: Record timestamps for specific events during a process.
- **Epoch Handling**: Start and end measurement phases using epochs.
- **Timeline Visualization**: Display detailed timelines with duration bars and color-coded performance indicators.

## Installation

Install the repository and import the module:

`import performance`

## Usage

### Create a Timer

`mut timer := performance.new('my_process')`

### Add Timestamps

Record a timestamp for an event:

`timer.new_timestamp('event_name')`

### Manage Epochs

Start or end a measurement phase:

```
timer.epoch()      // Start a new epoch
timer.epoch_end()  // End the current epoch
```

### Visualize Timelines

Display the recorded timeline:

`timer.timeline()`

## Dependencies

	•	Redis: Requires a Redis server for data storage.
	•	Redis Client: Uses freeflowuniverse.crystallib.clients.redisclient.

## Example
```
mut timer := performance.new('example_process')

timer.epoch()
timer.new_timestamp('start')
time.sleep(1 * time.second)
timer.new_timestamp('middle')
time.sleep(2 * time.second)
timer.new_timestamp('end')
timer.epoch_end()

timer.timeline()
```

This will output a detailed timeline with duration bars for each event.