module raft

import os
import net
import time
import rand
import json
import sync

const rand_min = 150
const rand_max = 300
const time_scale = 1000
const heartbeat_interval = 100
const rtt_interval = 50
const sock_recv_size = 32768

// TODO: global variables are discouraged by V, and i don't believe we need these to be global at all
__global (
	my_id       string
	replica_ids []string
	sock        net.UnixStreamSocket
)

struct StateMachine {
mut:
	id                     string
	other_server_ids       []string
	leader_id              string = 'FFFF'
	state                  string = 'follower' // leader, candidate, follower
	current_term           int // latest term server has seen
	votes_count            int
	voted_for              ?string    //# candidate id that received vote in current term
	log                    []LogEntry //# log entries; each entry contains mid, command for state machine, and term
	commit_index           int        //# index of highest log entry known to be committed
	last_applied           int        //# index of highest log entry applied to state machine
	next_index             []int      //# for each server, index of the next log entry to send to that server
	match_index            []int      //# for each server, index of highest log entry known to be replicated
	last_rpc_time          int        // last time state machine has received an RPC from replica
	election_timeout       int        // random.uniform(RAND_MIN, RAND_MAX)
	start_election_time    int
	key_value_store        map[string]string
	queued_client_requests []ClientRequest
	unacked_requests       map[int][]string // # MID -> list of server ids that haven't sent an accept_request back
	last_heartbeat_sent    int
}

// TODO: no mention of persistent storage, which is definitely needed, if a server crashes it has to be rebooted with the exact same configs
// TODO: there is no rpc server, only a unix socket, who should be at the other end of the socket? currently, it is expected to
// have some kind of message broker or router which needs to have persistant state about servers and their addresses
// TODO: no mention of reconfiguration, cluster cannot change
// TODO: the only defined struct is the StateMachine struct
// TODO: no error handling, either succeed or panic
// TODO: no mention of snapshotting,

struct ClientRequest {}

struct LogEntry {}

struct RaftMessage {}

struct CommandData {}

fn new_state_machine(id string, other_server_ids []string) &StateMachine {
	mut sm := &StateMachine{
		id:               id
		other_server_ids: other_server_ids
		log:              []LogEntry{len: 0, init: LogEntry{}}
	}
	sm.next_index = sm.init_next_idx_to_send()
	sm.match_index = sm.init_match_idxs()
	sm.election_timeout = rand.int_in_range(rand_min, rand_max) or { 0 }
	return sm
}

// run method
fn (mut sm StateMachine) run() {
	for {
		// TODO: sock is not initialized
		// TODO: servers act upon receiving a message, if no message is received server will block
		raw_msg := sock.recv(sock_recv_size)
		// received nothing
		if raw_msg.len == 0 {
			return
		} else {
			msg := json.decode(RaftMessage, raw_msg) or { panic(err) }
			// TODO: apply should not happen unless the log is committed (sent to a majority of servers)
			sm.apply_command_and_reply_client()
			if msg.type !in ['get', 'put'] {
				sm.check_terms(msg.term, msg.leader)
			}
			if sm.state == 'follower' {
				if msg.src == sm.leader_id {
					sm.last_rpc_time = time.sys_mono_unixtime_ms() // [[2]](https://poe.com/citation?message_id=175458693113&citation=2)
				}
				sm.act_as_follower(msg)
			} else if sm.state == 'candidate' {
				sm.act_as_candidate(msg)
			} else if sm.state == 'leader' {
				if time.sys_mono_unixtime_ms() - sm.last_heartbeat_sent >= heartbeat_interval
					&& sm.unacked_requests.len == 0 {
					sm.send_regular_heartbeat([])
				}
				sm.act_as_leader(msg)
			}
		}
	}
}

// print_msg method
fn (sm StateMachine) print_msg(msg string, bool bool) {
	if bool {
		println('[${time.sys_mono_unixtime_ms()}] [${sm.id}] [${sm.state}] [term: ${sm.current_term}] ${msg}')
	}
}

''
'
Volatile state on leader
upon election, leader initializes these values to its last log index + 1
'
''
fn (mut sm StateMachine) init_next_idx_to_send() map[string]int {
	mut next_idx_to_send := map[string]int{}
	if sm.state == 'leader' {
		for server_id in sm.other_server_ids {
			next_idx_to_send[server_id] = sm.log.len
		}
	}
	return next_idx_to_send
}

