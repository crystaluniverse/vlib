module gitea

import json

@[params]
pub struct SearchOptions {
	q     string // keyword
	uid   i64    // ID of the user to search for
	page  int    // page number of results to return (1-based)
	limit int    // page size of results
}

pub struct SearchUsersResponse {
	data []User
	ok   bool
}

// Get repositories from Gitea
pub fn (mut client GiteaClient[T]) search_users(options SearchOptions) ![]User {
	r := client.connection.get_json(
		prefix: 'users/search'
		data:   json.encode(options)
	)!

	decoded := json.decode(SearchUsersResponse, r)!
	return decoded.data
}

@[params]
pub struct UserReposOptions {
	page  int // page number of results to return (1-based)
	limit int // page size of results
}

// Get repositories from Gitea
pub fn (mut client GiteaClient[T]) user_repos(username string, options UserReposOptions) ![]Repo {
	r := client.connection.get_json_list(
		prefix: 'users/${username}/repos'
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

pub struct User {
pub mut:
	id                  int
	login               string
	login_name          string @[json: 'login_name']
	full_name           string @[json: 'full_name']
	email               string
	avatar_url          string @[json: 'avatar_url']
	language            string
	is_admin            bool   @[json: 'is_admin']
	last_login          string @[json: 'last_login']
	created             string
	restricted          bool
	active              bool
	prohibit_login      bool @[json: 'prohibit_login']
	location            string
	website             string
	description         string
	visibility          string
	followers_count     int @[json: 'followers_count']
	following_count     int @[json: 'following_count']
	starred_repos_count int @[json: 'starred_repos_count']
	username            string
}

struct ExternalTracker {
	external_tracker_format         string
	external_tracker_regexp_pattern string
	external_tracker_style          string
	external_tracker_url            string
}

struct ExternalWiki {
	external_wiki_url string
}

struct InternalTracker {
	allow_only_contributors_to_track_time bool
	enable_issue_dependencies             bool
	enable_time_tracker                   bool
}

struct Owner {
	active              bool
	avatar_url          string
	created             string
	description         string
	email               string
	followers_count     int
	following_count     int
	full_name           string
	id                  int
	is_admin            bool
	language            string
	last_login          string
	location            string
	login               string
	login_name          string
	prohibit_login      bool
	restricted          bool
	starred_repos_count int
	visibility          string
	website             string
}

struct Permissions {
	admin bool
	pull  bool
	push  bool
}

struct Team {
	can_create_org_repo       bool
	description               string
	id                        int
	includes_all_repositories bool
	name                      string
	organization              Organization
	permission                string
	units                     []string
	units_map                 map[string]string
}

struct RepoTransfer {
	doer      Owner
	recipient Owner
	teams     []Team
}

struct Repo {
pub:
	allow_merge_commits               bool
	allow_rebase                      bool
	allow_rebase_explicit             bool
	allow_rebase_update               bool
	allow_squash_merge                bool
	archived                          bool
	archived_at                       string
	avatar_url                        string
	clone_url                         string
	created_at                        string
	default_allow_maintainer_edit     bool
	default_branch                    string
	default_delete_branch_after_merge bool
	default_merge_style               string
	description                       string
	empty                             bool
	external_tracker                  ExternalTracker
	external_wiki                     ExternalWiki
	fork                              bool
	forks_count                       int
	full_name                         string
	has_actions                       bool
	has_issues                        bool
	has_packages                      bool
	has_projects                      bool
	has_pull_requests                 bool
	has_releases                      bool
	has_wiki                          bool
	html_url                          string
	id                                int
	ignore_whitespace_conflicts       bool
	internal                          bool
	internal_tracker                  InternalTracker
	language                          string
	languages_url                     string
	link                              string
	mirror                            bool
	mirror_interval                   string
	mirror_updated                    string
	name                              string
	open_issues_count                 int
	open_pr_counter                   int
	original_url                      string
	owner                             Owner
	parent                            string
	permissions                       Permissions
	private                           bool
	release_counter                   int
	repo_transfer                     RepoTransfer
	size                              int
	ssh_url                           string
	stars_count                       int
	template                          bool
	updated_at                        string
	url                               string
	watchers_count                    int
	website                           string
}
