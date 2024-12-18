module paramsparser

import freeflowuniverse.crystallib.core.texttools
import crypto.sha256
import freeflowuniverse.crystallib.ui.console

struct ParamExportItem {
mut:
	key       string
	value     string
	comment   string
	firstline bool // done by us to know if it still fits on the first line
	isarg     bool
}

fn (mut item ParamExportItem) check() {
	// should not be needed in theory
	item.value = item.value.replace('\\n', '\n').trim_space()
	item.comment = item.comment.replace('\\n', '\n').trim_space()
}

// is to put on first line typically
fn (item ParamExportItem) oneline() string {
	if item.isarg {
		return '${item.key}'
	} else if item.comment.len > 0 && item.value.len == 0 {
		comment := item.comment.replace('\n', '\\n')
		return '//${comment}-/'
	} else {
		txt := '${item.key}:${item.getval()}'
		if item.comment.len > 0 {
			comment := item.comment.replace('\n', '\\n')
			return '//${comment}-/ ${txt}'
		} else {
			return txt
		}
	}
}

fn (item ParamExportItem) getval() string {
	mut val := item.value
	val = val.replace('\n', '\\n')
	if val.contains(' ') || val.contains(':') || val.contains('\\n')
		|| item.key in ['cid', 'oid', 'gid'] {
		val = val.replace('"', "'")
		if val.contains("'") {
			val = val.replace("'", "\\'")
		}
		val = "'${val}'"
	}
	if val == '' {
		// so empty strings are written as empty quotes
		val = "''"
	}
	return val
}

// to put after the first line
fn (item ParamExportItem) afterline() string {
	mut out := ''
	if item.value.contains('\n') {
		if item.comment.len > 0 {
			out += texttools.indent(item.comment, ' // ')
		}
		out += '${item.key}:\'\n'
		out += texttools.indent(item.value, '    ')
		out += "    '"
	} else {
		if item.comment.contains('\n') {
			out += texttools.indent(item.comment, '// ')
		}
		out += '${item.key}:${item.getval()}'
		if item.comment.len > 0 && !item.comment.contains('\n') {
			out += ' //${item.comment}'
		}
	}
	return out.trim_right(' \n')
}

// will first do the args, then the kwargs
// presort means will always come first
fn (p Params) export_helper(args_ ExportArgs) ![]ParamExportItem {
	mut args := args_
	if args.sortdefault && args.presort.len == 0 {
		args.presort = ['id', 'cid', 'gid', 'oid', 'name', 'alias']
	}
	if p.args.len > 0 && args.args_allowed == false {
		return error('args are not allowed')
	}
	mut args_done := []string{}
	mut order := []string{}
	mut order_delayed := []string{}
	mut keys_to_be_sorted := []string{}
	mut keys_existing := []string{}
	mut dict_param := map[string]ParamExportItem{}
	mut result_params := []ParamExportItem{} // the ones who always need to come first
	mut firstlinesize := 0

	// comments are always 1st
	if args.comments_remove == false {
		for comment in p.comments {
			result_params << ParamExportItem{
				key:       ''
				isarg:     false
				comment:   comment
				firstline: args.oneline
			}
		}
	}

	// args are always 2nd
	if args.args_remove == false {
		mut args2 := p.args.clone()
		args2.sort()
		for mut arg in args2 {
			arg = texttools.name_fix(arg)
			if arg in args_done {
				return error('Double arg: ${arg}')
			}
			args_done << arg
			result_params << ParamExportItem{
				key:       arg
				isarg:     true
				comment:   ''
				firstline: true
			}
			firstlinesize += arg.len + 1
		}
	}

	// now we will process the params (comments and args done)
	for param in p.params {
		// skip empty parameter when exporting
		if args.skip_empty && val_is_empty(param.value) {
			continue
		}
		mut key := texttools.name_fix(param.key)
		keys_existing << key
		if key !in args.presort && key !in args.postsort {
			keys_to_be_sorted << key
		}
		dict_param[key] = ParamExportItem{
			key:       key
			value:     param.value
			comment:   param.comment
			firstline: false
		}
	}

	keys_to_be_sorted.sort()
	for key in args.presort.reverse() {
		if key in keys_existing {
			keys_to_be_sorted.prepend(key) // make sure we have the presorted once first
		}
	}
	for key in args.postsort {
		if key in keys_existing {
			keys_to_be_sorted << key // now add the ones at the end
		}
	}

	// now we have all keys sorted	
	for keyname in keys_to_be_sorted {
		param_export_item := dict_param[keyname] // or { panic("bug: can't find $keyname in dict in export/import for params.") }}
		val := param_export_item.value
		// if val.len == 0 {
		// 	continue
		// }		
		if val.len > 25 || param_export_item.comment.len > 0 || firstlinesize > args.maxcolsize
			|| val.contains('\\n') {
			order_delayed << keyname
			continue
		}
		order << keyname
		firstlinesize += keyname.len + val.len + 2
	}

	for key in order {
		mut param_export_item := dict_param[key] // or { panic("bug: can't find $keyname in dict in export/import for params.") }
		param_export_item.check()
		param_export_item.firstline = true
		result_params << param_export_item
	}

	for key in order_delayed {
		mut param_export_item := dict_param[key] // or { panic("bug: can't find $keyname in dict in export/import for params.") }
		param_export_item.check()
		result_params << param_export_item
	}

	return result_params
}

