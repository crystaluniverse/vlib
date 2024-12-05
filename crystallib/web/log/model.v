module log

import time

pub struct Log {
	id          int         @[primary; sql: serial]
pub:
	timestamp time.Time
pub mut:
	event   string
	subject string
	object  string 
	message string // a custom message that can be attached to a log
}

// pub struct Event {
// 	name        string
// 	description string
// }

// // log_request logs http requests
// pub fn create_log(log Log) Log {
// 	return Log{
// 		...log
// 		timestamp: time.now()
// 	})
// }

// // log_request logs http requests
// pub fn (mut a Analyzer) get_logs(subject string) []Log {
// 	return []Log{}
// }
