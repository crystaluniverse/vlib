module jobs

import freeflowuniverse.crystallib.clients.redisclient
import freeflowuniverse.crystallib.data.paramsparser { Params }
import rand
import time

pub struct Client {
pub mut:
	redis  redisclient.Redis
	twinid u32
}

// Factory method to create a client. It takes in
// the address where the redis server is running.
// Make sure to put the twinid of the system in
// the redis key client.mytwin.id.
pub fn new(redis_address string) !Client {
	mut redis := redisclient.get(redis_address)!
	mut client := Client{
		redis: redis
	}
	twinid := client.redis.get('client.mytwin.id') or { '0' }
	client.twinid = twinid.u32()
	return client
}

// Arguments for creating a new job
@[params]
pub struct JobNewArgs {
pub mut:
	twinid       u32
	action       string
	args         Params
	actionsource string
	src_twinid   u32
	timeout      f64
}

// Creates new actionjob
pub fn new(args JobNewArgs) !ActionJob {
	mut j := ActionJob{
		guid:       rand.uuid_v4()
		twinid:     args.twinid
		action:     args.action
		args:       args.args
		start:      time.now()
		src_action: args.actionsource
		src_twinid: args.src_twinid
	}
	return j
}
