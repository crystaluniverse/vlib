# Git Repository Management with Gittools

This project demonstrates the use of the `gittools` and `osal` modules from the `freeflowuniverse/crystallib` library to automate basic Git operations such as cloning a repository, creating branches, committing changes, and pushing them to a remote repository.

Features:

- Cloning or retrieving an existing repository.
- Creating and checking out new branches.
- Detecting file changes, adding them to staging, and committing.
- Pushing changes to a remote repository.
- Pulling changes from a remote repository.

### Example Workflow

The following example workflow is included in the script:

```v
// Initializes the Git structure.
import freeflowuniverse.crystallib.develop.gittools

coderoot := '~/code'
mut gs_default := gittools.new(coderoot: coderoot)!

// Retrieve the repository if exists.
mut repo := gs_default.get_repo(name: 'repo3')!
// in case the repo is a new repo and you want to clone it
mut repo := gs_default.get_repo(url: '<repo_url>')!

// Create a new branch and a V file.
branch_name := "testing_branch"
tag_name := "testing_tag"
file_name := "hello_world.v"

// Create a new branch, checkout, add changes, commit, and push.
repo.branch_create(branch_name)!
repo.branch_switch(branch_name)!

if repo.has_changes() {
    repo.commit(msg: "feat: Added ${file_name} file.")!
    repo.push()!
}

// Create tag from the base branch
repo.tag_create(tag_name)!
```

## Tests

The project includes several unit tests to ensure that the functionality works correctly.

To run the tests, use the following command in the project root:

```bash
v -enable-globals test crystallib/develop/gittools/tests/
```

This will run all the test cases and provide feedback on whether they pass or fail.

## Notes

- This project is highly dependent on proper configuration of Git in your environment.
- Ensure that SSH keys or access tokens are properly set up for pushing and pulling to/from the remote repository.
