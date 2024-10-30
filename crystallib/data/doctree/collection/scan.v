module collection

import freeflowuniverse.crystallib.conversiontools.imagemagick
import freeflowuniverse.crystallib.core.pathlib { Path }
import freeflowuniverse.crystallib.data.doctree.pointer
import freeflowuniverse.crystallib.data.doctree.collection.data

// walk over one specific collection, find all files and pages
pub fn (mut collection Collection) scan() ! {
	collection.scan_directory(mut collection.path)!
}

// path is the full path
fn (mut collection Collection) scan_directory(mut p Path) ! {
	mut entry_list := p.list(recursive: false)!
	for mut entry in entry_list.paths {
		if collection.should_skip_entry(mut entry) {
			continue
		}

		if !entry.exists() {
			collection.error(
				path: entry
				msg: 'Entry ${entry.name()} does not exists'
				cat: .unknown
			)!
			continue
		}

		if mut entry.is_link() {
			link_real_path := entry.realpath() // this is with the symlink resolved
			collection_abs_path := collection.path.absolute()
			if entry.extension_lower() == 'md' {
				// means we are linking pages,this should not be done, need or change
				collection.error(
					path: entry
					msg: 'Markdown files (${entry.path}) must not be linked'
					cat: .unknown
				)!
				continue
			}

			if !link_real_path.starts_with(collection_abs_path) {
				// means we are not in the collection so we need to copy
				entry.unlink()! // will transform link to become the file or dir it points too
			} else {
				// TODO: why do we need this?
				entry.relink()! // will check that the link is on the file with the shortest path
			}
		}

		if entry.is_dir() {
			collection.scan_directory(mut entry)!
			continue
		}

		if entry.extension_lower() == '' {
			continue
		}

		match entry.extension_lower() {
			'md' {
				collection.add_page(mut entry)!
			}
			else {
				collection.file_image_remember(mut entry)!
			}
		}
	}
}

fn (mut c Collection) should_skip_entry(mut entry Path) bool {
	entry_name := entry.name()

	// entries that start with . or _ are ignored
	if entry_name.starts_with('.') || entry_name.starts_with('_') {
		return true
	}

	// TODO: why do we skip all these???

	if entry.cat == .linkfile {
		// means we link to a file which is in the folder, so can be loaded later, nothing to do here
		return true
	}

	if entry.is_dir() && entry_name.starts_with('gallery_') {
		return true
	}

	if entry_name.to_lower() == 'defs.md' {
		return true
	}

	if entry_name.contains('.test') {
		return true
	}

	if entry.path.starts_with('sidebar') {
		return true
	}

	return false
}

// remember the file, so we know if we have duplicates
// also fixes the name
fn (mut collection Collection) file_image_remember(mut p Path) ! {
	if collection.heal {
		p.path_normalize()!
	}
	mut ptr := pointer.pointer_new(
		collection: collection.name
		text: p.name()
	)!

	if ptr.is_file_video_html() {
		collection.add_file(mut p)!
		return
	}

	if ptr.is_image() {
		if collection.heal && imagemagick.installed() {
			mut image := imagemagick.image_new(mut p)

			imagemagick.downsize(path: p.path)!
			// after downsize it could be the path has been changed, need to set it on the file
			if p.path != image.path.path {
				p.path = image.path.path
				p.check()
			}
		}

		// TODO: what are we trying to do?
		if !collection.image_exists(ptr.name) {
			collection.add_image(mut p)!
		}

		mut image_file := collection.get_image(ptr.name)!
		mut image_file_path := image_file.path.path
		if p.path.len <= image_file_path.len {
			// nothing to be done, because the already existing file is shortest or equal
			return
		}
		// file double is the one who already existed, need to change the path and can delete original
		// TODO: this is clearly a bug
		image_file.path = image_file.path
		image_file.init()!
		if collection.heal {
			p.delete()!
		}

		return
	}

	return error('unsupported file type: ${ptr.extension}')
}

// add a page to the collection, specify existing path
// the page will be parsed as markdown
pub fn (mut collection Collection) add_page(mut p Path) ! {
	if collection.heal {
		p.path_normalize()!
	}

	mut ptr := pointer.pointer_new(
		collection: collection.name
		text: p.name()
	)!

	// in case heal is true pointer_new can normalize the path
	if collection.page_exists(ptr.name) {
		collection.error(
			path: p
			msg: 'Can\'t add ${p.path}: a page named ${ptr.name} already exists in the collection'
			cat: .page_double
		)!
		return
	}

	new_page := data.new_page(
		name: ptr.name
		path: p
		collection_name: collection.name
	)!

	collection.pages[ptr.name] = &new_page
}

// add a file to the collection, specify existing path
pub fn (mut collection Collection) add_file(mut p Path) ! {
	if collection.heal {
		p.path_normalize()!
	}
	mut ptr := pointer.pointer_new(
		collection: collection.name
		text: p.name()
	)!

	// in case heal is true pointer_new can normalize the path
	if collection.file_exists(ptr.name) {
		collection.error(
			path: p
			msg: 'Can\'t add ${p.path}: a file named ${ptr.name} already exists in the collection'
			cat: .file_double
		)!
		return
	}

	mut new_file := data.new_file(
		path: p
		collection_path: collection.path
		collection_name: collection.name
	)!
	collection.files[ptr.name] = &new_file
}

// add a image to the collection, specify existing path
pub fn (mut collection Collection) add_image(mut p Path) ! {
	if collection.heal {
		p.path_normalize()!
	}
	mut ptr := pointer.pointer_new(
		collection: collection.name
		text: p.name()
	)!

	// in case heal is true pointer_new can normalize the path
	if collection.image_exists(ptr.name) {
		collection.error(
			path: p
			msg: 'Can\'t add ${p.path}: a file named ${ptr.name} already exists in the collection'
			cat: .image_double
		)!
		return
	}

	mut image_file := &data.File{
		path: p
		collection_path: collection.path
	}
	image_file.init()!
	collection.images[ptr.name] = image_file
}
