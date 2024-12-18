module vexecutor

import freeflowuniverse.crystallib.core.pathlib
import os
import freeflowuniverse.crystallib.ui.console

// TODO make sure each function opens and closes the executor.vsh file, no file should be open across functions

struct VExecutor {
mut:
	actions             []VAction
	execution_file      os.File
	execution_file_path pathlib.Path
	final_file_path     pathlib.Path
}

struct VAction {
	path  pathlib.Path
	lines []string
}

// Creates a new executor object
// ARGS:
// path string - /directory/filename.v
// cat Category - unknown, file, dir, linkdir, linkfile (enum)
// exist UYN - unknown, yes, no (enum)
pub fn new_executor(initial_file_path_ string, execution_file_path_ string, final_file_path_ string) !VExecutor {
	// create a execution file at execution_file_path and fill out
	mut execution_file_path := pathlib.get(execution_file_path_)
	execution_file_path.check()

	mut initial_file_path := pathlib.get(initial_file_path_)
	initial_file_path.check()

	mut final_file_path := pathlib.get(final_file_path_)
	final_file_path.check()

	// ensure that the execution file is an empty file
	if execution_file_path.exist == .yes {
		os.rm(execution_file_path.path) or {
			return error('Failed to remove execution file: ${err}')
		}
	}
	execution_file := os.create(execution_file_path.path) or {
		return error('Failed to create execution file at ' + @FN + ' : ${err}')
	}

	if initial_file_path.exist == .no {
		return error('Initial file does not exist at path: ${initial_file_path.path}')
	}

	// convert the initial file into an action
	initial_action := scan_file(mut initial_file_path) or {
		return error('Failed to scan initial file path at ' + @FN + ' : ${err}')
	}

	// create an VExecutor object
	mut v_executor := VExecutor{
		execution_file:      execution_file
		execution_file_path: execution_file_path
		final_file_path:     final_file_path
		actions:             [initial_action]
	}

	return v_executor
}

// Adds all the top level files in a directory to the VExecutor.actions list
// ARGS:
// directory_path string
pub fn (mut v_executor VExecutor) add_dir_to_end(directory_path_ string) ! {
	mut directory_path := pathlib.get(directory_path_)
	directory_path.check()

	mut fl := directory_path.list() or {
		return error('Failed to get file_paths of directory at ' + @FN + ' : ${err}')
	}
	// mut count := 0
	for mut file_path in fl.paths {
		// if count <= 10 {
		v_executor.actions << scan_file(mut file_path)!
		// count += 1
		// }
	}
}

// Scans a file and converts it into a VAction
// cuts out all content prior to // BEGINNING
// ARGS:
// path string - path to file
fn scan_file(mut path pathlib.Path) !VAction {
	if !path.exists() {
		return error('cannot find path: ${path.path} to scan for vlang files.')
	}

	// read all the lines in the file into an array of lines
	mut file := os.open(path.path) or { return error('Failed to open file: ${err}') }
	mut lines := os.read_lines(path.path) or {
		return error('Failed to readlines of file at ' + @FN + ' : ${err}')
	}
	file.close()
	// remove lines until '// BEGINNING' is reached
	mut beginning_found := false

	mut count := 0
	outer: for line in lines {
		count += 1
		if line.contains('// BEGINNING') {
			beginning_found = true
			break outer
		}
	}
	mut trimmed_lines := lines.clone()
	if beginning_found == true {
		trimmed_lines = lines[count..lines.len]
	}

	return VAction{
		lines: trimmed_lines
		path:  path
	}
}

// combine all actions in VExecutor into one file
pub fn (mut v_executor VExecutor) compile() ! {
	v_executor.actions << scan_file(mut v_executor.final_file_path) or {
		return error('Failed to scan file at ' + @FN + ' : ${err}')
	}

	mut all_lines := []string{}
	for action in v_executor.actions {
		for line in action.lines {
			all_lines << line
		}
	}

	for line in all_lines {
		v_executor.execution_file.writeln(line) or {
			return error('Failed to write line to execution file at ' + @FN + ' : ${err}')
		}
	}

	v_executor.execution_file.close()
}

// Executes the file
pub fn (mut v_executor VExecutor) do() ! {
	console.print_debug('v run ${v_executor.execution_file_path.path}')
	result := os.execute('v run ${v_executor.execution_file_path.path}')
	console.print_debug('Exit Code: ${result.exit_code}')
	if result.exit_code != 0 {
		console.print_debug(result)
		return error('Failed to run executor file! There are issues with the code.')
	}
}

// prints out all the file paths accessed
pub fn (mut v_executor VExecutor) info() {
	for action in v_executor.actions {
		console.print_debug('action_path: ${action.path.path}')
	}
}

// Cleans up VExecutors impact on the file system
pub fn (mut v_executor VExecutor) clean() ! {
	os.rm(v_executor.execution_file_path.path) or {
		return error('Failed to delete execution file at ' + @FN + ' : ${err}')
	}
}
