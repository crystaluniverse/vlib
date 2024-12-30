module openrpc

import json
import x.json2 { Any }
import os
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.data.jsonschema { Reference, decode_schemaref }

@[params]
pub struct Params {
pub:
	path string // path to openrpc.json file
	text string // content of openrpc specification text
}

pub fn new(params Params) !OpenRPC {
	if params.path == '' && params.text == '' {
		return OpenRPC{}
	}

	if params.text != '' && params.path != '' {
		return error('Either provide path or text')
	}

	text := if params.path != '' {
		os.read_file(params.path)!	
	} else { params.text }

	return decode(text)!	
}