module redisclient

import time

pub struct RedisQueue {
pub mut:
	key   string
	redis &Redis
}

pub fn (mut r Redis) queue_get(key string) RedisQueue {
	return RedisQueue{
		key:   key
		redis: r
	}
}

pub fn (mut q RedisQueue) add(val string) ! {
	q.redis.lpush(q.key, val)!
}

// timeout in msec
pub fn (mut q RedisQueue) get(timeout u64) !string {
	start := u64(time.now().unix_milli())
	for {
		r := q.redis.rpop(q.key) or { '' }
		if r != '' {
			return r
		}
		if u64(time.now().unix_milli()) > (start + timeout) {
			break
		}
		time.sleep(time.microsecond)
	}
	return error('timeout on ${q.key}')
}

// get without timeout, returns none if nil
pub fn (mut q RedisQueue) pop() !string {
	return q.redis.rpop(q.key)!
}
