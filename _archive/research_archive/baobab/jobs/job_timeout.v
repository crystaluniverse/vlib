module jobs

import time

// Checks if the timeout has not been reached yet.
pub fn (job &ActionJob) check_timeout_ok() bool {
	if job.timeout == 0 {
		return true
	}
	// TODO: implement/check
	deadline := job.start.unix_time() + i64(job.timeout)
	if deadline < time.now().unix_time() {
		return false
	}
	return true
}
