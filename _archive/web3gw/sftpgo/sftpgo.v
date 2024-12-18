module sftpgo

import json
import net.http
import encoding.base64

@[openrpc: exclude]
@[noinit]
pub struct SFTPGoClient {
pub mut:
	address string
	header  http.Header
}

@[openrpc: exlude]
@[params]
pub struct SFTPGOClientArgs {
pub:
	address string = 'http://localhost:8080/api/v2'
	key     string
}

@[params]
pub struct APIKeyParams {
pub:
	address     string = 'http://localhost:8080/api/v2'
	jwt         string
	name        string
	scope       int = 1
	description string
	user        string
	admin       string
}

@[openrpc: exclude]
pub fn new(args SFTPGOClientArgs) !SFTPGoClient {
	header := http.new_custom_header_from_map({
		'X-SFTPGO-API-KEY': args.key
	})!
	return SFTPGoClient{
		address: args.address
		header:  header
	}
}

@[params]
pub struct JWTArgs {
pub mut:
	address  string
	username string
	password string
}

pub fn generate_jwt_token(args JWTArgs) !string {
	cred := base64.encode_str('${args.username}:${args.password}')
	header := http.new_custom_header_from_map({
		'Authorization': 'basic ${cred}'
	})!
	req := http.Request{
		method: http.Method.get
		header: header
		url:    '${args.address}/token'
	}
	resp := req.do()!
	return resp.body
}

@[params]
pub struct APIKeyData {
pub mut:
	name        string
	scope       int = 1
	description string
	user        string
	admin       string
}

pub fn generate_api_key(args APIKeyParams) !string {
	key_data := APIKeyData{
		name:        args.name
		scope:       args.scope
		description: args.description
		user:        args.user
		admin:       args.admin
	}
	header := http.new_custom_header_from_map({
		'Authorization': 'Bearer ${args.jwt}'
	})!
	req := http.Request{
		method: http.Method.post
		header: header
		url:    '${args.address}/apikeys'
		data:   json.encode(key_data)
	}
	resp := req.do()!
	return resp.body
}
