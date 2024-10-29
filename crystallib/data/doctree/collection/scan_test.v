module collection

import freeflowuniverse.crystallib.core.pathlib

fn test_add_page_success() {
	/*
		create collection
		add page
		check page in collection
	*/

	mut col := Collection{
		name: 'col1'
		path: pathlib.get('/tmp/col1')
	}

	mut page1_path := pathlib.get_file(path: '/tmp/col1/page1.md', create: true)!
	col.add_page(mut page1_path)!
	assert col.page_exists('page1')

	mut page2_path := pathlib.get_file(path: '/tmp/col1/page:hamada.md', create: true)!
	col.add_page(mut page2_path)!
	assert col.page_exists('page_hamada')
}

fn test_add_page_already_exists() {
	/*
		create collection
		add page with path /tmp/col1/page1.md
		add page with path /tmp/col1/dir/page1.md
		second add should fail and error reported to collection errors
	*/

	mut col := Collection{
		name: 'col1'
		path: pathlib.get('/tmp/col1')
	}

	mut page1_path := pathlib.get_file(path: '/tmp/col1/page1.md', create: true)!
	col.add_page(mut page1_path)!
	assert col.page_exists('page1')

	mut page2_path := pathlib.get_file(path: '/tmp/col1/dir1/page1.md', create: true)!
	col.add_page(mut page2_path)!

	assert col.errors.len == 1
	assert col.errors[0].msg == "Can't add /tmp/col1/dir1/page1.md: a page named page1 already exists in the collection"
}

fn test_add_image_success() {
	mut col := Collection{
		name: 'col1'
		path: pathlib.get('/tmp/col1')
	}

	mut page1_path := pathlib.get_file(path: '/tmp/col1/image.png', create: true)!
	col.add_image(mut page1_path)!
	assert col.image_exists('image')

	mut page2_path := pathlib.get_file(path: '/tmp/col1/image:2.jpg', create: true)!
	col.add_image(mut page2_path)!
	assert col.image_exists('image_2')
}

fn test_add_file_success() {
	mut col := Collection{
		name: 'col1'
		path: pathlib.get('/tmp/col1')
	}

	mut page1_path := pathlib.get_file(path: '/tmp/col1/file1.html', create: true)!
	col.add_file(mut page1_path)!
	assert col.file_exists('file1')

	mut page2_path := pathlib.get_file(path: '/tmp/col1/file:2.mp4', create: true)!
	col.add_file(mut page2_path)!
	assert col.file_exists('file_2')
}

fn test_file_image_remember() {
	mut col := Collection{
		name: 'col1'
		path: pathlib.get('/tmp/col1')
	}

	mut file1_path := pathlib.get_file(path: '/tmp/col1/image.png', create: true)!
	col.file_image_remember(mut file1_path)!
	assert col.image_exists('image')

	mut file2_path := pathlib.get_file(path: '/tmp/col1/file.html', create: true)!
	col.file_image_remember(mut file2_path)!
	assert col.file_exists('file')

	mut file3_path := pathlib.get_file(path: '/tmp/col1/file2.unknownext', create: true)!
	col.file_image_remember(mut file3_path)!
	assert col.file_exists('file2')
}

fn test_scan_directory() {
	mut file := pathlib.get_file(path: '/tmp/mytree/dir1/.collection', create: true)!
	file.write('name:col1')!
	file = pathlib.get_file(path: '/tmp/mytree/dir1/file1.md', create: true)!
	file = pathlib.get_file(path: '/tmp/mytree/dir1/file2.html', create: true)!
	file = pathlib.get_file(path: '/tmp/mytree/dir1/file3.png', create: true)!
	file = pathlib.get_file(path: '/tmp/mytree/dir1/dir2/file4.md', create: true)!
	file = pathlib.get_file(path: '/tmp/mytree/dir1/.shouldbeskipped', create: true)!
	file = pathlib.get_file(path: '/tmp/mytree/dir1/_shouldbeskipped', create: true)!

	mut col := Collection{
		name: 'col1'
		path: pathlib.get('/tmp/mytree/dir1')
	}

	col.scan()!
	assert col.page_exists('file1')
	assert col.file_exists('file2')
	assert col.image_exists('file3')
	assert col.page_exists('file4')
	assert !col.file_exists('.shouldbeskipped')
	assert !col.file_exists('_shouldbeskipped')
}
