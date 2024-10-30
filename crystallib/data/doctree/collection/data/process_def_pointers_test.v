module data

import freeflowuniverse.crystallib.core.pathlib
import rand

fn test_process_def_pointers() {
	// create a page with def pointers to two different pages
	// set def links on page.
	// processed page should have links to the other two pages
	mut page1_path := pathlib.get_file(path: '/tmp/page1', create: true)!
	alias1, alias2 := rand.string(5).to_upper(), rand.string(5).to_upper()
	page1_content := '*${alias1}\n*${alias2}'
	page1_path.write(page1_content)!
	mut page1 := new_page(name: 'page1', path: page1_path, collection_name: 'col1')!

	mut defs := map[string][]string{}
	defs['${alias1.to_lower()}'] = ['col2:page2', 'page2 alias']
	defs['${alias2.to_lower()}'] = ['col3:page3', 'my page3 alias']

	page1.set_def_links(defs)!

	assert page1.get_markdown()! == '[page2 alias](col2:page2.md)\n[my page3 alias](col3:page3.md)'
}
