module macros

import freeflowuniverse.crystallib.core.texttools

fn macro_alias(mut state LineProcessorState, mut macro texttools.MacroObj) ? {
	if macro.params.args.len < 1 {
		return error('need to have at least 1 alias name (use comma separation).')
	}
	args := macro.params.args[0].value

	aliasses := args.split(',')

	// state.page.categories_add(categories)

	mut defobj := Def{
		pageid: state.page.id
		name:   state.page.name
		hidden: true
	}

	defid := state.publisher.def_add(defobj)?

	for alias in aliasses {
		aliasname := texttools.name_fix_no_underscore(alias)
		if aliasname == '' {
			return error("cannot be empty:'${aliasses}'")
		}
		if !state.publisher.def_exists(aliasname) {
			state.publisher.def_names[aliasname] = defid
		}
	}
}
