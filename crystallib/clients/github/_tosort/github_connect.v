module github

import x.json2
import json
import net.http
import freeflowuniverse.crystallib.clients.redisclient { RedisURL }
import freeflowuniverse.crystallib.core.crystaljson
import os
import freeflowuniverse.crystallib.ui.console

@[heap]
struct GithubConnection {
mut:
	url           string = 'https://api.github.com'
	redis         &redisclient.Redis
	auth_token    string
	cache_timeout int
	// pub mut:
	// projects map[int]&Project
}

// Init connection for github singleton
fn init_connection() GithubConnection {
	mut conn := GithubConnection{
		redis: redisclient.core_get(RedisURL{})!
	}
	return conn
}

// Singleton creation
const connection = init_connection()

// Make sure to use new first, so that the connection has been initiated
// then you can get it everywhere
pub fn connection_get() &GithubConnection {
	return &connection
}

pub fn new(cache_timeout int) ?&GithubConnection {
	mut conn := connection_get()

	if 'GITHUBKEY' !in os.environ() {
		return error("make sure 'export GITHUBKEY=...' has been done.")
	} else {
		conn.auth_token = os.environ()['GITHUBKEY']
	}

	// conn.auth(url, login, passwd) or {
	// 	panic("Could not connect to $url with $login and passwd:'$passwd'\n$err")
	// }
	conn.cache_timeout = cache_timeout
	return conn
}

// Get request with json data and return response as string
pub fn (mut h GithubConnection) get_json_str(prefix string, getdata string, cache bool) ?string {
	/*
	Get Request with Json Data
	Inputs:
		prefix: Github elements types, ex (projects, issues, tasks, ...).
		data: Json encoded data.
		cache: Flag to enable caching.

	Output:
		response: response as string.
	*/
	mut result := h.cache_get(prefix, getdata, cache)
	if result == '' {
		url := '${h.url}/${prefix}'
		mut req := http.new_request(http.Method.get, url, getdata)
		req.header = h.header()
		req.add_custom_header('x-disable-pagination', 'True')?
		res := req.do()?
		if res.status_code == 200 {
			result = res.body
		} else {
			return error('could not get: ${url}\n${res}')
		}
		h.cache_set(prefix, getdata, result, cache)?
	}
	return result
}

fn (mut h GithubConnection) header() http.Header {
	/*
	Create a new header for Content type and Authorization

	Output:
		header: http.Header with the needed headers
	*/
	mut header := http.new_header_from_map({
		http.CommonHeader.content_type:  'application/json'
		http.CommonHeader.authorization: 'Bearer ${h.auth_token}'
	})
	return header
}

// fn (mut h GithubConnection) post_json_dict(prefix string, postdata string, cache bool) ?map[string]json2.Any {
// 	/*
// 	Post Request with Json Data
// 	Inputs:
// 		prefix: Github elements types, ex (projects, issues, tasks, ...).
// 		postdata: Json encoded data.
// 		cache: Flag to enable caching.
// 		authenticated: Flag to add authorization flag with the request.

// 	Output:
// 		response: response as dict of further json strings
// 	*/
// 	mut result := h.post_json_str(prefix, postdata, cache) ?
// 	return crystaljson.json_dict_filter_any(result, false, [], [])
// }

// // Post request with json and return result as string
// // this is the method which calls to the service
// fn (mut h GithubConnection) post_json_str(prefix string, postdata string, cache bool) ?string {
// 	/*
// 	Post Request with Json Data
// 	Inputs:
// 		prefix: Github elements types, ex (projects, issues, tasks, ...).
// 		postdata: Json encoded data.
// 		cache: Flag to enable caching.
// 		authenticated: Flag to add authorization flag with the request.

// 	Output:
// 		response: response as string.
// 	*/
// 	// Post with auth header
// 	mut result := ''
// 	cached_data := h.cache_get(prefix, postdata, cache)
// 	if cached_data.len > 0 {
// 		return cached_data
// 	}
// 	url := '$h.url/api/v1/$prefix'
// 	mut req := http.new_request(http.Method.post, url, postdata)
// 	// console.print_debug(" --- $prefix\n$postdata")
// 	if prefix.contains('auth') {
// 		response := http.post_json('$h.url/api/v1/$prefix', postdata) ?
// 		result = response.body
// 	} else {
// 		req.header = h.header()
// 		req.add_custom_header('x-disable-pagination', 'True') ?
// 		response := req.do() ?
// 		if response.status_code == 201 {
// 			result = response.body
// 		} else {
// 			return error('could not post: $url\n$response')
// 		}
// 		result = response.body
// 	}
// 	h.cache_set(prefix, postdata, result, cache) ?
// 	return result
// }

// fn (mut h GithubConnection) get_json_list(prefix string, getdata string, cache bool) ?[]string {
// 	/*
// 	Get Request with Json Data
// 	Inputs:
// 		prefix: Github elements types, ex (projects, issues, tasks, ...).
// 		data: Json encoded data.
// 		cache: Flag to enable caching.

// 	Output:
// 		response: list of strings.
// 	*/
// 	mut result := h.get_json_str(prefix, getdata, cache) ?
// 	return crystaljson.json_list(result, false)
// }

// fn (mut h GithubConnection) edit_json(prefix string, id int, data string) ?string {
// 	/*
// 	Patch Request with Json Data
// 	Inputs:
// 		prefix: Github elements types, ex (projects, issues, tasks, ...).
// 		id: id of the element.
// 		data: Json encoded data.

// 	Output:
// 		response: response Json2.Any map.
// 	*/
// 	url := '$h.url/api/v1/$prefix/$id'
// 	mut req := http.new_request(http.Method.patch, url, data)
// 	req.header = h.header()
// 	mut res := req.do() ?
// 	mut result := ''
// 	if res.status_code == 200 {
// 		result = res.body
// 	} else {
// 		return error('could not get: $url\n$res')
// 	}
// 	return result
// }

// fn (mut h GithubConnection) delete(prefix string, id int) ?bool {
// 	/*
// 	Delete Request
// 	Inputs:
// 		prefix: Github elements types, ex (projects, issues, tasks, ...).
// 		id: id of the element.
// 		cache: Flag to enable caching.

// 	Output:
// 		bool: True if deleted successfully.
// 	*/
// 	url := '$h.url/api/v1/$prefix/$id'
// 	mut req := http.new_request(http.Method.delete, url, '')
// 	req.header = h.header()
// 	mut res := req.do() ?
// 	if res.status_code == 204 {
// 		h.cache_drop(prefix) ? // Drop from cache, will drop too much but is ok
// 		return true
// 	} else {
// 		return error('Could not delete $prefix:$id')
// 	}
// }

// fn (mut h GithubConnection) auth() ?AuthDetail {
// 	/*
// 	Get authorization token by verifing username and password
// 	Inputs:
// 		url: Github url.
// 		login: Username that used in login.
// 		passwd: Username password.

// 	Output:
// 		response: AuthDetails struct contains auth token and other info.
// 	*/
// 	h.url = url
// 	if !h.url.starts_with('http') {
// 		if h.url.contains('http') {
// 			return error('url needs to start with http or not contain http. $h.url ')
// 		}
// 		h.url = 'https://$h.url'
// 	}

// 	data := h.post_json_str('auth', '{
// 			"password": "$passwd",
// 			"type": "normal",
// 			"username": "$login"
// 		}',
// 		false) ?

// 	h.auth = json.decode(AuthDetail, data) ?

// 	return h.auth
// }
