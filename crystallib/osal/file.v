module osal

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console
import os

pub fn file_write(path string, text string) ! {
	return os.write_file(path, text)
}

pub fn file_read(path string) !string {
	return os.read_file(path)
}

// remove all if it exists
pub fn dir_ensure(path string) ! {
	if !os.exists(path) {
		os.mkdir_all(path)!
	}
}

// remove all if it exists
pub fn dir_delete(path string) ! {
	if os.exists(path) {
		return os.rmdir_all(path)
	}
}

// remove all if it exists
// and then (re-)create
pub fn dir_reset(path string) ! {
	os.rmdir_all(path)!
	os.mkdir_all(path)!
}

// can be list of dirs, files
// ~ supported
// can be \n or , separated
pub fn rm(todelete_ string) ! {
	for mut item in texttools.to_array(todelete_) {
		if item.trim_space() == '' {
			continue
		}
		item = item.replace('~', os.home_dir())
		console.print_debug(' - rm: ${item}')
		if item.starts_with('/') {
			if os.exists(item) {
				if os.is_dir(item) {
					os.rmdir_all(item)!
				} else {
					os.rm(item)!
				}
			}
		} else {
			if item.contains('/') {
				return error('there should be no / in to remove list')
			}
			cmd_delete(item)! // look for the command, if will be removed if found
		}
	}
}
