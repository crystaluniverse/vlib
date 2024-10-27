module codemodel

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import os

pub struct CodeFile {
pub mut:
	name    string
	mod     string
	imports []Import
	consts  []Const
	items   []CodeItem
	content string
}

pub fn new_file(config CodeFile) CodeFile {
	return CodeFile{
		...config
		mod: texttools.name_fix(config.mod)
		items: config.items
	}
}

pub fn (mut file CodeFile) add_import(import_ Import) ! {
	for mut i in file.imports {
		if i.mod == import_.mod {
			i.add_types(import_.types)
			return
		}
	}
	file.imports << import_
}

pub fn (code CodeFile) write_v(path string, options WriteOptions) ! {
	filename := '${options.prefix}${texttools.name_fix(code.name)}.v'
	mut filepath := pathlib.get('${path}/${filename}')

	if !options.overwrite && filepath.exists() {
		return
	}

	imports_str := code.imports.map(it.vgen()).join_lines()

	code_str := if code.content != '' {
		code.content
	} else {
		vgen(code.items)
	}

	consts_str := if code.consts.len > 1 {
		stmts := code.consts.map('${it.name} = ${it.value}')
		'\nconst(\n${stmts.join('\n')}\n)\n'
	} else if code.consts.len == 1 {
		'\nconst ${code.consts[0].name} = ${code.consts[0].value}\n'
	} else {
		''
	}

	mut file := pathlib.get_file(
		path: filepath.path
		create: true
	)!
	file.write('module ${code.mod}\n${imports_str}\n${consts_str}\n${code_str}')!
	if options.format {
		os.execute('v fmt -w ${file.path}')
	}
}

pub fn (file CodeFile) get_function(name string) ?Function {
	functions := file.items.filter(it is Function).map(it as Function)
	target_lst := functions.filter(it.name == name)

	if target_lst.len == 0 {
		return none
	}
	if target_lst.len > 1 {
		panic('This should never happen')
	}
	return target_lst[0]
}

pub fn (mut file CodeFile) set_function(function Function) ! {
	function_names := file.items.map(if it is Function { it.name } else { '' })

	index := function_names.index(function.name)
	if index == -1 {
		return error('function not found')
	}
	file.items[index] = function
}

pub fn (file CodeFile) functions() []Function {
	return file.items.filter(it is Function).map(it as Function)
}

pub fn (file CodeFile) structs() []Struct {
	return file.items.filter(it is Struct).map(it as Struct)
}