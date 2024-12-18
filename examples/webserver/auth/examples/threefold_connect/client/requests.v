module main

import vweb
import json
import rand
import encoding.base64
import libsodium
import toml
import os

const redirect_url = 'https://login.threefold.me'
const sign_len = 64

@['/login']
fn (mut client ClientApp) login() !vweb.Result {
	app_id := client.get_header('Host')
	mut server_public_key := ''

	mut key_path := ''
	if os.args.len > 1 {
		key_path = os.args[1]
	}
	if key_path == '' {
		key_path = os.getwd()
	}
	mut p := pathlib.get_dir(path: key_path, create: false)!
	mut keyspath := p.file_get_new('keys.toml')!

	keys := parse_keys(keyspath.path)!
	if keys.value('server') == toml.Any(toml.Null{}) {
		client.abort(400, file_dose_not_exist)
	} else {
		server_public_key = keys.value('server.SERVER_PUBLIC_KEY').string()
	}
	server_pk_decoded_32 := [32]u8{}
	server_curve_pk := []u8{len: 32}

	_ := base64.decode_in_buffer(&server_public_key, &server_pk_decoded_32)
	_ := libsodium.crypto_sign_ed25519_pk_to_curve25519(server_curve_pk.data, &server_pk_decoded_32[0])

	state := rand.uuid_v4().replace('-', '')
	params := {
		'state':       state
		'appid':       app_id
		'scope':       json.encode({
			'user':  true
			'email': true
		})
		'redirecturl': '/callback'
		'publickey':   base64.encode(server_curve_pk[..])
	}
	return client.redirect('${redirect_url}?${url_encode(params)}')
}

@['/callback']
fn (mut client ClientApp) callback() !vweb.Result {
	data := SignedAttempt{}
	query := client.query.clone()

	if query == {} {
		client.abort(400, signed_attempt_missing)
	}

	initial_data := data.load(query)!
	res := request_to_server_to_verify(initial_data)!
	return client.text('${res.body}')
}
