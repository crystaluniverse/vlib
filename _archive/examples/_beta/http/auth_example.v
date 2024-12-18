import json

// SERVES AS EXAMPLE (prob not working)

struct AuthDetail {
mut:
	auth_token        string
	bio               string
	email             string
	full_name         string
	full_name_display string
	gravatar_id       string
	id                int
	is_active         bool
	username          string
	uuid              string
}

fn (mut h HTTPConnection) auth(url string, login string, passwd string) !AuthDetail {
	/*
	Get authorization token by verifing username and password
	Inputs:
		url: HTTP url.
		login: Username that used in login.
		passwd: Username password.

	Output:
		response: AuthDetails struct contains auth token and other info.
	*/
	h.url = url
	if !h.url.starts_with('http') {
		if h.url.contains('http') {
			return error('url needs to start with http or not contain http. ${h.url} ')
		}
		h.url = 'https://${h.url}'
	}

	data := h.post_json_str(
		prefix:        'auth'
		postdata:      '{
			"password": "${passwd}",
			"type": "normal",
			"username": "${login}"
		}'
		cache_disable: false
	)!

	h.auth = json.decode(AuthDetail, data)!

	return h.auth
}
