module sftpgo

import json
import net.http

@[params]
pub struct User {
pub mut:
	username    string
	email       string
	password    string
	public_keys []string
	permissions map[string][]string
	status      int
}

pub fn (mut cl SFTPGoClient) add_user(user User) !string {
	req := http.Request{
		method: http.Method.post
		header: cl.header
		url:    '${cl.address}/users'
		data:   json.encode(user)
	}
	resp := req.do()!
	return resp.body
}

pub fn (mut cl SFTPGoClient) get_user(username string) !string {
	req := http.Request{
		method: http.Method.get
		header: cl.header
		url:    '${cl.address}/users/${username}'
	}
	resp := req.do()!
	return resp.body
}

pub fn (mut cl SFTPGoClient) update_user(user User) !string {
	req := http.Request{
		method: http.Method.put
		header: cl.header
		url:    '${cl.address}/users/${user.username}'
		data:   json.encode(user)
	}
	resp := req.do()!
	return resp.body
}

pub fn (mut cl SFTPGoClient) delete_user(username string) !string {
	req := http.Request{
		method: http.Method.delete
		header: cl.header
		url:    '${cl.address}/users/${username}'
	}
	resp := req.do()!
	return resp.body
}
