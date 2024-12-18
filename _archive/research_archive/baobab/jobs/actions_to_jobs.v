module jobs

import freeflowuniverse.crystallib.data.actionsparser
import freeflowuniverse.crystallib.baobab.jobs
import time
import rand

// Arguments of schedule_actions
@[params]
pub struct ScheduleActionsArgs {
	twinid     u32
	src_twinid u32
	src_action string
	timeout    u32
	actions    []actionsparser.Action
}

// Returns a collection of jobs from a list of actions
pub fn (mut client Client) schedule_actions(args ScheduleActionsArgs) !ActionJobs {
	mut jobsfactory := ActionJobs{}
	for a in args.actions {
		mut job := ActionJob{
			guid:   rand.uuid_v4()
			twinid: args.twinid
			action: a.name
			args:   a.params
			// result
			start: time.now()
			// end
			// grace_period
			// error
			timeout:    args.timeout
			src_twinid: args.src_twinid
			src_action: args.src_action
			// dependencies
		}

		// TODO: set as dependency the previous one done

		// call client to schedule the job
		client.job_schedule(mut job) or { return error('Failed to schedule: ${err}') }
		jobsfactory.jobs << job
	}
	return jobsfactory
}
