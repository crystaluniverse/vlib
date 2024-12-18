module main

import net.http
import json
import toml

struct CustomResponse {
	status  int
	message string
}

struct SignedAttempt {
	signed_attempt string
	double_name    string
}

struct ResultData {
	double_name string
	state       string
	nonce       string
	ciphertext  string
}

const file_dose_not_exist = "Couldn't parse kyes file, just make sure that you have kyes.toml by running create_keys.v file, then send its path when you running the client app."
const signed_attempt_missing = 'signedAttempt parameter is missing.'
const invalid_json = 'Invalid JSON Payload.'
const no_double_name = 'DoubleName is missing.'
const data_verfication_field = 'Data verfication failed!.'
const not_contain_doublename = 'Decrypted data does not contain (doubleName).'
const not_contain_state = 'Decrypted data does not contain (state).'
const username_mismatch = 'username mismatch!'
const data_decrypting_error = 'Error decrypting data!'
const email_not_verified = 'Email is not verified'

fn parse_keys(file_path string) !toml.Doc {
	return toml.parse_file(file_path)!
}

fn request_to_get_pub_key(username string) !http.Response {
	mut header := http.new_header_from_map({
		http.CommonHeader.content_type: 'application/json'
	})
	config := http.FetchConfig{
		header: header
		method: http.Method.get
	}
	url := 'https://login.threefold.me/api/users/${username}'
	resp := http.fetch(http.FetchConfig{ ...config, url: url })!
	println(resp)
	return resp
}

fn request_to_verify_sei(sei string) !http.Response {
	header := http.new_header_from_map({
		http.CommonHeader.content_type: 'application/json'
	})

	request := http.Request{
		url:    'https://openkyc.live/verification/verify-sei'
		method: http.Method.post
		header: header
		data:   json.encode({
			'signedEmailIdentifier': sei
		})
	}
	result := request.do()!
	return result
}

fn (c CustomResponse) to_json() string {
	return json.encode(c)
}
