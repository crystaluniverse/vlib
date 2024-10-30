#!/usr/bin/env -S v -cg -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.osal
import time


mut gs_default := gittools.new()!

println(gs_default)

// // Initializes the Git structure with the coderoot path.
// coderoot := '/tmp/code'
// mut gs_tmo := gittools.new(coderoot: coderoot)!

// // Retrieve the specified repository.
// mut repo := gs_default.get_repo(name: 'crystallib')!

// println(repo)
