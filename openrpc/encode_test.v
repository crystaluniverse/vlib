module openrpc

import json
import freeflowuniverse.crystallib.jsonschema {Schema, SchemaRef}

// test if encode can correctly encode a blank OpenRPC
fn test_encode_blank() ! {
	doc := OpenRPC{
		info: Info{
			title: ''
			version: '1.0.0'
		}
		methods: []Method{}
	}
	encoded := doc.encode()!
	assert encoded == '{"openrpc":"1.0.0","info":{"version":"1.0.0"},"methods":[]}'
}

// test if can correctly encode an OpenRPC doc with a method
fn test_encode_with_method() ! {
	doc := OpenRPC{
		info: Info{
			title: ''
			version: '1.0.0'
		}
		methods: [
			Method{
				name: 'method_name'
				summary: 'summary'
				description: 'description for this method'
				deprecated: true
				params: [
					ContentDescriptor{
						name: 'sample descriptor'
						schema: SchemaRef(Schema{
							typ: 'string'
						})
					}
				]
			}
		]
	}
	encoded := doc.encode()!
	assert encoded == '{"openrpc":"1.0.0","info":{"version":"1.0.0"},"methods":[{"name":"method_name","summary":"summary","description":"description for this method","params":[{"name":"sample descriptor"}]}]}'
}

// test if can correctly encode a complete OpenRPC doc
fn test_encode() ! {
	doc := OpenRPC{
		info: Info{
			title: ''
			version: '1.0.0'
		}
		methods: [
			Method{
				name: 'method_name'
				summary: 'summary'
				description: 'description for this method'
				deprecated: true
				params: [
					ContentDescriptor{
						name: 'sample descriptor'
						schema: SchemaRef(Schema{
							typ: 'string'
						})
					}
				]
			}
		]
	}
	encoded := json.encode(doc)
	panic(encoded)
	// jsonencoded := doc.encode()!
	// assert encoded == '{"openrpc":"1.0.0","info":{"version":"1.0.0"},"methods":[{"name":"method_name","summary":"summary","description":"description for this method","params":[{"name":"sample descriptor"}]}]}'
}