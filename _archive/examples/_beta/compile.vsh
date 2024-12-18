import freeflowuniverse.crystallib.core.pathlib
import log

dir_path := dir(@FILE)
example_dir := pathlib.get(dir_path)

example_dirs := example_dir.dir_list()!

mut logger := log.Logger(&log.Log{
	level: $if debug { .debug } $else { .info }
})

logger.info('Compiling examples')
for dir in example_dirs {
	logger.debug('Compiling ${dir.name()} examples')
	files := dir.file_list(recursive: true)!
	vfiles := files.filter(it.extension() == 'v')

	for vfile in vfiles {
		logger.debug('Compiling ${vfile.path.trim_string_left(dir_path)}')
		result := execute('v -w ${vfile.path}')
		if result.exit_code == 1 {
			logger.error('Failed to compile: ${result.output.all_before(': error:').all_before(': builder error:')}')
		}
		// logger.debug('Result ${result}')
	}
}
