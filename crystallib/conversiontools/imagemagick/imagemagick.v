module imagemagick

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console

pub struct DownsizeArgs {
pub:
	path       string // can be single file or dir
	backupdir  string
	redo       bool // if you want to check the file again, even if processed
	convertpng bool // if yes will go from png to jpg
}

// struct ScanArgs{
// 	path string //where to start from
// 	backupdir string //if you want a backup dir
// }
// will return the paths of the images which were downsized
pub fn downsize(args DownsizeArgs) ! {
	if !installed() {
		panic('cannot scan because imagemagic not installed.')
	}
	mut path := pathlib.get(args.path)

	mut params_ := paramsparser.Params{}
	if args.backupdir != '' {
		params_.set('backup', args.backupdir)
	}
	if args.redo {
		params_.set('redo', '1')
	}

	if args.convertpng {
		params_.set('convertpng', '1')
	}

	if path.is_dir() {
		path.scan(mut params_, [filter_imagemagic], [executor_imagemagic])!
	} else if path.is_file() {
		executor_imagemagic(mut path, mut params_)!
	} else {
		return error('can only process path or dir')
	}
}

/////////////////

fn installed0() bool {
	// console.print_header(' init imagemagick')
	out := osal.execute_silent('convert -version') or { return false }
	if !out.contains('ImageMagick') {
		return false
	}
	return true
}

// singleton creation
const installed1 = installed0()

pub fn installed() bool {
	// console.print_debug("imagemagick installed: $imagemagick.installed1")
	return installed1
}

fn filter_imagemagic(mut path pathlib.Path, mut params_ paramsparser.Params) !bool {
	// console.print_debug(" - check $path.path")
	// console.print_debug(" ===== "+path.name_no_ext())
	if path.name().starts_with('.') {
		// console.print_debug(" FALSE")
		return false
	} else if path.name().starts_with('_') {
		// console.print_debug(" FALSE")
		return false
	} else if path.name_no_ext().ends_with('_') {
		// console.print_debug(" FALSE")
		return false
	} else if path.is_dir() {
		return true
	} else if !path.is_file() {
		// console.print_debug(" FALSE")
		return false
	} else if !path.is_image_jpg_png() {
		return false
	}
	mut parent := path.parent()!
	// here we check that the file was already processed
	// console.print_debug(" check .done file: ${parent.path}")
	if parent.file_exists('.done') {
		// console.print_debug("DONE")
		mut p := parent.file_get('.done')!
		c := p.read()!
		console.print_debug(' image contains: ${path.name()}')
		if c.contains(path.name()) {
			return false
		}
	}
	// console.print_debug(" TRUE")
	return true
}

fn executor_imagemagic(mut path pathlib.Path, mut params_ paramsparser.Params) !paramsparser.Params {
	if path.is_dir() {
		return params_
	}
	// console.print_debug(' image check ${path.path}')
	mut backupdir := ''
	if params_.exists('backupdir') {
		backupdir = params_.get('backupdir') or { panic(error) }
	}
	mut image := image_new(mut path)
	mut redo := false
	if params_.exists('redo') {
		redo = true
	}
	mut convertpng := false
	if params_.exists('convertpng') {
		convertpng = true
	}
	if backupdir.len > 0 {
		image.downsize(backup: true, backup_dest: backupdir, redo: redo, convertpng: convertpng)!
	} else {
		image.downsize(redo: redo, convertpng: convertpng)!
	}
	return params_
}
