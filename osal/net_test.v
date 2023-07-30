module osal

fn test_ipaddr_pub_get() {
	ipaddr := ipaddr_pub_get()!
	assert ipaddr != ''
}

fn test_ping() {
	ping(address: '127.0.0.1', count: 1)!
}

fn test_ping_fails() ! {
	ping(address: '192.168.145.154', count: 5, timeout: 1) or {
		assert err.str().starts_with('Execution failed with code 1'), 'Expected a different error, got ${err}'
		return
	}
	return error('Ping should fail!')
}
