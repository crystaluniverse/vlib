module pointer

import freeflowuniverse.crystallib.core.texttools

pub enum PointerCat {
	page
	image
	video
	file
	html
}

// links to a page, image or file
pub struct Pointer {
pub mut:
	collection string // is the key of a collection
	name       string // is name without extension, all namefixed (lowercase...)
	cat        PointerCat
	extension  string // e.g. jpg
}

@[params]
pub struct NewPointerArgs {
pub:
	// pointer string (e.g. col:page.md)
	text string
	// used if text does not have collection information
	collection string
}

// will return a clean pointer to a page, image or file
//```
// input is e.g. mycollection:filename.jpg
// 	or filename.jpg
// 	or mypage.md
//
//```
pub fn pointer_new(args NewPointerArgs) !Pointer {
	mut txt := args.text.trim_space().replace('\\', '/').replace('//', '/')

	// take colon parts out
	split_colons := txt.split(':')
	if split_colons.len > 2 {
		return error("pointer can only have 1 ':' inside. ${txt}")
	}

	mut collection_name := args.collection
	mut file_name := ''
	if split_colons.len == 2 {
		collection_name = texttools.name_fix_keepext(split_colons[0].all_after_last('/'))
		file_name = texttools.name_fix_keepext(split_colons[1].all_after_last('/'))
	}

	if collection_name == '' {
		return error('provided args do not have collection information: ${args}')
	}

	if split_colons.len == 1 {
		file_name = texttools.name_fix_keepext(split_colons[0].all_after_last('/'))
	}

	split_file_name := file_name.split('.')
	file_name_no_extension := split_file_name[0]
	mut extension := 'md'
	if split_file_name.len > 1 {
		extension = split_file_name[1]
	}

	mut file_cat := PointerCat.page
	match extension {
		'md' {
			file_cat = .page
		}
		'jpg', 'jpeg', 'svg', 'gif', 'png' {
			file_cat = .image
		}
		'html' {
			file_cat = .html
		}
		'mp4', 'mov' {
			file_cat = .video
		}
		else {
			file_cat = .file
		}
	}

	return Pointer{
		name: file_name_no_extension
		collection: collection_name
		extension: extension
		cat: file_cat
	}
}

pub fn (p Pointer) is_image() bool {
	return p.cat == .image
}

pub fn (p Pointer) is_file_video_html() bool {
	return p.cat == .file || p.cat == .video || p.cat == .html
}

pub fn (p Pointer) str() string {
	return '${p.collection}:${p.name}.${p.extension}'
}
