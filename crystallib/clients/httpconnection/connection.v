module httpconnection

import net.http { Header, Method }
import freeflowuniverse.crystallib.clients.redisclient { Redis }

@[heap]
pub struct HTTPConnection {
pub mut:
	redis          Redis @[str: skip]
	base_url       string // the base url
	default_header Header
	cache          CacheConfig
	retry          int = 5
}

// @[heap]
// pub struct HTTPConnections {
// pub mut:
// 	connections map[string]&HTTPConnection
// }

// Join headers from httpconnection and Request
fn (mut h HTTPConnection) header(req Request) http.Header {
	mut header := req.header or { 
		return h.default_header
	 }
	return h.default_header.join(header)
}

// // get new request
// //
// // ```
// // method        Method (.get, .post, .put, ...)
// // prefix        string
// // id            string
// // params        map[string]string
// // data          string
// // cache_disable bool = true
// // header        Header
// // dict_key      string //if the return is a dict, then will take the element out of the dict with the key and process further
// // list_dict_key string //if the output is a list of dicts, then will process each element of the list to take the val with key out of that dict
// // debug         bool
// // dataformat    DataFormat
// // ```	
// // for header see https://modules.vlang.io/net.http.html#Method .
// // for method see https://modules.vlang.io/net.http.html#Header
// pub fn (mut h HTTPConnection) request(args_ Request) !Request {
// 	mut args := args_

// 	return args
// }
