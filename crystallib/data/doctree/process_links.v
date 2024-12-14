module doctree

pub fn (mut tree Tree) process_links() ! {
	file_paths := tree.generate_paths()!
	for _, mut c in tree.collections {
		for _, p in c.pages {
			not_found := p.process_links(file_paths)!
			for pointer_str in not_found {
				ptr := pointer.pointer_new(text: pointer_str)!
				c.error(error_pointer_not_found(ptr))
			}
		}
	}

}