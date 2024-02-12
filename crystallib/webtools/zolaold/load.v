module zola

import v.embed_file
import freeflowuniverse.crystallib.installers.web.zola as zola_installer
import freeflowuniverse.crystallib.webtools.tailwind

@[heap]
pub struct FileLoader {
pub mut:
	embedded_files []embed_file.EmbedFileData @[skip; str: skip]
}

// fn (mut loader FileLoader) load() ! {

// fn loader() !FileLoader{
// 	zola_installer.install()!
// 	mut loader:=FileLoader{}
// 	return loader
// }

// if true {
// 	panic('generate')
// }
// now we have to reset the rev keys, so we remember current status
// for key, mut status in self.gitrepos_status {
// 	osal.done_set('mdbookrev_${key}', status.revnew)!
// 	status.revlast = status.revnew
// }

// pub struct RepoStatus {
// pub mut:
// 	revlast string
// 	revnew  string
// }

// make sure all intial states for the revisions are reset
// fn (mut self MDBooksFactory) reset_state() ! {
// 	for key, mut status in self.gitrepos_status {
// 		osal.done_set('mdbookrev_${key}', '')!
// 		status.revlast = ''
// 	}
// }

// get all content
// pub fn (mut self MDBooksFactory) pull(reset bool) ! {
// 	console.print_header(' pull mdbooks')
// 	print_backtrace()
// 	self.init()!
// 	for key, repo_ in self.gitrepos {
// 		mut repo := repo_
// 		if reset {
// 			repo.pull_reset(reload: true)! // need to overwrite all changes
// 		} else {
// 			repo.pull(reload: true)! // will not overwrite changes
// 		}
// 		revnew := repo.rev()!
// 		lastrev := osal.done_get('mdbookrev_${key}') or { '' }
// 		self.gitrepos_status[key] = RepoStatus{
// 			revnew: revnew
// 			revlast: lastrev
// 		}
// 	}
// }

// @[params]
// pub struct WatchArgs {
// pub mut:
// 	period int = 300 // 5 min default
// 	reset  bool
// }

// pub fn (mut self MDBooksFactory) watch(args WatchArgs) {
// 	mut t := ourtime.now()
// 	mut last := i64(0)
// 	for {
// 		t.now()
// 		console.print_stdout('${t} ${t.unix_time()} period:${args.period}')
// 		if t.unix_time() > last + args.period {
// 			console.print_header(' will try to check the mdbooks')
// 			self.pull(args.reset) or { panic(" - ERROR: couldn't pull the repo's.\n${err}") }
// 			self.generate() or { panic(" - ERROR: couldn't generate the repo's.\n${err}") }
// 			last = t.unix_time()
// 		}
// 		time.sleep(time.second)
// 		if args.period == 0 {
// 			return
// 		}
// 	}
// }
