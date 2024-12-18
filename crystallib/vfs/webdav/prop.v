module webdav

import encoding.xml
import os
import time
import vweb

fn (mut app App) generate_response_element(path string) xml.XMLNode {
	href := xml.XMLNode{
		name:     'D:href'
		children: ['${path.all_after(app.root_dir.path)}']
	}

	propstat := app.generate_propstat_element(path)

	return xml.XMLNode{
		name:     'D:response'
		children: [href, propstat]
	}
}

fn (mut app App) generate_propstat_element(path string) xml.XMLNode {
	mut status := xml.XMLNode{
		name:     'D:status'
		children: ['HTTP/1.1 200 OK']
	}

	prop := app.generate_prop_element(path) or {
		// TODO: status should be according to returned error
		return xml.XMLNode{
			name:     'D:propstat'
			children: [
				xml.XMLNode{
					name:     'D:status'
					children: ['HTTP/1.1 500 Internal Server Error']
				},
			]
		}
	}

	return xml.XMLNode{
		name:     'D:propstat'
		children: [prop, status]
	}
}

fn (mut app App) generate_prop_element(path string) !xml.XMLNode {
	if !os.exists(path) {
		return error('not found')
	}

	stat := os.stat(path)!

	// name := match os.is_dir(path) {
	// 	true {
	// 		os.base(path)
	// 	}
	// 	false {
	// 		os.file_name(path)
	// 	}
	// }
	// display_name := xml.XMLNode{
	// 	name: 'D:displayname'
	// 	children: ['${name}']
	// }

	content_length := if os.is_dir(path) { 0 } else { stat.size }
	get_content_length := xml.XMLNode{
		name:     'D:getcontentlength'
		children: ['${content_length}']
	}

	ctime := format_iso8601(time.unix(stat.ctime))
	creation_date := xml.XMLNode{
		name:     'D:creationdate'
		children: ['${ctime}']
	}

	mtime := format_iso8601(time.unix(stat.mtime))
	get_last_mod := xml.XMLNode{
		name:     'D:getlastmodified'
		children: ['${mtime}']
	}

	content_type := match os.is_dir(path) {
		true {
			'httpd/unix-directory'
		}
		false {
			app.get_file_content_type(path)
		}
	}

	get_content_type := xml.XMLNode{
		name:     'D:getcontenttype'
		children: ['${content_type}']
	}

	mut get_resource_type_children := []xml.XMLNodeContents{}
	if os.is_dir(path) {
		get_resource_type_children << xml.XMLNode{
			name: 'D:collection '
		}
	}

	get_resource_type := xml.XMLNode{
		name:     'D:resourcetype'
		children: get_resource_type_children
	}

	return xml.XMLNode{
		name:     'D:prop'
		children: [
			// display_name,
			get_content_length,
			creation_date,
			get_last_mod,
			get_content_type,
			get_resource_type,
		]
	}
}

fn (mut app App) get_file_content_type(path string) string {
	ext := os.file_ext(path)
	content_type := if v := vweb.mime_types[ext] {
		v
	} else {
		'application/octet-stream'
	}

	return content_type
}

fn format_iso8601(t time.Time) string {
	return '${t.year:04d}-${t.month:02d}-${t.day:02d}T${t.hour:02d}:${t.minute:02d}:${t.second:02d}Z'
}
