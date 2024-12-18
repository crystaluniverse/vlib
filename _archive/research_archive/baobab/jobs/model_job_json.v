module jobs

import freeflowuniverse.crystallib.data.paramsparser
import json
import time

// Actionjob as how its being send & received from outside
pub struct ActionJobPublic {
pub mut:
	guid         string // unique jobid (unique per actor which is unique per twin)
	twinid       u32    // which twin needs to execute the action
	action       string // actionname in long form includes domain & actor
	args         paramsparser.Params
	result       paramsparser.Params
	state        string
	start        i64      // epoch
	end          i64      // epoch
	grace_period u32      // wait till next run, in seconds
	error        string   // string description of what went wrong
	timeout      u32      // time in seconds, 2h is maximum
	src_twinid   u32      // which twin was sending the job, 0 if local
	src_action   string   // unique actor path, runs on top of twin
	dependencies []string // list of guids we need to wait on
}

// Converts a job to the public representation of a job
pub fn (job ActionJob) pub_get() ActionJobPublic {
	mut statestr := ''
	match job.state {
		.init { statestr = 'init' }
		.tostart { statestr = 'tostart' }
		.recurring { statestr = 'recurring' }
		.scheduled { statestr = 'scheduled' }
		.active { statestr = 'active' }
		.done { statestr = 'done' }
		.error { statestr = 'error' }
	}
	mut job2 := ActionJobPublic{
		twinid:       job.twinid
		action:       job.action
		args:         job.args
		result:       job.result
		state:        statestr
		start:        job.start.unix_time()
		end:          job.end.unix_time()
		grace_period: job.grace_period
		error:        job.error
		timeout:      job.timeout
		guid:         job.guid
		src_twinid:   job.src_twinid
		src_action:   job.src_action
		dependencies: job.dependencies
	}
	return job2
}

// Encodes a job to json string
pub fn (job ActionJob) json_dump() string {
	mut job2 := job.pub_get()
	job2_data := json.encode(job2)
	return job2_data
}

// Decodes json string job into an ActionJob
pub fn json_load(data string) !ActionJob {
	job := json.decode(ActionJobPublic, data) or {
		return error('Could not json decode: ${data} .\nError:${err}')
	}
	mut statecat := ActionJobState.init
	match job.state {
		'init' { statecat = .init }
		'tostart' { statecat = .tostart }
		'recurring' { statecat = .recurring }
		'scheduled' { statecat = .scheduled }
		'active' { statecat = .active }
		'done' { statecat = .done }
		'error' { statecat = .error }
		else { return error('Could not find job state, needs to be init, tostart, recurring, scheduled, active, done, error') }
	}
	mut jobout := ActionJob{
		twinid:       job.twinid
		action:       job.action
		args:         job.args
		result:       job.result
		state:        statecat
		start:        time.unix(job.start)
		end:          time.unix(job.end)
		grace_period: job.grace_period
		error:        job.error
		timeout:      job.timeout
		guid:         job.guid
		src_twinid:   job.src_twinid
		src_action:   job.src_action
	}
	return jobout
}
