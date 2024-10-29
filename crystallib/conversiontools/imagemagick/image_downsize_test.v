import freeflowuniverse.crystallib.conversiontools.imagemagick { image_new }
import freeflowuniverse.crystallib.core.pathlib
import os
import freeflowuniverse.crystallib.ui.console

const testpath = os.dir(@FILE) + '/example'

// fn testsuite_begin() {
// 	os.rmdir_all(testpath) or {}
// 	assert !os.is_dir(testpath)
// 	os.mkdir_all(testpath) or {panic(err)}
// }

// fn testsuite_end() {
// 	os.rmdir_all(testpath) or {}
// }

fn test_image_downsize() {
	mut img_path := pathlib.get('${testpath}/large_png.png')
	mut image := image_new(mut img_path)
	image.init_() or { panic('Could not initialize image: ${err}') }
	assert image.size_kbyte > 600

	mut image_org := image
	image.downsize(backup: true) or { panic('Cannot downsize image: ${image} \n ${err}') }
	// test correct file renaming
	assert image.size_kbyte < image_org.size_kbyte
	assert image.path.name_no_ext() == '${image_org.path.name_no_ext()}_'
	// console.print_debug(image.path.name())

	// now need to put original file back
	image_org.path.restore(overwrite: true)!
	image.path.delete()!
}

// fn downsize_test() {
// 	img_path := pathlib.get('$testpath/small_png.png')
// 	image := image_new(img_path)
// }
