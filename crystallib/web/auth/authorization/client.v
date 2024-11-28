module authorization

import net.http
import json

pub struct Client {
	url string
}

pub fn (c Client) authorize(request AccessRequest) !bool {
	data := json.encode(request)
	req := http.new_request(.get, '${c.url}/authorize', data)
	resp := req.do()!
	if resp.status_code != 200 {
		return error(resp.body)
	}
	return resp.body == 'true'
}

pub fn (c Client) add_admin(user_id string) ! {
	req := http.new_request(.get, '${c.url}/add_admin', user_id)
	resp := req.do()!
	if resp.status_code != 200 {
		return error(resp.body)
	}
}
