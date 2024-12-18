module juggler

pub struct GiteaEvent {
pub:
	ref           string @[required]
	before        string
	after         string
	compare_url   string
	commits       []GiteaCommit
	total_commits int
	head_commit   GiteaCommit
	repository    GiteaRepository @[required]
	pusher        User
	sender        User
}

pub struct GiteaCommit {
pub:
	id           string
	message      string
	url          string
	author       CommitUser
	committer    CommitUser
	verification ?string
	timestamp    string
	added        ?[]string
	removed      ?[]string
	modified     ?[]string
}

pub struct CommitUser {
pub:
	name     string
	email    string
	username string
}

pub struct GiteaRepository {
pub:
	id                                int
	owner                             User
	name                              string
	full_name                         string @[required]
	description                       string
	empty                             bool
	private                           bool
	fork                              bool
	template                          bool
	parent                            ?string
	mirror                            bool
	size                              int
	language                          string
	languages_url                     string
	html_url                          string
	url                               string @[required]
	link                              string
	ssh_url                           string
	clone_url                         string @[required]
	original_url                      string
	website                           string
	stars_count                       int
	forks_count                       int
	watchers_count                    int
	open_issues_count                 int
	open_pr_counter                   int
	release_counter                   int
	default_branch                    string
	archived                          bool
	created_at                        string
	updated_at                        string
	archived_at                       string
	permissions                       Permissions
	has_issues                        bool
	internal_tracker                  InternalTracker
	has_wiki                          bool
	has_pull_requests                 bool
	has_projects                      bool
	has_releases                      bool
	has_packages                      bool
	has_actions                       bool
	ignore_whitespace_conflicts       bool
	allow_merge_commits               bool
	allow_rebase                      bool
	allow_rebase_explicit             bool
	allow_squash_merge                bool
	allow_rebase_update               bool
	default_delete_branch_after_merge bool
	default_merge_style               string
	default_allow_maintainer_edit     bool
	avatar_url                        string
	internal                          bool
	mirror_interval                   string
	mirror_updated                    string
	repo_transfer                     ?string
}

pub struct Permissions {
pub:
	admin bool
	push  bool
	pull  bool
}

pub struct InternalTracker {
pub:
	enable_time_tracker                   bool
	allow_only_contributors_to_track_time bool
	enable_issue_dependencies             bool
}

pub struct User {
pub:
	id                  int
	login               string
	login_name          string
	full_name           string
	email               string
	avatar_url          string
	language            string
	is_admin            bool
	last_login          string
	created             string
	restricted          bool
	active              bool
	prohibit_login      bool
	location            string
	website             string
	description         string
	visibility          string
	followers_count     int
	following_count     int
	starred_repos_count int
	username            string
}