''
'
for each server, index of highest log entry known to be replicated
always initialize to 0
'
''
fn (mut sm StateMachine) init_match_idxs() map[string]int {
	mut match_index := map[string]int{}
	if sm.state == 'leader' {
		for server_id in sm.other_server_ids {
			match_index[server_id] = 0
		}
	}
	return match_index
}

''
'
All servers:
if RPC request or response contains term given_term > current_term:
set current_term = given_term, convert to follower
return True if becomes follower
'
''
fn (mut sm StateMachine) check_terms(given_term int, leader string) {
	if given_term > sm.current_term {
		sm.become_follower(given_term, leader)
	}
}

''
'
Follower responds redirectly when received client messages, or queue up messages if leader is unknown
'
''
fn (mut sm StateMachine) client_handler(msg RaftMessage) {
	if sm.leader_id == 'FFFF' {
		sm.queued_client_requests << msg
	} else {
		for m in sm.queued_client_requests.clone() {
			response := RaftMessage{
				src:    sm.id
				dst:    m.src
				leader: sm.leader_id
				type_:  'redirect'
				mid:    m.mid
			}
			sock.send(response.encode()) or { panic(err) }
			sm.queued_client_requests.delete(m) // TODO: empty queue when done
		}
		response := RaftMessage{
			src:    sm.id
			dst:    msg.src
			leader: sm.leader_id
			type_:  'redirect'
			mid:    msg.mid
		}
		sock.send(response.encode()) or { panic(err) }
	}
}

fn (mut sm StateMachine) become_follower(new_term int, new_leader string) {
	sm.state = 'follower'
	sm.last_rpc_time = time.sys_mono_unixtime_ms()
	sm.current_term = new_term
	sm.voted_for = none
	sm.votes_count = 0
	sm.leader_id = new_leader
}

''
'
For all servers: commits and applies the commands to StateMachine
For leader: send clients all queued up responses
'
''
fn (mut sm StateMachine) apply_command_and_reply_client() {
	if sm.commit_index > sm.last_applied {
		sm.last_applied++
		mid, command, term := sm.log[sm.last_applied]
		command_data := json.decode(CommandData, command) or { panic(err) }
		if command_data.cmd == 'put' {
			sm.key_value_store[command_data.key] = command_data.value
		}
		if sm.state == 'leader' {
			if command_data.cmd == 'get' {
				value := sm.key_value_store[command_data.key] or { '' }
				response := RaftMessage{
					src:    sm.id
					dst:    command_data.client_id
					leader: sm.id
					type_:  'ok'
					mid:    mid
					value:  value
				}
				sock.send(response.encode()) or { panic(err) }
				sm.print_msg('RESPONSE SENT ${mid} ${time.sys_mono_unixtime_ms()}', true)
			} else if command_data.cmd == 'put' {
				response := RaftMessage{
					src:    sm.id
					dst:    command_data.client_id
					leader: sm.id
					type_:  'ok'
					mid:    mid
				}
				sock.send(response.encode()) or { panic(err) }
				sm.print_msg('RESPONSE SENT ${mid} ${time.sys_mono_unixtime_ms()}', true)
			}
		}
	}
}

''
'
Becomes a candidate, start election
'
''
fn (mut sm StateMachine) become_candidate() {
	sm.state = 'candidate'
	sm.voted_for = none
	sm.votes_count = 0
	sm.start_election()
}

''
'
Becomes a leader after election
'
''
fn (mut sm StateMachine) become_leader() {
	sm.state = 'leader'
	sm.next_index = sm.init_next_idx_to_send()
	sm.match_index = sm.init_match_idxs()
	sm.leader_id = sm.id
	sm.voted_for = none
	sm.votes_count = 0
	sm.commit_index = sm.log.len - 1
	sm.apply_command_and_reply_client()
	sm.send_regular_heartbeat([])
}

''
'
starts election. Candidate increments term, votes for itself
'
''
fn (mut sm StateMachine) start_election() {
	// increment term at start of each election
	sm.current_term++
	// votes for itself
	sm.votes_count = 1
	sm.voted_for = sm.id
	// set leader id to None
	sm.leader_id = 'FFFF'
	// reset election timer
	sm.election_timeout = rand.float_in_range(rand_min, rand_max)
	sm.start_election_time = time.sys_mono_unixtime_ms()
	// send out request vote RPCs
	sm.send_vote_requests()
	// process the results
}

