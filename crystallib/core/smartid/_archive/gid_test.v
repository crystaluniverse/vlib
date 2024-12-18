module smartid

import freeflowuniverse.crystallib.clients.redisclient

fn cleanup() ! {
	mut c := base.context()!
	mut r := c.redis()!
	all_keys := r.keys('circle:test:*')!
	for key in all_keys {
		r.del(key)!
	}
}

fn test_sid() {
	defer {
		cleanup() or { panic(err) }
	}

	cid1 := cid(name: 'test') or { panic(err) }

	for i in 0 .. 10000 {
		cid1.gid() or { panic(err) }
	}

	gid1 := cid1.gid(oid_str: 'aa') or { panic(err) }

	assert gid1 == GID{
		region: 0
		cid:    CID{
			circle: 11
		}
		id:     370
	}

	gid2 := cid1.gid(oid_str: 'ab') or { panic(err) }

	assert gid2 == GID{
		region: 0
		cid:    CID{
			circle: 11
		}
		id:     371
	}

	assert gid2.str() == 'b.ab'
	assert gid2.ostr() == 'ab'
	assert gid2.oid() == 371

	// TODO: acknowledge sid's, do tests if the right ones are in there, ...	

	// TODO: test sid_str, int, ... the checks, ...

	// cleanup()
}
