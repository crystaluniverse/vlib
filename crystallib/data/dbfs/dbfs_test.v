module dbfs

import time
import os
import freeflowuniverse.crystallib.ui.console

fn test_dbfs() {
	data_dir := '/tmp/db'
	os.rmdir_all(data_dir) or {}
	mut dbcollection := get(contextid: 1, dbpath: data_dir, secret: '123456')!

	mut db := dbcollection.db_create(name: 'db_a', encrypted: false, withkeys: true)!

	dotest(mut db, mut dbcollection) or { panic(err) }
}

fn test_dbfs2() {
	data_dir := '/tmp/db'
	os.rmdir_all(data_dir) or {}
	mut dbcollection := get(contextid: 1, dbpath: data_dir, secret: '123456')!

	mut db := dbcollection.db_create(name: 'db_a', encrypted: true, withkeys: true)!

	dotest(mut db, mut dbcollection) or { panic(err) }
}

fn test_dbfs3() {
	data_dir := '/tmp/db'
	os.rmdir_all(data_dir) or {}
	mut dbcollection := get(contextid: 1, dbpath: data_dir, secret: '123456')!

	mut db := dbcollection.db_create(
		name: 'db_a'
		encrypted: false
		withkeys: true
		keyshashed: true
	)!

	panic('need other test')
}

fn dotest(mut db DB, mut dbcollection DBCollection) ! {
	id := db.set(key: 'aaa', value: 'bbbb')!
	assert 'bbbb' == db.get(key: 'aaa')!

	id2 := db.set(key: 'aaa', value: 'bbbb2')!
	assert 'bbbb2' == db.get(key: 'aaa')!
	assert id == id2
	assert id == 1

	id3 := db.set(key: 'bbb', value: 'bbbb3')!
	assert 'bbbb3' == db.get(key: 'bbb')!
	assert id3 == id2 + 1

	assert db.exists(key: 'aaa')!
	assert db.exists(key: 'bbb')!
	assert db.exists(id: id2)!
	assert db.exists(id: id3)!
	id3_exsts := db.exists(id: id3 + 1)!
	console.print_debug(id3 + 1)
	assert id3_exsts == false

	for i in 3 .. 100 {
		id4 := db.set(key: 'a${i}', value: 'b${i}')!
		console.print_debug('${i} --> ${id4}')
		assert i == id4
	}
	db.delete(key: 'aaa')!
	assert db.exists(key: 'aaa')! == false
	assert db.exists(id: id2)! == false

	db.delete(id: 50)!
	assert db.exists(key: 'a50')! == false
	assert db.exists(id: 50)! == false

	dbcollection.destroy()!

	assert dbcollection.exists('a10') == false
	assert db.exists(key: 'test')! == false
}
