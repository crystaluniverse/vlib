module httpconnection

import crypto.md5
import json
import net.http { Method }

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

pub struct Result {
pub mut:
	code int
	data string
}

// calculate the key for the cache starting from data and url
fn (mut h HTTPConnection) cache_key(req Request) string {
	url := h.url(req).split('!')
	encoded_url := md5.hexhash(url[0]) // without params
	mut key := 'http:${h.cache.key}:${req.method}:${encoded_url}'
	mut req_data := req.data
	if h.cache.match_headers {
		req_data += json.encode(h.header())
	}
	req_data += if url.len > 1 { url[1] } else { '' } // add url param if exist
	key += if req_data.len > 0 { ':${md5.hexhash(req_data)}' } else { '' }
	return key
}

// Get request result from cache, return -1 if missed.
fn (mut h HTTPConnection) cache_get(req Request) !Result {
	key := h.cache_key(req)
	mut data := h.redis.get(key) or {
		assert '${err}' == 'none'
		// console.print_debug("cache get: ${key} not in redis")
		return Result{
			code: -1
		}
	}
	if data == '' {
		// console.print_debug("cache get: ${key} empty data")
		return Result{
			code: -1
		}
	}
	result := json.decode(Result, data) or {
		// console.print_debug("cache get: ${key} coud not decode")
		return error('failed to decode result with error: ${err}.\ndata:\n${data}')
	}
	// console.print_debug("cache get: ${key} ok")
	return result
}

// Set response result in cache
fn (mut h HTTPConnection) cache_set(req Request, res Result) ! {
	key := h.cache_key(req)
	value := json.encode(res)
	h.redis.set(key, value)!
	h.redis.expire(key, h.cache.expire_after)!
}

// Invalidate cache for specific url
fn (mut h HTTPConnection) cache_invalidate(req Request) ! {
	url := h.url(req).split('!')
	encoded_url := md5.hexhash(url[0])
	mut to_drop := []string{}
	to_drop << 'http:${h.cache.key}:*:${encoded_url}*'
	if req.id.len > 0 {
		url_no_id := url[0].trim_string_right('/${req.id}')
		encoded_url_no_id := md5.hexhash(url_no_id)
		to_drop << 'http:${h.cache.key}:*:${encoded_url_no_id}*'
	}
	for pattern in to_drop {
		all_keys := h.redis.keys(pattern)!
		for key in all_keys {
			h.redis.del(key)!
		}
	}
}

// drop full cache for specific cache_key
pub fn (mut h HTTPConnection) cache_drop() ! {
	todrop := 'http:${h.cache.key}*'
	all_keys := h.redis.keys(todrop)!
	for key in all_keys {
		h.redis.del(key)!
	}
}
