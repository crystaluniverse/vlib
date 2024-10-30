module data

import freeflowuniverse.crystallib.core.pathlib

fn test_process_link() {
	mut page1_path := pathlib.get_file(path: '/tmp/page1', create: true)!
	page1_content := '[some page description](col1:page1.md)\n![some other page desc](col2:img.png)'
	page1_path.write(page1_content)!
	mut page1 := new_page(name: 'page1', path: page1_path, collection_name: 'col1')!

	paths := {
		'col1:page1.md': 'col1/page1.md'
		'col2:img.png':  'col2/img/img.png'
	}

	notfound := page1.process_links(paths)!
	assert notfound.len == 0

	assert page1.get_markdown()! == '[some page description](./page1.md)\n![some other page desc](../col2/img/img.png)'
}
