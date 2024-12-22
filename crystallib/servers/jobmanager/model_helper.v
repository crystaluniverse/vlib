module jobmanager

import time

// Helper function to get current Unix timestamp
pub fn now() i64 {
	return time.now().unix()
}
