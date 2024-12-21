module rpcsocket

import freeflowuniverse.crystallib.data.ourtime

// Params for finding job logs
pub struct JobLogFindParams {
pub mut:
	id            ?u32
	job           ?string
	category      ?string
	log_sequence  ?int
	min_sequence  ?int
	max_sequence  ?int
}

// Manager for JobLog objects
pub struct JobLogManager {
mut:
	logs map[u32]JobLog
	last_id u32
}

// Create a new job log manager
pub fn new_job_log_manager() JobLogManager {
	return JobLogManager{
		logs: map[u32]JobLog{}
		last_id: 0
	}
}

// Set (create/update) a job log
pub fn (mut m JobLogManager) set(mut log JobLog) !JobLog {
	if log.id == 0 {
		// New log
		m.last_id++
		log.id = m.last_id
		log.log_time = ourtime.now()
	}
	m.logs[log.id] = log
	return log
}

// Get a job log by ID
pub fn (m JobLogManager) get(id u32) !JobLog {
	if id in m.logs {
		return m.logs[id]
	}
	return error('JobLog with ID ${id} not found')
}

// Delete a job log by ID
pub fn (mut m JobLogManager) delete(id u32) ! {
	if id in m.logs {
		m.logs.delete(id)
		return
	}
	return error('JobLog with ID ${id} not found')
}

// Delete all job logs
pub fn (mut m JobLogManager) delete_all() {
	m.logs.clear()
	m.last_id = 0
}

// Find job logs based on parameters
pub fn (m JobLogManager) find(params JobLogFindParams) []JobLog {
	mut result := []JobLog{}
	
	for _, log in m.logs {
		if !matches_job_log_params(log, params) {
			continue
		}
		result << log
	}
	
	return result
}

// Helper function to check if a job log matches the find parameters
fn matches_job_log_params(log JobLog, params JobLogFindParams) bool {
	if id := params.id {
		if id != log.id {
			return false
		}
	}
	if job := params.job {
		if job != log.job {
			return false
		}
	}
	if category := params.category {
		if category != log.category {
			return false
		}
	}
	if log_sequence := params.log_sequence {
		if log_sequence != log.log_sequence {
			return false
		}
	}
	if min_sequence := params.min_sequence {
		if log.log_sequence < min_sequence {
			return false
		}
	}
	if max_sequence := params.max_sequence {
		if log.log_sequence > max_sequence {
			return false
		}
	}
	return true
}
