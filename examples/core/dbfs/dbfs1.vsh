#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.data.dbfs
import time
import os

data_dir := '/tmp/db'
os.rmdir_all(data_dir) or {}
mut dbcollection := dbfs.get(contextid: 1, dbpath: data_dir, secret: '123456')!

mut db := dbcollection.db_create(name: 'db_a', encrypted: true, withkeys: true)!

id := db.set(key: 'a', value: 'bbbb')!
assert 'bbbb' == db.get(key: 'a')!

id2 := db.set(key: 'a', value: 'bbbb2')!
assert 'bbbb2' == db.get(key: 'a')!
assert id == id2
assert id == 1

id3 := db.set(key: 'b', value: 'bbbb3')!
assert 'bbbb3' == db.get(key: 'b')!
assert id3 == id2 + 1

assert db.exists(key: 'a')!
assert db.exists(key: 'b')!
assert db.exists(id: id2)!
assert db.exists(id: id3)!
id3_exsts := db.exists(id: id3 + 1)!
println(id3 + 1)
assert id3_exsts == false

for i in 3 .. 100 {
	id4 := db.set(key: 'a${i}', value: 'b${i}')!
	println('${i} --> ${id4}')
	assert i == id4
}

db.delete(key: 'a')!
assert db.exists(key: 'a')! == false
assert db.exists(id: id2)! == false

db.delete(id: 50)!
assert db.exists(key: 'a50')! == false
assert db.exists(id: 50)! == false
