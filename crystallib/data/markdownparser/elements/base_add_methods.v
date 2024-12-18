module elements

pub fn (mut base DocBase) paragraph_new(mut docparent ?&Doc, content string) &Paragraph {
	mut a := Paragraph{
		content:     content
		type_name:   'paragraph'
		parent_doc_: docparent
	}

	base.children << a
	return &a
}

pub fn (mut base DocBase) action_new(mut docparent ?&Doc, content string) &Action {
	mut a := Action{
		content:     content
		type_name:   'action'
		parent_doc_: docparent
	}
	base.children << a
	return &a
}

pub fn (mut base DocBase) table_new(mut docparent ?&Doc, content string) &Table {
	mut a := Table{
		content:     content
		type_name:   'table'
		parent_doc_: docparent
	}

	base.children << a
	return &a
}

pub fn (mut base DocBase) header_new(mut docparent ?&Doc, content string) &Header {
	mut a := Header{
		content:     content
		type_name:   'header'
		parent_doc_: docparent
	}

	base.children << a
	return &a
}

pub fn (mut base DocBase) list_new(mut docparent ?&Doc, content string) !&List {
	mut a := List{
		type_name:   'list'
		parent_doc_: docparent
	}
	a.add_list_item(content)!

	base.children << a

	return &a
}

pub fn (mut base DocBase) list_item_new(mut docparent ?&Doc, content string) &ListItem {
	mut a := ListItem{
		content:     content
		type_name:   'listitem'
		parent_doc_: docparent
	}
	a.process() or { panic(err) }
	base.children << a
	return &a
}

pub fn (mut base DocBase) text_new(mut docparent ?&Doc, content string) &Text {
	mut a := Text{
		content:     content
		type_name:   'text'
		parent_doc_: docparent
	}
	// a.trailing_lf = false
	base.children << a
	return &a
}

pub fn (mut base DocBase) empty_new() &Empty {
	mut a := Empty{}
	// a.trailing_lf = false
	base.children << a
	return &a
}

pub fn (mut base DocBase) comment_new(mut docparent ?&Doc, content string) &Comment {
	mut a := Comment{
		content:     content
		type_name:   'comment'
		parent_doc_: docparent
	}

	base.children << a
	return &a
}

pub fn (mut base DocBase) codeblock_new(mut docparent ?&Doc, content string) &Codeblock {
	mut a := Codeblock{
		content:     content
		type_name:   'codeblock'
		parent_doc_: docparent
	}

	base.children << a
	return &a
}

pub fn (mut base DocBase) frontmatter_new(mut docparent ?&Doc, content string) &Frontmatter {
	mut fm := Frontmatter{
		content:     content
		type_name:   'frontmatter'
		parent_doc_: docparent
	}

	base.children << fm
	return &fm
}

pub fn (mut base DocBase) link_new(mut docparent ?&Doc, content string) &Link {
	mut a := Link{
		content:   content
		type_name: 'link'
		// trailing_lf: false
		parent_doc_: docparent
	}
	// a.trailing_lf = false
	base.children << a
	return &a
}

pub fn (mut base DocBase) html_new(mut docparent ?&Doc, content string) &Html {
	mut a := Html{
		content:     content
		type_name:   'html'
		parent_doc_: docparent
	}

	base.children << a
	return &a
}

pub fn (mut base DocBase) def_new(mut docparent ?&Doc, content string) &Def {
	mut a := Def{
		content:   content
		type_name: 'def'
		// trailing_lf: false
		parent_doc_: docparent
	}
	base.children << a
	return &a
}
