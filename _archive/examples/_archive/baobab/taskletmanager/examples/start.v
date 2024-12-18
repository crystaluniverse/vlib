module main

import freeflowuniverse.crystallib.taskletmanager
import freeflowuniverse.crystallib.actionrunner

const taskletspath = '~/code/github/threefoldtech/farmerbot/tasklets'

const jobspath = '~/code/github/threefoldtech/farmerbot/jobsexamples'

fn do() ! {
	taskletmanager.generate(taskletspath)!
	mut tm := taskletmanager.new(taskletspath)!
	println(tm)
	// actionrunner.scheduler_new(jobspath)!
}

fn main() {
	do() or { panic(err) }
}
