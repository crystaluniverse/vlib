module macros

import freeflowuniverse.crystallib.core.texttools

fn macro_def(mut state LineProcessorState, mut macro texttools.MacroObj) ? {
	mut categories := macro.params.get_list('category')?
	categories2 := macro.params.get_list('categories')?
	categories << categories2
	mut defname2 := macro.params.get_default('name', '')?
	defname2 = defname2.trim(' ')
	// defname not defined, will get the title as the definition name
	if defname2 == '' {
		defname2 = state.page.title()
	}
	defname2 = defname2.replace('_', ' ')

	if defname2 == '' {
		return error('could not find name of the definition in the page.')
	}

	// state.page.categories_add(categories)

	mut defobj := Def{
		pageid: state.page.id
		name:   defname2
	}

	defid := state.publisher.def_add(defobj)?

	mut aliasses := macro.params.get_list('alias')?
	for alias in aliasses {
		aliasname := texttools.name_fix_no_underscore(alias)
		if aliasname == '' {
			panic("cannot be empty:'${aliasses}'")
		}
		if !state.publisher.def_exists(aliasname) {
			state.publisher.def_names[aliasname] = defid
		}
	}

	defobj.categories_add(categories)

	// if defname2 == "circlesandorganization"{
	// 	println(state.publisher.defs[""])
	// 	panic("sqq")
	// }
	// println(defobj)
}

// check if the def is not excluded or reverse
fn def_list_check(defobj Def, categories []string, exclude []string) bool {
	for cat in defobj.categories {
		if cat in exclude {
			return false
		}
		if cat in categories {
			return true
		}
	}
	if categories == [] {
		return true
	}
	return false
}

fn macro_def_list(mut state LineProcessorState, mut macro texttools.MacroObj) ? {
	mut categories := macro.params.get_list('category')?
	mut exclude := macro.params.get_list('exclude')?
	exclude = exclude.map(texttools.name_fix_no_underscore(it))
	categories = categories.map(texttools.name_fix_no_underscore(it))

	mut out := []string{}
	mut firstletter := ''
	mut firstletter_found := ''

	out << '# Definitions & Concepts'
	out << ''

	mut def_names := []string{}

	for defname, _ in state.publisher.def_names {
		if defname.trim(' ') == '' {
			return error('defname cannot be empty')
		}
		def_names << defname
	}
	def_names.sort()

	mut done := []int{}

	for defname in def_names {
		// println(" >>> $defname")
		defobj := state.publisher.def_get(defname)?
		if defobj.pageid in done {
			continue
		}
		if defobj.hidden {
			continue
		}
		if !def_list_check(defobj, categories, exclude) {
			continue
		}

		// println(state.publisher.defs)
		// println(" >>> $defname ok")
		firstletter_found = defname[0].ascii_str()
		if firstletter_found != firstletter {
			out << ''
			out << '## ${firstletter_found}'
			out << ''
			out << '| def | description |'
			out << '| ---- | ---- |'
			firstletter = firstletter_found
		}
		mut page := state.publisher.page_get_by_id(defobj.pageid) or { panic(err) }

		// site := page.site_get(mut state.publisher) or { panic(err) }

		deftitle := page.title()

		if state.site.name == page.site_name_get(mut state.publisher) {
			out << '| [${defobj.name}](${page.name}.md) | ${deftitle} |'
		}
		done << defobj.pageid
	}

	out << ''

	// content := out.join('\n')	

	state.lines_server << out

	// println(out)

	// println(categories)
	// panic("s")
}
