module webdav

import net.http
import freeflowuniverse.crystallib.core.pathlib
import time
import encoding.base64

fn test_get() {
	root_dir := '/tmp/webdav'
	mut app := new_app(
		root_dir: root_dir,
		username: 'mario',
		password: 'hashed_password',
	)!
	app.run(spawn_: true)
	time.sleep(1 * time.second)
	file_name := 'newfile.txt'
	mut p := pathlib.get_file(path: '${root_dir}/${file_name}', create: true)!
	p.write('my new file')!

	mut req := http.new_request(.get, 'http://localhost:${app.server_port}/${file_name}', '')
	signature := base64.encode_str("${app.username}:${app.password}")
	req.add_custom_header('Authorization', 'Basic ${signature}')!

	response := req.do()!
	assert response.body == 'my new file'
}

fn test_put() {
	root_dir := '/tmp/webdav'
	mut app := new_app(
		root_dir: root_dir,
		username: 'mario',
		password: 'hashed_password',
	)!
	app.run(spawn_: true)
	time.sleep(1 * time.second)
	file_name := 'newfile_put.txt'

	mut data := 'my new put file'
	mut req := http.new_request(.put, 'http://localhost:${app.server_port}/${file_name}', data)
	signature := base64.encode_str("${app.username}:${app.password}")
	req.add_custom_header('Authorization', 'Basic ${signature}')!
	mut response := req.do()!

	mut p := pathlib.get_file(path: '${root_dir}/${file_name}')!

	assert p.exists()
	assert p.read()! == data

	data = 'updated data'
	req = http.new_request(.put, 'http://localhost:${app.server_port}/${file_name}', data)
	req.add_custom_header('Authorization', 'Basic ${signature}')!
	response = req.do()!

	p = pathlib.get_file(path: '${root_dir}/${file_name}')!

	assert p.exists()
	assert p.read()! == data
}

fn test_copy() {
	root_dir := '/tmp/webdav'
	mut app := new_app(root_dir: root_dir, username: 'mario', password: 'hashed_password')!
	app.run(spawn_: true)

	time.sleep(1 * time.second)
	file_name1, file_name2 := 'newfile_copy1.txt', 'newfile_copy2.txt'
	mut p1 := pathlib.get_file(path: '${root_dir}/${file_name1}', create: true)!
	data := 'file copy data'
	p1.write(data)!

	mut req := http.new_request(.copy, 'http://localhost:${app.server_port}/${file_name1}', '')
	signature := base64.encode_str("${app.username}:${app.password}")
	req.add_custom_header('Authorization', 'Basic ${signature}')!
	req.add_custom_header('Destination', 'http://localhost:${app.server_port}}/${file_name2}')!
	mut response := req.do()!

	assert p1.exists()
	mut p2 := pathlib.get_file(path: '${root_dir}/${file_name2}')!
	assert p2.exists()
	assert p2.read()! == data
}

fn test_move() {
	root_dir := '/tmp/webdav'
	mut app := new_app(root_dir: root_dir, username: 'mario', password: 'hashed_password')!
	app.run(spawn_: true)

	time.sleep(1 * time.second)
	file_name1, file_name2 := 'newfile_move1.txt', 'newfile_move2.txt'
	mut p := pathlib.get_file(path: '${root_dir}/${file_name1}', create: true)!
	data := 'file move data'
	p.write(data)!

	mut req := http.new_request(.move, 'http://localhost:${app.server_port}/${file_name1}', '')
	signature := base64.encode_str("${app.username}:${app.password}")
	req.add_custom_header('Authorization', 'Basic ${signature}')!
	req.add_custom_header('Destination', 'http://localhost:${app.server_port}}/${file_name2}')!
	mut response := req.do()!

	p = pathlib.get_file(path: '${root_dir}/${file_name2}')!
	assert p.exists()
	assert p.read()! == data
}

fn test_delete() {
	root_dir := '/tmp/webdav'
	mut app := new_app(root_dir: root_dir, username: 'mario', password: 'hashed_password')!
	app.run(spawn_: true)

	time.sleep(1 * time.second)
	file_name := 'newfile_delete.txt'
	mut p := pathlib.get_file(path: '${root_dir}/${file_name}', create: true)!

	mut req := http.new_request(.delete, 'http://localhost:${app.server_port}/${file_name}', '')
	signature := base64.encode_str("${app.username}:${app.password}")
	req.add_custom_header('Authorization', 'Basic ${signature}')!
	mut response := req.do()!

	assert !p.exists()
}

fn test_mkcol() {
	root_dir := '/tmp/webdav'
	mut app := new_app(root_dir: root_dir, username: 'mario', password: 'hashed_password')!
	app.run(spawn_: true)

	time.sleep(1 * time.second)
	dir_name := 'newdir'

	mut req := http.new_request(.mkcol, 'http://localhost:${app.server_port}/${dir_name}', '')
	signature := base64.encode_str("${app.username}:${app.password}")
	req.add_custom_header('Authorization', 'Basic ${signature}')!
	mut response := req.do()!

	mut p := pathlib.get_dir(path: '${root_dir}/${dir_name}')!
	assert p.exists()
}

fn test_propfind() {
	root_dir := '/tmp/webdav'
	mut app := new_app(root_dir: root_dir, username: 'mario', password: 'hashed_password')!
	app.run(spawn_: true)

	time.sleep(1 * time.second)
	dir_name := 'newdir'
	file1 := 'file1.txt'
	file2 := 'file2.html'
	dir1 := 'dir1'

	mut p := pathlib.get_dir(path: '${root_dir}/${dir_name}', create: true)!
	mut file1_p := pathlib.get_file(path: '${p.path}/${file1}', create: true)!
	mut file2_p := pathlib.get_file(path: '${p.path}/${file2}', create: true)!
	mut dir1_p := pathlib.get_dir(path: '${p.path}/${dir1}', create: true)!

	mut req := http.new_request(.propfind, 'http://localhost:${app.server_port}/${dir_name}', '')
	signature := base64.encode_str("${app.username}:${app.password}")
	req.add_custom_header('Authorization', 'Basic ${signature}')!
	mut response := req.do()!

	assert response.status_code == 207
}
