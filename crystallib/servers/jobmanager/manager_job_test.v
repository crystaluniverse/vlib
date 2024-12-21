module rpcsocket

import freeflowuniverse.crystallib.data.ourtime

fn test_job_manager() {
	mut manager := new_job_manager()

	// Test creating new jobs
	now := ourtime.OurTime{
		unixt: i64(0)
	}
	mut job1 := Job{
		id: 0 // Will be set by manager
		actor: 'test_actor'
		action: 'test_action'
		job_type: 'test_type'
		state: .init
		create_date: now
		schedule_date: now
	}
	mut job2 := Job{
		id: 0 // Will be set by manager
		actor: 'test_actor2'
		action: 'test_action2'
		job_type: 'test_type2'
		state: .running
		create_date: now
		schedule_date: now
	}

	// Test set (create)
	job1 = manager.set(mut job1)!
	assert job1.id == 1
	assert job1.create_date.unixt > 0
	assert job1.schedule_date.unixt > 0

	job2 = manager.set(mut job2)!
	assert job2.id == 2
	assert job2.create_date.unixt > 0
	assert job2.schedule_date.unixt > 0

	// Test get
	found_job := manager.get(1)!
	assert found_job.id == 1
	assert found_job.actor == 'test_actor'
	assert found_job.action == 'test_action'
	assert found_job.job_type == 'test_type'
	assert found_job.state == .init

	// Test get with invalid ID
	if _ := manager.get(999) {
		assert false, 'Should not find job with invalid ID'
	}

	// Test find with various parameters
	mut params := JobFindParams{
		actor: 'test_actor'
	}
	mut found := manager.find(params)
	assert found.len == 1
	assert found[0].id == 1

	params = JobFindParams{
		state: .running
	}
	found = manager.find(params)
	assert found.len == 1
	assert found[0].id == 2

	params = JobFindParams{
		actor: 'test_actor'
		state: .init
	}
	found = manager.find(params)
	assert found.len == 1
	assert found[0].id == 1

	params = JobFindParams{
		actor: 'nonexistent'
	}
	found = manager.find(params)
	assert found.len == 0

	// Test updating a job
	mut updated_job := found_job
	updated_job.state = .running
	updated_job = manager.set(mut updated_job)!
	assert updated_job.state == .running

	found_after_update := manager.get(1)!
	assert found_after_update.state == .running

	// Test delete
	manager.delete(1)!
	if _ := manager.get(1) {
		assert false, 'Job should be deleted'
	}

	// Test delete with invalid ID
	if _ := manager.delete(999) {
		assert false, 'Should not delete non-existent job'
	}

	// Test delete all
	manager.delete_all()
	params = JobFindParams{}
	found = manager.find(params)
	assert found.len == 0

	// Test creating job after delete_all
	mut job3 := Job{
		id: 0 // Will be set by manager
		actor: 'test_actor3'
		action: 'test_action3'
		job_type: 'test_type3'
		state: .init
		create_date: now
		schedule_date: now
	}
	job3 = manager.set(mut job3)!
	assert job3.id == 1 // ID should start from 1 again
}

fn test_job_manager_params() {
	mut manager := new_job_manager()

	// Create jobs with different states and parameters
	now := ourtime.OurTime{
		unixt: i64(0)
	}
	mut jobs := [
		Job{
			id: 0 // Will be set by manager
			actor: 'actor1'
			action: 'action1'
			job_type: 'type1'
			state: .init
			completed: false
			agent: 1
			executor: 10
			create_date: now
			schedule_date: now
		},
		Job{
			id: 0 // Will be set by manager
			actor: 'actor1'
			action: 'action2'
			job_type: 'type1'
			state: .running
			completed: true
			agent: 2
			executor: 20
			create_date: now
			schedule_date: now
		},
		Job{
			id: 0 // Will be set by manager
			actor: 'actor2'
			action: 'action1'
			job_type: 'type2'
			state: .completed
			completed: true
			agent: 1
			executor: 30
			create_date: now
			schedule_date: now
		}
	]

	for mut job in jobs {
		manager.set(mut job)!
	}

	// Test finding by actor
	mut params := JobFindParams{
		actor: 'actor1'
	}
	mut found := manager.find(params)
	assert found.len == 2

	// Test finding by action
	params = JobFindParams{
		action: 'action1'
	}
	found = manager.find(params)
	assert found.len == 2

	// Test finding by job_type
	params = JobFindParams{
		job_type: 'type1'
	}
	found = manager.find(params)
	assert found.len == 2

	// Test finding by state
	params = JobFindParams{
		state: .running
	}
	found = manager.find(params)
	assert found.len == 1

	// Test finding by completed
	params = JobFindParams{
		completed: true
	}
	found = manager.find(params)
	assert found.len == 2

	// Test finding by agent
	params = JobFindParams{
		agent: 1
	}
	found = manager.find(params)
	assert found.len == 2

	// Test finding by executor
	params = JobFindParams{
		executor: 20
	}
	found = manager.find(params)
	assert found.len == 1

	// Test finding with multiple parameters
	params = JobFindParams{
		actor: 'actor1'
		completed: true
		state: .running
	}
	found = manager.find(params)
	assert found.len == 1
	assert found[0].action == 'action2'
}
