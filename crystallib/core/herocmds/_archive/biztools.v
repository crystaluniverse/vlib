module herocmds

import os
// import freeflowuniverse.crystallib.biz.bizmodel
import cli { Command, Flag }

// const wikipath = os.dir(@FILE) + '/wiki'

pub fn cmd_biztools(mut cmdroot Command) {
	mut cmd_run := Command{
		name:          'bizmodel'
		description:   'Run a bizmodel simulation.'
		usage:         '-s ~/mymodels/greenworld/mybook -i ~/mymodels/greenworld/wiki  -o /tmp/outputdir'
		required_args: 0
		execute:       cmd_biztools_execute
	}

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'summarydir'
		abbrev:      's'
		description: 'location of the summary file, if not specified will try current dir, if not current dir will try inputdir.'
	})

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'outputdir'
		abbrev:      'o'
		description: 'where the html will be generated, is optional, default: /tmp/bizmodel/output'
	})

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'inputdir'
		abbrev:      'i'
		description: 'path to the playbooks, can be more than 1, if not specifieds is current dir.'
	})

	cmdroot.add_command(cmd_run)
}

fn cmd_biztools_execute(cmd Command) ! {
	// mut inputdir := cmd.flags.get_string('inputdir') or { '' }

	// mut summarydir := cmd.flags.get_string('summarydir') or { '' }
	// if summarydir == '' {
	// 	if inputdir != '' {
	// 		for t in ['${inputdir}/summary.md', '${inputdir}/Summary.md'] {
	// 			if os.exists(t) {
	// 				summarydir = inputdir
	// 				break
	// 			}
	// 		}
	// 		''
	// 	}
	// 	for t in ['${os.getwd()}/summary.md', '${os.getwd()}/Summary.md'] {
	// 		if os.exists(t) {
	// 			summarydir = os.getwd()
	// 			break
	// 		}
	// 	}
	// 	''
	// }
	// if summarydir == '' {
	// 	return error("Could not find summary.md in inputdir:'${inputdir}' or currentdir.")
	// }

	// if inputdir == '' {
	// 	if summarydir != '' {
	// 		inputdir = summarydir
	// 	} else {
	// 		inputdir = os.getwd()
	// 	}
	// }

	// outputdir := cmd.flags.get_string('outputdir') or { '/tmp/bizmodel/output' }

	// // mut c := context.new()!

	// mut book := bizmodel.new(
	// 	name: 'example'
	// 	mdbook_name: 'biz_book'
	// 	mdbook_path: summarydir // TODO: need to make sure we support playbooks not to be on same place as summary
	// 	mdbook_dest: outputdir
	// 	path: inputdir
	// )!

	// book.read()! // will generate and open	
}
