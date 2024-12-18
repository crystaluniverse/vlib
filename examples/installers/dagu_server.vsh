#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.installers.sysadmintools.daguserver

// will call the installer underneith

mut dserver := daguserver.new()!
dserver.install()!
dserver.restart()!

println('DAGU installed & running')

mut dagucl := dserver.client()!

// name                 string  // The name of the DAG, which is optional. The default name is the name of the file.
// description          ?string // A brief description of the DAG.
// tags                 ?string // Free tags that can be used to categorize DAGs, separated by commas.
// env                  ?map[string]string // Environment variables that can be accessed by the DAG and its steps.
// restart_wait_sec     ?int // The number of seconds to wait after the DAG process stops before restarting it.
// hist_retention_days  ?int // The number of days to retain execution history (not for log files).
// delay_sec            ?int // The interval time in seconds between steps.
// max_active_runs      ?int // The maximum number of parallel running steps.
// max_cleanup_time_sec ?int // The maximum time to wait after sending a TERM signal to running steps before killing them.

mut mydag := dagucl.dag_new(
	nameswhere: 'test11'
)

// nr                int     @[required]
// name              string  // The name of the step.
// description       string  // A brief description of the step.
// dir               string  // The working directory for the step.
// command           string  // The command and parameters to execute.
// stdout            string  // The file to which the standard output is written.
// output            ?string // The variable to which the result is written.
// script            ?string // The script to execute.
// signal_on_stop    ?string // The signal name (e.g., SIGINT) to be sent when the process is stopped.
// continue_on_error bool
// depends           string
// retry_nr       	int   = 3
// retry_interval 	int = 5

mydag.step_add(
	script:         'ls /tmp'
	retry_interval: 1
	retry_nr:       3
)!

mydag.step_add(
	script:         'ls /root'
	retry_interval: 1
	retry_nr:       3
)!

dagresult := dagucl.dag_register(mydag, start: true)!
println(dagresult)

println('DAGU should have new steps')
