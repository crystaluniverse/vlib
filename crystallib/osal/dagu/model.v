module dagu

pub struct DAG {
	pub:
	path string
	name                 string // The name of the DAG, which is optional. The default name is the name of the file.
	description          string // A brief description of the DAG.
	schedule             string // The execution schedule of the DAG in Cron expression format.
	group                string // The group name to organize DAGs, which is optional.
	tags                 string // Free tags that can be used to categorize DAGs, separated by commas.
	env                  ?map[string]string // Environment variables that can be accessed by the DAG and its steps.
	log_dir              string      // The directory where the standard output is written. The default value is ${DAGU_HOME}/logs/dags.
	restart_wait_sec     int         // The number of seconds to wait after the DAG process stops before restarting it.
	hist_retention_days  int         // The number of days to retain execution history (not for log files).
	delay_sec            int         // The interval time in seconds between steps.
	max_active_runs      int         // The maximum number of parallel running steps.
	params               string      // The default parameters that can be referred to by $1, $2, and so on.
	preconditions        ?[]Condition // The conditions that must be met before a DAG or step can run.
	mail_on              ?MailOn      // Whether to send an email notification when a DAG or step fails or succeeds.
	max_cleanup_time_sec int        // The maximum time to wait after sending a TERM signal to running steps before killing them.
	handler_on           ?HandlerOn  // The command to execute when a DAG or step succeeds, fails, cancels, or exits.
	functions            []Function // https://dagu.readthedocs.io/en/latest/yaml_format.html#id9
	steps                []Step     // A list of steps to execute in the DAG.
}

pub struct Condition {
	pub:
	condition string
	expected  string
}

pub struct MailOn {
	pub:
	failure bool
	success bool
}

pub struct HandlerOn {
	pub:
	success string
	failure string
	cancel  string
	exit    string
}

// https://dagu.readthedocs.io/en/latest/yaml_format.html#id9
pub struct Function {
	pub:
	name    string
	params  string
	command string
}

pub struct Step {
	pub:
	name           string       // The name of the step.
	description    string       // A brief description of the step.
	dir            string       // The working directory for the step.
	command        string       // The command and parameters to execute.
	stdout         string       // The file to which the standard output is written.
	output         ?string       // The variable to which the result is written.
	script         ?string       // The script to execute.
	signal_on_stop string       // The signal name (e.g., SIGINT) to be sent when the process is stopped.
	mail_on        ?MailOn       // Whether to send an email notification when the step fails or succeeds.
	continue_on    ?ContinueOn   // Whether to continue to the next step, regardless of whether the step failed or not or the preconditions are met or not.
	retry_policy   ?RetryPolicy  // The retry policy for the step.
	repeat_policy  ?RepeatPolicy // The repeat policy for the step.
	preconditions  ?[]string     // The conditions that must be met before a step can run.
	depends        ?string       // The step depends on the other step.
	call           Call // User defined function call
}

pub struct ContinueOn {
	pub:
	failure bool
	skipped bool
}

pub struct RetryPolicy {
	pub:
	limit        int
	interval_sec int
}

pub struct RepeatPolicy {
	pub:
	repeat       bool
	interval_sec int
}

// https://dagu.readthedocs.io/en/latest/yaml_format.html#id9
pub struct Call {
	pub:
	function string
	args     map[string]string
}

@[params]
pub struct Config {
	pub:
	log_dir                string // directory path to save logs from standard output
	history_retention_days int    // history retention days (default: 30)
	mail_on                MailOn // Email notification settings
	smtp                   SMTP   // SMTP server settings
	error_mail             Mail   // Error mail configuration
	info_mail              Mail   // Info mail configuration
}

pub struct SMTP {
	pub:
	host       string
	port       string
	username   string
	password   string
	error_mail Mail
}

pub struct Mail {
	pub:
	from   string
	to     string
	prefix string
}

// pub struct Step {
// pub mut:
// 	name    string
// 	command string
// 	script  string [json: raw]
// 	output  string [json: 'output']
// 	depends []string [skip]
// }

// [heap]
// struct DAG {
// pub mut:
// 	name                string
// 	description         string
// 	steps []Step	
// 	schedule            string //in cron format
// 	group               string
// 	tags                string
// 	env                 map[string]string
// 	log_dir             string [json: 'logDir']
// 	restart_wait_sec    int    [json: 'restartWaitSec']
// 	hist_retention_days int    [json: 'histRetentionDays']
// 	delay_sec           int    [json: 'delaySec']
// 	max_active_runs     int    [json: 'maxActiveRuns']
// 	params              []string
// 	preconditions       []Precondition
// 	mail_on             MailOn [json: 'mailOn']
// 	max_clean_up_time_sec int  [json: 'MaxCleanUpTimeSec']
// 	handler_on          HandlerOn [json: 'handlerOn']
// }

// struct Precondition {
// pub mut:	
// 	condition string
// 	expected  string
// }

// struct MailOn {
// pub mut:	
// 	failure bool
// 	success bool
// }

// struct Handler {
// pub mut:	
// 	command string
// }

// struct HandlerOn {
// pub mut:	
// 	success Handler
// 	failure Handler
// 	cancel  Handler
// 	exit    Handler
// }

// handlerOn:
//   failure:
//     command: notify_error.sh
//   exit:
//     command: cleanup.sh
// steps:
//   - name: A task
//     command: main.sh
