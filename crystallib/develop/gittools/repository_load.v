module gittools
import time
import freeflowuniverse.crystallib.ui.console

// Load repo information
fn (mut repo GitRepo) load() ! {
	console.print_debug('load ${repo.get_key()}')
	repo.init()!
	repo.exec('git fetch --all') or {
		return error('Cannot fetch repo: ${repo.get_path()!}. Error: ${err}')
	}
	repo.load_branches()!
	repo.load_tags()!
	repo.last_load = int(time.now().unix())
	repo.cache_set()!
}

// Helper to load remote tags
fn (mut repo GitRepo) load_branches() ! {
	
	tags_result := repo.exec("git for-each-ref --format='%(objectname) %(refname:short)' refs/heads refs/remotes/origin")!
	for line in tags_result.split('\n') {
		if line.trim_space() != '' {
			parts := line.split(' ')
			if parts.len == 2 {
				commit_hash := parts[0].trim_space()
				mut name := parts[1].trim_space()
				if name.contains("_archive"){
					continue
				} else if name == "origin"{
					repo.status_remote.ref_default = commit_hash
				} else if name.starts_with("origin"){
					name = name.all_after('origin/').trim_space()
					// Update remote tags info
					repo.status_remote.branches[name] = commit_hash
				}else{
					repo.status_local.branches[name] = commit_hash
				}
			}
		}
	}

	mybranch := repo.exec("git branch --show-current")!.split_into_lines().filter(it.trim_space() != '')
	if mybranch.len==1{
		repo.status_local.branch = mybranch[0].trim_space()
	}
	// Could be a tag.
	// else{
	// 	panic("bug: git branch does not give branchname")
	// }
}

// Helper to load remote tags
fn (mut repo GitRepo) load_tags() ! {
	tags_result := repo.exec('git tag --list')!

	for line in tags_result.split('\n') {
		if line.trim_space() != '' {
			parts := line.split(' ')
			if parts.len == 2 {
				commit_hash := parts[0].trim_space()
				tag_name := parts[1].all_after('refs/tags/').trim_space()

				// Update remote tags info
				repo.status_remote.tags[tag_name] = commit_hash
			}
		}
	}
}