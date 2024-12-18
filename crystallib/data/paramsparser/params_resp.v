module paramsparser

import freeflowuniverse.crystallib.data.resp

// TODO: fix this. encoding some params and redecoding them does not work.

// encode using resp (redis procotol)
pub fn (mut p Params) to_resp() ![]u8 {
	mut b_main := resp.builder_new()
	mut b_param := resp.builder_new()
	for param in p.params {
		b_param.add(resp.r_list_string([param.key, param.value]))
	}
	mut b_arg := resp.builder_new()
	for arg in p.args {
		b_arg.add(resp.r_string(arg))
	}
	b_main.add(resp.r_list_bytestring([b_param.data, b_arg.data]))

	return b_main.data
}

pub fn from_resp(data []u8) !Params {
	mut p := Params{}

	mut top_array_ := resp.decode(data)![0]
	top_array := top_array_ as resp.RArray

	params_string := top_array.values[0] as resp.RBString
	params_array := resp.decode(params_string.value)!

	for param_string_ in params_array {
		param_string := param_string_ as resp.RArray
		key_rstring := param_string.values[0] as resp.RString
		value_rstring := param_string.values[1] as resp.RString
		p.params << Param{
			key:   key_rstring.value
			value: value_rstring.value
		}
	}

	args_string := top_array.values[1] as resp.RBString
	args_array := resp.decode(args_string.value)!

	for arg_string_ in args_array {
		arg_string := arg_string_ as resp.RString
		p.args << arg_string.value
	}

	return p
}

// NEXT: needs to do a good test, this protocol is much smaller than default text format
