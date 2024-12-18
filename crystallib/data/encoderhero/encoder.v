module encoderhero

import freeflowuniverse.crystallib.data.paramsparser
import time
import v.reflection
import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.core.texttools
// import freeflowuniverse.crystallib.ui.console

// Encoder encodes the an `Any` type into HEROSCRIPT representation.
// It provides parameters in order to change the end result.
pub struct Encoder {
pub mut:
	escape_unicode bool = true
	action_name    string
	action_names   []string
	params         paramsparser.Params
	children       []Encoder
	parent         ?&Encoder @[skip; str: skip]
}

// encode is a generic function that encodes a type into a HEROSCRIPT string.
pub fn encode[T](val T) !string {
	mut e := Encoder{
		params: paramsparser.Params{}
	}

	$if T is $struct {
		e.encode_struct[T](val)!
	} $else $if T is $array {
		e.add_child_list[T](val, 'TODO')
	} $else {
		return error('can only add elements for struct or array of structs. \n${val}')
	}
	return e.export()!
}

// export exports an encoder into encoded heroscript
pub fn (e Encoder) export() !string {
	mut script := e.params.export(
		pre:        '!!define.${e.action_names.join('.')}'
		indent:     '	'
		skip_empty: true
	)

	script += e.children.map(it.export()!).join('\n')
	return script
}

// needs to be a struct we are adding
// parent is the name of the action e.g define.customer:contact
pub fn (mut e Encoder) add_child[T](val T, parent string) ! {
	$if T is $array {
		mut counter := 0
		for valitem in val {
			mut e2 := e.add_child[T](valitem, '${parent}:${counter}')!
		}
		return
	}
	mut e2 := Encoder{
		params:       paramsparser.Params{}
		parent:       &e
		action_names: e.action_names.clone() // careful, if not cloned gets mutated later
	}
	$if T is $struct {
		e2.params.set('key', parent)
		e2.encode_struct[T](val)!
		e.children << e2
	} $else {
		return error('can only add elements for struct or array of structs. \n${val}')
	}
}

pub fn (mut e Encoder) add_child_list[U](val []U, parent string) ! {
	for i in 0 .. val.len {
		mut counter := 0
		$if U is $struct {
			e.add_child(val[i], '${parent}:${counter}')!
			counter += 1
		}
	}
}

// needs to be a struct we are adding
// parent is the name of the action e.g define.customer:contact
pub fn (mut e Encoder) add[T](val T) ! {
	// $if T is []$struct {
	// 	// panic("not implemented")
	// 	for valitem in val{
	// 		mut e2:=e.add[T](valitem)!
	// 	}		
	// }
	mut e2 := Encoder{
		params:       paramsparser.Params{}
		parent:       &e
		action_names: e.action_names.clone() // careful, if not cloned gets mutated later
	}
	$if T is $struct && T !is time.Time {
		e2.params.set('key', '${val}')
		e2.encode_struct[T](val)!
		e.children << e2
	} $else {
		return error('can only add elements for struct or array of structs. \n${val}')
	}
}

pub fn (mut e Encoder) encode_array[U](val []U) ! {
	for i in 0 .. val.len {
		$if U is $struct {
			e.add(val[i])!
		}
	}
}

// now encode the struct
pub fn (mut e Encoder) encode_struct[T](t T) ! {
	mut mytype := reflection.type_of[T](t)
	struct_attrs := attrs_get_reflection(mytype)

	mut action_name := texttools.name_fix_pascal_to_snake(T.name.all_after_last('.'))
	if 'alias' in struct_attrs {
		action_name = struct_attrs['alias'].to_lower()
	}
	e.action_names << action_name

	params := paramsparser.encode[T](t, recursive: false)!
	e.params = params

	// encode children structs and array of structs
	$for field in T.fields {
		val := t.$(field.name)
		// time is encoded in the above params encoding step so skip and dont treat as recursive struct
		$if val is time.Time || val is ourtime.OurTime {
		} $else $if val is $struct {
			if field.name[0].is_capital() {
				embedded_params := paramsparser.encode(val, recursive: false)!
				e.params.params << embedded_params.params
			} else {
				e.add(val)!
			}
		} $else $if val is $array {
			e.encode_array(val)!
		}
	}
}
