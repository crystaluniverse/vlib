module codemodel

pub struct Import {
pub mut:
	mod   string
	types []string
}

pub fn (mut i Import) add_types(types []string) {
	i.types << types.filter(it !in i.types)
}

pub fn parse_import(code_ string) Import {
	code := code_.trim_space().trim_string_left('import').trim_space()
	types_str := if code.contains(' ') { code.all_after(' ').trim('{}') } else { '' }
	return Import{
		mod:   code.all_before(' ')
		types: if types_str != '' {
			types_str.split(',').map(it.trim_space())
		} else {
			[]string{}
		}
	}
}
