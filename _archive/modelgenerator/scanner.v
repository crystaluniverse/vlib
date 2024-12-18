module modelgenerator

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.data.params

enum ParserState {
	init
	modelfound
	fields
}

fn new(path_in string, path_out string) !CodeGenerator {
	mut path_in2 := pathlib.get_dir(path_in, false)!
	mut path_out2 := pathlib.get_dir(path_out, true)!
	return CodeGenerator{
		path_in:  path_in2
		path_out: path_out2
	}
}

pub fn (mut generator CodeGenerator) scan() ! {
	generator.scan_domains(mut generator.path_in)!
}

// look for domains
fn (mut generator CodeGenerator) scan_domains(mut p pathlib.Path) ! {
	$if debug {
		println(' - codegenerator scan domain ${p.path}')
	}
	mut llist := p.list(recursive: false)!
	for mut p_in in llist {
		p_name := texttools.name_fix(p_in.name())
		if p_name.starts_with('.') || p_name.starts_with('_') {
			continue
		}
		if p_in.is_dir() && p_name.starts_with('domain_') {
			name := p_name.all_after_first('_')
			mut domain := Domain{
				path: p_in
				name: name
			}
			generator.domains << &domain
			generator.scan_actors(mut p_in, mut &domain)!
		}
	}
}

// look for actors
fn (mut generator CodeGenerator) scan_actors(mut p pathlib.Path, mut domain Domain) ! {
	$if debug {
		println(' - codegenerator scan actor ${p.path}')
	}
	mut llist := p.list(recursive: false)!
	for mut p_in in llist {
		p_name := texttools.name_fix(p_in.name())
		if p_name.starts_with('.') || p_name.starts_with('_') {
			continue
		}
		if p_in.is_dir() && p_name.starts_with('actor_') {
			name := p_name.all_after_first('_')
			mut actor := Actor{
				path: p_in
				name: name
			}
			domain.actors << &actor
			generator.scan_models(mut p_in, mut &domain, mut &actor)!
		}
	}
}

fn (mut generator CodeGenerator) scan_models(mut p pathlib.Path, mut domain Domain, mut actor Actor) ! {
	$if debug {
		println(' - codegenerator scan models ${p.path}')
	}
	p_name := p.name()
	if p_name.starts_with('.') || p_name.starts_with('_') {
		return
	}
	if p.is_dir() {
		mut llist := p.list(recursive: false)!
		// make sure we walk sorted
		mut names := []string{}
		for mut item in llist {
			names << item.name()
		}
		names.sort()
		mut sortedlist := []pathlib.Path{}
		for name in names {
			mut p2 := p.file_get(name)!
			sortedlist << p2
		}

		for mut p_in in sortedlist {
			generator.scan_models(mut p_in, mut &domain, mut &actor)!
		}
	} else {
		// now we get the paths in order, here it should be a file
		generator.parse(mut p, mut &domain, mut &actor)!
	}
}

fn (mut generator CodeGenerator) parse(mut p pathlib.Path, mut domain Domain, mut actor Actor) ! {
	$if debug {
		println(' - codegenerator model: parse: ${p.path} \n     for domain:${domain.name} for actor:${actor.name}')
	}
	mut model_last := Model{}
	content := p.read()!
	mut parserstate := ParserState.init
	mut ispub := false
	mut ismut := false
	mut comments := []string{}
	mut imports := []string{}
	for mut line in content.split_into_lines() {
		// println(" -- $line $parserstate commentslen:${comments.len}")
		if line.starts_with('//') {
			comments << line.all_after_first('//').trim_space()
		}
		if line.starts_with('import ') {
			imports << line
		}
		if line.starts_with('[root') {
			// example [root ; domain:'generic' ; actor:'usermanager' ; features:'remarks,timestamps,tags,guid' ; index:'tags,name']
			line = line.all_after_first('root').all_before_last(']').replace(';', '')
			mut params := paramsparser.parse(line)!
			model_last = Model{
				root: true
			}
			if params.exists('inherit') {
				model_last.inherit = params.get('inherit')!
			}
			parserstate = .modelfound
			continue
		}
		if parserstate == .init {
			if line.contains('struct ') {
				// found non root model
				model_last = Model{
					root: false
				}
				parserstate = .modelfound
			}
		}
		if parserstate == .modelfound {
			if !(line.contains('struct ')) {
				return error('Should find struct on next line after rootobj def, but didnt.\n${line}\nIN:\n${content}')
			}
			if !(model_last.name == '') {
				panic('bug needs to be empty')
			}
			model_last.name = line.all_after_first('struct ').all_before('{').trim_space()
			model_last.name_lower = texttools.name_fix(model_last.name)
			// check model exists
			if actor.model_find(model_last.name_lower).len > 0 {
				return error('duplicate model name: ${model_last}')
			}
			parserstate = .fields
			continue
		}
		if parserstate == .fields {
			if (line.contains('pub') || line.contains('mut')) && (line.trim_space().ends_with(':')) {
				// means we need to set the pub & mut
				ispub = line.contains('pub')
				ismut = line.contains('mut')
				continue
			}
			if line.trim_space().starts_with('}') {
				// FINISH THE OBJECT
				model_last.comments = comments
				model_last.domain = domain.name
				model_last.actor = actor.name
				model_last.path = p
				model_last.imports = imports
				comments = []string{}
				actor.models << &model_last
				model_last = Model{}
				parserstate = .init
				continue
			}
			mut field := Field{
				ismut: ismut
				ispub: ispub
			}
			line = line.trim_space()
			line = line.replace('\t', ' ').replace('  ', ' ').replace('  ', ' ').replace('  ',
				' ')
			parts := line.split(' ')
			if parts.len < 2 {
				return error('not enough parts in: \n${parts}\n${line}\nIN:\n${content}')
			}
			field.name = parts[0]
			field.name_lower = texttools.name_fix(field.name)
			field.typestr = parts[1]
			line = parts[2..].join(' ') // needed to go after the type and then see for rest of line
			if line.contains('//') {
				field.comments = line.all_after_first('//')
			}
			if line.contains('[') {
				if !(line.contains(']')) {
					return error('Found [ but no ] in: \n${line}\nIN:\n${content}')
				}
				// means we have [...] part
				tags := line.all_after_first('[').all_before_last(']').replace(';', '')
				mut params := paramsparser.parse(tags)!
				field.tag = params.exists('tag')
				field.index = params.exists('index')
				field.strskip = params.exists('strskip')
				if params.exists('model') {
					field.modellocation = params.get('model')!
				}
				if line.contains('str: skip') || line.contains('str:skip') {
					field.strskip = true
				}
			}
			model_last.fields << field
		}
	}
}

fn (mut generator CodeGenerator) process() ! {
	for mut domain in generator.domains {
		for mut actor in domain.actors {
			for mut model in actor.models {
				// resolve the inherited models
				if model.inherit.len > 0 {
					mut modelinherit := actor.model_get_priority(mut generator, mut domain,
						model.inherit)! // will look over multiple levels to find it
					for field in modelinherit.fields {
						// always needs to be inserted at beginning, this to minimize chance on corruption
						model.fields.prepend(field)
					}
					for toimport in modelinherit.imports {
						// always needs to be inserted at beginning, this to minimize chance on corruption
						model.imports.prepend(toimport)
					}
				}
				// resolve the linked models & other types
				for mut field in model.fields {
					field.crtype = generator.typerecognizer(mut domain, mut actor, field)!
				}
			}
		}
	}
}
