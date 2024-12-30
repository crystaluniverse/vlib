module example_actor

const test_port = 8101

pub fn test_new() ! {
	new() or {
		return error('Failed to create actor:\n${err}')
	}
}

pub fn test_run() ! {
	spawn run()
}

pub fn test_run_server() ! {
	spawn run_server(port: test_port)
}