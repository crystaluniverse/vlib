module osal

import os
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console
// import regex
import freeflowuniverse.crystallib.core.texttools

pub struct CmdAddArgs {
pub mut:
	cmdname string
	source  string @[required] // path where the binary is
	symlink bool // if rather than copy do a symlink
	reset   bool = true // if existing cmd will delete
	// bin_repo_url string = 'https://github.com/freeflowuniverse/freeflow_binary' // binary where we put the results
}

// copy a binary to the right location on the local computer .
// e.g. is /usr/local/bin on linux .
// e.g. is ~/hero/bin on osx .
// will also add the bin location to the path of .zprofile and .zshrc (different per platform)
pub fn cmd_add(args_ CmdAddArgs) ! {
	mut args := args_
	if args.cmdname == '' {
		args.cmdname = os.base(args.source)
	}
	mut dest := bin_path()!

	mut sourcepath := pathlib.get_file(path: args.source, create: false)!
	mut destpath := '${dest}/${args.cmdname}'

	console.print_debug(destpath)

	// check if there is other file
	res := os.execute('which ${args.cmdname}')
	if res.exit_code == 0 {
		existing_path := res.output.trim_space()
		if destpath != existing_path {
			console.print_debug(' - did find a cmd which is not in path we expect:\n    expected:${destpath}\n    got:${existing_path}')
			if args.reset {
				if existing_path.contains('homebrew/bin') {
					exec(cmd: 'brew uninstall ${args.cmdname}') or {
						return error('failed to remove existing command using brew')
					}
				} else {
					os.rm(existing_path)!
				}
			} else {
				return error("existing cmd found on: ${existing_path} and can't delete.\nWas trying to install on ${destpath}.")
			}
		}
	}

	if args.symlink {
		sourcepath.link(destpath, true)!
	} else {
		sourcepath.copy(dest: destpath, rsync: false)!
	}

	mut destfile := pathlib.get_file(path: destpath, create: false)!

	destfile.chmod(0o770)! // includes read & write & execute

	// lets make sure this path is in profile
	profile_path_add_remove(paths2add: dest)!
}

pub fn profile_path_add_hero() !string {
	mut dest := bin_path()!
	profile_path_add_remove(paths2add: dest)!
	return dest
}

pub fn bin_path() !string {
	mut dest := ''
	if is_osx() {
		dest = '${os.home_dir()}/hero/bin'
		dir_ensure(dest)!
	} else {
		dest = '/usr/local/bin'
	}
	return dest
}

pub fn hero_path() !string {
	mut dest := ''
	dest = '${os.home_dir()}/hero'
	dir_ensure(dest)!
	return dest
}

///usr/local on linux, ${os.home_dir()}/hero on osx
pub fn usr_local_path() !string {
	mut dest := ''
	if is_osx() {
		dest = '${os.home_dir()}/hero'
		dir_ensure(dest)!
	} else {
		dest = '/usr/local'
	}
	return dest
}

// return the source statement if the profile exists
pub fn profile_path_source() string {
	if hostname() or { '' } == 'rescue' {
		return ''
	}
	pp := profile_path()
	if os.exists(pp) {
		return 'source ${pp}'
	}
	return ''
}

// return source $path &&  .
// or empty if it doesn't exist
pub fn profile_path_source_and() string {
	if hostname() or { '' } == 'rescue' {
		return ''
	}
	pp := profile_path()
	if os.exists(pp) {
		return '. ${pp} &&'
	}
	return ''
}

fn profile_paths_get(content string) []string {
	mut paths := []string{}
	for line in content.split_into_lines() {
		if line.contains('PATH') {
			post := line.all_after_last('=').trim('\'" ,')
			splitted := post.split(':')
			for item in splitted {
				item2 := item.trim(' "\'')
				if item2 !in paths && !item2.contains('PATH') {
					paths << item2
				}
			}
		}
	}
	return paths
}

@[params]
pub struct ProfilePathAddRemoveArgs {
pub mut:
	paths_profile string
	paths2add     string
	paths2delete  string
	allprofiles   bool
}