''
'
As a candidate, request other followers to vote for self
'
''
fn (mut sm StateMachine) send_vote_requests() {
	// indexed by 1
	last_log_index := sm.log.len - 1
	mid, command, last_log_term := sm.log[last_log_index]
	for server_id in sm.other_server_ids {
		request_for_vote := RaftMessage{
			src:            sm.id
			dst:            server_id
			leader:         sm.leader_id
			type_:          'vote_request'
			mid:            uuid.uuid4().str()
			term:           sm.current_term
			last_log_index: last_log_index
			last_log_term:  last_log_term
		}
		sock.send(request_for_vote.encode()) or { panic(err) }
	}
}

''
'
Respond to the candidate with a vote result
'
''
fn (mut sm StateMachine) send_vote_response(msg RaftMessage, term int, vote_granted bool) {
	vote_response := RaftMessage{
		src:          sm.id
		dst:          msg.src
		leader:       sm.leader_id
		type_:        'vote_response'
		mid:          msg.mid
		term:         term
		vote_granted: vote_granted
	}
	sock.send(vote_response.encode()) or { panic(err) }
}

// find_first_term_instance finds the first index in the log where the term is less than the given term
fn (mut sm StateMachine) find_first_term_instance(term int, start_index int) int {
	for i := start_index; i >= 0; i-- {
		_, _, cur_term := sm.log[i]
		if cur_term < term {
			return i + 1
		}
	}
	return 1
}

// send_append_response sends an 'append_response' message to the leader
fn (mut sm StateMachine) send_append_response(msg RaftMessage, prev_log_index int, prev_log_term int, accept_request bool) {
	response := RaftMessage{
		src:            sm.id
		dst:            msg.src
		leader:         sm.leader_id
		type_:          'append_response'
		mid:            msg.mid
		term:           sm.current_term
		prev_log_index: prev_log_index
		prev_log_term:  prev_log_term
		entries:        msg.entries
		receive_time:   time.sys_mono_unixtime_ms()
		last_log_index: sm.log.len - 1
		accept_request: accept_request
	}
	sock.send(response.encode()) or { panic(err) }
}

// append_handler handles append entry requests from the leader
fn (mut sm StateMachine) append_handler(msg RaftMessage) {
	if msg.entries.len == 0 {
		// Heartbeat, update follower state and commit index if needed
		sm.become_follower(msg.term, msg.leader)
		if msg.leader_commit > sm.commit_index {
			sm.commit_index = min(msg.leader_commit, sm.log.len - 1)
		}
		return
	}

	// # the 3 servers will have a longer log because they are able to process client requests
	// # the 2 servers might have a higher term, because they might need to elect new leader
	// # when the partition is gone, the 2 servers will always reject the new entries because of their higher term
	if sm.current_term > msg.term {
		sm.print_msg('REJECTED because I\'m at term ${sm.current_term} compared to ${msg.term}',
			true)
		sm.send_append_response(msg, msg.prev_log_index, msg.prev_log_term, false)
		return
	}

	// Check if previous log entry's term matches leader's term [[6]](https://poe.com/citation?message_id=175464093689&citation=6)
	prev_mid, prev_command, prev_term := sm.log[msg.prev_log_index]
	if prev_term != msg.prev_log_term {
		index := sm.find_first_term_instance(prev_term, msg.prev_log_index)
		sm.print_msg('REJECTED ${msg.mid} because my prev_term ${prev_term} doesn\'t match their\'s ${msg.prev_log_term} at index ${msg.prev_log_index}',
			true)
		mid, command, term := sm.log[index]
		sm.print_msg('ADJUSTED index to ${index} with term ${term}', true)
		sm.send_append_response(msg, index, prev_term, false)
		return
	}

	// Previous log entry not found, reject the request [[6]](https://poe.com/citation?message_id=175464093689&citation=6)
	if msg.prev_log_index >= sm.log.len {
		mid, command, term := sm.log.last()
		sm.print_msg('REJECTED ${msg.mid} because length of log is ${sm.log.len}', true)
		sm.send_append_response(msg, sm.log.len - 1, term, false)
		return
	}

	// # ready to accept the AppendEntriesRPC request
	// # delete all following entries after the current one
	// # If an existing entry conflicts with a new one (same index
	// # but different terms), delete the ***existing*** entry and all that
	// # follow it
	keep_index := msg.prev_log_index + 1
	sm.log = sm.log[..keep_index]
	for entry in msg.entries {
		if !sm.log.contains(entry) {
			sm.log << entry
		}
	}

	// # ready to accept the AppendEntriesRPC request
	// # delete all following entries after the current one
	// # If an existing entry conflicts with a new one (same index
	// # but different terms), delete the ***existing*** entry and all that
	// # follow it
	sm.last_applied = max(sm.last_applied, sm.log.len - 1)
	sm.commit_index = max(sm.commit_index, sm.log.len - 1)
	if msg.leader_commit > sm.commit_index {
		sm.commit_index = min(msg.leader_commit, sm.log.len - 1)
	}
	sm.send_append_response(msg, msg.prev_log_index, msg.prev_log_term, true)
}

