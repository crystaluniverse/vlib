#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.webdav
import freeflowuniverse.crystallib.core.pathlib
import vweb
import time
import net.http
import encoding.base64

root_dir := '/tmp/webdav'
file_name := 'newfile.txt'
hashed_password := base64.encode_str('omda:hashed_password')

app := webdav.new_app(root_dir) or {
	eprintln('failed to create new server: ${err}')
	exit(1)
}

vweb.run(app, 8080)

time.sleep(1 * time.second)
mut p := pathlib.get_file(path: '${root_dir}/${file_name}', create: true)!
p.write('my new file')!

mut req := http.new_request(.get, 'http://localhost:8080/${file_name}', '')
req.add_custom_header('Authorization', 'Basic ${hashed_password}')!
req.do()!
