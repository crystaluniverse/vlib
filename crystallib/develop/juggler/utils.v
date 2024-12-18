module juggler

import time
import json
import net.http

// get repository returns the Repository which belongs to the webhook being evented
pub fn (mut j Juggler) get_event(req http.Request) !Event {
	mut event := match git_service(req)! {
		.gitea {
			j.get_gitea_event(req.data)!
		}
		.github {
			j.get_github_event(req.data)!
		}
		else {
			return error('Unsupported git service.')
		}
	}
	event.time = time.now()
	return event
}

pub fn (mut j Juggler) get_gitea_event(data string) !Event {
	event := json.decode(GiteaEvent, data) or { return error('failed to decode gitea event') }

	name_split := event.repository.full_name.split('/')
	if name_split.len != 2 {
		return error('invalid gitea event format')
	}

	repo := Repository{
		owner:  name_split[0]
		name:   name_split[1]
		host:   event.repository.clone_url.trim_string_left('https://').all_before('/')
		branch: event.ref.all_after_last('/')
	}

	repos := j.osis.generic_list[Repository]()!
	repo_lst := repos.filter(it.owner == repo.owner && it.name == repo.name && it.host == repo.host
		&& it.branch == repo.branch)
	if repo_lst.len < 1 {
		return error('repo ${repo} not found in repos ${repos}')
	}
	repo_id := repo_lst[0].id

	if event.commits.len == 0 {
		return error('event contains no commits')
	}
	commit := event.commits[0]
	return Event{
		commit:    Commit{
			committer: commit.committer.name
			hash:      commit.id
			message:   commit.message
			time:      time.parse_iso8601(commit.timestamp)!
			url:       commit.url
		}
		object_id: repo_id
	}
}

pub fn (mut j Juggler) get_github_event(data string) !Event {
	payload := json.decode(GitHubPayload, data) or { return error('failed to decode github event') }

	repo := Repository{
		owner:  payload.repository.owner.name
		name:   payload.repository.name
		host:   'github.com'
		branch: payload.ref.all_after_last('/')
	}

	repos := j.osis.generic_list[Repository]()!
	repo_lst := repos.filter(it.owner == repo.owner && it.name == repo.name && it.host == repo.host
		&& it.branch == repo.branch)
	if repo_lst.len < 1 {
		return error('repo ${repo} not found in repos ${repos}')
	}
	repo_id := repo_lst[0].id

	return Event{
		object_id: repo_id
		commit:    Commit{
			hash:      payload.commits[0].id
			url:       payload.commits[0].url
			message:   payload.commits[0].message
			committer: payload.commits[0].committer.name
			time:      time.parse_iso8601(payload.commits[0].timestamp)!
		}
	}
}

pub enum GitService {
	@none
	gitea
	github
}

// git_service returns the git service responsible for a request
pub fn git_service(req http.Request) !GitService {
	user_agent := req.header.get(.user_agent)!
	if user_agent.starts_with('GitHub-Hookshot') {
		return .github
	}
	return .gitea
}
