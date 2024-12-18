module daguclient

import freeflowuniverse.crystallib.core.texttools

@[params]
pub struct DAGArgs {
pub:
	name                 string             // The name of the DAG, which is optional. The default name is the name of the file.
	description          ?string            // A brief description of the DAG.
	tags                 ?string            // Free tags that can be used to categorize DAGs, separated by commas.
	env                  ?map[string]string // Environment variables that can be accessed by the DAG and its steps.
	restart_wait_sec     ?int               // The number of seconds to wait after the DAG process stops before restarting it.
	hist_retention_days  ?int               // The number of days to retain execution history (not for log files).
	delay_sec            ?int               // The interval time in seconds between steps.
	max_active_runs      ?int               // The maximum number of parallel running steps.
	max_cleanup_time_sec ?int               // The maximum time to wait after sending a TERM signal to running steps before killing them.
}

// create new DAG
// ```
// name                 string // The name of the DAG, which is optional. The default name is the name of the file.
// description          ?string // A brief description of the DAG.
// tags                 ?string // Free tags that can be used to categorize DAGs, separated by commas.
// env                  ?map[string]string // Environment variables that can be accessed by the DAG and its steps.
// restart_wait_sec     ?int          // The number of seconds to wait after the DAG process stops before restarting it.
// hist_retention_days  ?int          // The number of days to retain execution history (not for log files).
// delay_sec            ?int          // The interval time in seconds between steps.
// max_active_runs      ?int          // The maximum number of parallel running steps.
// max_cleanup_time_sec ?int        // The maximum time to wait after sending a TERM signal to running steps before killing them.
// ```
pub fn dag_new(args_ DAGArgs) DAG {
	mut args := args_
	mut d := DAG{
		name:                 args.name
		description:          args.description
		tags:                 args.tags
		env:                  args.env
		restart_wait_sec:     args.restart_wait_sec
		hist_retention_days:  args.hist_retention_days
		delay_sec:            args.delay_sec
		max_active_runs:      args.max_active_runs
		max_cleanup_time_sec: args.max_cleanup_time_sec
	}
	return d
}

@[params]
pub struct StepArgs {
pub mut:
	nr                int
	name              string  // The name of the step.
	description       string  // A brief description of the step.
	dir               string  // The working directory for the step.
	command           string  // The command and parameters to execute.
	stdout            string  // The file to which the standard output is written.
	output            ?string // The variable to which the result is written.
	script            ?string // The script to execute.
	signal_on_stop    ?string // The signal name (e.g., SIGINT) to be sent when the process is stopped.
	continue_on_error bool
	depends           string
	retry_nr          int = 3
	retry_interval    int = 5
}

pub fn (mut d DAG) step_add(args_ StepArgs) !&Step {
	mut args := args_
	if args.nr == 0 {
		args.nr = d.steps.len + 1
	}
	if args.name == '' {
		args.name = 'step_${args.nr}'
	}
	mut s := Step{
		nr:             args.nr
		name:           args.name
		description:    args.description
		dir:            args.dir
		command:        args.command
		stdout:         args.stdout
		output:         args.output
		script:         args.script
		signal_on_stop: args.signal_on_stop
	}
	scr := s.script or { '' }
	if scr.len > 0 && s.command == '' {
		s.command = 'bash'
	}
	// s.retry_policy(args.retry,1)

	if args.depends.len > 0 {
		s.depends = []string{}
		for nr in texttools.to_array_int(args.depends) {
			step_dep := d.step_get(nr)!
			// console.print_debug("depend on: ${step_dep.name}")
			s.depends << step_dep.name
		}
	}

	if args.continue_on_error {
		s.continue_on(true, false) // means we continue even if failure)
	}

	s.retry_policy(retry_nr: args.retry_nr, retry_interval: args.retry_interval)

	d.steps << s
	return &s
}

pub fn (mut d DAG) step_get(nr int) !Step {
	for step in d.steps {
		if step.nr == nr {
			return step
		}
	}
	return error('Could not find step with nr:${nr} in dag:${d.name}')
}

// Whether to continue to the next step,
// regardless of whether the step failed or not or the preconditions are met or not.
// arg1: failure, if true will continue if fialed
// arg2: skipped, if preconditions not met will still continue
pub fn (mut self Step) continue_on(failure bool, skipped bool) {
	c := ContinueOn{
		failure: failure
		skipped: skipped
	}
	self.continue_on = c
}

@[params]
pub struct RetryPolicyArgs {
pub:
	retry_nr       int = 1
	retry_interval int = 15
}

// should we retry and if yes how long .
// args
//```
// nrtimes        int //nr of times to retry
// interval_sec int //sec between the retries in seconds
//```
pub fn (mut self Step) retry_policy(args RetryPolicyArgs) {
	c := RetryPolicy{
		limit:        args.retry_nr
		interval_sec: args.retry_interval
	}
	self.retry_policy = c
}
