module tests

import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.osal
import os
import time

__global (
    branch_name_tests string
    tag_name_tests string
    repo_path_tests string
    repo_tests gittools.GitRepo
    repo_setup_tests GittoolsTests
)

// Setup function that initializes global variables for use across tests.
// This simulates lifecycle methods like `before_all` and runs before the tests.
fn setup_generate_globals(){
    runtime := time.now().unix()
    branch_name_tests = "branch_${runtime}"
    tag_name_tests = "tag_${runtime}"
}

// Function that runs at the start of the testsuite, ensuring that the repository
// is set up and global variables are initialized for the tests.
fn testsuite_begin() {
    setup_generate_globals()
}

fn testsuite_end() {
  repo_setup_tests.clean()!
}

// Test cloning a Git repository and verifying that it exists locally.
//
// This test performs the following steps:
// - Sets up the repository directory and global variables.
// - Clones the repository using a provided URL.
// - Verifies that the repository's path exists in the local filesystem.
[test]
fn test_clone_repo() {
    repo_setup_tests = setup_repo()!
    mut gs := gittools.new(coderoot: repo_setup_tests.coderoot)!
    repo_tests = gs.get_repo(url: repo_setup_tests.repo_url)!
    repo_path_tests = repo_tests.get_path()!
    assert os.exists(repo_path_tests) == true
}

// Test creating a new branch in the Git repository.
//
// This test performs the following steps:
// - Clones the repository.
// - Creates a new branch using the global `branch_name_tests` variable.
// - Verifies that the new branch was created but not checked out.
[test]
fn test_branch_create() {
    repo_tests.branch_create(branch_name_tests)!
    assert repo_tests.status_local.branch != branch_name_tests
}

// Test switching to an existing branch in the repository.
//
// This test performs the following steps:
// - Ensures the repository is set up.
// - Switches to the branch created in the `test_branch_create` test.
// - Verifies that the branch was successfully switched.
[test]
fn test_switch() {
    repo_tests.branch_switch(branch_name_tests)!
    assert repo_tests.status_local.branch == branch_name_tests
}

// Test creating a tag in the Git repository.
//
// This test performs the following steps:
// - Ensures the repository is set up.
// - Creates a tag using the global `tag_name_tests` variable.
// - Verifies that the tag was successfully created in the repository.
[test]
fn test_tag_create() {
    repo_tests.tag_create(tag_name_tests)!
    assert repo_tests.tag_exists(tag_name_tests)! == true
}

// Test detecting changes in the repository, adding changes, and committing them.
//
// This test performs the following steps:
// - Clones the repository and creates a new file.
// - Verifies that the repository has unstaged changes after creating the file.
// - Stages and commits the changes, then verifies that there are no more unstaged changes.
[test]
fn test_has_changes_add_changes_commit_changes() {
    file_name := create_new_file(repo_path_tests)!
    assert repo_tests.has_changes()! == true
    mut unstaged_changes := repo_tests.get_changes_unstaged()!
    assert unstaged_changes.len == 1
    mut staged_changes := repo_tests.get_changes_staged()!
    assert staged_changes.len == 0
    commit_msg := 'feat: Added ${file_name} file.'
    repo_tests.commit(commit_msg)!
    staged_changes = repo_tests.get_changes_staged()!
    assert staged_changes.len == 0
    unstaged_changes = repo_tests.get_changes_unstaged()!
    assert unstaged_changes.len == 0
}

// Test pushing changes to the repository.
//
// This test performs the following steps:
// - Clones the repository and creates a new branch.
// - Creates a new file and commits the changes.
// - Verifies that the changes have been successfully pushed to the remote repository.
[test]
fn test_push_changes() {
    file_name := create_new_file(repo_path_tests)!
    assert repo_tests.has_changes()! == true
    mut unstaged_changes := repo_tests.get_changes_unstaged()!
    assert unstaged_changes.len == 1
    mut staged_changes := repo_tests.get_changes_staged()!
    assert staged_changes.len == 0
    commit_msg := 'feat: Added ${file_name} file.'
    repo_tests.commit(commit_msg)!
    repo_tests.push()!
    staged_changes = repo_tests.get_changes_staged()!
    assert staged_changes.len == 0
    unstaged_changes = repo_tests.get_changes_unstaged()!
    assert unstaged_changes.len == 0
}

