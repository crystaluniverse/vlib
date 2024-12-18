module codemodel

import freeflowuniverse.crystallib.core.pathlib
// Code is a list of statements
// pub type Code = []CodeItem

pub type CodeItem = Alias | Comment | CustomCode | Function | Import | Struct | Sumtype

// item for adding custom code in
pub struct CustomCode {
pub:
	text string
}

pub struct Comment {
pub:
	text     string
	is_multi bool
}

pub struct Struct {
pub mut:
	name        string
	description string
	mod         string
	is_pub      bool
	embeds      []Struct          @[str: skip]
	generics    map[string]string @[str: skip]
	attrs       []Attribute
	fields      []StructField
}

pub struct Sumtype {
pub:
	name        string
	description string
	types       []Type
}

pub struct StructField {
pub mut:
	comments    []Comment
	attrs       []Attribute
	name        string
	description string
	default     string
	is_pub      bool
	is_mut      bool
	is_ref      bool
	anon_struct Struct @[str: skip] // sometimes fields may hold anonymous structs
	typ         Type
	structure   Struct @[str: skip]
}

pub struct Attribute {
pub:
	name    string // [name]
	has_arg bool
	arg     string // [name: arg]
}

pub struct Function {
pub:
	name     string
	receiver Param
	is_pub   bool
	mod      string
pub mut:
	description string
	params      []Param
	body        string
	result      Result
	has_return  bool
}

pub fn parse_function(code_ string) !Function {
	mut code := code_.trim_space()
	is_pub := code.starts_with('pub ')
	if is_pub {
		code = code.trim_string_left('pub ').trim_space()
	}

	is_fn := code.starts_with('fn ')
	if !is_fn {
		return error('invalid function format')
	}
	code = code.trim_string_left('fn ').trim_space()

	receiver := if code.starts_with('(') {
		param_str := code.all_after('(').all_before(')').trim_space()
		code = code.all_after(')').trim_space()
		parse_param(param_str)!
	} else {
		Param{}
	}

	name := code.all_before('(').trim_space()
	code = code.trim_string_left(name).trim_space()

	params_str := code.all_after('(').all_before(')')
	params := if params_str.trim_space() != '' {
		params_str_lst := params_str.split(',')
		params_str_lst.map(parse_param(it)!)
	} else {
		[]Param{}
	}
	result := parse_result(code.all_after(')').all_before('{').replace(' ', ''))!

	body := if code.contains('{') { code.all_after('{').all_before_last('}') } else { '' }
	return Function{
		name:     name
		receiver: receiver
		params:   params
		result:   result
		body:     body
	}
}

pub fn parse_param(code_ string) !Param {
	mut code := code_.trim_space()
	is_mut := code.starts_with('mut ')
	if is_mut {
		code = code.trim_string_left('mut ').trim_space()
	}
	split := code.split(' ').filter(it != '')
	if split.len != 2 {
		return error('invalid param format: ${code_}')
	}
	return Param{
		name:    split[0]
		typ:     Type{
			symbol: split[1]
		}
		mutable: is_mut
	}
}

pub fn parse_result(code_ string) !Result {
	code := code_.replace(' ', '').trim_space()

	return Result{
		result:   code_.starts_with('!')
		optional: code_.starts_with('?')
		typ:      Type{
			symbol:      code.trim('!?')
			is_optional: code.starts_with('?')
			is_result:   code.starts_with('!')
		}
	}
}

pub struct Param {
pub:
	required    bool
	mutable     bool
	is_shared   bool
	is_optional bool
	description string
	name        string
	typ         Type
	struct_     Struct
}

pub struct Result {
pub mut:
	typ         Type
	description string
	name        string
	result      bool // whether is result type
	optional    bool // whether is result type
	structure   Struct
}

// todo: maybe make 'is_' fields methods?
pub struct Type {
pub mut:
	is_reference bool @[str: skip]
	is_map       bool @[str: skip]
	is_array     bool
	is_mutable   bool @[str: skip]
	is_shared    bool @[str: skip]
	is_optional  bool @[str: skip]
	is_result    bool @[str: skip]
	symbol       string
	mod          string @[str: skip]
}

pub struct File {
pub mut:
	name      string
	extension string
	content   string
}

pub fn (f File) write(path string) ! {
	mut fd_file := pathlib.get_file(path: '${path}/${f.name}.${f.extension}')!
	fd_file.write(f.content)!
}

pub struct Alias {
pub:
	name        string
	description string
	typ         Type
}
