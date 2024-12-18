module daguclient

import json

@[params]
pub struct NewDagOptions {
pub:
	overwrite bool = true // whether to overwrite existing dag with same name
	start     bool
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
pub fn (mut client DaguClient) dag_new(args_ DAGArgs) DAG {
	return dag_new(args_)
}

pub fn (mut client DaguClient) dag_register(dag DAG, opts NewDagOptions) !PostDagActionResponse {
	if opts.overwrite {
		dag_list := client.dags_list()!
		// println(dag_list)
		if dag_list.dags.any(it.dag.name == dag.name) {
			client.dag_delete(dag.name)!
		}
	}

	client.dag_create(dag.name)!
	mut d_result := client.edit_dag(dag.name, dag)!
	if opts.start {
		client.dag_start(dag.name)!
	}
	return d_result
}

fn (mut client DaguClient) edit_dag(name string, dag DAG) !PostDagActionResponse {
	return client.post_dag_action(name,
		action: .save
		value:  json.encode(dag)
	) or { return error('Failed to edit dag: ${err}') }
}

pub fn (mut client DaguClient) dag_start(name string) !PostDagActionResponse {
	println('dag start ${name}')
	return client.post_dag_action(name, action: .start)!
}

pub fn (mut client DaguClient) dag_stop(name string) !PostDagActionResponse {
	return client.post_dag_action(name, action: .stop)!
}

pub fn (mut client DaguClient) dag_suspend(name string) !PostDagActionResponse {
	return client.post_dag_action(name, action: .suspend)!
}
