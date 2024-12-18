module gitea

import json

// Get repositories from Gitea
pub fn (mut client GiteaClient[T]) get_issues(owner string, repo string) ![]Issue {
	r := client.connection.get_json_list(prefix: 'repos/${owner}/${repo}/issues')!
	mut res := []Issue{}
	for i in r {
		if i.trim_space() != '' {
			res << json.decode(Issue, i)!
		}
	}
	return res
}

pub struct Repository {
pub mut:
	id        int
	name      string
	owner     string
	full_name string @[json: 'full_name']
}

pub struct Issue {
pub mut:
	id                 int
	url                string
	html_url           string @[json: 'html_url']
	number             int
	user               User
	original_author    string @[json: 'original_author']
	original_author_id int    @[json: 'original_author_id']
	title              string
	body               string
	ref                string
	assets             []string // Assuming assets is an array of strings; adjust based on actual data structure
	labels             []string // Assuming labels is an array of strings; adjust based on actual data structure
	milestone          ?string  // Use option type if the field can be null
	assignee           ?User    // Use option type if the field can be null, adjust based on actual data structure
	assignees          ?[]User  // Use option type if the field can be null, adjust based on actual data structure
	state              string
	is_locked          bool @[json: 'is_locked']
	comments           int
	created_at         string @[json: 'created_at']
	updated_at         string @[json: 'updated_at']
	closed_at          ?string // Use option type if the field can be null
	due_date           ?string // Use option type if the field can be null
	pull_request       ?string // Use option type if the field can be null, adjust based on actual data structure
	repository         Repository
	pin_order          int @[json: 'pin_order']
}
