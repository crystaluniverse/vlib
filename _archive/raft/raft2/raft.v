import json
import time
import rand
import sync

// Mock Redis client implementation
struct MockRedisClient {
mut:
    queues map[string][]string
}

fn new_mock_redis() &MockRedisClient {
    return &MockRedisClient{
        queues: map[string][]string{}
    }
}

fn (mut r MockRedisClient) blpop(keys []string, timeout int) ![]string {
    for key in keys {
        if key in r.queues && r.queues[key].len > 0 {
            value := r.queues[key][0]
            r.queues[key] = r.queues[key][1..]
            return [key, value]
        }
    }
    return error('no data available')
}

fn (mut r MockRedisClient) rpush(key string, value string) !int {
    if key !in r.queues {
        r.queues[key] = []string{}
    }
    r.queues[key] << value
    return r.queues[key].len
}

// Define the state of a Raft node
enum NodeState {
    follower
    candidate
    leader
}

// Log entry structure
struct LogEntry {
    term    int
    command string
}

// Message structure for communication
struct Message {
    msg_type string
    term     int
    sender   int
    receiver int
    data     map[string]int
}

// Raft Node structure
struct RaftNode {
    id             int
mut:
    state          NodeState
    current_term   int
    voted_for      int
    log            []LogEntry
    commit_index   int
    last_applied   int
    peers          []int
    redis_client   &MockRedisClient = new_mock_redis()
    election_reset i64         // Monotonic timestamp
    mutex          &sync.Mutex = sync.new_mutex()
}

// Initialize the node
fn (mut rn RaftNode) init_node() {
    rn.state = .follower
    rn.current_term = 0
    rn.voted_for = -1
    rn.commit_index = 0
    rn.last_applied = 0
    rn.election_reset = time.unix()
}

// Start the Raft node
fn (mut rn RaftNode) start() {
    go rn.run()
    rn.listen()
}

// Main loop for the node
fn (mut rn RaftNode) run() {
    for {
        match rn.state {
            .follower { rn.follower() }
            .candidate { rn.candidate() }
            .leader { rn.leader() }
        }
    }
}

// Follower state behavior
fn (mut rn RaftNode) follower() {
    timeout := 200 * time.millisecond
    for rn.state == .follower {
        now := time.sys_mono_now()
        if now - rn.election_reset > timeout {
            rn.state = .candidate
            break
        }
        time.sleep(10 * time.millisecond)
    }
}

// Candidate state behavior
fn (mut rn RaftNode) candidate() {
    rn.mutex.@lock()
    rn.current_term += 1
    rn.voted_for = rn.id
    rn.election_reset = time.sys_mono_now()
    mut votes_received := 1
    rn.mutex.unlock()

    // Send RequestVote RPCs to all peers
    for peer_id in rn.peers {
        go rn.send_request_vote(peer_id)
    }

    timeout := 200 * time.millisecond
    for rn.state == .candidate {
        now := time.sys_mono_now()
        if now - rn.election_reset > timeout {
            // Election timeout
            break
        }

        // Check if received majority of votes
        rn.mutex.@lock()
        if votes_received > (rn.peers.len + 1) / 2 {
            rn.state = .leader
            rn.mutex.unlock()
            return
        }
        rn.mutex.unlock()
        time.sleep(10 * time.millisecond)
    }
}

// Leader state behavior
fn (mut rn RaftNode) leader() {
    // Send heartbeats to all followers
    heartbeat_interval := 50 * time.millisecond
    for rn.state == .leader {
        for peer_id in rn.peers {
            go rn.send_append_entries(peer_id, [])
        }
        time.sleep(heartbeat_interval)
    }
}

// Listen for incoming messages
fn (mut rn RaftNode) listen() {
    queue_name := 'node_${rn.id}_queue'
    for {
        msgs := rn.redis_client.blpop([queue_name], 0) or {
            println('Redis BLPOP error: $err')
            continue
        }
        for _, msg_data in msgs {
            msg := json.decode(Message, msg_data) or {
                println('Failed to decode message: $msg_data')
                continue
            }
            go rn.handle_message(msg)
        }
    }
}

// Handle incoming messages
fn (mut rn RaftNode) handle_message(msg Message) {
    match msg.msg_type {
        'RequestVote' {
            rn.handle_request_vote(msg)
        }
        'RequestVoteResponse' {
            rn.handle_request_vote_response(msg)
        }
        'AppendEntries' {
            rn.handle_append_entries(msg)
        }
        'AppendEntriesResponse' {
            rn.handle_append_entries_response(msg)
        }
        else {
            println('Unknown message type: $msg.msg_type')
        }
    }
}

// Send RequestVote RPC
fn (mut rn RaftNode) send_request_vote(peer_id int) {
    msg := Message{
        msg_type: 'RequestVote'
        term: rn.current_term
        sender: rn.id
        receiver: peer_id
        data: {
            'last_log_index': rn.log.len - 1
            'last_log_term': if rn.log.len > 0 { rn.log[rn.log.len - 1].term } else { 0 }
        }
    }
    rn.send_message(msg)
}

