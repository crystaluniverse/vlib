module main

import vweb
import x.json2
import encoding.base64
import libsodium
import os

@['/verify'; post]
fn (mut server ServerApp) verify() !vweb.Result {
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
	server_public_key := keys.value('server.SERVER_PUBLIC_KEY').string()
	server_private_key := keys.value('server.SERVER_SECRET_KEY').string()
	server_pk_decoded_32 := [32]u8{}
	server_sk_decoded_64 := [64]u8{}

	_ := base64.decode_in_buffer(&server_public_key, &server_pk_decoded_32)
	_ := base64.decode_in_buffer(&server_private_key, &server_sk_decoded_64)

	request_data := json2.raw_decode(server.Context.req.data)!
	data := SignedAttempt{
		signed_attempt: request_data.as_map()['signed_attempt']!.str()
		double_name:    request_data.as_map()['double_name']!.str()
	}

	if data.double_name == '' {
		server.abort(400, no_double_name)
	}

	res := request_to_get_pub_key(data.double_name)!
	if res.status_code != 200 {
		server.abort(400, 'Error getting user pub key')
	}

	body := json2.raw_decode(res.body)!
	user_pk := body.as_map()['publicKey']!.str()
	user_pk_buff := [32]u8{}
	_ := base64.decode_in_buffer(&user_pk, &user_pk_buff)
	signed_data := data.signed_attempt

	// This is just workaround becouse we need to access pub key inside verify key and we can not do it while this struct is private.
	signing_key := libsodium.new_signing_key(user_pk_buff, [32]u8{})
	verify_key := signing_key.verify_key
	verifed := verify_key.verify(base64.decode(signed_data))

	if verifed == false {
		server.abort(400, data_verfication_field)
	}

	verified_data := base64.decode(signed_data)
	data_obj := json2.raw_decode(verified_data[64..].bytestr())!
	data_ := json2.raw_decode(data_obj.as_map()['data']!.str())!

	res_data_struct := ResultData{data_obj.as_map()['doubleName']!.str(), data_obj.as_map()['signedState']!.str(), data_.as_map()['nonce']!.str(), data_.as_map()['ciphertext']!.str()}

	if res_data_struct.double_name == '' {
		server.abort(400, not_contain_doublename)
	}

	if res_data_struct.state == '' {
		server.abort(400, not_contain_state)
	}

	if res_data_struct.double_name != data.double_name {
		server.abort(400, username_mismatch)
	}

	nonce := base64.decode(res_data_struct.nonce)
	ciphertext := base64.decode(res_data_struct.ciphertext)

	nonce_bff := [24]u8{}
	unsafe { vmemcpy(&nonce_bff[0], nonce.data, 24) }

	user_curve_pk := []u8{len: 32}
	server_curve_sk := []u8{len: 32}
	server_curve_pk := []u8{len: 32}

	_ := libsodium.crypto_sign_ed25519_pk_to_curve25519(user_curve_pk.data, &user_pk_buff)
	_ := libsodium.crypto_sign_ed25519_pk_to_curve25519(server_curve_pk.data, &server_pk_decoded_32[0])
	_ := libsodium.crypto_sign_ed25519_sk_to_curve25519(server_curve_sk.data, &server_sk_decoded_64[0])

	mut new_private_key := libsodium.PrivateKey{
		public_key: server_curve_pk
		secret_key: server_curve_sk
	}

	mut box := libsodium.Box{
		nonce:      nonce_bff
		public_key: user_curve_pk
		key:        new_private_key
	}

	decrypted_bytes := box.decrypt(ciphertext)
	response_email := json2.raw_decode(decrypted_bytes.bytestr())!
	response := json2.raw_decode(response_email.as_map()['email']!.str())!

	if response.as_map()['email']!.str() == '' {
		server.abort(400, data_decrypting_error)
	}

	sei := response.as_map()['sei']!
	verify_sei := request_to_verify_sei(sei.str())!

	if verify_sei.status_code != 200 {
		server.abort(400, email_not_verified)
	}

	return server.text('${verify_sei.body}')
}
