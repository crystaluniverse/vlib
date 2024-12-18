module docsorter

import freeflowuniverse.crystallib.ui.console
import os

fn (mut pc DocSorter) slides_process(path string) ! {
	console.print_green('Extract slides from ${path}')

	pdf_path := path
	basedirname := '${os.dir(pdf_path)}'
	slidesdirname := '${os.base(pdf_path).replace('.pdf', '')}'
	output_folder := '${basedirname}/${slidesdirname}'

	cmd := $tmpl('pythonscripts/extract.py')

	mut pyenv := pc.py or { panic('no python env') }
	pyenv.exec(cmd: cmd)!
}
