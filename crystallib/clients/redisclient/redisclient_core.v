module redisclient

@[params]
pub struct RedisURL {
	address string = '127.0.0.1'
	port    int    = 6379
	// db      int
}

pub fn get_redis_url(url string) !RedisURL {
	if !url.contains(':') {
		return error('url doesnt contain port')
	} else {
		return RedisURL{
			address: url.all_before_last(':')
			port:    url.all_after_last(':').u16()
		}
	}
}

pub fn core_get(url RedisURL) !Redis {
	mut r := new('${url.address}:${url.port}')!
	return r
}
