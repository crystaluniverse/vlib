module params

import texttools
import os
import time { Duration }

// check if kwarg exist
// line:
//    arg1 arg2 color:red priority:'incredible' description:'with spaces, lets see if ok
// arg1 is an arg
// description is a kwarg
pub fn (params &Params) exists(key_ string) bool {
	key := key_.to_lower()
	for p in params.params {
		if p.key == key && p.value != '' {
			return true
		}
	}
	return false
}

// check if arg exist (arg is just a value in the string e.g. red, not value:something)
// line:
//    arg1 arg2 color:red priority:'incredible' description:'with spaces, lets see if ok
// arg1 is an arg
// description is a kwarg
pub fn (params &Params) arg_exists(key_ string) bool {
	key := key_.to_lower()
	for p in params.args {
		if p == key {
			return true
		}
	}
	return false
}

// see if the kwarg with the key exists
// if yes return as string trimmed
pub fn (params &Params) get(key_ string) !string {
	key := texttools.name_fix(key_)
	for p in params.params {
		if p.key == key {
			return p.value.trim(' ')
		}
	}
	return error('Did not find key:${key} in ${params}')
}

// get kwarg return as string, ifn't exist return the defval
// line:
//    arg1 arg2 color:red priority:'incredible' description:'with spaces, lets see if ok
// arg1 is an arg
// description is a kwarg
pub fn (params &Params) get_default(key string, defval string) !string {
	if params.exists(key) {
		valuestr := params.get(key)!
		return valuestr.trim(' ')
	}
	return defval
}

// get kwarg return as int
// line:
//    arg1 arg2 color:red priority:'incredible' description:'with spaces, lets see if ok
// arg1 is an arg
// description is a kwarg
pub fn (params &Params) get_int(key string) !int {
	valuestr := params.get(key)!
	return valuestr.int()
}

pub fn (params &Params) get_u64(key string) !u64 {
	valuestr := params.get(key)!
	return valuestr.u64()
}

pub fn (params &Params) get_u64_default(key string, defval u64) !u64 {
	if params.exists(key) {
		valuestr := params.get(key)!
		return valuestr.u64()
	}
	return defval
}

pub fn (params &Params) get_u32(key string) !u32 {
	valuestr := params.get(key)!
	return valuestr.u32()
}

pub fn (params &Params) get_u32_default(key string, defval u32) !u32 {
	if params.exists(key) {
		valuestr := params.get(key)!
		return valuestr.u32()
	}
	return defval
}

pub fn (params &Params) get_u8(key string) !u8 {
	valuestr := params.get(key)!
	return valuestr.u8()
}

pub fn (params &Params) get_u8_default(key string, defval u8) !u8 {
	if params.exists(key) {
		valuestr := params.get(key)!
		return valuestr.u8()
	}
	return defval
}

pub fn (params &Params) get_resource_in_bytes(key string) !u64 {
	valuestr := params.get(key)!
	mut times := 1
	if valuestr.len > 2 && !valuestr[valuestr.len - 2].is_digit()
		&& !valuestr[valuestr.len - 1].is_digit() {
		times = match valuestr[valuestr.len - 2..].to_upper() {
			'GB' {
				1024 * 1024 * 1024
			}
			'MB' {
				1024 * 1024
			}
			'KB' {
				1024
			}
			else {
				0
			}
		}
		if times == 0 {
			return error('not valid: should end with kb, mb or gb')
		}
	}
	return valuestr.u64() * u64(times)
}

pub fn (params &Params) get_resource_in_bytes_default(key string, defval u64) !u64 {
	if params.exists(key) {
		return params.get_resource_in_bytes(key)!
	}
	return defval
}