// Acting as a follower
fn (mut sm StateMachine) act_as_follower(msg RaftMessage) {
	// have we timed out
	if time.sys_mono_unixtime_ms() - sm.last_rpc_time >= sm.election_timeout {
		// TODO We'll talk about this

		// TODO: this way we lose the msg, no???
		if sm.voted_for.len == 0 {
			sm.become_candidate()
			return
		}
	}

	if msg.type_ in ['get', 'put'] {
		sm.client_handler(msg)
		return
	}

	sm.election_timeout = rand.float_in_range(rand_min, rand_max) or { 0 }

	if msg.type_ == 'append_request' {
		sm.append_handler(msg)
	} else if msg.type_ == 'vote_request' {
		if msg.term < sm.current_term {
			sm.send_vote_response(msg, sm.current_term, false)
		} else if sm.voted_for.len == 0 || sm.voted_for == msg.src {
			last_log_index := sm.log.len - 1
			mid, command, last_log_term := sm.log[last_log_index]
			if last_log_index <= msg.last_log_index && last_log_term <= msg.last_log_term {
				sm.voted_for = msg.src
				sm.send_vote_response(msg, msg.term, true)
			} else {
				sm.send_vote_response(msg, sm.current_term, false)
			}
		} else {
			sm.send_vote_response(msg, sm.current_term, false)
		}
	}
}

// Acting as a candidate:
// - Process the received votes:
// - receive responses, if N/2 + 1 then become leader and send heartbeat
// - if tie, timeout and restart election
// - if failed, become follower
fn (mut sm StateMachine) act_as_candidate(msg RaftMessage) {
	n := sm.other_server_ids.len
	majority_votes := n / 2 + 1

	// if we've timed out
	if time.sys_mono_unixtime_ms() - sm.start_election_time >= sm.election_timeout {
		// split vote scenario
		sm.become_candidate()
	} else {
		// checks if received enough votes
		// if gathered majority votes, become leader
		if sm.votes_count >= majority_votes {
			sm.become_leader()
			return
		}
		// receive more messages
		if msg.type_ in ['get', 'put'] {
			sm.client_handler(msg)
			return
		} else if msg.type_ == 'vote_response' {
			if msg.vote_granted {
				// collect vote
				sm.votes_count++
				if sm.votes_count >= majority_votes {
					sm.become_leader()
					return
				}
			}
			// don't vote because we're a candidate
		} else if msg.type_ == '0' {
			sm.send_vote_response(msg, sm.current_term, false)
		} else if msg.type_ == 'append_request' {
			sm.append_handler(msg)
		}
	}
}

// For leader, appends new command to its log as a new entry
fn (mut sm StateMachine) append_new_log_entry(command string, mid string) (int, string, int) {
	// TODO should entry contain MID ?
	// TODO do i care about duplicate?
	entry := mid, command, sm.current_term
	sm.log << entry
	return entry
}

