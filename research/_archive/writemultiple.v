module main

import os
import json

__global (
	ciddb shared []CIDDB
)

pub struct CIDDB {
pub mut:
	cid2u32 map[string]u32
}

fn dbpath() string {
	mut h := os.getenv('HOME')
	if h == '' {
		panic("can't find home env")
	}
	return '${h}/hero/db/test/'
}

fn cid_db_get() !CIDDB {
	lock ciddb {
		if ciddb.len == 0 {
			ciddb << CIDDB{}
		}
		println(ciddb[0].cid2u32)
		if ciddb[0].cid2u32.keys().len == 0 {
			println(':check disk')
			if os.exists('${dbpath()}//ciddb.json') {
				d := os.read_file('${dbpath()}//ciddb.json')!
				cdb := json.decode(CIDDB, d)!
				ciddb[0] = cdb
				println(':decode')
			} else {
				ciddb[0].cid2u32['core'] = 1
				println(':exists')
			}
		}
		return ciddb[0]
	}
	panic('bug')
}

fn cid_db_set() ! {
	mut d := ''
	lock ciddb {
		if ciddb.len == 0 {
			ciddb << CIDDB{
				cid2u32: {
					'aaa': u32(1)
				}
			}
		}
		d = json.encode(ciddb[0])
	}
	println('write1')
	os.mkdir_all(dbpath())!
	os.write_file('${dbpath()}/ciddb.json', d)!
	println('write2')
}

fn test_cid() ! {
	for i in 0 .. 1 {
		cid_db_get()!
		cid_db_set()!
	}
}

fn main() {
	test_cid() or { panic(err) }
}
