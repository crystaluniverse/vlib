module db

import time
import freeflowuniverse.crystallib.core.smartid
import freeflowuniverse.crystallib.data.ourtime

pub struct MyStruct {
	Base
pub mut:
	color string
	nr    int
}

// example of how we should implement binary serialization
pub fn (o MyStruct) serialize_binary() ![]u8 {
	mut b := o.bin_encoder()!
	b.add_string(o.color)
	b.add_int(o.nr)
	return b.data
}

pub fn load(data []u8) !MyStruct {
	mut d, base := base_decoder(data)!
	mut o := MyStruct{
		Base: base
	}
	o.color = d.get_string()
	o.nr = d.get_int()
	return o
}

fn test_base() {
	m := create_struct()

	data := m.serialize_binary()!
	m2 := load(data)!

	assert m.gid == m2.gid

	assert m.params.params.len == m2.params.params.len
	for id, _ in m.params.params {
		assert m.params.params[id] == m2.params.params[id]
	}

	assert m.params.args.len == m2.params.args.len
	mut args_map := map[string]bool{}
	for id, _ in m.params.args {
		args_map[m.params.args[id]] = true
	}
	for a in m2.params.args {
		assert args_map[a] == true
	}

	assert m.version_base == m2.version_base
	assert m.serialization_type == m2.serialization_type
	assert m.name == m2.name
	assert m.description == m2.description

	assert m.remarks.remarks.len == m2.remarks.remarks.len
	for id, _ in m.remarks.remarks {
		assert m.remarks.remarks[id].content == m2.remarks.remarks[id].content
		assert m.remarks.remarks[id].time == m2.remarks.remarks[id].time
		assert m.remarks.remarks[id].rtype == m2.remarks.remarks[id].rtype
		a1 := m.remarks.remarks[id].author or {
			if _ := m2.remarks.remarks[id].author {
				panic('author is in original object, but not in deserialized object')
			}
			continue
		}

		a2 := m2.remarks.remarks[id].author or {
			panic('author is in deserialized object, but not in original object')
		}

		assert a1 == a2
	}
}

fn create_struct() MyStruct {
	mut m := MyStruct{
		name: 'aname'
		description: 'a description\ncan be multiline\n1'
		gid: smartid.gid(oid_u32: 99, cid_name: 'test') or { panic(err) }
		color: 'red'
		nr: 8
	}

	author_gid := smartid.gid(oid_u32: 333, cid_name: 'test') or { panic(err) }

	m.params_add('priority:urgent silver') or { panic(err) }
	m.params_add('priority:low gold') or { panic(err) }
	m.params_add('timing:now gold') or { panic(err) }

	m.remark_add(
		author: author_gid
		content: '
			lucky we did do this
			can be multiline
		'
		rtype: .audit
	) or { panic(err) }

	m.remark_add(
		content: '
			another one
		'
		rtype: .log
		params: 'color:red urgent'
	) or { panic(err) }

	m.remark_add(
		content: 'hiii'
		rtype: .log
		params: 'color:red urgent'
	) or { panic(err) }

	return m
}

fn test_find_remark() {
	m := create_struct()
	mut r := m.remarks.find_remark(time_to: ourtime.now())!
	assert r.len == 3

	r = m.remarks.find_remark(params_filter: 'color:red*')!
	assert r.len == 2

	r = m.remarks.find_remark(
		time_from: ourtime.OurTime{
			unix: i64(time.now().unix()) - time.second
		}
	)!
	assert r.len == 3

	a := smartid.gid(oid_u32: 333, cid_name: 'test')!
	r = m.remarks.find_remark(author: a)!
	assert r.len == 1
}
