import freeflowuniverse.crystallib.core.pathlib { Path }
import freeflowuniverse.crystallib.ui.console
import os

const testpath = os.dir(@FILE) + '/examples/test_path'

fn testsuite_begin() {
	console.print_debug('create files for link test')
	os.rmdir_all(os.dir(@FILE) + '/examples') or {}
	assert !os.is_dir(testpath)
	os.mkdir_all(testpath) or { panic(err) }
	os.mkdir_all('${testpath}/test_parent') or { panic(err) }
	os.create('${testpath}/testfile1.md') or { panic(err) }
	os.create('${testpath}/test_parent/testfile2.md') or { panic(err) }
	os.create('${testpath}/test_parent/testfile3.md') or { panic(err) }
}

fn testsuite_end() {
	os.rmdir_all(os.dir(@FILE) + '/examples') or {}
}

fn test_link() {
	testsuite_begin()
	console.print_stdout('************ TEST_link ************')
	mut source1 := pathlib.get('${testpath}/test_parent/testfile2.md')
	mut source2 := pathlib.get('${testpath}/test_parent/testfile3.md')
	mut source3 := pathlib.get('${testpath}/testfile1.md')

	assert source1.exists()
	assert source2.exists()
	assert source3.exists()

	// link to a parent
	mut link11 := source3.link('${testpath}/test_parent/uplink', true) or {
		panic('no uplink: ${err}')
	}
	mut link11_link := pathlib.get('${testpath}/test_parent/uplink')
	path11 := link11_link.readlink() or { panic(err) }
	assert path11 == '../testfile1.md'

	// test delete exists with nonexistent dest
	mut dest := pathlib.get('${testpath}/test_link.md')
	assert !dest.exists()
	mut link1 := source1.link(dest.path, true) or { panic('no link: ${err}') }
	assert link1.path == '${testpath}/test_link.md'
	dest = pathlib.get('${testpath}/test_link.md')
	assert dest.exists()

	// test delete exists with existing dest
	assert dest.realpath() == source1.path
	mut link2 := source2.link(dest.path, true) or { panic('no link ${err}') }
	assert link2.path == '${testpath}/test_link.md'
	assert link2.realpath() != source1.path
	assert link2.realpath() == source2.path

	// test delete_exists false with existing dest
	dest = pathlib.get('${testpath}/test_link.md')
	assert dest.realpath() == source2.path
	mut link3 := source1.link(dest.path, false) or { Path{} }
	assert link3.path == '' // link should error so check empty path obj
	dest = pathlib.get('${testpath}/test_link.md')
	assert dest.realpath() == source2.path // dest reamins unchanged

	dest.delete() or {}
	console.print_stdout('Link function working correctly')
}

fn test_readlink() {
	testsuite_begin()
	console.print_stdout('************ TEST_readlink ************')
	// test with none link path
	mut source := pathlib.get('${testpath}/test_parent/testfile2.md')
	mut dest_ := '${testpath}/test_readlink.md'
	path := source.readlink() or { '' }
	assert path == '' // is not a link so cannot read

	// test with filelink path
	mut link := source.link(dest_, true) or { panic('error: ${err}') }
	mut dest := pathlib.get(dest_)

	assert dest.cat == .linkfile
	assert dest.path == dest_

	link_source := dest.readlink() or { panic(err) }
	assert link_source == 'test_parent/testfile2.md'

	dest.delete() or {}
	console.print_stdout('Readlink function working correctly')
}

// fn test_unlink() {
// 	console.print_stdout('************ TEST_unlink ************')
// 	// test with filelink path

// 	mut source := pathlib.get('${testpath}/test_parent/testfile3.md')
// 	mut dest_ := '${testpath}/test_unlink.md'

// 	mut link := source.link(dest_, true) or { panic('error: ${err}') }
// 	mut dest := pathlib.get(dest_)

// 	// TODO: check if content is from source

// 	assert dest.cat == .linkfile
// 	dest.unlink() or { panic('Failed to unlink: ${err}') }
// 	assert dest.exists()
// 	assert dest.cat == .file

// 	dest.delete()!

// 	// TODO: maybe more edge cases?
// 	console.print_stdout('Unlink function working correctly')
// }

fn test_relink() {
	testsuite_begin()
	console.print_stdout('************ TEST_relink ************')

	mut source := pathlib.get('${testpath}/test_parent/testfile2.md')
	mut dest_ := '${testpath}/test_relink.md'
	mut link := source.link(dest_, true) or { panic('error: ${err}') }
	mut dest := pathlib.get(dest_)

	// linked correctly so doesn't change
	assert source.cat == .file
	assert dest.cat == .linkfile
	dest.relink() or { panic('Failed to relink: ${err}') }
	source_new := pathlib.get(source.path)
	assert source_new.cat == .file
	assert dest.cat == .linkfile

	// switching source and destination
	mut source2 := pathlib.get(dest_)
	source2.unlink() or { panic('Failed to unlink: ${err}') }
	mut dest2_ := source.path

	// linked incorrectly so should relink
	mut link2 := source2.link(dest2_, true) or { panic('error: ${err}') }
	mut dest2 := pathlib.get(dest2_)
	assert source2.cat == .file
	assert dest2.cat == .linkfile
	dest2.relink() or { panic('Failed to relink: ${err}') }
	source2_new := pathlib.get(source2.path)
	assert source2_new.cat == .linkfile
	assert dest2.cat == .file

	dest.delete()!
}
