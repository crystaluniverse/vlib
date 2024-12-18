module openssl

import freeflowuniverse.crystallib.core.pathlib { Path }
import json

pub struct OpenSSLKey {
pub mut:
	name      string
	domain    string
	md5       string
	path_key  Path
	path_cert Path
	path_json Path
}

pub fn (mut ossl OpenSSL) new(args OpenSSLGenerateArgs) !OpenSSLKey {
	path_key := '${ossl.certpath.path}/${args.name}.key'
	path_cert := '${ossl.certpath.path}/${args.name}.crt'
	path_json := '${ossl.certpath.path}/${args.name}.json'
	mut path_keyo := pathlib.get(path_key)
	mut path_certo := pathlib.get(path_cert)
	mut path_jsono := pathlib.get(path_json)

	if args.reset {
		path_keyo.delete()!
		path_certo.delete()!
		path_jsono.delete()!
	}

	r := OpenSSLKey{
		name:      args.name
		domain:    args.domain
		path_key:  path_keyo
		path_cert: path_certo
		path_json: path_jsono
	}

	return r
}

pub fn (mut ossl OpenSSL) exists(args OpenSSLGenerateArgs) !bool {
	mut r := ossl.new(args)!

	if r.path_key.exists() && r.path_cert.exists() && r.path_json.exists() {
		return true
	}

	return false
}

// will get openssl key, from fs if exists, otherwise it will generate
pub fn (mut ossl OpenSSL) get(args OpenSSLGenerateArgs) !OpenSSLKey {
	mut r := ossl.new(args)!
	if r.path_json.exists() {
		jsontext := r.path_json.read()!
		return json.decode(OpenSSLKey, jsontext)
	} else {
		return ossl.generate(args)!
	}
}
