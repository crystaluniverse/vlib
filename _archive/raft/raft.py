#!/usr/bin/env python

import time
import uuid
import sys
import socket
import json
import random

# Server ID number
my_id = sys.argv[1]

# The ID numbers of all other replicas
replica_ids = sys.argv[2:]

RAND_MIN = 150
RAND_MAX = 300
TIME_SCALE = 1000
HEARTBEAT_INTERVAL = 100
RTT_INTERVAL = 50

# Connect to the network. All messages to/from other replicas and clients will
# occur over this socket
SOCK_RECV_SIZE = 32768

sock = socket.socket(socket.AF_UNIX, socket.SOCK_SEQPACKET)
sock.connect(my_id)


class StateMachine:

    def __init__(self, id, other_server_ids):
        self.id = id
        self.other_server_ids = other_server_ids
        self.leader_id = 'FFFF'
        # leader, candidate, follower
        self.state = 'follower'
        # latest term server has seen
        self.current_term = 0
        # total votes
        self.votes_count = 0
        # candidate id that received vote in current term
        self.voted_for = None
        # log entries; each entry contains mid, command for state machine, and term
        self.log = []
        # to index by 1
        self.log.append((None, None, self.current_term))
        # index of highest log entry known to be committed
        self.commit_index = 0
        # index of highest log entry applied to state machine
        self.last_applied = 0
        # for each server, index of the next log entry to send to that server
        self.next_index = self.init_next_idx_to_send()
        # for each server, index of highest log entry known to be replicated
        self.match_index = self.init_match_idxs()
        # last time state machine has received an RPC from replica
        self.last_RPC_time = time.time() * TIME_SCALE
        # get random timeout between values
        self.election_timeout = random.uniform(RAND_MIN, RAND_MAX)
        self.start_election_time = 0
        self.key_value_store = {}
        self.queued_client_requests = []
        # MID -> list of server ids that haven't sent an accept_request back
        self.unacked_requests = {}
        # time the last heartbeat was sent
        self.last_heartbeat_sent = 0

    def run(self):
        global sock, SOCK_RECV_SIZE

        while True:
            raw_msg = sock.recv(SOCK_RECV_SIZE)
            # received nothing
            if len(raw_msg) == 0:
                return
            else:
                msg = json.loads(raw_msg)
                self.apply_command_and_reply_client()
                if msg['type'] not in ['get', 'put']:
                    self.check_terms(msg['term'], msg['leader'])
                if self.state == 'follower':
                    if msg['src'] == self.leader_id:
                        self.last_RPC_time = time.time() * TIME_SCALE
                    self.act_as_follower(msg)
                elif self.state == 'candidate':
                    self.act_as_candidate(msg)
                elif self.state == 'leader':
                    if time.time() * TIME_SCALE - self.last_heartbeat_sent >= HEARTBEAT_INTERVAL \
                            and len(self.unacked_requests) == 0:
                        self.send_regular_heartbeat([])
                    self.act_as_leader(msg)

    def print_msg(self, msg, bool=False):
        bool = False
        if bool:
            print("[%s] [%s] [%s] [term: %s] %s" % (str(time.time()), self.id, self.state, self.current_term, msg))
        return

    '''
    Volatile state on leader
    upon election, leader initializes these values to its last log index + 1
    '''
    def init_next_idx_to_send(self):
        next_idx_to_send = {}
        if self.state == 'leader':
            for server_id in self.other_server_ids:
                next_idx_to_send[server_id] = len(self.log)
        return next_idx_to_send

    '''
    for each server, index of highest log entry known to be replicated
    always initialize to 0
    '''
    def init_match_idxs(self):
        match_index = {}
        if self.state == 'leader':
            for server_id in self.other_server_ids:
                match_index[server_id] = 0
        return match_index

    '''
    All servers:
    if RPC request or response contains term given_term > current_term:
    set current_term = given_term, convert to follower
    return True if becomes follower
    '''
    def check_terms(self, given_term, leader):
        if given_term > self.current_term:
            self.become_follower(given_term, leader)

    '''
    Follower responds redirectly when received client messages, or queue up messages if leader is unknown
    '''
    def client_handler(self, msg):
        global sock

        if self.leader_id == 'FFFF':
            self.queued_client_requests.append(msg)
        else:
            for m in list(self.queued_client_requests):
                response_prev_requests_to_client = {'src': self.id, "dst": m['src'], 'leader': self.leader_id,
                                                    'type': 'redirect', 'MID': m['MID']}
                sock.send(json.dumps(response_prev_requests_to_client))
                self.queued_client_requests.remove(m)
            response_to_client = {'src': self.id, "dst": msg['src'], 'leader': self.leader_id,
                                  'type': 'redirect', 'MID': msg['MID']}
            sock.send(json.dumps(response_to_client))

    '''
    For all servers: commits and applies the commands to StateMachine
    For leader: send clients all queued up responses
    '''
    def apply_command_and_reply_client(self):
        global sock

        if self.commit_index > self.last_applied:
            self.last_applied += 1
            # print("LENGTH: " + str(len(self.log)) + "LAST_APPLIED: " + str(self.last_applied) + "COMMIT: " + str(self.commit_index))
            # print("LOG: " + str(self.log[self.last_applied]) + "LEN: " + str(len(self.log[self.last_applied])))
            (mid, command, term) = self.log[self.last_applied]
            command = json.loads(command)
            if command['cmd'] == 'put':
                self.key_value_store[command['key']] = command['value']
            if self.state == 'leader':
                if command['cmd'] == 'get':
                    value = self.key_value_store.get(command['key'], '')
                    response = {'src': self.id, 'dst': command['client_id'],
                                                     'leader': self.id, 'type': 'ok',
                                                     'MID': mid, 'value': value}
                elif command['cmd'] == 'put':
                    response = {'src': self.id, 'dst': command['client_id'],
                                                     'leader': self.id, 'type': 'ok',
                                                     'MID': mid}
                sock.send(json.dumps(response))
                self.print_msg("RESPONSE SENT " + mid + " " + str(time.time()))

    '''
    Becomes a follower
     - update the term, RPC time, and leader
    '''
    def become_follower(self, new_term, new_leader):
        global TIME_SCALE

        self.state = 'follower'
        self.last_RPC_time = time.time() * TIME_SCALE
        self.current_term = new_term
        self.voted_for = None
        self.votes_count = 0
        self.leader_id = new_leader

    '''
    Becomes a candidate, start election
    '''
    def become_candidate(self):
        self.state = 'candidate'
        self.voted_for = None
        self.votes_count = 0
        self.start_election()

    """
    Becomes a leader after election
    """
    def become_leader(self):
        self.state = 'leader'
        self.next_index = self.init_next_idx_to_send()
        self.match_index = self.init_match_idxs()
        self.leader_id = self.id
        self.voted_for = None
        self.votes_count = 0
        self.commit_index = len(self.log) - 1
        self.apply_command_and_reply_client()
        self.send_regular_heartbeat([])

    '''
    starts election. Candidate increments term, votes for itself
    '''
    def start_election(self):
        global TIME_SCALE, RAND_MIN, RAND_MAX
        # increment term at start of each election
        self.current_term += 1
        # votes for itself
        self.votes_count += 1
        self.voted_for = self.id
        # set leader id to None
        self.leader_id = 'FFFF'
        # reset election timer
        self.election_timeout = random.uniform(RAND_MIN, RAND_MAX)
        self.start_election_time = time.time() * TIME_SCALE
        # send out request vote RPCs
        self.send_vote_requests()
        # process the results


    """
    As a candidate, request other followers to vote for self
    """
    def send_vote_requests(self):
        global sock

        for server_id in self.other_server_ids:
            # indexed by 1
            last_log_index = len(self.log) - 1
            (mid, command, last_log_term) = self.log[last_log_index]
            request_for_vote = {'src': self.id, 'dst': server_id, 'leader': self.leader_id,
                                'type': 'vote_request', 'MID': str(uuid.UUID), 'term': self.current_term,
                                'last_log_index': last_log_index, 'last_log_term': last_log_term}
            sock.send(json.dumps(request_for_vote))

    """
    Respond to the candidate with a vote result
    """
    def send_vote_response(self, msg, term, vote_granted):
        global sock

        vote_response = {'src': self.id, 'dst': msg['src'], 'leader': self.leader_id,
                         'type': 'vote_response', 'MID': msg['MID'], 'term': term,
                         'vote_granted': vote_granted}
        sock.send(json.dumps(vote_response))

    '''
    finds first instance of term in this log
    '''
    def find_first_term_instance(self, term, start_index):
        for i in range(start_index, 0, -1):
            (mid, command, cur_term) = self.log[i]
            if cur_term < term:
                return i + 1
        return 1

    '''
    sends append response with given values
    '''
    def send_append_response(self, msg, prev_log_index, prev_log_term, accept_request):
        global sock

        response = {'src': self.id, "dst": msg['src'], 'leader': self.leader_id, 'term': self.current_term,
                    'type': 'append_response', 'MID': msg['MID'], 'prev_log_index': prev_log_index,
                    'prev_log_term': prev_log_term, 'entries': msg['entries'], 'receive_time': time.time() * TIME_SCALE,
                    'last_log_index': len(self.log) - 1, 'accept_request': accept_request}
        sock.send(json.dumps(response))

    '''
    For followers and candidates, handle append entry requests 
    '''
    def append_handler(self, msg):
        if len(msg['entries']) == 0:
            # TODO maybe heartbeats should respond?
            self.become_follower(msg['term'], msg['leader'])
            # update commit index too
            if msg['leader_commit'] > self.commit_index:
                self.commit_index = min(msg['leader_commit'], len(self.log) - 1)
            return
        # TODO this could be a problem: in the case of a partition 3 servers | 2 servers
        # the 3 servers will have a longer log because they are able to process client requests
        # the 2 servers might have a higher term, because they might need to elect new leader
        # when the partition is gone, the 2 servers will always reject the new entries because of their higher term
        if self.current_term > msg['term']:
            self.print_msg("REJECTED because I'm at term %s compared to %s" % (self.current_term, msg['term']), True)
            self.send_append_response(msg, msg['prev_log_index'], msg['prev_log_term'], False)
            return
        try:
            (prev_mid, prev_command, prev_term) = self.log[msg['prev_log_index']]
            if prev_term != msg['prev_log_term']:
                index = self.find_first_term_instance(prev_term, msg['prev_log_index'])
                self.print_msg("REJECTED %s because my prev_term %s doesn't match their's %s at index %s"
                               % (msg['MID'], prev_term, msg['prev_log_term'], msg['prev_log_index']), True)
                (mid, command, term) = self.log[index]
                self.print_msg("ADJUSTED index to %s with term %s" % (index, term), True)
                self.send_append_response(msg, index, prev_term, False)
                return
        except IndexError:
            (mid, command, term) = self.log[len(self.log) - 1]
            self.print_msg("REJECTED %s because length of log is %s"
                           % (msg['MID'], str(len(self.log))), True)
            self.send_append_response(msg, len(self.log) - 1, term, False)
            return
        # ready to accept the AppendEntriesRPC request
        # delete all following entries after the current one
        # If an existing entry conflicts with a new one (same index
        # but different terms), delete the ***existing*** entry and all that
        # follow it
        keep_index = msg['prev_log_index'] + 1
        self.log = self.log[:keep_index]
        for entry in msg['entries']:  # TODO swapped the if and for
            if entry not in self.log:
                self.log.append(entry)
        if self.last_applied > len(self.log) - 1:
            self.last_applied = len(self.log) - 1
        if self.commit_index > len(self.log) - 1:
            self.commit_index = len(self.log) - 1
        if msg['leader_commit'] > self.commit_index:
            self.commit_index = min(msg['leader_commit'], len(self.log) - 1)
        self.send_append_response(msg, msg['prev_log_index'], msg['prev_log_term'], True)


    """
    Acting as a follower
    """
    def act_as_follower(self, msg):
        # have we timed out
        if time.time() * TIME_SCALE - self.last_RPC_time >= self.election_timeout:
            # TODO We'll talk about this
            if self.voted_for is None:
                self.become_candidate()
                return

        if msg['type'] in ['get', 'put']:
            self.client_handler(msg)
            return

        self.election_timeout = random.uniform(RAND_MIN, RAND_MAX)

        if msg['type'] == 'append_request':
            self.append_handler(msg)
        elif msg['type'] == 'vote_request':
            if msg['term'] < self.current_term:
                self.send_vote_response(msg, self.current_term, False)
            elif self.voted_for is None or self.voted_for == msg['src']:
                last_log_index = len(self.log) - 1
                (mid, command, last_log_term) = self.log[last_log_index]
                if last_log_index <= msg['last_log_index'] and last_log_term <= msg['last_log_term']:
                    self.voted_for = msg['src']
                    self.send_vote_response(msg, msg['term'], True)
                else:
                    self.send_vote_response(msg, self.current_term, False)
            else:
                self.send_vote_response(msg, self.current_term, False)

    '''
    Acting as a candidate:
     - Process the received votes:
     - receive responses, if N/2 + 1 then become leader and send heartbeat
     - if tie, timeout and restart election
     - if failed, become follower
    '''
    def act_as_candidate(self, msg):
        N = len(self.other_server_ids)
        majority_votes = N / 2 + 1

        # if we've timed out
        if time.time() * TIME_SCALE - self.start_election_time >= self.election_timeout:
            # split vote scenario
            self.become_candidate()
        else:
            # checks if received enough votes
            # if gathered majority votes, become leader
            if self.votes_count >= majority_votes:
                self.become_leader()
                return
            # receive more messages
            if msg['type'] in ['get', 'put']:
                self.client_handler(msg)
                return
            elif msg['type'] == 'vote_response':
                if msg['vote_granted']:
                    # collect vote
                    self.votes_count += 1
                    if self.votes_count >= majority_votes:
                        self.become_leader()
                        return
            # don't vote because we're a candidate
            elif msg['type'] == 'vote_request':
                self.send_vote_response(msg, self.current_term, False)
            elif msg['type'] == 'append_request':
                self.append_handler(msg)

    '''
    For leader, appends new command to its log as a new entry
    '''
    def append_new_log_entry(self, command, mid):
        # TODO should entry contain MID ?
        # TODO do i care about duplicate?
        entry = (mid, command, self.current_term)
        self.log.append(entry)
        return entry

    """
    Acting as a leader
    """
    def act_as_leader(self, msg):
        N = len(self.other_server_ids) + 1
        majority = N / 2 + 1
        minority = N - majority
        entries = []
        if msg['type'] == 'get':
            # self.committed_message[msg['MID']] = False
            key = msg['key']
            # self.number_appended[msg['MID']] = set()
            command = json.dumps({'cmd': msg['type'], 'client_id': msg['src'], 'key': key})
            self.unacked_requests[msg['MID']] = set()
            entry = self.append_new_log_entry(command, msg['MID'])
            entries.append(entry)
            self.print_msg("i %s CREATED %s" % (str(self.id), msg['MID']), True)
            self.send_append_request(entries, msg['MID'])
            value = self.key_value_store[key]
            # send back to client
        elif msg['type'] == 'put':
            key = msg['key']
            value = msg['value']
            command = json.dumps({'cmd': msg['type'], 'client_id': msg['src'], 'key': key, 'value': value})
            entry = self.append_new_log_entry(command, msg['MID'])
            entries.append(entry)
            self.unacked_requests[msg['MID']] = set()
            self.print_msg("i %s CREATED %s" % (str(self.id), msg['MID']), True)
            self.send_append_request(entries, msg['MID'])
        elif msg['type'] == 'append_response':
            if msg['accept_request']:
                # set the next index to send to be: the index of last entry appended + 1
                self.next_index[msg['src']] = msg['last_log_index'] + 1  # TODO unsure
                try:
                    unacked_msgs = self.unacked_requests[msg['MID']]
                except KeyError:
                    self.check_timeouts()
                    return
                for m in list(unacked_msgs):
                    m_json = json.loads(m)
                    if m_json['dst'] == msg['src']:
                        self.unacked_requests[msg['MID']].remove(m)
                        self.print_msg("i %s REMOVED %s request_accepted" % (str(self.id), m_json['MID']), True)
                        break
                if len(self.unacked_requests[msg['MID']]) == minority:
                    self.commit_index += 1
                    self.unacked_requests.pop(msg['MID'])
            elif not msg['accept_request']:
                self.print_msg("REJECTED " + msg['MID'], True)
                self.next_index[msg['src']] = msg['prev_log_index']
                temp_entries = []
                temp_entries.append(self.log[self.next_index[msg['src']]])
                # print("%s temp_entries %s" % (self.id, self.log[self.next_index[msg['src']]]))
                for entry in msg['entries']:
                    temp_entries.append(entry)  # TODO care about prev_term and prev_idx
                try:
                    unacked_servers = self.unacked_requests[msg['MID']]
                except KeyError:
                    self.check_timeouts()
                    return
                for m in list(unacked_servers):
                    m_json = json.loads(m)
                    if m_json['dst'] == msg['src']:
                        self.unacked_requests[msg['MID']].remove(m)
                        self.print_msg("i %s REMOVED %s request_rejected" % (str(self.id), m_json['MID']), True)
                        break
                self.append_one_server(temp_entries, msg['src'], msg['MID'])
            self.check_timeouts()


    """
    Leader resend messages when did not receive an ack of a message after timeout
    """
    def check_timeouts(self):
        global sock

        for mid in self.unacked_requests:
            unacked_msgs = self.unacked_requests[mid]
            for m in list(unacked_msgs):
                m_json = json.loads(m)
                if time.time() * TIME_SCALE - m_json['send_time'] >= RTT_INTERVAL:
                    cur_time = time.time() * TIME_SCALE
                    # update time and dict
                    m_json['send_time'] = cur_time
                    new_m = json.dumps(m_json)
                    self.unacked_requests[mid].remove(m)
                    self.unacked_requests[mid].add(new_m)
                    sock.send(new_m)
                    self.print_msg("RESENDING " + m_json['MID'], True)
                    return

    """
    Leader send appendEntryRPC to all followers
    """
    def send_append_request(self, entries, mid):
        for server_id in self.other_server_ids:
            self.append_one_server(entries, server_id, mid)


    """
    Leader send appendEntryRPC to one follower
    """
    def append_one_server(self, entries, server_id, mid):
        global sock, TIME_SCALE

        prev_log_index = self.next_index[server_id] - 1
        (prev_mid, prev_command, prev_log_term) = self.log[prev_log_index]
        send_time = time.time() * TIME_SCALE
        append_entry_RPC = {'src': self.id, 'dst': server_id, 'leader': self.id,
                            'type': 'append_request', 'MID': mid, 'term': self.current_term,
                            'entries': entries, 'leader_commit': self.commit_index, 'send_time': send_time,
                            'prev_log_index': prev_log_index, 'prev_log_term': prev_log_term}
        sock.send(json.dumps(append_entry_RPC))
        # check that it's not a heartbeat
        if len(entries) > 0:
            self.unacked_requests[mid].add(json.dumps(append_entry_RPC))
            self.print_msg("i %s ADDED %s" % (str(self.id), str(mid)), True)


    """
    Leader sends regular heartbeat to the followers
    """
    def send_regular_heartbeat(self, entries):
        mid = str(uuid.UUID)
        self.last_heartbeat_sent = time.time() * TIME_SCALE
        self.send_append_request(entries, mid)


def main():
    global my_id, replica_ids

    my_server = StateMachine(my_id, replica_ids)
    my_server.run()


if __name__ == "__main__":
    main()