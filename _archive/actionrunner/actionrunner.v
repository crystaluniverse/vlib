module actionrunner

import freeflowuniverse.crystallib.baobab.actor
import freeflowuniverse.crystallib.baobab.client { Client }
import freeflowuniverse.crystallib.baobab.jobs { ActionJob }
import rand

const default_waiting_actors = 1.0

// A struct representing an ActionRunner. It contains
// a list of actors that it manages and a client that it
// uses to create jobs in redis and to submit the to the
// processor
@[heap]
pub struct ActionRunner {
pub mut:
	client                 &Client
	running                bool
	timeout_waiting_actors f64 = default_waiting_actors
}

// This is the factory function for actionrunner
pub fn new(client_ Client, actors []&actor.IActor) ActionRunner {
	mut ar := ActionRunner{
		actors: actors
		client: &client_
	}
	return ar
}

// This function will run forever until you set the running attribute
// to false. You should call this function in a separate thread. It
// will look into the queues of its actors
// (jobs.actors.$domain_name.$actor_name)
pub fn (mut ar ActionRunner) run() {
	ar.running = true
	mut queues_actors := ar.actors.map('jobs.actors.${it.name}')
	for ar.running {
		rand.shuffle[string](mut queues_actors) or { eprintln('Failed to shuffle actor queues') }
		// pull jobs for our actors: wait till one of the actors has a job
		res := ar.client.redis.brpop(queues_actors, ar.timeout_waiting_actors) or {
			if '${err}' != 'timeout on brpop' {
				eprintln('Unexpected error: ${err}')
			}
			continue
		}
		if res.len != 2 || res[1] == '' {
			continue
		}
		mut job := ar.client.job_get(res[1]) or {
			eprintln('Failed getting job from db: ${err}')
			continue
		}
		ar.execute(mut job) or { eprintln('Failed to execute the job: ${err}') }
	}
}

// execute calls execute_internal and handles error/result
fn (mut ar ActionRunner) execute(mut job ActionJob) ! {
	$if debug {
		eprintln('Executing job: ${job.guid}')
	}

	ar.execute_internal(mut job) or {
		ar.job_error(mut job, err.msg())!
		return
	}
	ar.job_result(mut job)!
	$if debug {
		eprintln('Execution finished: ${job.guid}')
	}
}

// matches job with actor, and calls actor.execute to execute job
fn (mut ar ActionRunner) execute_internal(mut job ActionJob) ! {
	// match actionjob with correct actor
	mut actor_ := ar.actors.filter(job.action.starts_with(it.name))
	if actor_.len == 1 {
		ar.client.job_status_set(mut job, .active)!
		actor_[0].execute(mut job)!
		return
	}
	// todo: handle multiple actor case

	return error('could not find actor to execute on the job')
}

// a job has failed, this function will set the status to failure
// and return the job
fn (mut ar ActionRunner) job_error(mut job ActionJob, errmsg string) ! {
	job.error = errmsg
	ar.client.job_status_set(mut job, .error)!

	mut q_error := ar.client.redis.queue_get('jobs.processor.error')
	q_error.add(job.guid)!
}

// job was a success so let's return the job.
fn (mut ar ActionRunner) job_result(mut job ActionJob) ! {
	ar.client.job_status_set(mut job, .done)!

	mut q_result := ar.client.redis.queue_get('jobs.processor.result')
	q_result.add(job.guid)!
}
