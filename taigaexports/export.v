module taigaexports

import json
import net.urllib
import net.http
import time

// TODO: caching

struct Auth {
	username string
	password string
	type_ string [json: "type"] = "normal"
}

struct AuthResult {
	auth_token string
}

struct AsyncExportResult {
	export_id string
}

struct SyncExportResult {
	url string
}

struct Exporter {
mut:
	url string
	api_version string = "v1"
	api_url	string
	username string
	password string
	auth_token string

pub mut:
	// async mode timeouts
	// time to wait between download trials
	async_wait int = 2000 // in millisconds, defaults to 2 seconds
	// time to wait until all download trials are failed
	async_timeout int = 30000 // in millisconds, defaults to 30 seconds
}

pub fn new(url string, username string, password string) ?&Exporter {
	parsed_url := urllib.parse(url)?
	mut path := ''
	if parsed_url.path !in ['', '/'] {
		path = parsed_url.path.trim('/')
	}

	base_url := 'https://$parsed_url.host/$path'.trim('/')

	mut exporter := &Exporter{
		url: base_url,
		username: username,
		password: password
	}

	exporter.api_url = '$base_url/api/$exporter.api_version'
	exporter.authenticate()?
	return exporter
}

// do request and return the full response
pub fn (mut exporter Exporter) do_req(method http.Method, url string, data string, headers map[http.CommonHeader]string) ?http.Response {
	mut req := http.new_request(method, url, data)?
	if headers.len > 0 {
		req.header = http.new_header_from_map(headers)
	}
	return req.do()
}


pub fn (mut exporter Exporter) authenticate()? {
	mut auth := Auth{
		username: exporter.username,
		password: exporter.password
	}

	url := '$exporter.api_url/auth'
	data := json.encode(auth)
	resp := exporter.do_req(http.Method.post, url, data, {
		http.CommonHeader.content_type:  'application/json'
	})?

	if resp.status_code == 200 {
		result := json.decode(AuthResult, resp.text)?
		exporter.auth_token = result.auth_token
	} else {
		return error('autentication failed ($resp.status_code): $resp.text')
	}
}

// do an authenticated request and return the full response
pub fn (mut exporter Exporter) do_auth_req(method http.Method, url string, data string) ?http.Response {
	return exporter.do_req(method, url, data, {
		http.CommonHeader.content_type:  'application/json'
		http.CommonHeader.authorization: 'Bearer $exporter.auth_token'
	})
}

pub fn (mut exporter Exporter) download(url string) ?string {
	resp := exporter.do_auth_req(http.Method.get, url, '')?
	if resp.status_code == 200 {
		return resp.text
	}

	return error('could not download $url ($resp.status_code): $resp.text')
}

pub fn (mut exporter Exporter) export_project(id int, project_slug string) ?ProjectExport {
	// request status need to be checked to decode the result accordingly
	// if the taiga client is async, it will return 202, otherwise it will return 200

	url := '$exporter.api_url/exporter/$id'
	resp := exporter.do_auth_req(http.Method.get, url, '')?
	if resp.status_code == 200 {
		result := json.decode(SyncExportResult, resp.text)?
		data := exporter.download(result.url)?
		return json.decode(ProjectExport, data)
	}

	ch := chan string{}

	if resp.status_code == 202 {
		// here we get an export id, and try to poll the result
		result := json.decode(AsyncExportResult, resp.text)?
		export_url := '$exporter.url/media/exports/$id/$project_slug-${result.export_id}.json'

		go fn (mut exporter Exporter, url string, download_chan chan string) {
			mut trials := 0
			for {
				trials += 1

				println("trial #$trials to download $url")
				download_chan <- exporter.download(url) or {
					println("trial #$trials failed: $err")
					time.sleep(exporter.async_wait * time.millisecond)
					continue
				}

				break
			}
		}(mut exporter, export_url, ch)

		timeout := exporter.async_timeout * time.millisecond
		select {
			data := <- ch {
				return json.decode(ProjectExport, data)
			}
			timeout {
				timeout_in_seconds := timeout / time.second
				return error("timeout waiting for async export for $timeout_in_seconds second(s).")
			}
		}
	}

	return error("exporting error ($resp.status_code): $resp.text")
}
