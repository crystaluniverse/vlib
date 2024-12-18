module caddy

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.servers.caddy.security
import freeflowuniverse.crystallib.servers.caddy.http
import freeflowuniverse.crystallib.osal
import arrays
import json

// Functions for common directives
pub fn (mut file CaddyFile) add_reverse_proxy(args http.ReverseProxy) ! {
	file.apps.http.add_reverse_proxy(args)!
}

pub fn (mut file CaddyFile) add_file_server(args http.FileServer) ! {
	file.apps.http.add_file_server(args)!
}

pub fn (mut file CaddyFile) add_basic_auth(args http.BasicAuth) ! {
	file.apps.http.add_basic_auth(args)!
}

pub fn (mut file CaddyFile) add_oauth(config security.OAuthConfig) ! {
	file.apps.security.add_oauth(config)!
}

pub fn (file CaddyFile) export(path_ string) ! {
	// Load the existing file and merge it with the current instance
	mut path := path_
	if !path.ends_with('.json') {
		path = '${path}.json'
	}
	mut existing_file := pathlib.get_file(
		path:   path
		create: true
	)!

	caddyfile_json := existing_file.read()!

	merged_file := if caddyfile_json != '' {
		existing_object := json.decode(CaddyFile, caddyfile_json) or { panic(err) }
		merge_caddyfiles(existing_object, file)
	} else {
		file
	}

	content := json.encode(merged_file)

	validate(text: content) or { return error('Caddyfile is not valid\n${err}') }
	mut json_file := pathlib.get_file(path: path)!
	json_file.write(content)!
}

pub struct ValidateArgs {
pub:
	text string
	path string
}

pub fn validate(args ValidateArgs) ! {
	if args.text != '' && args.path != '' {
		return error('either text or path is required to validate caddyfile, cant be both')
	}
	if args.text != '' {
		job := osal.exec(
			cmd: "echo '${args.text.trim_space()}' | caddy validate --config -"
		)!
		if job.exit_code != 0 || !job.output.trim_space().ends_with('Valid configuration') {
			return error(job.output)
		}
		return
	}
	return error('either text or path is required to validate caddyfile')
}

pub fn merge_caddyfiles(file1 CaddyFile, file2 CaddyFile) CaddyFile {
	apps := Apps{
		http: http.merge_http(file1.apps.http, file2.apps.http)
	}

	return CaddyFile{
		apps: apps
	}
}