// add and/or remove paths from profiles
// if paths_profile not specified it will walk over all of them
pub fn profile_path_add_remove(args_ ProfilePathAddRemoveArgs) ! {
	mut args := args_

	mut paths_profile := texttools.to_array(args.paths_profile)
	mut paths2add := texttools.to_array(args.paths2add)
	mut paths2delete := texttools.to_array(args.paths2delete)

	if paths_profile.len == 0 {
		if args.allprofiles {
			paths_profile = profile_paths_all()!
		} else {
			paths_profile = profile_paths_preferred()!
		}
	}

	for path_profile_str in paths_profile {
		mut path_profile := pathlib.get_file(path: path_profile_str, create: true)!
		mut c := path_profile.read()!
		mut c_out := '' // the result file
		mut paths_existing_inprofile := profile_paths_get(c)
		console.print_debug(" -- profile path profile:'${path_profile_str}' add:'${args.paths2add}' delete:'${args.paths2delete}'")
		// Remove paths to delete
		for mut todelete in paths2delete {
			todelete = todelete.trim_space()
			if todelete.len > 0 {
				if todelete.starts_with('/') || todelete.starts_with('~') {
					paths_existing_inprofile = paths_existing_inprofile.filter(it != todelete)
					paths_existing_inprofile = paths_existing_inprofile.filter(it.replace('~',
						os.home_dir()) != todelete)
				} else {
					paths_existing_inprofile = paths_existing_inprofile.filter(!(it.contains(todelete)))
				}
			}
		}

		// Add new paths if they don't exist
		for mut path2add in paths2add {
			if path2add !in paths_existing_inprofile {
				path2add = path2add.replace('~', os.home_dir())
				if !os.exists(path2add) {
					return error("can't add path to profile, doesn't exist: ${path2add}")
				}
				paths_existing_inprofile << path2add
			}
		}

		// Remove existing PATH declarations
		lines := c.split_into_lines()
		for line in lines {
			if !line.to_lower().starts_with('export path=') {
				c_out += line + '\n'
			}
		}

		// Sort the paths
		paths_existing_inprofile.sort()

		// println(paths_existing_inprofile)
		// if true{panic("ss")}		

		// Add the sorted paths
		for item in paths_existing_inprofile {
			c_out += 'export PATH=\$PATH:${item}\n'
		}

		// Only write if the content has changed
		if c.trim_space() != c_out.trim_space() {
			path_profile.write(c_out)!
		}
	}
}

// is same as executing which in OS
// returns path or error
pub fn cmd_path(cmd string) !string {
	res := os.execute('which ${cmd}')
	if res.exit_code == 0 {
		return res.output.trim_space()
	}
	return error("can't do find path for cmd: ${cmd}")
}

// delete cmds from found locations
// can be one command of multiple
pub fn cmd_delete(cmd string) ! {
	cmds := texttools.to_array(cmd)
	for cmd2 in cmds {
		res := cmd_path(cmd2) or { '' }
		if res.len > 0 {
			if os.exists(res) {
				os.rm(res)!
			}
		}
	}
}

// return possible profile paths in OS
pub fn profile_paths_all() ![]string {
	mut profile_files_ := []string{}

	profile_files_ = [
		'/etc/profile',
		'/etc/bash.bashrc',
		'${os.home_dir()}/.bashrc',
		'${os.home_dir()}/.bash_profile',
		'${os.home_dir()}/.profile',
		'${os.home_dir()}/.zprofile',
		'${os.home_dir()}/.zshrc',
	]

	mut profile_files2 := []string{}

	for file in profile_files_ {
		if os.exists(file) {
			profile_files2 << file
		}
	}
	return profile_files_
}

pub fn profile_paths_preferred() ![]string {
	mut toadd := []string{}
	if is_osx() {
		toadd << '${os.home_dir()}/.zprofile'
		toadd << '${os.home_dir()}/.zshrc'
	} else {
		toadd << '${os.home_dir()}/.bash_profile'
		toadd << '${os.home_dir()}/.bashrc'
		toadd << '${os.home_dir()}/.zshrc'
	}
	mut profile_files2 := []string{}

	for file in toadd {
		if os.exists(file) {
			println('${file} exists')
			profile_files2 << file
		}
	}
	return profile_files2
}

pub fn profile_path() string {
	if is_osx() {
		return '${os.home_dir()}/.zprofile'
	} else {
		return '${os.home_dir()}/.bash_profile'
	}
}
