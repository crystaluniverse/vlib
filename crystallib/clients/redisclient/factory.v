module redisclient

// original code see https://github.com/patrickpissurno/vredis/blob/master/vredis_test.v
// credits see there as well (-:
import net
// import sync
// import strconv

__global (
	redis_connections []Redis
)

const default_read_timeout = net.infinite_timeout

@[heap]
pub struct Redis {
pub:
	addr string
mut:
	socket net.TcpConn
}

// https://redis.io/topics/protocol
// examples:
//   localhost:6379
//   /tmp/redis-default.sock
pub fn new(addr string) !Redis {
	// lock redis_connections {	
	for mut conn in redis_connections {
		if conn.addr == addr {
			return conn
		}
	}
	// means there is no connection yet
	mut r := Redis{
		addr: addr
	}
	r.socket_connect()!
	redis_connections << r
	return r
	//}
	// panic("bug")
}

pub fn reset() ! {
	// lock redis_connections {	
	for mut conn in redis_connections {
		conn.disconnect()
	}
	redis_connections = []Redis{}
	//}
}

pub fn checkempty() {
	// lock redis_connections {	
	assert redis_connections.len == 0
	//}
}
