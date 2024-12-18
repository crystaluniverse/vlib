module main

import net.http
import json
import encoding.base64

fn encode(username string, password string) string {
	return base64.encode('${username}:${password}'.bytes())
}

fn register() ? {
	// Push new user into database if this user not registered yet.
	// Otherwise, 400 error, but this will pass because login function working based on same cerds.
	mut header := http.new_header_from_map({
		http.CommonHeader.content_type: 'application/json'
	})
	config := http.FetchConfig{
		header: header
		data:   json.encode({
			'username': 'Emad'
			'password': '0000'
		})
		method: http.Method.post
	}
	url := 'http://localhost:8000/users'
	resp := http.fetch(http.FetchConfig{ ...config, url: url }) or {
		println('failed to fetch data from the server')
		return
	}
	println(resp)
}

fn login() ? {
	mut header := http.new_header_from_map({
		http.CommonHeader.content_type: 'application/json'
	})
	// header.add_custom_map({"Authorization": "Basic " + encode("Emad", "0000")}) ?
	config := http.FetchConfig{
		header: header
		method: http.Method.get
	}
	url := 'http://localhost:8000/users'
	resp := http.fetch(http.FetchConfig{ ...config, url: url }) or {
		println('failed to fetch data from the server')
		return
	}
	println(resp)
}

fn main() {
	register() or { panic(err) }
	login() or { panic(err) }
}
