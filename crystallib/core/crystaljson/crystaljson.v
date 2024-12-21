module crystaljson

import x.json2
import freeflowuniverse.crystallib.core.texttools

const keep_ascii = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_-+={}[]"\':;!/>.<,|\\~` '

// rought splitter for json, splits a list of dicts into the text blocks
pub fn json_list(r string, clean bool) []string {
	// mut res := []string{}
	mut open_counter := 0
	mut block := []string{}
	mut blocks := []string{}
	for ch in r {
		mut c := ch.ascii_str()
		// //rough one to debug
		// if clean && ! keep_ascii.contains(c){
		// 	console.print_debug("SKIP")
		// 	continue
		// }		
		// console.print_debug('${c}')
		if c == '{' {
			open_counter += 1
		}
		if c == '}' {
			open_counter -= 1
		}
		// console.print_debug(open_counter)
		if open_counter > 0 {
			block << c
			// console.print_debug(block.len)
		}
		if open_counter == 0 && block.len > 2 {
			blocks << block.join('') + '}'
			block = []string{}
		}
	}
	return blocks
}

// get dict out of json
// if include used (not empty, then will only match on keys given)
pub fn json_dict_get_any(r string, clean bool, key string) !json2.Any {
	mut r2 := r
	if clean {
		r2 = texttools.ascii_clean(r2)
	}
	if r2.trim(' \n') == '' {
		return error('Cannot do json2 raw decode in json_dict_get_any.\ndata was empty.')
	}
	data_raw := json2.raw_decode(r2) or {
		return error('Cannot do json2 raw decode in json_dict_get_any.\ndata:\n${r2}\nerror:${err}')
	}
	mut res := data_raw.as_map()
	if key in res {
		return res[key]!
	} else {
		return error('Could not find key:${key} in ${r}')
	}
}

pub fn json_dict_get_string(r string, clean bool, key string) !string {
	r2 := json_dict_get_any(r, clean, key)!
	return r2.json_str()
}

// get dict out of json
// if include used (not empty, then will only match on keys given)
pub fn json_dict_filter_any(r string, clean bool, include []string, exclude []string) !map[string]json2.Any {
	mut r2 := r
	if clean {
		r2 = texttools.ascii_clean(r2)
	}
	if r2.trim(' \n') == '' {
		return error('Cannot do json2 raw decode in json_dict_filter_any.\ndata was empty.')
	}
	data_raw := json2.raw_decode(r2) or {
		return error('Cannot do json2 raw decode in json_dict_filter_any.\ndata:\n${r2}\nerror:${err}')
	}
	mut res := data_raw.as_map()
	if include != [] {
		for key in res.keys() {
			if key !in include {
				res.delete(key)
			}
		}
	}
	for key in exclude {
		res.delete(key)
	}
	return res
}

pub fn json_dict_filter_string(r string, clean bool, include []string, exclude []string) !map[string]string {
	mut res := json_dict_filter_any(r, clean, include, exclude)!
	mut res2 := map[string]string{}
	for key in res.keys() {
		res2[key] = res[key]!.json_str()
	}
	return res2
}




// the input is a list of dicts e.g. [{"key":{"name":"kristof@incubaid.com",...},{"key":...}]
// in this key the key would be key
// returns list of json2.any
pub fn json_list_dict_get_any(r string, clean bool, key string) ![]json2.Any {
	mut r2 := r
	if clean {
		r2 = texttools.ascii_clean(r2)
	}
	if r2.trim(' \n') == '' {
		return error('Cannot do json2 raw decode in json_dict_get_any.\ndata was empty.')
	}
	data_raw := json2.raw_decode(r2) or {
		return error('Cannot do json2 raw decode in json_dict_get_any.\ndata:\n${r2}\nerror:${err}')
	}
	mut res_list := data_raw.arr()
	mut res_final := []json2.Any{}
	for item in res_list{
		mut res := item.as_map()
		if key in res {
			res_final << res[key] or {panic("bug")}
		}else{
			return error('Could not find key:${key} in ${res} as part of json_list_dict_get_any')
		}
	}
	return res_final
}

// the input is a list of dicts e.g. [{"key":{"name":"kristof@incubaid.com",...},{"key":...}]
// in this key the key would be key
// returns list strings which can be parsed as json
pub fn json_list_dict_get_string(r string, clean bool, key string) ![]string {
	r2 := json_list_dict_get_any(r, clean, key)!
	return r2.map(it.json_str())
}
