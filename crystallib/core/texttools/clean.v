// make sure that the names are always normalized so its easy to find them back
module texttools

const ignore_for_name = '\\/[]()?!@#$%^&*<>:;{}|~'

const keep_ascii = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_-+={}[]"\':;?/>.<,|\\~` '

pub fn name_clean(r string) string {
	mut res := []string{}
	for ch in r {
		mut c := ch.ascii_str()
		if ignore_for_name.contains(c) {
			continue
		}
		res << c
	}
	return res.join('')
}

// remove all chars which are not ascii
pub fn ascii_clean(r string) string {
	mut res := []string{}
	for ch in r {
		mut c := ch.ascii_str()
		if keep_ascii.contains(c) {
			res << c
		}
	}
	return res.join('')
}

// https://en.wikipedia.org/wiki/Unicode#Standardized_subsets

pub fn remove_empty_lines(text string) string {
	mut out := []string{}
	for l in text.split_into_lines() {
		if l.trim_space() == '' {
			continue
		}
		out << l
	}
	return out.join('\n')
}

pub fn remove_double_lines(text string) string {
	mut out := []string{}
	mut prev := true
	for l in text.split_into_lines() {
		if l.trim_space() == '' {
			if prev {
				continue
			}
			out << ''
			prev = true
			continue
		}
		prev = false
		out << l
	}
	if out.len > 0 && out.last() == '' {
		out.pop()
	}
	return out.join('\n')
}

// remove ```??  ``` , can be over multiple lines .
// also removes double lines
pub fn remove_empty_js_blocks(text string) string {
	mut out := []string{}
	mut block_capture_pre := ''
	mut block_capture_inside := []string{}
	mut foundblock := false
	for l in text.split_into_lines() {
		lt := l.trim_space()
		if lt.starts_with('```') || lt.starts_with("'''") || lt.starts_with('"""') {
			if foundblock {
				if block_capture_inside.filter(it.trim_space() != '').len > 0 {
					// now we know the block inside is not empty
					out << block_capture_pre
					out << block_capture_inside
					out << l // the last line
				}
				foundblock = false
				block_capture_pre = ''
				block_capture_inside = []string{}
				continue
			} else {
				foundblock = true
				block_capture_pre = l
				continue
			}
		}
		if foundblock {
			block_capture_inside << l
		} else {
			out << l
		}
	}
	if out.len > 0 && out.last() == '' {
		out.pop()
	}
	return remove_double_lines(out.join('\n'))
}
