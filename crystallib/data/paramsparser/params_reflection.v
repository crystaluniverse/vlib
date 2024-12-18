module paramsparser

import time
import v.reflection
// import freeflowuniverse.crystallib.data.encoderhero
// TODO: support more field types

pub fn (params Params) decode[T]() !T {
	// work around to allow recursive decoding
	// otherwise v cant infer generic type for child fields that are structs
	return params.decode_struct[T](T{})!
}

pub fn (params Params) decode_struct[T](_ T) !T {
	mut t := T{}
	$for field in T.fields {
		$if field.is_enum {
			t.$(field.name) = params.get_int(field.name) or { 0 }
		} $else {
			if field.name[0].is_capital() {
				// embed := params.decode_struct(t.$(field.name))!
				t.$(field.name) = params.decode_struct(t.$(field.name))!
			} else {
				t.$(field.name) = params.decode_value(t.$(field.name), field.name)!
			}
		}
	}
	return t
}

pub fn (params Params) decode_value[T](_ T, key string) !T {
	// $if T is $option {
	// 	// unwrap and encode optionals
	// 	workaround := t
	// 	if workaround != none {
	// 		encode(t, args)!
	// 	}
	// }
	// value := params.get(field.name)!

	// TODO: handle required fields
	if !params.exists(key) {
		return T{}
	}

	$if T is string {
		return params.get(key)!
	} $else $if T is int {
		return params.get_int(key)!
	} $else $if T is u32 {
		return params.get_u32(key)!
	} $else $if T is bool {
		return params.get_default_true(key)
	} $else $if T is []string {
		return params.get_list(key)!
	} $else $if T is []int {
		return params.get_list_int(key)!
	} $else $if T is []u32 {
		lst := params.get_list_u32(key)!
		return lst
	} $else $if T is time.Time {
		time_str := params.get(key)!
		// todo: 'handle other null times'
		if time_str == '0000-00-00 00:00:00' {
			return time.Time{}
		}
		return time.parse(time_str)!
	} $else $if T is $struct {
		child_params := params.get_params(key)!
		child := child_params.decode_struct(T{})!
		return child
	}
	return T{}
}

@[params]
pub struct EncodeArgs {
pub:
	recursive bool = true
}

pub fn encode[T](t T, args EncodeArgs) !Params {
	$if t is $option {
		// unwrap and encode optionals
		workaround := t
		if workaround != none {
			encode(t, args)!
		}
	}
	mut params := Params{}

	// struct_attrs := attrs_get_reflection(mytype)

	$for field in T.fields {
		val := t.$(field.name)
		field_attrs := attrs_get(field.attrs)
		mut key := field.name
		if 'alias' in field_attrs {
			key = field_attrs['alias']
		}
		$if val is string || val is int || val is bool || val is i64 || val is u32
			|| val is time.Time {
			params.set(key, '${val}')
		} $else $if field.is_enum {
			params.set(key, '${int(val)}')
		} $else $if field.typ is []string {
			mut v2 := ''
			for i in val {
				if i.contains(' ') {
					v2 += "\"${i}\","
				} else {
					v2 += '${i},'
				}
			}
			v2 = v2.trim(',')
			params.params << Param{
				key:   field.name
				value: v2
			}
		} $else $if field.typ is []int {
			mut v2 := ''
			for i in val {
				v2 += '${i},'
			}
			v2 = v2.trim(',')
			params.params << Param{
				key:   field.name
				value: v2
			}
		} $else $if field.typ is []u32 {
			mut v2 := ''
			for i in val {
				v2 += '${i},'
			}
			v2 = v2.trim(',')
			params.params << Param{
				key:   field.name
				value: v2
			}
		} $else $if field.typ is $struct {
			// TODO: Handle embeds better
			is_embed := field.name[0].is_capital()
			if is_embed {
				$if val is string || val is int || val is bool || val is i64 || val is u32
					|| val is time.Time {
					params.set(key, '${val}')
				}
			} else {
				if args.recursive {
					child_params := encode(val)!
					params.params << Param{
						key:   field.name
						value: child_params.export()
					}
				}
			}
		} $else {
		}
	}
	return params
}

// BACKLOG: can we do the encode recursive?

// if at top of struct we have: @[name:"teststruct " ; params] .
// will return {'name': 'teststruct', 'params': ''}
fn attrs_get_reflection(mytype reflection.Type) map[string]string {
	if mytype.sym.info is reflection.Struct {
		return attrs_get(mytype.sym.info.attrs)
	}
	return map[string]string{}
}

// will return {'name': 'teststruct', 'params': ''}
fn attrs_get(attrs []string) map[string]string {
	mut out := map[string]string{}
	for i in attrs {
		if i.contains('=') {
			kv := i.split('=')
			out[kv[0].trim_space().to_lower()] = kv[1].trim_space().to_lower()
		} else {
			out[i.trim_space().to_lower()] = ''
		}
	}
	return out
}
