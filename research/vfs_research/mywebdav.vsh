#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.vfs.webdav
import freeflowuniverse.crystallib.core.pathlib
import time
import net.http
import encoding.base64
import os

file_name := 'newfile.txt'
root_dir := '/tmp/webdav'

username := "admin"
password := "1234"
base64_encoded_creds := base64.encode_str('${username}:${password}')

mut server := webdav.new_app(root_dir: root_dir, user_db: {username: password}) or {
  eprintln('failed to create new server: ${err}')
  exit(1)
}

//server.run(spawn_: true)
server.run()

//server.user_add(name:'admin',passw:'1234')!

time.sleep(500 * time.millisecond)


// get file
mut p := pathlib.get_file(path: '${root_dir}/${file_name}', create: true)!
p.write('my new file')!
mut req := http.new_request(.get, 'http://localhost:${server.server_port}/${file_name}','')
req.add_custom_header('Authorization', 'Basic ${base64_encoded_creds}')!
mut response := req.do()!
assert response.body == 'my new file'

// create/update file
data2 := 'newdata'
req = http.new_request(.put, 'http://localhost:${server.server_port}/${file_name}', data2)
req.add_custom_header('Authorization', 'Basic ${base64_encoded_creds}')!
response = req.do()!
assert p.read()! == data2

file_name2 := 'newfile2.txt'
// copy file
req = http.new_request(.copy, 'http://localhost:${server.server_port}/${file_name}', '')
req.add_custom_header('Authorization', 'Basic ${base64_encoded_creds}')!
req.add_custom_header('Destination', 'http://localhost:${server.server_port}/${file_name2}')!
response = req.do()!
mut p2 := pathlib.get_file(path: '${root_dir}/${file_name2}')!
assert p2.read()! == data2

// move file
file_name3 := 'newfile3.txt'
req = http.new_request(.move, 'http://localhost:${server.server_port}/${file_name2}', '')
req.add_custom_header('Authorization', 'Basic ${base64_encoded_creds}')!
req.add_custom_header('Destination', 'http://localhost:${server.server_port}/${file_name3}')!
response = req.do()!
p2 = pathlib.get_file(path: '${root_dir}/${file_name3}')!
assert p2.read()! == data2

// delete file
req = http.new_request(.delete, 'http://localhost:${server.server_port}/${file_name3}', '')
req.add_custom_header('Authorization', 'Basic ${base64_encoded_creds}')!
response = req.do()!
assert !p2.exists()


// create directory
dir_name := 'newdir'
req = http.new_request(.mkcol, 'http://localhost:${server.server_port}/${dir_name}', '')
req.add_custom_header('Authorization', 'Basic ${base64_encoded_creds}')!
response = req.do()!
assert os.exists('${root_dir}/${dir_name}')
