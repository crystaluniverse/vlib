module sftpgo

import json
import net.http

@[params]
pub struct Role {
pub mut:
	name        string
	description string
	users       []string
	admins      []string
}

pub fn (mut cl SFTPGoClient) list_roles() !string {
	req := http.Request{
		method: http.Method.get
		header: cl.header
		url:    '${cl.address}/roles'
	}
	resp := req.do()!
	return resp.body
}

pub fn (mut cl SFTPGoClient) add_role(role Role) !string {
	req := http.Request{
		method: http.Method.post
		header: cl.header
		url:    '${cl.address}/roles'
		data:   json.encode(role)
	}
	resp := req.do()!
	return resp.body
}

pub fn (mut cl SFTPGoClient) get_role(name string) !string {
	req := http.Request{
		method: http.Method.get
		header: cl.header
		url:    '${cl.address}/roles/${name}'
	}
	resp := req.do()!
	return resp.body
}

pub fn (mut cl SFTPGoClient) update_role(role Role) !string {
	req := http.Request{
		method: http.Method.put
		header: cl.header
		url:    '${cl.address}/roles/${role.name}'
		data:   json.encode(role)
	}
	resp := req.do()!
	return resp.body
}

pub fn (mut cl SFTPGoClient) delete_role(name string) !string {
	req := http.Request{
		method: http.Method.delete
		header: cl.header
		url:    '${cl.address}/roles/${name}'
	}
	resp := req.do()!
	return resp.body
}