// Test performing multiple commits and pushing them.
//
// This test performs the following steps:
// - Clones the repository.
// - Creates multiple files.
// - Commits each change and pushes them to the remote repository.
[test]
fn test_multiple_commits_and_push() {
    file_name_1 := create_new_file(repo_path_tests)!
    repo_tests.commit('feat: Added ${file_name_1} file.')!

    file_name_2 := create_new_file(repo_path_tests)!
    repo_tests.commit('feat: Added ${file_name_2} file.')!

    repo_tests.push()!
    assert repo_tests.has_changes()! == false
}

// Test committing with valid changes.
//
// This test performs the following steps:
// - Creates a new file in the repository.
// - Verifies that there are uncommitted changes.
// - Commits the changes.
[test]
fn test_commit_with_valid_changes() {
    file_name_1 := create_new_file(repo_path_tests)!
    assert repo_tests.need_commit()! == true
    repo_tests.commit('Initial commit')!
}

// Test committing without changes.
//
// This test performs the following steps:
// - Verifies that there are no uncommitted changes.
// - Attempts to commit and expects a failure.
[test]
fn test_commit_without_changes() {
    assert repo_tests.has_changes()! == false
    assert repo_tests.need_commit()! == false
    repo_tests.commit('Initial commit') or {
        assert false, 'Commit should be done with some changes'
    }
}

// Test pushing with no changes.
//
// This test verifies that pushing with no changes results in no action.
[test]
fn test_push_with_no_changes() {
    assert repo_tests.need_push_or_pull()! == false
    repo_tests.push() or {
        assert false, 'Push should not perform any action when no changes exist'
    }
}

// Test pulling remote changes.
//
// This test ensures that the pull operation succeeds without errors.
[test]
fn test_pull_remote_changes() {
    repo_tests.pull() or {
        assert false, 'Pull should succeed'
    }
}

// Test creating and switching to a new branch.
//
// This test creates a new branch and then switches to it.
[test]
fn test_create_and_switch_new_branch() {
    repo_tests.branch_create('testing-branch') or {
        assert false, 'Branch creation should succeed'
    }

    repo_tests.branch_switch('testing-branch') or {
        assert false, 'Branch switch should succeed'
    }
}

// Test creating and switching to a tag.
//
// This test creates a new tag and then switches to it.
[test]
fn test_create_and_check_tag() {
    repo_tests.tag_create('v1.0.0') or {
        assert false, 'Tag creation should succeed'
    }

    repo_tests.tag_exists('v1.0.0') or {
        assert false, 'Tag switch should succeed'
    }
}

// Test removing changes.
//
// This test verifies that changes are successfully removed after they are made.
[test]
fn test_remove_changes() {
    mut unstaged_changes := repo_tests.get_changes_unstaged()!
    assert unstaged_changes.len == 0

    mut staged_changes := repo_tests.get_changes_staged()!
    assert staged_changes.len == 0

    file_name := create_new_file(repo_path_tests)!
    assert repo_tests.has_changes()! == true

    unstaged_changes = repo_tests.get_changes_unstaged()!
    assert unstaged_changes.len == 1

    staged_changes = repo_tests.get_changes_staged()!
    assert staged_changes.len == 0

    repo_tests.remove_changes() or {
        assert false, 'Changes should be removed successfully'
    }

    unstaged_changes = repo_tests.get_changes_unstaged()!
    assert unstaged_changes.len == 0

    staged_changes = repo_tests.get_changes_staged()!
    assert staged_changes.len == 0
}
