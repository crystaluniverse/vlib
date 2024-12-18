module gitea

import json

// Get repositories from Gitea
pub fn (mut client GiteaClient[Config]) orgs() ![]Organization {
	r := client.connection.get_json(prefix: 'orgs')!
	return json.decode([]Organization, r)!
}

pub struct Organization {
pub:
	avatar_url                    string
	description                   string
	email                         string
	full_name                     string
	id                            int
	location                      string
	name                          string
	repo_admin_change_team_access bool
	username                      string
	visibility                    string
	website                       string
}

@[params]
pub struct OrgReposOptions {
	page  int // page number of results to return (1-based)
	limit int // page size of results
}

// Get repositories from Gitea
pub fn (mut client GiteaClient[T]) organization_repos(name string, options OrgReposOptions) ![]Repo {
	r := client.connection.get_json_list(
		prefix: 'orgs/${name}/repos'
		data:   json.encode(options)
	)!

	mut res := []Repo{}
	for i in r {
		if i.trim_space() != '' {
			res << json.decode(Repo, i)!
		}
	}
	return res
}
