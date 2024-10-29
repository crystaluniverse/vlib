module data

// returns all page def elements (similar to *DEF)
pub fn (mut page Page) get_def_names() ![]string {
	mut defnames := map[string]bool{}
	mut doc := page.doc()!
	for defitem in doc.defpointers() {
		defname := defitem.nameshort
		defnames[defname] = true
	}

	return defnames.keys()
}

// removes the def content, and generates a link to the page
pub fn (mut page Page) set_def_links(def_data map[string][]string) ! {
	mut doc := page.doc()!
	for mut defitem in doc.defpointers() {
		defname := defitem.nameshort

		v := def_data[defname] or { continue }
		if v.len != 2 {
			return error('invalid def data length: expected 2, found ${v.len}')
		}

		defitem.pagekey = v[0]
		defitem.pagename = v[1]

		defitem.process_link()!
	}

	doc.process()!
	page.changed = true
}
