#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import vdoc
import os

fn main() {
	mut factory := vdoc.new()
	project_path := os.join_path(os.home_dir(), 'code/github/freeflowuniverse/crystallib/crystallib')

	if !os.exists(project_path) {
		eprintln('Error: Directory does not exist: ${project_path}')
		exit(1)
	}

	println('\nScanning directory: ${project_path}')
	println('-----------------------------------')

	// Process the directory
	factory.scan(project_path) or {
		eprintln('Error scanning directory: ${err}')
		exit(1)
	}

	// Look for specific module
	target_module_path := 'biz/bizmodel'
	mut found := false

	for m in factory.modules {
		if m.path == target_module_path {
			found = true
			println('Found module: ${target_module_path}')
			println('\nModule Details:')
			println('==============\n')
			println(m.str())

			// Save the output to a file
			output_file := 'module_scan_result.txt'
			os.write_file(output_file, m.str()) or {
				eprintln('Error saving to file: ${err}')
				exit(1)
			}
			println('\nResults saved to: ${output_file}')
			break
		}
	}

	if !found {
		println('\nAvailable modules:')
		for m in factory.modules {
			println('- ${m.path}')
		}
		eprintln('Module ${target_module_path} not found!')
		exit(1)
	}
}
