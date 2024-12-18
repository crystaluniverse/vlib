module jobs

import freeflowuniverse.crystallib.baobab.jobs { ActionJob, ActionJobState, JobNewArgs, json_load }

// Create a new job, it does not send it for execution
// yet
pub fn (mut client Client) job_new(args JobNewArgs) !ActionJob {
	mut j := jobs.new(args)!
	j.src_twinid = client.twinid
	return j
}

// Creates a new job and schedules i (aka sending it
// to the processor).
pub fn (mut client Client) job_new_schedule(args JobNewArgs) !ActionJob {
	mut job := client.job_new(args)!
	client.job_schedule(mut job)!
	return job
}

// Creates a new job, schedules it and waits for the
// job to finish.
pub fn (mut client Client) job_new_wait(args JobNewArgs) !ActionJob {
	mut job := client.job_new(args)!
	return client.job_schedule_wait(mut job, args.timeout)! //? should this be the job timeout or a custom timeout
}

// Schedules the job to be executed
pub fn (mut client Client) job_schedule(mut job ActionJob) ! {
	$if debug {
		eprintln('Scheduling job: ${job.guid}')
	}
	job.state = .tostart
	client.job_set(job)!
	client.redis.lpush('jobs.processor.in', '${job.guid}')!
}

// Gets a job back from redis.
pub fn (mut client Client) job_get(guid string) !ActionJob {
	data := client.redis.hget('jobs.db', '${guid}') or {
		return error('Cannot find job: ${guid}.\n${err}')
	}
	mut job := json_load(data)!
	return job
}

// Saves a job in local redis.
pub fn (mut client Client) job_set(job ActionJob) ! {
	data := job.json_dump()
	client.redis.hset('jobs.db', '${job.guid}', data)!
}

// Removes the job from the local redis.
pub fn (mut client Client) job_delete(guid string) ! {
	client.redis.hdel('jobs.db', '${guid}')!
}

// Updates the status of a job in local redis.
pub fn (mut client Client) job_status_set(mut job ActionJob, state ActionJobState) ! {
	job.state = state
	client.job_set(job)!
}

// Updates the status of a job to error and sets the
// error message.
pub fn (mut client Client) job_error_set(mut job ActionJob, error string) ! {
	job.state = .error
	job.error = error
	client.job_set(job)!
}

// Checks if the job is ready to be retrieved (if the
// state is error or ok).
pub fn (mut client Client) job_check_ready(guid string) !bool {
	key := 'jobs.return.${guid}'
	ll := client.redis.llen(key)!
	if ll > 0 {
		return true
	}
	return false
}

// Waits for a given time in seconds until the job finishes
// (can be error or ok). If it finishes the job will be
// returned. If the timeout exceeds an error will be thrown.
// Setting the timout 0, means we will wait for 1h.
pub fn (mut client Client) job_wait(guid string, timeout_ f64) !ActionJob {
	mut timeout := timeout_
	if timeout == 0 {
		timeout = 3600.0
	}
	key := 'jobs.return.${guid}'
	client.redis.brpop([key], timeout)! // will block and wait
	return client.job_get(guid)!
}

// Schedules the job to be executed and wait for it to
// finish.
pub fn (mut client Client) job_schedule_wait(mut job ActionJob, timeout f64) !ActionJob {
	client.job_schedule(mut job)!
	return client.job_wait(job.guid, timeout)!
}

// Helper function to reset the redis keys used by the
// client.
pub fn (mut client Client) reset() ! {
	client.redis.del('jobs.db')!
	client.redis.del('client.iam')!

	// need to save the info we still have in mem to redis
	client.redis.set('client.mytwin.id', client.twinid.str())!
}
