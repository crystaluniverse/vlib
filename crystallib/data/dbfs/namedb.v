module dbfs

import json
import crypto.md5
import freeflowuniverse.crystallib.core.pathlib
// import freeflowuniverse.crystallib.ui.console

@[heap]
pub struct NameDB {
pub mut:
	path   pathlib.Path
	config NameDBConfig
}

pub struct NameDBConfig {
pub mut:
	levels int = 1
}

// TODO: need to put levels in, so that use less directories if nr of items in DB is small

// purpose of this file is to create an index (can optionally have data attached to this index per key)
// so we can easily map between a key and an id or other way around

// if key and ok to hash, then we can generated unique id out of the hashed key

pub fn namedb_new(path string) !NameDB {
	mut p := pathlib.get_dir(path: path, create: true)!
	mut p_meta := p.file_get('.meta') or {
		p2 := pathlib.get_file(path: '${p.path}/.meta', create: true)!
		p2
	}
	data := p_meta.read()!
	mut cfg := NameDBConfig{}
	if data.len > 0 {
		cfg = json.decode(NameDBConfig, data)!
	}
	return NameDB{
		path: p
		config: cfg
	}
}

pub fn (mut db NameDB) save() ! {
	mut p := pathlib.get_file(path: '${db.path.path}/.meta', create: false)!
	data := json.encode(db.config)
	p.write(data)!
}

// will store in a place where it can easily be found back and it returns a unique u32
pub fn (mut db NameDB) set(key string, data string) !u32 {
	myid, mut mypath := db.key2path(key)!
	// Check if the pubkey already exists in the file
	mut line_num := 0
	content := mypath.read()!
	mut lines := content.trim_space().split_into_lines()
	mut lines_out := []string{}
	mut idfound := 0
	for mut line in lines {
		key_in_file, _ := namedb_process_line(mypath.path, line)
		if key_in_file == key {
			line = '${key}:${data}'
			if idfound > 0 {
				panic('bug, there is double key, should not be possible')
			}
			idfound = myid + line_num
		}
		line_num += 1
		lines_out << line
	}
	if idfound == 0 {
		// need to add the line was not in file yet
		lines << '${key}:${data}'
	}
	mypath.write(lines.join('\n'))!

	return u32(myid + lines.len - 1)
}

pub fn (mut db NameDB) delete(key string) ! {
	_, mut mypath := db.key2path(key)!
	content := mypath.read()!
	mut lines := content.trim_space().split_into_lines()
	mut lines_out := []string{}
	mut found := false
	for mut line in lines {
		key_in_file, _ := namedb_process_line(mypath.path, line)
		if key_in_file == key {
			found = true
			continue // skip
		}
		lines_out << line
	}
	if found {
		mypath.write(lines.join('\n'))!
	}
}

// will store in a place where it can easily be found back and it returns a unique u32
pub fn (mut db NameDB) get(key string) !(u32, string) {
	myid, mut mypath := db.key2path(key)!
	mut line_num := 0
	content := mypath.read()!
	mut lines := content.trim_space().split_into_lines()
	for line in lines {
		key_in_file, data := namedb_process_line(mypath.path, line)
		if key_in_file == key {
			return u32(myid + line_num), data
		}
		line_num += 1
	}
	return error("can't find key:${key} in db:${db.path.path}")
}

pub fn (mut db NameDB) exists(key string) !bool {
	_, mut mypath := db.key2path(key)!
	content := mypath.read()!
	mut lines := content.trim_space().split_into_lines()
	for line in lines {
		key_in_file, _ := namedb_process_line(mypath.path, line)
		if key_in_file == key {
			return true
		}
	}
	return false
}

pub fn (mut db NameDB) get_from_id(myid u32) !(string, string) {
	// console.print_debug("key get: ${myid}")
	mut mypath := db.dbpath(myid)!
	// console.print_debug("path: ${mypath.path}")
	_, _, c := namedb_dbid(myid)
	// console.print_debug("ids: ${a} ${b} ${c}")
	content := mypath.read()!
	mut lines := content.trim_space().split_into_lines()
	// console.print_debug(lines)
	if c < lines.len {
		myline := lines[c] or {
			return error('out of bounds for: ${mypath.path}. Nrlines:${lines.len}. Line:${c}')
		}
		key_in_file, data := namedb_process_line(mypath.path, myline)
		return key_in_file, data
	}
	return error('Line nr higher than file nr of lines: ${mypath.path}. Nrlines:${lines.len}. Line:${c}')
}

// calculate the id's as needed to create the path
fn namedb_dbid(myid u32) (u8, u8, u16) {
	a := u8(myid / (256 * 256))
	a_post := myid - a * int(256 * 256)
	b := u8(a_post / 256)
	b_post := a_post - b * int(256)
	c := u16(b_post)
	return a, b, c
}

fn (mut db NameDB) key2path(key string) !(u32, pathlib.Path) {
	hash_bytes := md5.sum(key.bytes())
	if key.len < 2 {
		return error('key needs to be at least 2 chars')
	}
	a := hash_bytes[0] or { panic('bug') }
	b := hash_bytes[1] or { panic('bug') }
	mut myid := int(a) * 256 * 256 + int(b) * 256
	mut mypath := db.dbpath(u32(myid))!
	return u32(myid), mypath
}

fn namedb_process_line(path string, line string) (string, string) {
	if line.contains(':') {
		myline_parts := line.split(':').map(it.trim_space())
		if myline_parts.len != 2 {
			panic('syntax error in line ${line} in ${path}, not enough parts.')
		}
		return myline_parts[0], myline_parts[1]
	}
	return line.trim_space(), ''
}

fn (mut db NameDB) dbpath(myid u32) !pathlib.Path {
	a, b, _ := namedb_dbid(myid)
	// console.print_debug("dbpath ids: ${a} ${b} ${c}")
	dir_name := a.hex()
	file_name := b.hex()
	mut mydatafile := pathlib.get_file(
		path: '${db.path.path}/${dir_name}/${file_name}.txt'
		create: true
	)!
	return mydatafile
}
