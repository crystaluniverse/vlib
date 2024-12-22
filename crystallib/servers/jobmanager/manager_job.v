module jobmanager

import freeflowuniverse.crystallib.data.ourtime

// Params for finding jobs
pub struct JobFindParams {
pub mut:
	id        ?u32
	actor     ?string
	action    ?string
	job_type  ?string
	completed ?bool
	state     ?JobState
	agent     ?u32
	executor  ?u32
}

// Manager for Job objects
pub struct JobManager {
mut:
	jobs    map[u32]Job
	last_id u32
}

// Create a new job manager
pub fn new_job_manager() JobManager {
	return JobManager{
		jobs:    map[u32]Job{}
		last_id: 0
	}
}

// Set (create/update) a job
pub fn (mut m JobManager) set(mut job Job) !Job {
	if job.id == 0 {
		// New job
		m.last_id++
		job.id = m.last_id
		job.create_date = ourtime.now()
		if job.schedule_date.unixt == 0 {
			job.schedule_date = job.create_date
		}
	}
	m.jobs[job.id] = job
	return job
}

// Get a job by ID
pub fn (m JobManager) get(id u32) !Job {
	if id in m.jobs {
		return m.jobs[id]
	}
	return error('Job with ID ${id} not found')
}

// Delete a job by ID
pub fn (mut m JobManager) delete(id u32) ! {
	if id in m.jobs {
		m.jobs.delete(id)
		return
	}
	return error('Job with ID ${id} not found')
}

// Delete all jobs
pub fn (mut m JobManager) delete_all() {
	m.jobs.clear()
	m.last_id = 0
}

// Find jobs based on parameters
pub fn (m JobManager) find(params JobFindParams) []Job {
	mut result := []Job{}

	for _, job in m.jobs {
		if !matches_job_params(job, params) {
			continue
		}
		result << job
	}

	return result
}

// Helper function to check if a job matches the find parameters
fn matches_job_params(job Job, params JobFindParams) bool {
	if id := params.id {
		if id != job.id {
			return false
		}
	}
	if actor := params.actor {
		if actor != job.actor {
			return false
		}
	}
	if action := params.action {
		if action != job.action {
			return false
		}
	}
	if job_type := params.job_type {
		if job_type != job.job_type {
			return false
		}
	}
	if completed := params.completed {
		if completed != job.completed {
			return false
		}
	}
	if state := params.state {
		if state != job.state {
			return false
		}
	}
	if agent := params.agent {
		if agent != job.agent {
			return false
		}
	}
	if executor := params.executor {
		if executor != job.executor {
			return false
		}
	}
	return true
}
