module rpcsocket

import time
import freeflowuniverse.crystallib.data.ourtime

// Test struct for params
pub struct TestParams {
	key   string
	value int
}

fn test_job_encode_decode() ! {
	// Create test data
	now := time.now()
	mut original_job := Job{
		id: 1234
		actor: 'test_actor'
		action: 'test_action'
		params: '{"key": "value"}'
		job_type: 'test_type'
		create_date: ourtime.OurTime{unixt: now.unix()}
		schedule_date: ourtime.OurTime{unixt: now.unix() + 3600} // 1 hour later
		finish_date: ourtime.OurTime{unixt: now.unix() + 7200} // 2 hours later
		locked_until: ourtime.OurTime{unixt: now.unix() + 300} // 5 minutes later
		completed: true
		state: .completed
		error: ''
		recurring: '0 0 * * *' // daily at midnight
		deadline: ourtime.OurTime{unixt: now.unix() + 86400} // 24 hours later
		signature: 'test_signature'
		executor: 5678
		agent: 9012
	}

	// Encode to binary
	encoded := original_job.encode()!

	// Decode back to Job
	mut decoded_job := Job{
		id: 0
		actor: ''
		action: ''
		job_type: ''
		create_date: ourtime.OurTime{unixt: 0}
		schedule_date: ourtime.OurTime{unixt: 0}
		state: .init
	}
	decoded_job.decode(encoded)!

	// Compare all fields
	assert original_job.id == decoded_job.id
	assert original_job.actor == decoded_job.actor
	assert original_job.action == decoded_job.action
	assert original_job.params == decoded_job.params
	assert original_job.job_type == decoded_job.job_type
	assert original_job.create_date.unixt == decoded_job.create_date.unixt
	assert original_job.schedule_date.unixt == decoded_job.schedule_date.unixt
	assert original_job.finish_date.unixt == decoded_job.finish_date.unixt
	assert original_job.locked_until.unixt == decoded_job.locked_until.unixt
	assert original_job.completed == decoded_job.completed
	assert original_job.state == decoded_job.state
	assert original_job.error == decoded_job.error
	assert original_job.recurring == decoded_job.recurring
	assert original_job.deadline.unixt == decoded_job.deadline.unixt
	assert original_job.signature == decoded_job.signature
	assert original_job.executor == decoded_job.executor
	assert original_job.agent == decoded_job.agent
}

fn test_job_params() ! {
	mut job := Job{
		id: 1
		actor: 'test'
		action: 'test'
		job_type: 'test'
		create_date: ourtime.OurTime{unixt: time.now().unix()}
		schedule_date: ourtime.OurTime{unixt: time.now().unix()}
		state: .init
	}

	// Test setting params
	test_params := TestParams{
		key: 'test_key'
		value: 42
	}
	job.params_set(test_params)!

	// Test getting params
	decoded_params := job.params_get[TestParams]()!
	assert decoded_params.key == test_params.key
	assert decoded_params.value == test_params.value
}
