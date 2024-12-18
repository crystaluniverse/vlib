module milvus

import net.http
import x.json2

pub struct Client {
	endpoint string = 'http://localhost:19530'
	token    string
}

pub fn new(endpoint string, token string) Client {
	return Client{
		endpoint: endpoint
		token:    token
	}
}

fn (c Client) add_headers(mut r http.Request) ! {
	r.add_custom_header('Authorization', 'Bearer ${c.token}')!
	r.add_custom_header('content-type', 'application/json')!
	r.add_custom_header('accept', 'application/json')!
}

pub struct MilvusResponse {
pub mut:
	code    u32
	data    json2.Any
	message ?string
}

fn (c Client) do_request(mut req http.Request) !json2.Any {
	c.add_headers(mut req)!
	res := req.do()!
	if res.status() != http.Status.ok {
		return error('${res.status_code} ${res.status_msg}')
	}

	milvus_response := json2.raw_decode(res.body) or {
		return error('failed to decode milvus response: ${err}')
	}

	mp := milvus_response.as_map()
	code := mp['code'] or { return error('invalid response body: ${milvus_response}') }
	if code.u64() != 200 {
		message := mp['message'] or { '' }
		return error('milvus error ${code.u64()}: ${message}')
	}

	data := mp['data'] or { return error('invalid response body: ${milvus_response}') }
	return data
}