// Handle RequestVote RPC
fn (mut rn RaftNode) handle_request_vote(msg Message) {
    mut vote_granted := 0
    rn.mutex.@lock()
    if msg.term > rn.current_term {
        rn.current_term = msg.term
        rn.state = .follower
        rn.voted_for = -1
    }
    if (rn.voted_for == -1 || rn.voted_for == msg.sender) && msg.term >= rn.current_term {
        rn.voted_for = msg.sender
        vote_granted = 1
        rn.election_reset = time.sys_mono_now()
    }
    rn.mutex.unlock()

    // Send response
    response := Message{
        msg_type: 'RequestVoteResponse'
        term: rn.current_term
        sender: rn.id
        receiver: msg.sender
        data: {
            'vote_granted': vote_granted
        }
    }
    rn.send_message(response)
}

// Handle RequestVoteResponse
fn (mut rn RaftNode) handle_request_vote_response(msg Message) {
    rn.mutex.@lock()
    if msg.term > rn.current_term {
        rn.current_term = msg.term
        rn.state = .follower
        rn.voted_for = -1
        rn.mutex.unlock()
        return
    }
    if rn.state == .candidate && msg.term == rn.current_term && msg.data['vote_granted'] == 1 {
        // Increment vote count
        // Check if majority is reached is done in candidate()
    }
    rn.mutex.unlock()
}

// Send AppendEntries RPC (Heartbeat)
fn (mut rn RaftNode) send_append_entries(peer_id int, entries []LogEntry) {
    msg := Message{
        msg_type: 'AppendEntries'
        term: rn.current_term
        sender: rn.id
        receiver: peer_id
        data: {
            'prev_log_index': rn.log.len - 1
            'prev_log_term': if rn.log.len > 0 { rn.log[rn.log.len - 1].term } else { 0 }
            'entries': entries.len
            'leader_commit': rn.commit_index
        }
    }
    rn.send_message(msg)
}

// Handle AppendEntries RPC
fn (mut rn RaftNode) handle_append_entries(msg Message) {
    rn.mutex.@lock()
    defer {
        rn.mutex.unlock()
    }
    if msg.term < rn.current_term {
        // Reply false if term is outdated
        response := Message{
            msg_type: 'AppendEntriesResponse'
            term: rn.current_term
            sender: rn.id
            receiver: msg.sender
            data: {
                'success': 0
            }
        }
        rn.send_message(response)
        return
    }

    rn.current_term = msg.term
    rn.state = .follower
    rn.election_reset = time.sys_mono_now()
    // For simplicity, we ignore log consistency checks in this PoC
    // Acknowledge heartbeat
    response := Message{
        msg_type: 'AppendEntriesResponse'
        term: rn.current_term
        sender: rn.id
        receiver: msg.sender
        data: {
            'success': 1
        }
    }
    rn.send_message(response)
}

// Handle AppendEntriesResponse
fn (mut rn RaftNode) handle_append_entries_response(msg Message) {
    rn.mutex.@lock()
    defer {
        rn.mutex.unlock()
    }
    if msg.term > rn.current_term {
        rn.current_term = msg.term
        rn.state = .follower
        rn.voted_for = -1
    }
    // In a full implementation, we'd update matchIndex and nextIndex here
}

// Send a message to a peer via Redis queue
fn (mut rn RaftNode) send_message(msg Message) {
    queue_name := 'node_${msg.receiver}_queue'
    msg_json := json.encode(msg)
    rn.redis_client.rpush(queue_name, msg_json) or {
        println('Failed to send message to node ${msg.receiver}: $err')
    }
}

// Utility function to submit a command (used in RPC mechanism)
fn (mut rn RaftNode) submit_command(command string) {
    rn.mutex.@lock()
    if rn.state != .leader {
        println('Node ${rn.id} is not the leader. Cannot submit command.')
        rn.mutex.unlock()
        return
    }
    // Append command to the log
    new_entry := LogEntry{
        term: rn.current_term
        command: command
    }
    rn.log << new_entry
    rn.mutex.unlock()
    // In a full implementation, we'd replicate this entry to followers
}

fn main() {
    // List of node IDs
    node_ids := [1, 2, 3]
    mut nodes := []&RaftNode{}

    // Initialize nodes
    for id in node_ids {
        mut peers := node_ids.clone()
        peers.delete(id - 1) // Remove self from peers
        mut node := &RaftNode{
            id: id
            peers: peers
        }
        node.init_node()
        nodes << node
    }

    // Start nodes
    for mut node in nodes {
        go node.start()
    }

    // Simulate submitting commands from the leader
    time.sleep(1000 * time.millisecond) // Wait for leader election
    mut leader_id := nodes[0].id // For simplicity, assume first node is leader after election
    for mut node in nodes {
        if node.state == .leader {
            leader_id = node.id
            node.submit_command('Set X = 10')
            break
        }
    }

    // Keep the program running
    for {
        time.sleep(1000 * time.millisecond)
    }
}
