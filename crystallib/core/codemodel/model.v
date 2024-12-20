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
	anon_struct Struct      @[str: skip] // sometimes fields may hold anonymous structs
	typ         Type
	structure   Struct      @[str: skip]
}

pub struct Attribute {
pub:
	name    string // [name]
	has_arg bool
	arg     string // [name: arg]
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
		name: split[0]
		typ: Type{
			symbol: split[1]
		}
		mutable: is_mut
	}
}

pub fn parse_result(code_ string) !Result {
	code := code_.replace(' ', '').trim_space()

	return Result{
		result: code_.starts_with('!')
		optional: code_.starts_with('?')
		typ: Type{
			symbol: code.trim('!?')
			is_optional: code.starts_with('?')
			is_result: code.starts_with('!')
		}
	}
}

// todo: maybe make 'is_' fields methods?
pub struct Type {
pub mut:
	is_reference bool   @[str: skip]
	is_map       bool   @[str: skip]
	is_array     bool
	is_mutable   bool   @[str: skip]
	is_shared    bool   @[str: skip]
	is_optional  bool   @[str: skip]
	is_result    bool   @[str: skip]
	symbol       string
	mod          string @[str: skip]
}

pub struct Alias {
pub:
	name        string
	description string
	typ         Type
}
