module tests

import freeflowuniverse.crystallib.osal
import os
import time

struct GittoolsTests {
    coderoot  string
    repo_dir  string
    repo_url  string
    repo_name string
}

// Creates a new Python file with 'Hello, World!' content in the specified repository path.
// The file name includes a timestamp to ensure uniqueness.
//
// Args:
// - repo_path (string): Path to the repository where the new file will be created.
// - runtime (i64): Unix timestamp used to generate a unique file name.
//
// Returns:
// - string: Name of the newly created file.
fn create_new_file(repo_path string)! string {
	coded_now := time.now().unix()
	file_name := 'hello_world_${coded_now}.py'
	osal.execute_silent("echo \"print('Hello, World!')\" > ${repo_path}/${file_name}")!
	return file_name
}

// Sets up a GittoolsTests instance with predefined values for repository setup.
//
// Returns:
// - GittoolsTests: Struct containing information about the repo setup.
fn setup_repo() !GittoolsTests {
    ts := GittoolsTests{
        coderoot: '/tmp/code',
        repo_url: 'https://github.com/Mahmoud-Emad/repo2.git',
    }

    if os.exists(ts.coderoot){
        ts.clean()!
    }

    os.mkdir_all(ts.coderoot)!
    return ts
}

// Removes the directory structure created during repository setup.
//
// Raises:
// - Error: If the directory cannot be removed.
fn (ts GittoolsTests) clean()! {
    os.rmdir_all(ts.coderoot)!
}
