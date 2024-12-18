module main

import json
import x.json2
import net.http
import toml

struct CustomResponse {
	status  int
	message string
}

struct SignedAttempt {
	signed_attempt string
	double_name    string
}

fn (c CustomResponse) to_json() string {
	return json.encode(c)
}

fn (s SignedAttempt) load(data map[string]string) !SignedAttempt {
	data_ := json2.raw_decode(data['signedAttempt'])!
	signed_attempt := data_.as_map()['signedAttempt']!.str()
	double_name := data_.as_map()['doubleName']!.str()
	initial_data := SignedAttempt{signed_attempt, double_name}
	return initial_data
}

const file_dose_not_exist = "Couldn't parse kyes file, just make sure that you have kyes.toml by running create_keys.v file, then send its path when you running the client app."
const signed_attempt_missing = 'signedAttempt parameter is missing.'
const server_host = 'http://localhost:8000'

fn parse_keys(file_path string) !toml.Doc {
	return toml.parse_file(file_path)!
}

fn url_encode(map_ map[string]string) string {
	mut formated := ''

	for k, v in map_ {
		if formated != '' {
			formated += '&' + k + '=' + v
		} else {
			formated = k + '=' + v
		}
	}
	return formated
}

fn request_to_server_to_verify(data SignedAttempt) !http.Response {
	header := http.new_header_from_map({
		http.CommonHeader.content_type: 'application/json'
	})

	request := http.Request{
		url:    '${server_host}/verify'
		method: http.Method.post
		header: header
		data:   json.encode(data)
	}
	result := request.do()!
	return result
}
