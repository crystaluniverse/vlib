module rmb

import json
import encoding.base64

struct ZosPoolJSON {
mut:
	name      string
	pool_type string @[json: 'type'] // TODO: this should be an enum and we need to define what it is
	size      int // TODO: what does it mean? used how much what type?
	used      int // TODO: what does it mean? used how much what type?
}

pub struct ZosPool {
pub mut:
	name      string
	pool_type PoolType
	size      int
	used      int
}

enum PoolType {
	dontknow // TODO:
}

// get storage pools from a zos, the argument is u32 address of the zos
pub fn (mut z RMBClient) get_storage_pools(dst u32) ![]ZosPool {
	response := z.rmb_client_request('zos.storage.pools', dst, '')!
	if response.err.message != '' {
		return error('${response.err.message}')
	}
	objs := json.decode([]ZosPoolJSON, base64.decode_str(response.dat))
	_ := []ZosPool{}
	for o in objs {
		res = ZosPool{
			name:      o.name
			size:      o.size
			used:      o.used
			pool_type: .dontknow // TODO
		}
	}
}
