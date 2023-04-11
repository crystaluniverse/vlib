import freeflowuniverse.crystallib.redisclient

fn setup() &redisclient.Redis {
	mut redis := redisclient.core_get()
	// Select db 10 to be away from default one '0'
	redis.selectdb(10) or { panic(err) }
	return &redis
}

fn cleanup(mut redis redisclient.Redis) ! {
	redis.flushall()!
	redis.disconnect()
}

fn process_test(cmd string, data string) !string {
	return '${cmd}+++++${data}------'
}

fn test_rpc() {
	mut redis := setup()
	defer {
		cleanup(mut redis) or { panic(err) }
	}
	mut r := redis.rpc_get('testrpc')

	returnqueue := r.call('test.cmd', 'this is my data, normally json')!
	r.process[string, string](10000, process_test)!
	mut res := r.result[string](10000, returnqueue)!

	assert res == 'test.cmd+++++this is my data, normally json------'
}
