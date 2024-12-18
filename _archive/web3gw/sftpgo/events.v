module sftpgo

import net.http

@[params]
pub struct EventRequest {
	start int    // start_timestamp
	end   int    // end_timestamp
	limit int    // represents max result count
	order string // result order for example DESC
}

pub fn (mut cl SFTPGoClient) get_fs_events(start int, end int, limit int, order string) !string {
	req := http.Request{
		method: http.Method.get
		header: cl.header
		url:    '${cl.address}/events/fs?start_timestamp=${start}&end_timestamp=${end}&csv_export=false&limit=${limit}&order=${order}'
	}
	resp := req.do()!
	return resp.body
}

pub fn (mut cl SFTPGoClient) get_provider_events(start int, end int, limit int, order string) !string {
	req := http.Request{
		method: http.Method.get
		header: cl.header
		url:    '${cl.address}/events/provider?start_timestamp=${start}&end_timestamp=${end}&csv_export=false&omit_object_data=false&&limit=${limit}&order=${order}'
	}
	resp := req.do()!
	return resp.body
}
