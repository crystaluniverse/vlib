module imagemagick

import freeflowuniverse.crystallib.core.pathlib

pub struct Image {
pub mut:
	path         pathlib.Path
	size_x       int
	size_y       int
	resolution_x int
	resolution_y int
	size_kbyte   int
	transparent  bool
}

fn (mut image Image) init_() ! {
	if image.size_kbyte == 0 {
		image.size_kbyte = image.path.size_kb() or {
			return error('cannot define size file in kb.\n${err}')
		}
		image.path.path_normalize() or { panic('normalize: ${err}') }
	}
}

pub fn image_new(mut path pathlib.Path) Image {
	mut i := Image{
		path: path
	}
	// i.init_()!
	return i
}

pub fn (mut image Image) is_png() bool {
	if image.path.extension().to_lower() == 'png' {
		return true
	}
	return false
}

fn (mut image Image) skip() bool {
	if image.path.name_no_ext().ends_with('_') {
		// TODO: we need to change the image back without _ at the end (was something we did before)
		return true
	}
	if image.size_kbyte < 500 {
		// console.print_debug("SMALLER  $image.path (size: $image.size_kbyte)")
		return true
	}

	mut parent := image.path.parent() or { panic('bug') }
	// here we check that the file was already processed
	// console.print_debug(" check .done file: ${parent.path}")
	if parent.file_exists('.done') {
		// console.print_debug("DONE")
		mut p := parent.file_get('.done') or { panic('bug') }
		c := p.read() or { panic('bug') }
		// console.print_debug(" image contains: ${path.name()}")
		if c.contains(image.path.name()) {
			return true
		}
	}

	return false
}