fn (params &Params) parse_time(value string) !Duration {
	is_am := value.ends_with('AM')
	is_pm := value.ends_with('PM')
	is_am_pm := is_am || is_pm
	data := if is_am_pm { value[..value.len - 2].split(':') } else { value.split(':') }
	if data.len > 2 {
		return error('Invalid duration value')
	}
	minute := if data.len == 2 { data[1].int() } else { 0 }
	mut hour := data[0].int()
	if is_am || is_pm {
		if hour < 0 || hour > 12 {
			return error('Invalid duration value')
		}
		if is_pm {
			hour += 12
		}
	} else {
		if hour < 0 || hour > 24 {
			return error('Invalid duration value')
		}
	}
	if minute < 0 || minute > 60 {
		return error('Invalid duration value')
	}
	return Duration(time.hour * hour + time.minute * minute)
}

pub fn (params &Params) get_time_interval(key string) !(Duration, Duration) {
	valuestr := params.get(key)!
	data := valuestr.split('-')
	if data.len != 2 {
		return error('Invalid time interval: begin and end time required')
	}
	start := params.parse_time(data[0])!
	end := params.parse_time(data[1])!
	if end < start {
		return error('Invalid time interval: begin time cannot be after end time')
	}
	return start, end
}

pub fn (params &Params) get_time(key string) !Duration {
	valuestr := params.get(key)!
	return params.parse_time(valuestr)!
}

pub fn (params &Params) get_time_default(key string, defval Duration) !Duration {
	if params.exists(key) {
		return params.get_time(key)!
	}
	return defval
}

// get kwarg return as int, if it doesnt' exist return a default
// line:
//    arg1 arg2 color:red priority:'incredible' description:'with spaces, lets see if ok
// arg1 is an arg
// description is a kwarg
pub fn (params &Params) get_int_default(key string, defval int) !int {
	if params.exists(key) {
		valuestr := params.get(key)!
		return valuestr.int()
	}
	return defval
}

// get kwarg, and return list of string
// line:
//    arg1 arg2 color:red priority:'incredible' description:'with spaces, lets see if ok
// arg1 is an arg
// description is a kwarg
pub fn (params &Params) get_list(key string) ![]string {
	mut res := []string{}
	if params.exists(key) {
		mut valuestr := params.get(key)!
		if valuestr.contains(',') {
			valuestr = valuestr.trim('[] ,')
			res = valuestr.split(',').map(it.trim(' \'"'))
		} else {
			res = [valuestr.trim('[] \'"')]
		}
	}
	return res
}

pub fn (params &Params) get_list_u32(key string) ![]u32 {
	mut res := params.get_list(key)!
	return res.map(it.u32())
}

pub fn (params &Params) get_list_namefix(key string) ![]string {
	mut res := params.get_list(key)!
	res = res.map(texttools.name_fix(it))
	return res
}

// get kwarg, and return list of ints
// line:
//    arg1 arg2 color:red priority:'incredible' description:'with spaces, lets see if ok
// arg1 is an arg
// description is a kwarg
pub fn (params &Params) get_list_int(key string) ![]int {
	mut res := []int{}
	if params.exists(key) {
		mut valuestr := params.get(key)!
		if valuestr.contains(',') {
			valuestr = valuestr.trim(' ,')
			res = valuestr.split(',').map(it.trim(' \'"').int())
		} else {
			res = [valuestr.trim(' \'"').int()]
		}
	}
	return res
}

pub fn (params &Params) get_default_true(key string) bool {
	mut r := params.get(key) or { '' }
	r = texttools.name_fix_no_underscore(r)
	if r == '' || r == '1' || r == 'true' || r == 'y' {
		return true
	}
	return false
}

pub fn (params &Params) get_default_false(key string) bool {
	mut r := params.get(key) or { '' }
	r = texttools.name_fix_no_underscore(r)
	if r == '' || r == '0' || r == 'false' || r == 'n' {
		return false
	}
	return true
}

// will get path and check it exists
pub fn (params &Params) get_path(key string) !string {
	path := params.get(key)!

	if !os.exists(path) {
		return error('Cannot find path: ${key}')
	}

	return path
}

// will get path and check it exists if not will create
pub fn (params &Params) get_path_create(key string) !string {
	path := params.get(key)!

	if !os.exists(path) {
		os.mkdir_all(path)!
	}

	return path
}
