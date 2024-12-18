module namecom

import json
import freeflowuniverse.crystallib.clients.httpconnection

pub struct Record {
pub:
	id          int
	domain_name string @[json: 'domainName']
	host        string
	fqdn        string
	type_       string @[json: 'type']
	answer      string
	ttl         int
	priority    ?int
}

struct ListRecordsResponse {
pub:
	records   []Record
	next_page int
	last_page int
}

pub fn (r Record) write() !string {
	s := match r.type_ {
		'A' {
			'a("${r.domain_name}", "${r.answer}", ${r.ttl})'
		}
		'AAAA' {
			'aaaa("${r.domain_name}", "${r.answer}", ${r.ttl})'
		}
		'CNAME' {
			'cname("${r.domain_name}", "${r.answer}", ${r.ttl})'
		}
		'MX' {
			mut prio := 0
			if p := r.priority {
				prio = p
			}
			'mx("${r.domain_name}", "${r.answer}", ${prio}, ${r.ttl})'
		}
		'NS' {
			'ns("${r.domain_name}", "${r.fqdn}", ${r.ttl})'
		}
		'SRV' {
			ans := r.answer.split(' ')
			weight, port, target := ans[0], ans[1], ans[2]
			mut prio := 0
			if p := r.priority {
				prio = p
			}
			'srv("${r.domain_name}", "${target}", ${port}, ${prio}, ${weight}, ${r.ttl})'
		}
		'TXT' {
			'txt("${r.domain_name}", "${r.answer}", "${r.ttl}")'
		}
		else {
			return error('invalid record type: ${r.type_}')
		}
	}
	return s
}

pub fn list_records(domain_name string, username string, token string) !ListRecordsResponse {
	url := 'https://api.name.com/v4/domains/${domain_name}/records'

	mut con := httpconnection.new(
		name: 'mycon'
		url:  url
	)!
	con.basic_auth(username, token)
	mut req := httpconnection.new_request(method: .get)!

	result := con.send(req)!

	if result.code != 200 {
		return error('API request failed with status code ${result.code}: ${result.data}')
	}

	response := json.decode(ListRecordsResponse, result.data) or {
		return error('Failed to parse JSON response: ${err}')
	}

	return response
}

// fn main() {
// 	domain_name := 'example.org'
// 	username := 'mario'
// 	token := 'c17cdf4cb49989c120535cb28be900b133eae244'

// 	records := list_records(domain_name, username, token) or {
// 		println('Error: ${err}')
// 		return
// 	}

// 	println('Records for ${domain_name}:')
// 	for record in records.records {
// 		println('ID: ${record.id}, Host: ${record.host}, Type: ${record.@type}, Answer: ${record.answer}')
// 	}

// 	println('Next page: ${records.next_page}')
// 	println('Last page: ${records.last_page}')
// }
