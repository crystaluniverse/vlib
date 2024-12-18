#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.webdav
import freeflowuniverse.crystallib.core.pathlib
import time
import net.http
import encoding.base64

file_name := 'newfile.txt'
root_dir := '/tmp/webdav'

username := 'omda'
password := 'password'
hashed_password := base64.encode_str('${username}:${password}')

mut app := webdav.new_app(root_dir: root_dir, username: username, password: password) or {
	eprintln('failed to create new server: ${err}')
	exit(1)
}

app.run(spawn_: true)

time.sleep(1 * time.second)
mut p := pathlib.get_file(path: '${root_dir}/${file_name}', create: true)!
p.write('my new file')!

mut req := http.new_request(.get, 'http://localhost:${app.server_port}/${file_name}',
	'')
req.add_custom_header('Authorization', 'Basic ${hashed_password}')!
req.do()!
