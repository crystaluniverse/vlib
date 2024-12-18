module redisclient

import rand
import time
import json

pub struct RedisRpc {
pub mut:
	key   string // queue name as used by this rpc
	redis &Redis
}

// return a rpc mechanism
pub fn (mut r Redis) rpc_get(key string) RedisRpc {
	return RedisRpc{
		key:   key
		redis: r
	}
}

pub struct RPCArgs {
pub:
	cmd     string @[required]
	data    string @[required]
	timeout u64  = 60000 // 60 sec
	wait    bool = true
}

pub struct Message {
pub:
	ret_queue string
	now       i64
	cmd       string
	data      string
}

pub struct Response {
pub:
	result string
	error  string
}

// send data to a queue and wait till return comes back
// timeout in milliseconds
// params
// 	cmd string @[required]
// 	data string @[required]
// 	timeout u64=60000  //60 sec
// 	wait bool=true
pub fn (mut q RedisRpc) call(args RPCArgs) !string {
	retqueue := rand.uuid_v4()
	now := time.now().unix()
	message := Message{
		ret_queue: retqueue
		now:       now
		cmd:       args.cmd
		data:      args.data
	}
	encoded := json.encode(message)
	q.redis.lpush(q.key, encoded)!

	if args.wait {
		return q.result(args.timeout, retqueue)!
	}
	return ''
}

// get return once result processed
pub fn (mut q RedisRpc) result(timeout u64, retqueue string) !string {
	start := u64(time.now().unix_milli())
	for {
		r := q.redis.rpop(retqueue) or { '' }
		if r != '' {
			res := json.decode(Response, r)!
			if res.error != '' {
				return res.error
			}
			return res.result
		}
		if u64(time.now().unix_milli()) > (start + timeout) {
			break
		}
		time.sleep(time.millisecond)
	}
	return error('timeout on returnqueue: ${retqueue}')
}

@[params]
pub struct ProcessParams {
pub:
	timeout u64
}

// to be used by processor, to get request and execute, this is the server side of a RPC mechanism
// 2nd argument is a function which needs to execute the job: fn (string,string) !string
pub fn (mut q RedisRpc) process(op fn (string, string) !string, params ProcessParams) !string {
	start := u64(time.now().unix_milli())
	for {
		r := q.redis.rpop(q.key) or { '' }
		if r != '' {
			msg := json.decode(Message, r)!

			returnqueue := msg.ret_queue
			// epochtime:=parts[1].u64() //we don't do anything with it now
			cmd := msg.cmd
			data := msg.data
			// if true{panic("sd")}
			datareturn := op(cmd, data) or {
				response := Response{
					result: ''
					error:  err.str()
				}
				encoded := json.encode(response)
				q.redis.lpush(returnqueue, encoded)!
				return ''
			}
			response := Response{
				result: datareturn
				error:  ''
			}
			encoded := json.encode(response)
			q.redis.lpush(returnqueue, encoded)!
			return returnqueue
		}
		if params.timeout != 0 && u64(time.now().unix_milli()) > (start + params.timeout) {
			break
		}
		time.sleep(time.millisecond)
	}
	return error('timeout for waiting for cmd on ${q.key}')
}

// get without timeout, returns none if nil
pub fn (mut q RedisRpc) delete() ! {
	q.redis.del(q.key)!
}
