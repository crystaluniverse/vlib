// make sure that the names are always normalized so its easy to find them back
module texttools

import os

pub fn email_fix(name string) !string {
	mut name2 := name.to_lower().trim_space()
	if name2.contains('<') {
		name2 = name2.split('<')[1].split('<')[0]
	}
	if !name2.is_ascii() {
		return error('email needs to be ascii, was ${name}')
	}
	if name2.contains(' ') {
		return error('email cannot have spaces, was ${name}')
	}
	return name2
}

// like name_fix but _ becomes space
pub fn name_fix_keepspace(name string) !string {
	mut name2 := name_fix(name)
	name2 = name2.replace('_', ' ')
	return name2
}

// fix string which represenst a tel nr
pub fn tel_fix(name_ string) !string {
	mut name := name_.to_lower().trim_space()
	for x in ['[', ']', '{', '}', '(', ')', '*', '-', '.', ' '] {
		name = name.replace(x, '')
	}
	if !name.is_ascii() {
		return error('email needs to be ascii, was ${name}')
	}
	return name
}

pub fn wiki_fix(content_ string) string {
	mut content := content_
	for _ in 0 .. 5 {
		content = content.replace('\n\n\n', '\n\n')
	}
	content = content.replace('\n\n-', '\n-')
	return content
}

pub fn action_multiline_fix(content string) string {
	if content.trim_space().contains('\n') {
		splitted := content.split('\n')
		mut out := '\n'
		for item in splitted {
			out += '    ${item}\n'
		}
		return out
	}
	return content.trim_space()
}

pub fn name_fix(name string) string {
	name2 := name_fix_keepext(name)
	return name2
}

pub fn name_fix_list(name string) []string {
	name2 := name_fix_keepext(name)
	return name2.split(',').map(it.trim_space()).map(name_fix(it))
}

// get name back keep extensions and underscores, but when end on .md then remove extension
pub fn name_fix_no_md(name string) string {
	name2 := name_fix_keepext(name)
	if name2.ends_with('.md') {
		name3 := name2[0..name2.len - 3]
		return name3
	}
	return name2
}

pub fn name_fix_no_underscore(name string) string {
	mut name2 := name_fix_keepext(name)
	x := name2.replace('_', '')

	return x
}

pub fn name_fix_snake_to_pascal(name string) string {
	x := name.replace('_', ' ')
	p := x.title().replace(' ', '')
	return p
}

pub fn name_fix_dot_notation_to_pascal(name string) string {
	x := name.replace('.', ' ')
	p := x.title().replace(' ', '')
	return p
}

pub fn name_fix_pascal(name string) string {
	name_ := name_fix_snake_to_pascal(name)
	return name_fix_dot_notation_to_pascal(name_)
}

pub fn name_fix_pascal_to_snake(name string) string {
	mut fixed := ''
	for i, c in name {
		if c.is_capital() && i != 0 {
			fixed += '_'
		}
		fixed += c.ascii_str()
	}
	return fixed.to_lower()
}

pub fn name_fix_dot_notation_to_snake_case(name string) string {
	return name.replace('.', '_')
}

// remove underscores and extension
pub fn name_fix_no_underscore_no_ext(name_ string) string {
	return name_fix_keepext(name_).all_before_last('.').replace('_', '')
}

// remove underscores and extension
pub fn name_fix_no_ext(name_ string) string {
	return name_fix_keepext(name_).all_before_last('.').trim_right('_')
}

pub fn name_fix_keepext(name_ string) string {
	mut name := name_.to_lower().trim_space()
	if name.contains('#') {
		old_name := name
		name = old_name.split('#')[0]
	}

	// need to replace . to _ but not the last one (because is ext)
	fext := os.file_ext(name)
	extension := fext.trim('.')
	if extension != '' {
		name = name[..(name.len - extension.len - 1)]
	}

	to_replace_ := '-;:. '
	mut to_replace := []u8{}
	for i in to_replace_ {
		to_replace << i
	}

	mut out := []u8{}
	mut prev := u8(0)
	for u in name {
		if u == 95 { // underscore
			if prev != 95 {
				// only when previous is not _
				out << u
			}
		} else if u > 47 && u < 58 { // see https://www.charset.org/utf-8
			out << u
		} else if u > 96 && u < 123 {
			out << u
		} else if u in to_replace {
			if prev != 95 {
				out << u8(95)
			}
		} else {
			// means previous one should not be used
			continue
		}
		prev = u
	}
	name = out.bytestr()

	// name = name.trim(' _') //DONT DO final _ is ok to keep
	if extension.len > 0 {
		name += '.${extension}'
	}
	return name
}
