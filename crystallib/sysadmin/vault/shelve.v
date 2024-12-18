module vault

import freeflowuniverse.crystallib.core.pathlib
import time
import os
import freeflowuniverse.crystallib.ui.console

// represents one directory in which backup was done
// is like a shelve in a vault
pub struct Shelve {
pub mut:
	items   []Item
	path    pathlib.Path // path of the dir which is represented by the shelve
	changed bool
}

// save the metadata for the backups
fn (mut shelve Shelve) meta_data(current_time time.Time) string {
	mut out := ['time:${current_time.unix()}']
	for item in shelve.items {
		out << item.meta()
	}
	return out.join_lines()
}

// save the metadata for the backups
pub fn (mut shelve Shelve) save() ! {
	mut mpath := shelve.path_meta()!
	out := shelve.meta_data(time.now())
	mpath.write(out)!
}

// get the data from the directory
fn (mut shelve Shelve) path_meta() !pathlib.Path {
	pathmeta := '${shelve.path.path}/.vault/meta'
	return pathlib.get_file(path: pathmeta, create: true)
}

// load the shelve, if its not there yet, then will return empty
pub fn (mut shelve Shelve) load() ! {
	mut mpath := shelve.path_meta()!
	if mpath.exists() {
		text := mpath.read()!
		for line in text.split_into_lines() {
			if line.trim_space() == '' {
				continue
			}
			splitted := line.split('|')
			if splitted.len != 4 {
				panic('format shelve data is wrong, not enough parts on ${line}')
			}
			// "${i.sha256()}|${i.time.unix()}|${i.nr}|${i.name}"
			mut item := Item{
				sha256: splitted[0].trim_space()
				time:   time.unix(splitted[1].i64())
				nr:     splitted[2].u16()
				name:   splitted[3].trim_space()
				shelve: &shelve
			}
			shelve.items << item
		}
	}
}

// walk over the directory which is represented by the shelve, walk over it and find new elements
pub fn (mut shelve Shelve) shelve() ! {
	// means the diretory was not processed yet, walk over all files in the directory and add
	mut llist := shelve.path.list(recursive: false)!
	for mut file in llist {
		if file.name().starts_with('.') || file.name().starts_with('_') {
			continue
		}
		if file.is_file() {
			shelve.add(mut file)!
		}
	}
	shelve.save()!
}

// find the latest item for specific name, if it does not exist will create
pub fn (mut shelve Shelve) latest_nr(name string) int {
	mut latest := 0
	for i in shelve.items {
		if i.name == name {
			if i.nr > latest {
				latest = i.nr
			}
		}
	}
	return latest
}

// check if we can find the name on the shelve
pub fn (mut shelve Shelve) exists(name string) bool {
	for i in shelve.items {
		if i.name == name {
			return true
		}
	}
	return false
}

// find the latest item for specific name, if it does not exist will create
pub fn (mut shelve Shelve) latest(name string) Item {
	mut latest_i := Item{
		shelve: &shelve
	}
	mut latest_nr := 0
	for i in shelve.items {
		if i.name == name {
			if i.nr > latest_nr {
				latest_nr = i.nr
				latest_i = i
			}
		}
	}
	return latest_i
}

// add a file to the shelve
pub fn (mut shelve Shelve) add(mut path pathlib.Path) !Item {
	console.print_header(' shelve: ${path}')
	if !path.exists() {
		error("cannot find path to add to shell: '${path}'")
	}
	if !path.is_file() {
		return error('only support file and filelink')
	}

	name := path.name()
	sha := path.sha256()!

	// get the latest one if it exists
	mut item := shelve.latest(name)
	if sha == item.sha256 {
		return item
	}

	// means there is a filechange
	mut item_new := Item{
		nr:     item.nr + 1
		name:   name
		time:   time.now()
		sha256: sha
		shelve: &shelve
	}
	newname := item_new.name_nr()
	mut dest := pathlib.get_no_check('${shelve.path.path}/.vault/${newname}')
	// console.print_debug('------ ${dest}')
	path.copy(dest: dest.path)!
	shelve.items << item_new
	shelve.changed = true
	return item_new
}

// delete the shelve info
pub fn (mut shelve Shelve) delete() ! {
	pp := '${shelve.path.path}/.vault'
	if os.exists(pp) {
		os.rmdir_all(pp)!
	}
	shelve.items = []Item{}
}

// walk over the vault and re-shelve all dir's as owned by the vault
pub fn (mut shelve Shelve) superlist() string {
	mut out := 'SHELVE:${shelve.path.path}\n'
	for mut item in shelve.items {
		out += '${item.meta()}\n'
	}
	return out
}

// restore to the unixtime state
// only implemented to go to 0, which is the first state
// TODO: implement restore on other times
// pub fn (mut shelve Shelve) restore(unixtime int )! {
// 	for mut item in shelve.items {
// 		item.restore(unixtime int)!
// 	}
// }
