module main

import freeflowuniverse.crystallib.baobab.smartid

fn test_cid() ! {
	cid00 := smartid.cid(name: 'test')!
	// assert cid00.circle==2
	// assert cid00.str() == "2"
	println(cid00)
	for i in 0 .. 10000 {
		cid2 := smartid.cid(name: 'test_${i}')!
	}
	if true {
		panic('s')
	}

	// cid1 := cid(cid_int: 9999)!
	// assert cid1.str() == '7pr'
	// assert cid1.u32() == 9999
	// assert cid1.name()! == 'test_9988'

	// cid2 := cid(cid_int: 9998)!
	// assert cid2.str() == '7pq'
	// assert cid2.u32() == 9998
	// assert cid2.name()! == 'test_9987'

	// g1 := cid1.gid(oid_str: '1')!
	// g2 := cid1.gid(oid_str: '2')!

	// // println(g1)
	// // println(g2)

	// cido := CID{
	// 	circle: 9999
	// }

	// assert g2 == GID{
	// 	region: 0
	// 	cid: cido
	// 	id: 2
	// }

	// g3 := cid1.gid()!
	// assert g3 == GID{
	// 	region: 0
	// 	cid: cido
	// 	id: 11
	// }

	// g4 := cid1.gid()!
	// assert g4 == GID{
	// 	region: 0
	// 	cid: cido
	// 	id: 12
	// }
}

fn main() {
	test_cid() or { panic(err) }
}
