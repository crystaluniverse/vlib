module taskletmanager

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib

// walk over taslkets, build up structure
pub fn (mut tm TaskletManager) scan() ! {
	tm.scan_domains(mut tm.path)!
}

// look for domains
fn (mut tm TaskletManager) scan_domains(mut p pathlib.Path) ! {
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
			tm.domains[name] = &domain
			tm.scan_actors(mut p_in, mut &domain)!
		}
	}
}

fn (mut tm TaskletManager) scan_actors(mut p pathlib.Path, mut domain Domain) ! {
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
			domain.actors[name] = &actor
			tm.scan_actions(mut p_in, mut &actor)!
		}
	}
}

fn (mut tm TaskletManager) scan_actions(mut p pathlib.Path, mut actor Actor) ! {
	p_name := texttools.name_fix(p.name())
	if p_name.starts_with('.') || p_name.starts_with('_') {
		return
	}
	if p.is_dir() {
		mut llist := p.list(recursive: false)!
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
			tm.scan_actions(mut p_in, mut actor)!
		}
	} else {
		// now we get the paths in order, here it should be a file
		tm.parse_actions(mut p, mut actor)!
	}
}

fn (mut tm TaskletManager) parse_actions(mut p pathlib.Path, mut actor Actor) ! {
	content := p.read()!
	for line in content.split_into_lines() {
		if line.contains(') action_') && line.contains('&TaskletManager') {
			// probably a definition of an action
			mut a := Action{}
			a.namelong = line.all_after_first(')').all_before('(').all_after_first('action_').trim(' ')
			if a.namelong.contains('__') {
				a.instance = a.namelong.all_after_first('__')
				a.name = a.namelong.all_before('__')
			} else {
				a.name = a.namelong
			}
			if a.name !in actor.actions {
				actor.actions[a.name] = []&Action{}
			}
			actor.actions[a.name] << &a
		}
	}
}
