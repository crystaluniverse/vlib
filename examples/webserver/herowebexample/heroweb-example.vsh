#!/usr/bin/env -S v -n -w -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import os
import veb
import freeflowuniverse.crystallib.core.playcmds
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.osal

// TODO: not sure this is needed
os.chdir('${os.home_dir()}/code/github/freeflowuniverse/crystallib/crystallib/webserver/heroweb')!

// heroweb.slides_demo()!

// lets get our collection

// TODO: NEXT IS NOT WORKING, PLEASE HELP FIX

// heroscripts_url:='https://git.ourworld.tf/tfgrid/info_tfgrid/src/branch/development/heroscript/exporter'
// mut plbook := playbook.new(git_url: heroscripts_url,git_pull:true,git_reset:false)!
// console.print_stdout(plbook.str())
// playcmds.run(mut plbook, false)!

//	ABOVE DOESN'T WORK BUT I COULD GET AROUND IT BY
// MAKE SURE HERO HAS BEEN COMPILED USING
// ~/code/github/freeflowuniverse/crystallib/cli/hero/compile.sh  the _dev.sh version doesn't work thats issue of above
// osal.execute_interactive('/Users/despiegk/code/git.ourworld.tf/tfgrid/info_tfgrid/heroscript/exporter/run.sh')!

mut app := heroweb.new('~/code/github/freeflowuniverse/crystallib/examples/webserver/herowebexample/heroscripts')!
veb.run[App, Context](mut app, 8090)
