module raft

import redis
import time
import rand

pub struct RaftNode {
pub mut:
    id              string
    state           string
    current_term    int
    voted_for       string
    log             []string
    commit_index    int
    last_applied    int
    next_index      map[string]int
    match_index     map[string]int
    election_timer  time.Time
    heartbeat_timer time.Time
    redis_client    redis.Client
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
