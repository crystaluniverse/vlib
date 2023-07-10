module builder

import process
import os

[heap]
pub struct ExecutorLocal {
	retry int = 1 // nr of times something will be retried before failing, need to check also what error is, only things which should be retried need to be done, default 1 because is local
pub mut:
	debug bool
}

pub fn (mut executor ExecutorLocal) exec(cmd string) ?string {
	res := process.execute_job(cmd: cmd, stdout: true)?
	return res.output
}

pub fn (mut executor ExecutorLocal) exec_silent(cmd string) ?string {
	mut stdout := false
	if executor.debug {
		stdout = true
	}
	res := process.execute_job(cmd: cmd, stdout: stdout)?
	return res.output
}

pub fn (mut executor ExecutorLocal) file_write(path string, text string) ? {
	return os.write_file(path, text)
}

pub fn (mut executor ExecutorLocal) file_read(path string) ?string {
	return os.read_file(path)
}

pub fn (mut executor ExecutorLocal) file_exists(path string) bool {
	return os.exists(path)
}

pub fn (mut executor ExecutorLocal) debug_on() {
	executor.debug = true
}

pub fn (mut executor ExecutorLocal) debug_off() {
	executor.debug = false
}

// carefull removes everything
pub fn (mut executor ExecutorLocal) remove(path string) ? {
	if os.is_file(path) || os.is_link(path) {
		return os.rm(path)
	} else if os.is_dir(path) {
		return os.rmdir_all(path)
	}
	return
}

// get environment variables from the executor
pub fn (mut executor ExecutorLocal) environ_get() ?map[string]string {
	env := os.environ()
	if false {
		return error('can never happen')
	}
	return env
}

/*
Executor info or meta data
accessing type Executor won't allow to access the
fields of the struct, so this is workaround
*/
pub fn (mut executor ExecutorLocal) info() map[string]string {
	return {
		'category': 'local'
	}
}

// upload from local FS to executor FS
pub fn (mut executor ExecutorLocal) upload(source string, dest string) ? {
	executor.exec('cp -r $source $dest')?
}

// download from executor FS to local FS
pub fn (mut executor ExecutorLocal) download(source string, dest string) ? {
	executor.exec('cp -r $source $dest')?
}

pub fn (mut executor ExecutorLocal) shell(cmd string) ? {
	if cmd.len > 0 {
		os.execvp('/bin/bash', ["-c '$cmd'"])?
	} else {
		os.execvp('/bin/bash', [])?
	}
}

pub fn (mut executor ExecutorLocal) list(path string) ?[]string {
	if !executor.dir_exists(path) {
		panic('Dir Not found')
	}
	return os.ls(path)
}

pub fn (mut executor ExecutorLocal) dir_exists(path string) bool {
	return os.is_dir(path)
}
