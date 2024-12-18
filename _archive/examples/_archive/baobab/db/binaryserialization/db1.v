module main

import mystruct
import time
import freeflowuniverse.crystallib.data.ourtime

fn do() ! {
	mydb := mystruct.db_new(circlename: 'testcircle')!

	mydb.delete_all()!

	mydb.find() or { println('this should fail, tables are still not created. ${err}') }

	mut o1 := mydb.new(
		name:        'my name'
		nr:          2
		color:       'red'
		description: 'is this a serious descripion'
		nr2:         10
		listu32:     [u32(2), u32(3), u32(4)]
	)!
	mydb.set(o1)!

	time.sleep(time.second)
	before_creating_o2 := ourtime.now()
	time.sleep(time.second)
	objs_4 := mydb.find()!
	assert objs_4.len == 1

	mut o2 := mydb.new(
		name:    'my second name'
		nr:      2
		color:   'blue'
		nr2:     11
		listu32: [u32(5), u32(6), u32(7)]
	)!
	mydb.set(o2)!

	objs_7 := mydb.find(ctime_to: before_creating_o2)!
	assert objs_7.len == 1
	are_equal(objs_7[0], o1)

	objs_8 := mydb.find(ctime_from: before_creating_o2)!
	assert objs_8.len == 1
	are_equal(objs_8[0], o2)

	objs_5 := mydb.find()!
	assert objs_5.len == 2

	o3 := mydb.get(o1.gid)!
	o1data := mydb.serialize(o1)!
	o3data := mydb.serialize(o3)!
	assert o1data == o3data

	heroscript := mydb.serialize_heroscript(o1)!
	deserialized_heroscript := mydb.unserialize_heroscript(heroscript)!

	are_equal(o1, deserialized_heroscript[0])

	mut objs := mydb.find(
		name: 'my name'
	)!
	assert objs.len == 1
	are_equal(objs[0], o1)

	objs = mydb.find(
		listu32: [u32(2), u32(3), u32(4)]
	)!
	assert objs.len == 1

	objs = mydb.find(
		nr2: 11
	)!
	assert objs.len == 1
	are_equal(objs[0], o2)

	objs = mydb.find(
		nr: 2
	)!
	assert objs.len == 2
	are_equal(objs[0], o1)
	are_equal(objs[1], o2)

	mydb.delete(o1.gid)!
	mydb.delete(o2.gid)!

	objs_6 := mydb.find()!
	assert objs_6.len == 0
	println('all tests were successful!')

	perf_write(mydb)!
	perf_find(mydb)!

	mydb.delete_all()!
}

fn perf_write(mydb mystruct.MyDB) ! {
	now := time.now()
	for i in 0 .. 1000 {
		o := mystruct.MyStruct{
			gid:     mydb.cid.gid()!
			name:    'my ${i} record'
			nr:      1
			color:   'blue'
			nr2:     2
			listu32: [u32(5), u32(6), u32(7)]
		}
		mydb.set(o)!
	}
	diff := time.since(now)
	println('writing 1000 objects took ${diff.seconds()} seconds.\n')
}

fn perf_find(mydb mystruct.MyDB) ! {
	now := time.now()
	objs := mydb.find(nr: 1)!
	diff := time.since(now)
	println('querying 1000 objects took ${diff.seconds()} seconds.\n')
	assert objs.len == 1000
}

fn are_equal(o1 mystruct.MyStruct, o2 mystruct.MyStruct) {
	assert o1.gid == o2.gid
	assert o1.params == o2.params
	assert o1.version_base == o2.version_base
	assert o1.serialization_type == o2.serialization_type
	assert o1.name == o2.name
	assert o1.description == o2.description
	assert o1.remarks == o2.remarks
	assert o1.mtime.str() == o2.mtime.str()
	assert o1.ctime.str() == o2.ctime.str()
	assert o1.nr == o2.nr
	assert o1.color == o2.color
	assert o1.nr2 == o2.nr2
	assert o1.listu32 == o2.listu32
}

fn main() {
	do() or { panic(err) }
}
