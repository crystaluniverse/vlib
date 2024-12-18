module main

import freeflowuniverse.crystallib.core.openrpc
import freeflowuniverse.crystallib.core.pathlib
import cli { Command, Flag }
import os

fn main() {
	mut cmd := Command{
		name:        'openrpc'
		description: 'OpenRPC Library CLI'
		version:     '1.0.0'
	}
	mut docgen_cmd := Command{
		name:          'docgen'
		description:   'Generates docs for a given OpenRPC Client Module in V'
		usage:         '<client_path>'
		required_args: 1
		execute:       cli_docgen
	}
	docgen_cmd.add_flag(Flag{
		flag:        .string
		required:    true
		name:        'title'
		abbrev:      't'
		description: 'Title of the OpenRPC Document.'
	})
	docgen_cmd.add_flag(Flag{
		flag:          .string
		name:          'version'
		abbrev:        'v'
		default_value: ['1.0.0']
		description:   'OpenRPC Version of the document.'
	})
	docgen_cmd.add_flag(Flag{
		flag:          .string
		name:          'output_path'
		abbrev:        'o'
		default_value: ['.']
		description:   'Path the OpenRPC client will be created at.'
	})
	docgen_cmd.add_flag(Flag{
		flag:        .string
		name:        'description'
		abbrev:      'd'
		description: 'Description of the OpenRPC Document'
	})
	docgen_cmd.add_flag(Flag{
		flag:        .string_array
		name:        'exclude_dirs'
		abbrev:      'ed'
		description: 'Directories to be excluded from source code to generate document from.'
	})
	docgen_cmd.add_flag(Flag{
		flag:        .string_array
		name:        'exclude_files'
		abbrev:      'f'
		description: 'Files to be excluded from source code to generate document from.'
	})
	docgen_cmd.add_flag(Flag{
		flag:        .bool
		name:        'public_only'
		abbrev:      'p'
		description: 'Generates document only from public functions.'
	})

	cmd.add_command(docgen_cmd)
	cmd.setup()
	cmd.parse(os.args)
}

fn cli_docgen(cmd Command) ! {
	config := openrpc.DocGenConfig{
		title:         cmd.flags.get_string('title') or {
			panic('Failed to get `title` flag: ${err}')
		}
		description:   cmd.flags.get_string('description') or {
			panic('Failed to get `description` flag: ${err}')
		}
		version:       cmd.flags.get_string('version') or {
			panic('Failed to get `version` flag: ${err}')
		}
		source:        cmd.args[0]
		exclude_dirs:  cmd.flags.get_strings('exclude_dirs') or {
			panic('Failed to get `exclude_dirs` flag: ${err}')
		}
		exclude_files: cmd.flags.get_strings('exclude_files') or {
			panic('Failed to get `exclude_files` flag: ${err}')
		}
		only_pub:      cmd.flags.get_bool('public_only') or {
			panic('Failed to get `public_only` flag: ${err}')
		}
	}
	doc := openrpc.docgen(config) or { panic('Failed to generate OpenRPC Document.\n${err}') }
	target := cmd.flags.get_string('output_path') or {
		panic('Failed to get `output_path` flag: ${err}')
	}
	doc_str := doc.encode()!

	mut path_ := pathlib.get(target)
	if !path_.exists() {
		return error('Provided target`${target}` does not exist.')
	}
	mut target_path := path_.path + '/openrpc.json'
	if target == '.' {
		target_path = os.getwd() + '/openrpc.json'
	}

	os.write_file(target_path, doc_str)!
}