// Acting as a leader
fn (mut sm StateMachine) act_as_leader(msg RaftMessage) {
	n := sm.other_server_ids.len + 1
	majority := n / 2 + 1
	minority := n - majority
	mut entries := []LogEntry{}
	if msg.type_ == 'get' {
		key := msg.key
		command := json.encode({
			'cmd':       msg.type_
			'client_id': msg.src
			'key':       key
		})
		sm.unacked_requests[msg.mid] = []string{}
		entry := sm.append_new_log_entry(command, msg.mid)
		entries << entry
		sm.print_msg('i ${sm.id} CREATED ${msg.mid}', true)
		sm.send_append_request(entries, msg.mid)
		value := sm.key_value_store[key]
		// send back to client
	} else if msg.type_ == 'put' {
		key := msg.key
		value := msg.value
		command := json.encode({
			'cmd':       msg.type_
			'client_id': msg.src
			'key':       key
			'value':     value
		})
		entry := sm.append_new_log_entry(command, msg.mid)
		entries << entry
		sm.unacked_requests[msg.mid] = []string{}
		sm.print_msg('i ${sm.id} CREATED ${msg.mid}', true)
		sm.send_append_request(entries, msg.mid)
	} else if msg.type_ == 'append_response' {
		if msg.accept_request {
			// set the next index to send to be: the index of last entry appended + 1
			sm.next_index[msg.src] = msg.last_log_index + 1 // TODO unsure
			mut unacked_msgs := sm.unacked_requests[msg.mid] or { []string{} }
			for m in unacked_msgs {
				m_json := json.decode(string, m) or {
					map[string]string{}
				}
				if m_json['dst'] == msg.src {
					sm.unacked_requests[msg.mid].filter(it != m)
					sm.print_msg('i ${sm.id} REMOVED ${m_json}[\'MID\'] request_accepted',
						true)
					break
				}
			}
			if sm.unacked_requests[msg.mid].len == minority {
				sm.commit_index++
				sm.unacked_requests.remove(msg.mid)
			}
		} else {
			sm.print_msg('REJECTED ${msg.mid}', true)
			sm.next_index[msg.src] = msg.prev_log_index
			mut temp_entries := [sm.log[sm.next_index[msg.src]]]
			for entry in msg.entries {
				temp_entries << entry // TODO care about prev_term and prev_idx
			}
			mut unacked_servers := sm.unacked_requests[msg.mid] or { []string{} }
			for m in unacked_servers {
				m_json := json.decode(string, m) or {
					map[string]string{}
				}
				if m_json['dst'] == msg.src {
					sm.unacked_requests[msg.mid].filter(it != m)
					sm.print_msg('i ${sm.id} REMOVED ${m_json}[\'MID\'] request_rejected',
						true)
					break
				}
			}
			sm.append_one_server(temp_entries, msg.src, msg.mid)
		}
		sm.check_timeouts()
	}
}

// Leader resend messages when did not receive an ack of a message after timeout
fn (mut sm StateMachine) check_timeouts() {
	for mid, unacked_msgs in sm.unacked_requests {
		for m in unacked_msgs {
			m_json := json.decode(string, m) or {
				map[string]string{}
			}
			if time.sys_mono_unixtime_ms() - m_json['send_time'] >= rtt_interval {
				cur_time := time.sys_mono_unixtime_ms()
				// update time and dict
				m_json['send_time'] = cur_time
				new_m := json.encode(m_json)
				sm.unacked_requests[mid].filter(it != m)
				sm.unacked_requests[mid] << new_m
				sock.send(new_m) or {}
				sm.print_msg('RESENDING ${m_json}[\'MID\']', true)
				return
			}
		}
	}
}

// Leader send appendEntryRPC to all followers
fn (sm StateMachine) send_append_request(entries []LogEntry, mid string) {
	for server_id in sm.other_server_ids {
		sm.append_one_server(entries, server_id, mid)
	}
}

// Leader send appendEntryRPC to one follower
fn (mut sm StateMachine) append_one_server(entries []LogEntry, server_id string, mid string) {
	prev_log_index := sm.next_index[server_id] - 1
	prev_mid, prev_command, prev_log_term := sm.log[prev_log_index]
	send_time := time.sys_mono_unixtime_ms()
	append_entry_rpc := {
		'src':            sm.id
		'dst':            server_id
		'leader':         sm.id
		'type':           'append_request'
		'MID':            mid
		'term':           sm.current_term
		'entries':        entries
		'leader_commit':  sm.commit_index
		'send_time':      send_time
		'prev_log_index': prev_log_index
		'prev_log_term':  prev_log_term
	}
	sock.send(json.encode(append_entry_rpc)) or {}
	// check that it's not a heartbeat
	if entries.len > 0 {
		sm.unacked_requests[mid] << json.encode(append_entry_rpc)
		sm.print_msg('i ${sm.id} ADDED ${mid}', true)
	}
}

// Leader sends regular heartbeat to the followers
fn (mut sm StateMachine) send_regular_heartbeat(entries []LogEntry) {
	mid := uuid.uuid4().str()
	sm.last_heartbeat_sent = time.sys_mono_unixtime_ms()
	sm.send_append_request(entries, mid)
}

fn main() {
	my_server := StateMachine{
		id:               my_id
		other_server_ids: replica_ids
	}
	my_server.run()
}
