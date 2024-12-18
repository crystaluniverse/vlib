module main

import redis
import time
import rand
import json

fn new_raft_node(id string, redis_client redis.Client) &RaftNode {
	return &RaftNode{
		id:              id
		state:           'follower'
		current_term:    0
		voted_for:       ''
		log:             []
		commit_index:    0
		last_applied:    0
		next_index:      map[string]int{}
		match_index:     map[string]int{}
		election_timer:  time.now()
		heartbeat_timer: time.now()
		redis_client:    redis_client
	}
}

fn (mut node RaftNode) start_election() {
	node.state = 'candidate'
	node.current_term++
	node.voted_for = node.id
	node.election_timer = time.now().add_seconds(rand.int_in_range(5, 10))

	vote_request := VoteRequest{
		term:           node.current_term
		candidate_id:   node.id
		last_log_index: node.log.len - 1
		last_log_term:  if node.log.len > 0 { node.log.last().split(',')[0].int() } else { 0 }
	}

	json_request := json.encode(vote_request)
	node.redis_client.publish('raft_channel', json_request) or { panic(err) }
}

fn (mut node RaftNode) send_heartbeat() {
	heartbeat := AppendEntries{
		term:           node.current_term
		leader_id:      node.id
		prev_log_index: 0
		prev_log_term:  0
		entries:        []
		leader_commit:  node.commit_index
	}

	json_heartbeat := json.encode(heartbeat)
	node.redis_client.publish('raft_channel', json_heartbeat) or { panic(err) }
	node.heartbeat_timer = time.now().add_seconds(1)
}

fn (mut node RaftNode) handle_vote_request(vote_request VoteRequest) {
	if vote_request.term > node.current_term {
		node.current_term = vote_request.term
		node.state = 'follower'
		node.voted_for = ''
	}

	if vote_request.term < node.current_term {
		return
	}

	if node.voted_for == '' || node.voted_for == vote_request.candidate_id {
		node.voted_for = vote_request.candidate_id
		node.election_timer = time.now().add_seconds(rand.int_in_range(5, 10))

		vote_response := VoteResponse{
			term:         node.current_term
			voter_id:     node.id
			vote_granted: true
		}

		json_response := json.encode(vote_response)
		node.redis_client.publish('raft_channel', json_response) or { panic(err) }
	}
}

fn (mut node RaftNode) handle_vote_response(vote_response VoteResponse) {
	if node.state != 'candidate' {
		return
	}

	if vote_response.term > node.current_term {
		node.current_term = vote_response.term
		node.state = 'follower'
		node.voted_for = ''
		return
	}

	if vote_response.vote_granted {
		// In a real implementation, you'd count votes and become leader if majority achieved
		node.state = 'leader'
		node.send_heartbeat()
	}
}

fn (mut node RaftNode) handle_append_entries(append_entries AppendEntries) {
	if append_entries.term > node.current_term {
		node.current_term = append_entries.term
		node.state = 'follower'
		node.voted_for = ''
	}

	if append_entries.term < node.current_term {
		return
	}

	node.election_timer = time.now().add_seconds(rand.int_in_range(5, 10))

	// In a real implementation, you'd handle log replication here
}

fn (mut node RaftNode) check_messages() {
	message := node.redis_client.subscribe('raft_channel') or { return }

	decoded := json.decode(message) or {
		println('Failed to decode message: ${err}')
		return
	}

	match decoded['type'].str() {
		'vote_request' {
			vote_request := json.decode(VoteRequest, message) or { panic(err) }
			node.handle_vote_request(vote_request)
		}
		'vote_response' {
			vote_response := json.decode(VoteResponse, message) or { panic(err) }
			node.handle_vote_response(vote_response)
		}
		'append_entries' {
			append_entries := json.decode(AppendEntries, message) or { panic(err) }
			node.handle_append_entries(append_entries)
		}
		else {
			println('Unknown message type: ${decoded['type']}')
		}
	}
}

fn (mut node RaftNode) run() {
	for {
		match node.state {
			'follower' { node.run_follower() }
			'candidate' { node.run_candidate() }
			'leader' { node.run_leader() }
			else { panic('Invalid state') }
		}
		time.sleep(100 * time.millisecond)
	}
}

fn (mut node RaftNode) run_follower() {
	if time.now() > node.election_timer {
		node.start_election()
	}
	node.check_messages()
}

fn (mut node RaftNode) run_candidate() {
	if time.now() > node.election_timer {
		node.start_election()
	}
	node.check_messages()
}

fn (mut node RaftNode) run_leader() {
	if time.now() > node.heartbeat_timer {
		node.send_heartbeat()
	}
	node.check_messages()
}

fn run_node(id string) {
	redis_client := redis.connect('localhost:6379') or { panic(err) }
	mut node := new_raft_node(id, redis_client)
	node.run()
}

fn main() {
	for i := 0; i < 7; i++ {
		node_id := rand.uuid_v4()
		go run_node(node_id)
	}

	// Keep the main thread alive
	for {
		time.sleep(1 * time.second)
	}
}
