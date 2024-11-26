module gdrive

import freeflowuniverse.crystallib.lang.python
// import  json
import freeflowuniverse.crystallib.core.dbfs
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.pathlib
import os

pub struct GDrive {
pub mut:
	key_path pathlib.Path
	py       python.PythonEnv
}

@[params]
pub struct GDriveNewArgs {
pub mut:
	name  string @[required]
	reset bool
}

pub fn new(args GDriveNewArgs) !GDrive {
	name := args.name

	mut drive := GDrive{}

	mut db := dbfs.new(name: 'gdrive_${name}')! //,encryption:true
	if args.reset {
		db.delete('key')!
	}

	mut key := db.get('key') or { '' }
	if key.len == 0 {
		mut c := console.UIConsole{}
		key_path := c.ask_question(question: 'Path to your json file \n', minlen: 10)
		mut src_key_path := pathlib.get_file(path: key_path)!
		key = src_key_path.read()!
		db.set('key', key)!
	}

	drive.key_path = pathlib.get_file(
		path: '${os.home_dir()}/hero/config/gdrive_key_${name}.json'
		create: true
	)!
	drive.key_path.write(key)!

	drive.py = python.new(name: 'google')! // a python env with name test
	drive.py.pip('google-api-python-client,google-auth-httplib2,google-auth-oauthlib,PyMuPDF,ipython')!

	return drive
}

@[params]
pub struct SlidesGetArgs {
pub mut:
	presentation_id string @[required]
	dest_path       string = '/tmp/slides'
}

pub fn (mut drive GDrive) slides_download(args_ SlidesGetArgs) ! {
	mut args := args_

	mut py := python.new(name: 'google')! // a python env with name test
	cmd := $tmpl('python/slides_get2.py')
	drive.py.exec(cmd: cmd, python_script_name: 'slides_get')!
}
