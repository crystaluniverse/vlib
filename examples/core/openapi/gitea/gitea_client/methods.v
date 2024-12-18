module gitea_client

import json
import net.http

// Repository operations
pub fn (mut client GiteaClient) create_repo(name string, description string, private bool) !string {
	data := {
		'name':        name
		'description': description
		'private':     private.str()
	}

	resp := client.connection.post('/api/v1/user/repos', json.encode(data))!
	return resp
}

pub fn (mut client GiteaClient) get_repo(owner string, repo string) !string {
	resp := client.connection.get('/api/v1/repos/${owner}/${repo}')!
	return resp
}

pub fn (mut client GiteaClient) list_repos() !string {
	resp := client.connection.get('/api/v1/user/repos')!
	return resp
}

// User operations
pub fn (mut client GiteaClient) get_user() !string {
	resp := client.connection.get('/api/v1/user')!
	return resp
}

pub fn (mut client GiteaClient) list_users() !string {
	resp := client.connection.get('/api/v1/admin/users')!
	return resp
}

// Organization operations
pub fn (mut client GiteaClient) create_org(name string, description string) !string {
	data := {
		'username':    name
		'description': description
	}

	resp := client.connection.post('/api/v1/orgs', json.encode(data))!
	return resp
}

pub fn (mut client GiteaClient) list_orgs() !string {
	resp := client.connection.get('/api/v1/orgs')!
	return resp
}

// Issue operations
pub fn (mut client GiteaClient) create_issue(owner string, repo string, title string, body string) !string {
	data := {
		'title': title
		'body':  body
	}

	resp := client.connection.post('/api/v1/repos/${owner}/${repo}/issues', json.encode(data))!
	return resp
}

pub fn (mut client GiteaClient) list_issues(owner string, repo string) !string {
	resp := client.connection.get('/api/v1/repos/${owner}/${repo}/issues')!
	return resp
}
