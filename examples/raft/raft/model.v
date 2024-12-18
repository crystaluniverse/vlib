module main

import redis
import time
import rand
import json

pub struct VoteRequest {
pub mut:
	typ            string = 'vote_request'
	term           int
	candidate_id   string
	last_log_index int
	last_log_term  int
}

pub struct VoteResponse {
pub mut:
	typ          string = 'vote_response'
	term         int
	voter_id     string
	vote_granted bool
}

pub struct AppendEntries {
pub mut:
	typ            string = 'append_entries'
	term           int
	leader_id      string
	prev_log_index int
	prev_log_term  int
	entries        []string
	leader_commit  int
}
