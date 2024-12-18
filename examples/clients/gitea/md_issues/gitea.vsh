#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.clients.gitea
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
import cli { Command, Flag }
import os

// configures cli command and flags
fn main() {
	mut cmd := Command{
		name:        'mdgen'
		description: 'Markdown generator from gitea issues'
		execute:     mdgen
	}
	cmd.add_flag(Flag{
		flag:          .string
		name:          'output_path'
		abbrev:        'o'
		default_value: ['.']
		description:   'Path the OpenRPC client will be created at.'
	})
	cmd.add_flag(Flag{
		flag:        .string_array
		name:        'users'
		abbrev:      'u'
		description: 'Filter user repositories for issues.'
	})
	cmd.add_flag(Flag{
		flag:        .string_array
		name:        'organizations'
		abbrev:      'x'
		description: 'Filter organization repositories for issues.'
	})
	cmd.add_flag(Flag{
		flag:        .string_array
		name:        'repositories'
		abbrev:      'r'
		description: 'Issues of repositories to be generated from.'
	})
	cmd.setup()
	cmd.parse(os.args)
}

// mdgen is the main command of the cli. Fetches filtered issues and
// generates md files for users, issues and repos
fn mdgen(cmd Command) ! {
	filter_users := cmd.flags.get_strings('users')!
	filter_repos := cmd.flags.get_strings('repositories')!
	filter_orgs := cmd.flags.get_strings('organizations')!
	target := cmd.flags.get_string('output_path')!

	issues := get_issues(
		users:         filter_users
		repositories:  filter_repos
		organizations: filter_orgs
	)!
	write_issues(issues, target)!

	users := get_users(issues)!
	write_users(users, target)!

	repos := get_repos(issues)
	write_repos(repos, target)!
}

// filter for fetching issues, passed with to cli
pub struct Filter {
	users         []string
	repositories  []string
	organizations []string
}

struct Issue {
	gitea.Issue
mut:
	name string
}

// get_issues returns filtered issues fetched from gitea api
// uses credentials if provided
fn get_issues(filter Filter) ![]Issue {
	username := os.getenv('GITEA_USERNAME')
	password := os.getenv('GITEA_PASSWORD')
	mut client := gitea.get(instance: 'example')!
	mut cfg := client.config()!
	cfg.url = 'git.ourworld.tf'
	cfg.username = username
	cfg.password = password
	client.config_save()!

	if username != '' && password != '' {
		client.connection.basic_auth(username, password)
	}

	repos := if filter.repositories.len == 0 {
		repo_objs := client.search_repos()!
		repo_objs.map(it.full_name)
	} else {
		filter.repositories
	}

	mut issues := []gitea.Issue{}
	for repo in repos {
		owner := repo.split('/')[0]
		name := repo.split('/')[1]
		if filter.users.len > 1 && owner !in filter.users {
			continue
		}
		if filter.organizations.len > 1 && owner !in filter.organizations {
			continue
		}
		if filter.repositories.len > 1 && repo !in filter.repositories {
			continue
		}
		issues << client.get_issues(owner, name)!
	}

	return issues.map(Issue{
		Issue: it
		name:  '${it.id}_${texttools.name_fix(it.title)}'
	})
}

// writes issues in target/issues dir
fn write_issues(issues []Issue, target string) ! {
	issue_dir := pathlib.get_dir(
		path:   '${target}/issues'
		create: true
	)!
	for issue in issues {
		issue.write(issue_dir.path)!
	}
}

fn (issue Issue) write(dir string) ! {
	assignees_str := create_assignees_str(issue)
	mut file := pathlib.get_file(
		path:   '${dir}/${issue.name}.md'
		create: true
	)!
	file.write($tmpl('./templates/issue.md'))!
}

fn create_assignees_str(issue Issue) string {
	return if assignee := issue.assignee {
		'[${assignee.username}](${assignee.avatar_url})'
	} else {
		if assignees := issue.assignees {
			assignees.map('[${it.username}](${it.avatar_url})').join(', ')
		} else {
			'none'
		}
	}
}

struct User {
	gitea.User
mut:
	assigned []Issue
	created  []Issue
}

// get_users gets users that have created or been assigned
// to an issue in a given list of issues
fn get_users(issues []Issue) ![]User {
	mut user_map := map[string]User{}
	for issue in issues {
		// add to user's created issues
		if issue.user.username !in user_map {
			user_map[issue.user.username] = User{
				User: issue.user
			}
		}
		user_map[issue.user.username].created << issue

		// add to user's assigned issue for all assignees
		mut assignees := issue.assignees or { []gitea.User{} }
		if assignee := issue.assignee {
			assignees << assignee
		}
		for assignee in assignees {
			if assignee.username !in user_map {
				user_map[issue.user.username] = User{
					User: issue.user
				}
			}
			user_map[issue.user.username].assigned << issue
		}
	}
	return user_map.values()
}

// writes users in target/users dir
fn write_users(users []User, target string) ! {
	user_dir := pathlib.get_dir(
		path:   '${target}/users'
		create: true
	)!
	for user in users {
		user.write(user_dir.path)!
	}
}

fn (user User) write(dir string) ! {
	mut file := pathlib.get_file(
		path:   '${dir}/${texttools.name_fix(user.username)}.md'
		create: true
	)!
	file.write($tmpl('./templates/user.md'))!
}

struct Repository {
	gitea.Repository
mut:
	issues []Issue
}

// get_repos returns the repositories that are the parents of a list of issues
fn get_repos(issues []Issue) []Repository {
	mut repo_map := map[string]Repository{}
	for issue in issues {
		if issue.repository.full_name !in repo_map {
			repo_map[issue.repository.full_name] = Repository{
				Repository: issue.repository
			}
		}
		repo_map[issue.repository.full_name].issues << issue
	}
	return repo_map.values()
}

// writes repositories in target/repositories dir
fn write_repos(repos []Repository, target string) ! {
	repo_dir := pathlib.get_dir(
		path:   '${target}/repositories'
		create: true
	)!
	for repo in repos {
		repo.write(repo_dir.path)!
	}
}

fn (repo Repository) write(dir string) ! {
	mut file := pathlib.get_file(
		path:   '${dir}/${texttools.name_fix(repo.owner)}/${texttools.name_fix(repo.name)}.md'
		create: true
	)!
	file.write($tmpl('./templates/repository.md'))!
}
