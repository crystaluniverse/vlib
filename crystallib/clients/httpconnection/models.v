module httpconnection

import net.http { Header, Method }
import freeflowuniverse.crystallib.clients.redisclient { Redis }

// https://cassiomolin.com/2016/09/09/which-http-status-codes-are-cacheable/
const default_cacheable_codes = [200, 203, 204, 206, 300, 404, 405, 410, 414, 501]

const unsafe_http_methods = [Method.put, .patch, .post, .delete]

pub struct CacheConfig {
pub mut:
	key               string // as used to identity in redis
	allowable_methods []Method = [.get, .head]
	allowable_codes   []int    = default_cacheable_codes
	disable           bool     = true // default cache is not working
	expire_after      int      = 3600 // default expire_after is 1h
	match_headers     bool // cache the request header to be matched later
}

@[heap]
pub struct HTTPConnection {
pub mut:
	redis          Redis @[str: skip]
	base_url       string // the base url
	default_header Header
	cache          CacheConfig @[str: skip]
	retry          int = 5
}

@[heap]
pub struct HTTPConnections {
pub mut:
	connections map[string]&HTTPConnection
}

pub struct Result {
pub mut:
	code int
	data string
}
