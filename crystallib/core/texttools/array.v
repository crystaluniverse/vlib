module texttools

// a comma or \n separated list gets converted to a list of strings .
//'..' also gets converted to without ''
// check also splitsmart which is more intelligent
pub fn to_array(r string) []string {
	mut res := []string{}
	mut r2 := dedent(r)
	r2 = r2.replace(',', '\n')

	for mut line in r2.split_into_lines() {
		line = line.trim_space()
		if line.trim('\'"') == '' {
			continue
		}
		res << line.trim("'")
	}
	return res
}

pub fn to_array_int(r string) []int {
	mut r2 := to_array(r).map(it.int())
	return r2
}

// intelligent way how to map a line to a map
//```
// r:=texttools.to_map("name,-,-,-,-,pid,-,-,-,-,path",
// 	"root   304   0.0  0.0 408185328   1360   ??  S    16Dec23   0:34.06 /usr/sbin/distnoted\n \n")
// assert {'name': 'root', 'pid': '1360', 'path': '/usr/sbin/distnoted'} == r

// r2:=texttools.to_map("name,-,-,-,-,pid,-,-,-,-,path",
// 	"root   304   0.0  0.0 408185328   1360   ??  S    16Dec23   0:34.06 /usr/sbin/distnoted anotherone anotherone\n \n")
// assert {'name': 'root', 'pid': '1360', 'path': '/usr/sbin/distnoted'} == r2

// r3:=texttools.to_map("name,-,-,-,-,pid,-,-,-,-,path",
// 	"root   304   0.0  0.0 408185328   1360   ??  S    16Dec23   0:34.06 \n \n")
// assert {'name': 'root', 'pid': '1360', 'path': ''} == r3
//```
pub fn to_map(mapstring string, line string, delimiter_ string) map[string]string {
	mapstring_array := split_smart(mapstring, '')
	mut line_array := split_smart(line, '')
	mut result := map[string]string{}
	for x in 0 .. mapstring_array.len {
		mapstring_item := mapstring_array[x] or { '' }
		if mapstring_item != '-' {
			result[mapstring_item] = line_array[x] or { '' }
		}
	}
	return result
}

// smart way how to get useful info out of text block
// ```
// t:='
// _cmiodalassistants   304   0.0  0.0 408185328   1360   ??  S    16Dec23   0:34.06 /usr/sbin/distnoted agent
// _locationd         281   0.0  0.0 408185328   1344   ??  S    16Dec23   0:35.80 /usr/sbin/distnoted agent

// 	root               275   0.0  0.0 408311904   7296   ??  Ss   16Dec23   2:00.56 /usr/libexec/storagekitd
// _coreaudiod        268   0.0  0.0 408185328   1344   ??  S    16Dec23   0:35.49 /usr/sbin/distnoted agent
// '

// r4:=texttools.to_list_map("name,-,-,-,-,pid,-,-,-,-,path",t)
// assert [{'name': '_cmiodalassistants', 'pid': '1360', 'path': '/usr/sbin/distnoted'},
// 		{'name': '_locationd', 'pid': '1344', 'path': '/usr/sbin/distnoted'},
// 		{'name': 'root', 'pid': '7296', 'path': '/usr/libexec/storagekitd'},
// 		{'name': '_coreaudiod', 'pid': '1344', 'path': '/usr/sbin/distnoted'}] == r4
// ```
pub fn to_list_map(mapstring string, txt_ string, delimiter_ string) []map[string]string {
	mut result := []map[string]string{}
	mut txt := remove_empty_lines(txt_)
	txt = dedent(txt)
	for line in txt.split_into_lines() {
		result << to_map(mapstring, line, delimiter_)
	}
	return result
}
