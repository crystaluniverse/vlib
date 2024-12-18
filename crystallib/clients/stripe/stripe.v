module sms

import net.http
import x.json2
import log
import encoding.base64
import freeflowuniverse.crystallib.ui.console

const success_status = 'queued'

pub struct Client {
pub:
	api_url string = 'https://api.twilio.com/2010-04-01/Accounts'
	token   string
	sid     string
	source  string
pub mut:
	logger log.Log
}

@[params]
pub struct Credentials {
pub:
	sid    string
	token  string
	source string
}

@[params]
pub struct Message {
pub:
	content     string
	destination string
}

pub struct Result {
pub:
	level     StatusTypes
	content   string
	more_info string
}

pub enum StatusTypes {
	error
	success
}

pub fn new_sms_client(cred Credentials, mut logger log.Log) !Client {
	return Client{
		sid:    cred.sid
		token:  cred.token
		source: cred.source
		logger: logger
	}
}

fn (mut c Client) validate_credentials() ! {
	if c.sid != '' && c.token != '' && c.source != '' {
		return
	}

	return error('missing credentials')
}

fn get_value(res json2.Any, key string) string {
	mp := res.as_map()
	ret := mp[key] or {
		console.print_debug("couldn't parse the key: ${key}")
		return ''
	}

	return ret.str()
}

pub fn (mut c Client) get_auth_headers() !http.Header {
	mut headers_map := map[string]string{}
	token := base64.encode_str('${c.sid}:${c.token}')
	headers_map['Authorization'] = 'Basic ${token}'
	headers := http.new_custom_header_from_map(headers_map)!

	return headers
}

pub fn (mut c Client) get_data_form(msg Message) !map[string]string {
	mut data := map[string]string{}
	data['To'] = msg.destination
	data['Body'] = msg.content
	data['From'] = c.source

	return data
}

pub fn (mut c Client) send(msg Message) !Result {
	c.validate_credentials() or { return error(err.str()) }

	headers := c.get_auth_headers()!
	form := c.get_data_form(msg)!

	post_form := http.PostMultipartFormConfig{
		form:   form
		header: headers
	}

	res := http.post_multipart_form('${c.api_url}/${c.sid}/Messages.json', post_form)!

	res_obj := json2.raw_decode(res.body) or {
		c.logger.error(err.str())
		return Result{}
	}

	if get_value(res_obj, 'status') != success_status {
		return Result{
			level:     .error
			content:   get_value(res_obj, 'message')
			more_info: get_value(res_obj, 'more_info')
		}
	}

	return Result{
		level:   .success
		content: get_value(res_obj, 'body')
	}
}
