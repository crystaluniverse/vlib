module syncthing

import x.json2
import freeflowuniverse.crystallib.clients.httpconnection
import freeflowuniverse.crystallib.ui.console

pub fn (mut a App) query() ! {
	mut conn := httpconnection.new(name: 'example', url: 'https://localhost:8384/rest/', retry: 5)!
	// console.print_debug(conn)
	// conn.default_header.add(.content_language, 'Content-Language: en-US')
	conn.default_header.set_custom('X-API-Key', 'TR2DcP2zkVgCSFaKykoR74pDZgFZuKM7')!
	res := conn.get(prefix: 'events?events=ItemFinished&limit=10')!
	res2 := json2.raw_decode(res)!
	for item in res2.arr() {
		o := item.as_map()
		// console.print_debug(o["type"])
		if o['type'].str() == 'ItemFinished' {
			gid := o['globalID'].int()
			if gid > a.last_gid {
				console.print_debug(o)
				a.last_gid = gid
			}
			// console.print_debug(item.prettify_json_str())
		}
	}

	// https://docs.syncthing.net/v1.23.7/rest/events-get
	// file:///Users/despiegk1/_code/v/vlib/_docs/x.json2.html#Any.as_map

	// console.print_debug(res)
}