fn val_is_empty(val string) bool {
	return val == '' || val == '[]'
}

@[params]
pub struct ExportArgs {
pub mut:
	presort         []string
	postsort        []string
	sortdefault     bool = true // if set will do the default sorting
	args_allowed    bool = true
	args_remove     bool
	comments_remove bool
	maxcolsize      int = 120
	oneline         bool // if set then will put all on oneline
	multiline       bool = true // if we will put the multiline strings as multiline in output
	indent          string
	pre             string // e.g. can be used to insert action e.g. !!remark.define (pre=prefix on the first line)
	skip_empty      bool
}

// standardised export format .
// .
// it outputs a default way sorted and readable .
//```js
// presort      []string
// postsort     []string
// sortdefault bool = true //if set will do the default sorting
// args_allowed bool = true
// args_remove  bool
// comments_remove bool
// maxcolsize   int = 120
// oneline      bool // if set then will put all on oneline
// multiline    bool = true // if we will put the multiline strings as multiline in output
// indent       string
// pre          string // e.g. can be used to insert action e.g. !!remark.define (pre=prefix on the first line)
//```
pub fn (p Params) export(args ExportArgs) string {
	items := p.export_helper(args) or { panic(err) }
	mut out_pre := []string{}
	mut out := []string{}
	mut out_post := []string{}
	for item in items {
		if args.oneline {
			out << item.oneline()
		} else {
			if item.key == '' && item.comment.len > 0 {
				out_pre << texttools.indent(item.comment, '// ')
				continue
			}
			if item.isarg {
				assert item.comment.len == 0
				out << item.key
				continue
			}
			if item.firstline {
				out << item.oneline()
			} else {
				out_post << '${args.indent}${item.afterline()}'
			}
		}
	}
	mut outstr := ''
	if args.oneline {
		if args.pre.len > 0 {
			outstr += args.pre + ' '
		}
		outstr += out.join(' ')
	} else {
		comments := out_pre.join('\n')
		oneliner := out.join(' ') + '\n'
		poststr := out_post.join('\n')
		if args.pre.len > 0 {
			outstr += comments
			outstr += args.pre + ' ' + oneliner
			outstr += poststr
		} else {
			outstr += comments
			outstr += oneliner
			outstr += poststr
		}
	}
	return outstr
}

pub fn importparams(txt string) !Params {
	return parse(txt)
}

pub fn (p Params) equal(p2 Params) bool {
	a := p.export()
	b := p2.export()
	// console.print_debug("----------------\n$a")
	// console.print_debug("================\n$b")
	// console.print_debug("----------------")
	return a == b
}

// returns a unique sha256 in hex, will allways return the same independent of order of params
pub fn (p Params) hexhash() string {
	a := p.export(oneline: true, multiline: false)
	console.print_debug(a)
	return sha256.hexhash(a)
}
