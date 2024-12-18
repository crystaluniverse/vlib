module sftpgo

import json
import net.http

@[params]
pub struct Folder {
pub mut:
	name        string
	mapped_path string
	description string
}

pub fn (mut cl SFTPGoClient) list_folders() !string {
	req := http.Request{
		method: http.Method.get
		header: cl.header
		url:    '${cl.address}/folders'
	}
	resp := req.do()!
	return resp.body
}

pub fn (mut cl SFTPGoClient) add_folder(folder Folder) !string {
	req := http.Request{
		method: http.Method.post
		header: cl.header
		url:    '${cl.address}/folders'
		data:   json.encode(folder)
	}
	resp := req.do()!
	return resp.body
}

pub fn (mut cl SFTPGoClient) get_folder(name string) !string {
	req := http.Request{
		method: http.Method.get
		header: cl.header
		url:    '${cl.address}/folders/${name}'
	}
	resp := req.do()!
	return resp.body
}

pub fn (mut cl SFTPGoClient) update_folder(folder Folder) !string {
	req := http.Request{
		method: http.Method.put
		header: cl.header
		url:    '${cl.address}/folders/${folder.name}'
		data:   json.encode(folder)
	}
	resp := req.do()!
	return resp.body
}

pub fn (mut cl SFTPGoClient) delete_folder(name string) !string {
	req := http.Request{
		method: http.Method.delete
		header: cl.header
		url:    '${cl.address}/folders/${name}'
	}
	resp := req.do()!
	return resp.body
}
