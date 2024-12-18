module jobs

import freeflowuniverse.crystallib.clients.redisclient
import freeflowuniverse.crystallib.data.actionsparser
import os

const samples_dir = os.dir(@FILE) + '/../../examples/actionsdir'

// reset redis on test begin and run servers
fn testsuite_begin() {
	mut redis := redisclient.core_get()!
	redis.flushall()!
	redis.disconnect()
}

// reset redis on test end
fn testsuite_end() {
	mut redis := redisclient.core_get()!
	redis.flushall()!
	redis.disconnect()
}

fn test_get_jobs() {
	mut cl := new('localhost:6379')!

	mut actionsmgr := actions.dir_parse(client.samples_dir)!
	assert actionsmgr.actions.len == 11

	mut j := cl.schedule_actions(actions: actionsmgr.actions)!
	assert j.jobs.last().action == 'threefold.books.mdbook_develop'
}
