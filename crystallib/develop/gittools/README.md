# Git Tools Module

A comprehensive Git management module for V that provides high-level abstractions for Git operations, repository management, and automation of common Git workflows.

## Features

- Repository management (clone, load, delete)
- Branch operations (create, switch, checkout)
- Tag management (create, switch, verify)
- Change tracking and commits
- Remote operations (push, pull)
- SSH key integration
- Submodule support
- Repository status tracking
- Light cloning option for large repositories

## Basic Usage

### Repository Management

```v
import freeflowuniverse.crystallib.develop.gittools

// Initialize with code root directory
mut gs := gittools.new(coderoot: '~/code')!

// Clone a repository
mut repo := gs.clone(GitCloneArgs{
    url: 'git@github.com:username/repo.git'
    sshkey: 'deploy_key'  // Optional SSH key name
})!

// Or get existing repository
mut repo := gs.get_repo(name: 'existing_repo')!

// Delete repository
repo.delete()!
```

### Branch Operations

```v
// Create and switch to new branch
repo.branch_create('feature-branch')!
repo.branch_switch('feature-branch')!

// Check status and commit changes
if repo.has_changes() {
    repo.commit('feat: Add new feature')!
    repo.push()!
}

// Pull latest changes
repo.pull()!

// Pull with submodules
repo.pull(submodules: true)!
```

### Tag Management

```v
// Create a new tag
repo.tag_create('v1.0.0')!

// Switch to tag
repo.tag_switch('v1.0.0')!

// Check if tag exists
exists := repo.tag_exists('v1.0.0')!

// Get tag information
if repo.status_local.tag == 'v1.0.0' {
    // Currently on tag v1.0.0
}
```

## Advanced Features

### SSH Key Integration

```v
// Clone with SSH key
mut repo := gs.clone(GitCloneArgs{
    url: 'git@github.com:username/repo.git'
    sshkey: 'deploy_key'
})!

// Set SSH key for existing repository
repo.set_sshkey('deploy_key')!
```

### Repository Status

```v
// Update repository status
repo.status_update()!

// Check various status conditions
if repo.need_commit() {
    // Has uncommitted changes
}

if repo.need_push_or_pull() {
    // Has unpushed/unpulled changes
}

if repo.need_checkout() {
    // Needs to checkout different branch/tag
}
```

### Change Management

```v
// Check for changes
if repo.has_changes() {
    // Handle changes
}

// Reset all changes
repo.reset()!
// or
repo.remove_changes()!

// Update submodules
repo.update_submodules()!
```

## Repository Configuration

### GitRepo Structure

```v
pub struct GitRepo {
pub mut:
    provider      string              // e.g., github.com
    account       string              // Git account name
    name          string              // Repository name
    status_remote GitRepoStatusRemote // Remote repository status
    status_local  GitRepoStatusLocal  // Local repository status
    status_wanted GitRepoStatusWanted // Desired status
    config        GitRepoConfig       // Repository configuration
    deploysshkey  string              // SSH key for git operations
}
```

### Status Tracking

```v
// Remote Status
pub struct GitRepoStatusRemote {
pub mut:
    ref_default string            // Default branch hash
    branches    map[string]string // Branch name -> commit hash
    tags        map[string]string // Tag name -> commit hash
}

// Local Status
pub struct GitRepoStatusLocal {
pub mut:
    branches map[string]string // Branch name -> commit hash
    branch   string           // Current branch
    tag      string           // Current tag
}

// Desired Status
pub struct GitRepoStatusWanted {
pub mut:
    branch   string
    tag      string
    url      string // Remote repository URL
    readonly bool   // Prevent push/commit operations
}
```

## Error Handling

The module provides comprehensive error handling:

```v
// Clone with error handling
mut repo := gs.clone(url: 'invalid_url') or {
    println('Clone failed: ${err}')
    return
}

// Commit with error handling
repo.commit('feat: New feature') or {
    if err.msg().contains('nothing to commit') {
        println('No changes to commit')
    } else {
        println('Commit failed: ${err}')
    }
    return
}
```

## Testing

Run the test suite:

```bash
v -enable-globals test crystallib/develop/gittools/tests/
```

## Notes

- SSH keys should be properly configured in `~/.ssh/`
- For readonly repositories, all local changes will be reset on pull
- Light cloning option (`config.light: true`) creates shallow clones
- Repository status is automatically cached and updated
- Submodules are handled recursively when specified
- All operations maintain repository consistency
