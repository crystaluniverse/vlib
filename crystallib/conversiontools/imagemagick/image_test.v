import freeflowuniverse.crystallib.conversiontools.imagemagick { image_new }
import freeflowuniverse.crystallib.core.pathlib
import os

const testpath = os.dir(@FILE) + '/example'

// fn testsuite_begin() {
// 	os.rmdir_all(testpath) or {}
// 	assert !os.is_dir(testpath)
// 	os.mkdir_all(testpath) or {panic(err)}
// }

// fn testsuite_end() {
// 	os.rmdir_all(testpath) or {}
// }

fn test_init_() {
	mut img_path := pathlib.get('${testpath}/small_png.png')
	mut image := image_new(mut img_path)

	assert image.path.path == img_path.path
	assert image.size_kbyte == 0
	image.init_() or { panic('Could not initialize image: ${err}') }
	assert image.size_kbyte == 175
}
