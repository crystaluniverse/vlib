module httpconnection

import net.http { Header, Method }

pub enum DataFormat {
	json           // application/json
	urlencoded     //
	multipart_form //
}

@[params]
pub struct Request {
pub mut:
	method        Method
	prefix        string
	id            string
	params        map[string]string
	data          string
	cache_disable bool // do not put this default on true, this is set on the connection, this is here to be overruled in specific cases
	header        ?Header
	dict_key      string // if the return is a dict, then will take the element out of the dict with the key and process further
	list_dict_key string // if the output is a list of dicts, then will process each element of the list to take the val with key out of that dict
	debug         bool
	dataformat    DataFormat
}

/// Creates a new HTTP request with the specified parameters.
///
/// This function takes a `Request` object and modifies it based on the provided
/// data format (`json`, `urlencoded`, or `multipart_form`). If the method is POST,
/// and the `data` field is empty but `params` is provided, it will encode the `params`
/// as form data. The corresponding `Content-Type` header is set based on the data format.
///
/// # Arguments
///
/// - `args`: A `Request` object containing the details of the request (method, data, params, etc.).
///
/// # Returns
///
/// - A reference to the modified `Request` object.
pub fn new_request(args_ Request) !&Request {
	mut args := args_
	if args.method == .post && args.data == '' && args.params.len > 0 {
		args.data = http.url_encode_form_data(args.params)
	}

	mut header := Header{}

	if args_.dataformat == DataFormat.json {
		header = http.new_header_from_map({
			http.CommonHeader.content_type: 'application/json'
		})
		args.header = header
	} else if args_.dataformat == DataFormat.urlencoded {
		header = http.new_header_from_map({
			http.CommonHeader.content_type: 'application/x-www-form-urlencoded'
		})
		args.header = header
	} else if args_.dataformat == DataFormat.multipart_form {
		header = http.new_header_from_map({
			http.CommonHeader.content_type: 'multipart/form-data'
		})
		args.header = header
	}

	return &args
}

// // set a custom hdeader on the request
// // ```v
// // import net.http { Header }
// // header: http.new_header(
// //     key: .content_type
// //     value: 'application/json'
// // )
// // )!
// // ```
// fn (mut r Request) header_set(header Header) {
// 	r.header = header
// }
