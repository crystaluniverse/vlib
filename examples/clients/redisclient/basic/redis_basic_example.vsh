#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.clients.redisclient

mut redis := redisclient.core_get()!

redis.selectdb(0)!

redis.set('test', 'some data')!

redis.set('hello', 'bla\r\nbli\r\nblu')!

mut r := redis.get('test')!
assert r == 'some data'

rr := 'a'.repeat(100000)
for i in 0 .. 5 {
	redis.set('test0', rr)!
	rr2 := redis.get('test0')!
	if rr != rr2 {
		// println(rr)
		// println("------")
		// println(rr2)
		// println("------")

		println('DATA SEND TO REDIS & RECEIVED IS NOT SAME (test ${i})')
		println('SIZE DATA SEND: ${rr.len}')
		println('SIZE DATA RECEIVED: ${rr2.len}')
		println(rr.count('a'))
		println(rr2.count('a'))

		panic('large set fail')
	}
}

r = redis.get('hello')!
assert r == 'bla\r\nbli\r\nblu'

redis.set('counter', '0')!

mut i := redis.incrby('counter', 17)!
assert i == 17

r = redis.get('counter')!
assert r == '17'

i = redis.incrby('counter', 10)!
assert i == 27

i = redis.incr('counter')!
assert i == 28

i = redis.decrby('counter', 5)!
assert i == 23

i = redis.decr('counter')!
assert i == 22

r = redis.get('counter')!
assert r == '22'

mut f := redis.incrbyfloat('counter', 1.42)!
assert f == 23.42

i = redis.append('test', ', added')!
assert i == 16

r = redis.get('test')!
assert r == 'some data, added'

i = redis.rpush('push', 'rpush')!
assert i == 1

i = redis.lpush('push', 'lpush')!
assert i == 2

r = redis.getset('test', 'newvalue')!
assert r == 'some data, added'

r = redis.get('test')!
assert r == 'newvalue'

r = redis.getrange('test', 1, 4)!
assert r == 'ewva'

r = redis.getrange('nonexist', 0, 42)!
assert r == ''

r = redis.randomkey()!
println(r)

i = redis.strlen('test')!
assert i == 8

// should fails wrong type
i = redis.strlen('push') or { 0 }

i = redis.llen('push')!
assert i == 2

r = redis.lpop('push')!
assert r == 'lpush'

r = redis.rpop('push')!
assert r == 'rpush'

i = redis.ttl('push')!
assert i == -2

// should be nil
redis.rpop('push') or { assert '${err}' == '(nil)' }

i = redis.pttl('push')!
assert i == -2

i = redis.del('push')!
assert i == 0

i = redis.llen('push')!
assert i == 0

// should fails
i = redis.llen('counter') or { 0 }

redis.rename('test', 'newtest')!
// assert b == true

// array example support
mut cursor, values := redis.scan(0)!
println(cursor)
println(values)

assert values.len == 4
