module docker

import freeflowuniverse.crystallib.osal { file_read }

@[params]
pub struct AddFileEmbeddedArgs {
pub mut:
	source          string // is the filename, needs to be embedded
	dest            string // in the container we're building
	make_executable bool
}

pub struct AddFileEmbeddedItem {
pub mut:
	source          string
	dest            string // in the container we're building
	recipe          &DockerBuilderRecipe @[str: skip]
	make_executable bool
	check_embed     bool = true
}

// to do something like: 'Add alpine:latest'
pub fn (mut b DockerBuilderRecipe) add_file_embedded(args AddFileEmbeddedArgs) ! {
	mut item := AddFileEmbeddedItem{
		source:          args.source
		dest:            args.dest
		make_executable: args.make_executable
		recipe:          &b
	}
	if item.source == '' {
		return error('source cant be empty, \n${b}')
	}
	if item.dest == '' {
		return error('dest cant be empty, \n${b}')
	}
	b.items << item
}

pub fn (mut i AddFileEmbeddedItem) check() ! {
	if i.check_embed == false {
		return
	}
	for fileitem in i.recipe.files {
		filename := fileitem.path.all_after_first('/')
		if filename == i.source {
			return
		}
	}
	return error('Could not find filename: ${i.source} in embedded files. \n ${i}')
}

pub fn (mut i AddFileEmbeddedItem) render() !string {
	mut out := 'ADD ${i.source} ${i.dest}'
	if i.make_executable {
		out += '\nRUN chmod +x ${i.dest}\n'
	}
	return out
}

// get code from the file added
fn (mut i AddFileEmbeddedItem) getcontent() !string {
	srcpath := '${i.recipe.engine.buildpath}/${i.recipe.name}/${i.source}'
	content := file_read(srcpath)!
	return content
}
