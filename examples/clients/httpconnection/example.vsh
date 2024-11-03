#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.clients.httpconnection
import json


mut conn := httpconnection.new(name: 'test', url: 'https://jsonplaceholder.typicode.com/', cache: true)!
println(conn)
// drop all caches
conn.cache_drop()!
mut keys := conn.redis.keys('http:${conn.cache.key}*')!
assert keys.len == 0
// adding a header field to be used in all requests.
// default header have the field Content-Type set to 'application/json',
// but we should reconsider this and leave it out, set it manually when needed
conn.default_header.add(.content_language, 'Content-Language: en-US')
// adding a specfic response status code to be cached
conn.cache.allowable_codes << 301
// defaults are [200, 203, 204, 206, 300, 404, 405, 410, 414, 501]
conn.cache.expire_after = 1800 // default is 3600
println(conn)
// Getting a resource post id 1, should be fresh response from the server
mut res := conn.send(prefix: 'posts', id: '1', cache_disable: false)!
// Result object have minimum fileds (code, data) and one method is_ok()
println('Status code: ${res.code}')
// you can check if you got a success status code or not
println('Success: ${res.is_ok()}')
// access the result data
println('Data: ${res.data}')
keys = conn.redis.keys('http:${conn.cache.key}*')!
assert keys.len == 1
// send another get request, should be served from the cache this time
res = conn.send(prefix: 'posts', id: '1', cache_disable: false)!
println(res.code)
keys = conn.redis.keys('http:${conn.cache.key}*')!
assert keys.len == 1
// listing all resources, should be fresh response from the server
res = conn.send(prefix: 'posts', cache_disable: false)!
println(res.code)
keys = conn.redis.keys('http:${conn.cache.key}*')!
assert keys.len == 2
// Creating a resource, response won't be cached here, as by default we cache requests made by GET and HEAD methods only,
// also POST is unsafe method it would invalidate caches for resource `/posts` on subsequent GET requests.
payload := {
  'title':  'foo'
  'body':   'bar'
  'userId': '1'
}
res = conn.send(method: .post, prefix: 'posts', data: json.encode(payload), cache_disable: false)!
println(res.code)
keys = conn.redis.keys('http:${conn.cache.key}*')!
assert keys.len == 1
// Getting a resource post id 1, should be served from the cache
res = conn.send(prefix: 'posts', id: '1', cache_disable: false)!
println(res.code)
keys = conn.redis.keys('http:${conn.cache.key}*')!
assert keys.len == 1
// listing all resources, should be fresh response from the server
res = conn.send(prefix: 'posts', cache_disable: false)!
println(res.code)
keys = conn.redis.keys('http:${conn.cache.key}*')!
assert keys.len == 2
// Updating a resource post id 1, would be invalidate caches for these resources, `/posts` and `/posts/1`
// so on subsequent GET requests you get fresh response from the server
updated_payload := {
  'title':  'foo'
  'body':   'bar'
  'userId': '1'
}
res = conn.send(method: .put, prefix: 'posts', id: '1', data: json.encode(updated_payload), cache_disable: false)!
println(res.code)
keys = conn.redis.keys('http:${conn.cache.key}*')!
assert keys.len == 0
// Patching a resource post id 1, would be invalidate caches for these resources, `/posts` and `/posts/1`
// so on subsequent GET requests you get fresh response from the server.
patch_payload := {
  'title': 'foo'
}
res = conn.send(method: .patch, prefix: 'posts', id: '1', data: json.encode(patch_payload), cache_disable: false)!
println(res.code)
keys = conn.redis.keys('http:${conn.cache.key}*')!
assert keys.len == 0
// Deleting a resource, would be invalidate caches for these resources, `/posts` and `/posts/1`
// so on subsequent GET requests you get fresh response from the server.
res = conn.send(method: .delete, prefix: 'posts', id: '1', cache_disable: false)!
println(res.code)
keys = conn.redis.keys('http:${conn.cache.key}*')!
assert keys.len == 0
// using query parameters,
res = conn.send(
  prefix: 'posts'
  params: {
    'userId': '1'
  }
  cache_disable: false
)!
println(res.code)

keys = conn.redis.keys('http:${conn.cache.key}*')!
assert keys.len == 1
// in cases we know that POST would be idempotent in the context of this connection, and we want to cache its responses we can add it to allowable methods
conn.cache.allowable_methods << .post
// you should not do this as 201 response should not be cached, but we do here for demonstration purposes
conn.cache.allowable_codes << 201
// Creating a resource, should be fresh response from the server but response will be cahced this time,
// and no cache would be invalidate as we decleare POST as cachable/safe by adding it to allowable methods.
res = conn.send(method: .post, prefix: 'posts', data: json.encode(payload), cache_disable: false)!
println(res.code)
keys = conn.redis.keys('http:${conn.cache.key}*')!
assert keys.len == 2
// customize one time request
mut custom_req := httpconnection.Request{}
custom_req.header.add(.user_agent, 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:50.0) Gecko/20100101')
custom_req.cache_disable = false // default false
custom_req.prefix = '/posts'
// this request only will have custom user agent field in its header.
// also cache will be disabled, won't get or set any cache for this request.
res = conn.send(custom_req)!
println(res.code)
keys = conn.redis.keys('http:${conn.cache.key}*')!
assert keys.len == 3
