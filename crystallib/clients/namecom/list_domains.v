module namecom

// import net.http
import freeflowuniverse.crystallib.clients.httpconnection
// import net.http
// import encoding.base64
import json

struct Domain {
pub:
	domain_name       string @[json: 'domainName']
	locked            bool
	autorenew_enabled bool   @[json: 'autorenewEnabled']
	expire_date       string @[json: 'expireDate']
	create_date       string @[json: 'createDate']
}

struct ListDomainsResponse {
pub:
	domains   []Domain
	next_page int
	last_page int
}

pub fn list_domains(username string, token string) !ListDomainsResponse {
	mut con := httpconnection.new(
		name: 'mycon'
		url:  'https://api.name.com/v4/domains'
	)!
	con.basic_auth(username, token)
	mut req := httpconnection.new_request(method: .get)!

	result := con.send(req)!

	if result.code != 200 {
		return error('API request failed with status code ${result.code}: ${result.data}')
	}

	list_domains_response := json.decode(ListDomainsResponse, result.data) or {
		return error('Failed to decode JSON: ${err}')
	}

	return list_domains_response
}

// pub fn list_records(domain_name string, username string, token string) !ListRecordsResponse {

// fn main() {
// 	username := 'your_username'
// 	token := 'your_api_token'
// 	url := 'https://api.name.com/v4/domains'

// mut con := httpconnection.new(
// 	name: 'mycon'
// 	url: url
// 	// method: .get
// 	// header: http.new_header(
// 	// 	key: 'Authorization'
// 	// 	value: 'Basic ' + base64.encode(username + ':' + token)
// 	// )
// )!
// req := httpconnection.new_request(method: .get, header: http.new_header(
// 		key: .authorization
// 		value: 'Basic ' + base64.encode((username + ':' + token).bytes())
// 	))!

// result := con.send(req)!

// // response := http.fetch(config) or {
// // 	println('Failed to fetch: $err')
// // 	return
// // }

// // if response.status_code != 200 {
// // 	println('Error: ${response.status_code} ${response.status_msg}')
// // 	return
// // }

// list_domains_response := json.decode(ListDomainsResponse, result.data) or {
// 	println('Failed to decode JSON: $err')
// 	return
// }

// println('Domains:')
// for domain in list_domains_response.domains {
// 	println('- ${domain.domain_name}')
// 	println('  Locked: ${domain.locked}')
// 	println('  Autorenew Enabled: ${domain.autorenew_enabled}')
// 	println('  Expire Date: ${domain.expire_date}')
// 	println('  Create Date: ${domain.create_date}')
// 	println('')
// }

// if list_domains_response.next_page > 0 {
// 	println('Next Page: ${list_domains_response.next_page}')
// }
// if list_domains_response.last_page > 0 {
// 	println('Last Page: ${list_domains_response.last_page}')
// }
// }
