module osal

// import freeflowuniverse.crystallib.core.texttools
// import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console
import json
import os
import time
// import io.util

pub struct JobError {
	Error
pub mut:
	job        Job
	error_type ErrorType
}

pub enum ErrorType {
	exec
	timeout
	args
}

fn (err JobError) msg() string {
	if err.error_type == .args {
		return 'Error in arguments:\n${err.job.cmd}'
	}
	if err.error_type == .timeout {
		return 'Execution failed timeout\n${err.job}'
	}
	mut msg := 'Execution failed with code ${err.job.exit_code}\n'
	if err.job.cmd.scriptpath.len > 0 {
		msg += '\nscript path:${err.job.cmd.scriptpath}'
	}
	if err.job.output.len > 0 {
		msg += '\n\n## stdout:\n${err.job.output}'
	}
	if err.job.error.len > 0 {
		msg += '\n\n## stderr:\n${err.job.error}'
	}
	return msg
}

fn (err JobError) code() int {
	if err.error_type == .timeout {
		return 9999
	}
	return err.job.exit_code
}

@[params]
pub struct Command {
pub mut:
	name               string // to give a name to your command, good to see logs...
	cmd                string
	description        string
	timeout            int  = 3600 // timeout in sec
	stdout             bool = true
	stdout_log         bool = true
	raise_error        bool = true // if false, will not raise an error but still error report
	ignore_error       bool // means if error will just exit and not raise, there will be no error reporting
	work_folder        string // location where cmd will be executed
	environment        map[string]string // env variables
	ignore_error_codes []int
	scriptpath         string // is the path where the script will be put which is executed
	scriptkeep         bool   // means we don't remove the script
	debug              bool    // if debug will put +ex in the script which is being executed and will make sure script stays
	shell              bool   // means we will execute it in a shell interactive
	retry              int
	interactive        bool = true
	async              bool
	runtime            RunTime
}

pub enum JobStatus {
	init
	running
	error_exec
	error_timeout
	error_args
	done
}

pub enum RunTime {
	bash
	python
	heroscript
	herocmd
	v
}

pub struct Job {
pub mut:
	start     time.Time
	end       time.Time
	cmd       Command
	output    string
	error     string
	exit_code int
	status    JobStatus
	process   ?&os.Process @[skip; str: skip]
	runnr     int // nr of time it runs, is for retry
}

// cmd is the cmd to execute can use ' ' and spaces .
// if \n in cmd it will write it to ext and then execute with bash .
// if die==false then will just return returncode,out but not return error .
// if stdout will show stderr and stdout .
// .
// if cmd starts with find or ls, will give to bash -c so it can execute .
// if cmd has no path, path will be found .
// .
// Command argument: .
//```
// name                             string // to give a name to your command, good to see logs...
// cmd                              string
// description                      string
// timeout                          int  = 3600 // timeout in sec
// stdout                           bool = true
// stdout_log                       bool = true
// raise_error                      bool = true // if false, will not raise an error but still error report
// ignore_error                     bool // means if error will just exit and not raise, there will be no error reporting
// work_folder                      string // location where cmd will be executed
// environment                      map[string]string // env variables
// ignore_error_codes               []int
// scriptpath                       string // is the path where the script will be put which is executed
// scriptkeep                       bool   // means we don't remove the script
// debug                            bool   // if debug will put +ex in the script which is being executed and will make sure script stays
// shell                            bool   // means we will execute it in a shell interactive
// retry                            int
// interactive 					 	bool = true // make sure we run on non interactive way
// async							 bool
// runtime							 RunTime (.bash, .python)
//
// returns Job:
// start  time.Time
// end    time.Time
// cmd    Command
// output []string
// error    []string
// exit_code int
// status JobStatus
// process os.Process
//```
// return Job .
pub fn exec(cmd Command) !Job {
	mut job := Job{
		cmd: cmd
	}
	job.start = time.now()

	if job.cmd.debug {
		job.cmd.stdout = true
		console.print_header(' execute: ${job.cmd.cmd}')
	}

	if cmd.shell {
		// $if debug {
		// 	console.print_debug('cmd shell: ${cmd.cmd}')
		// }
		scriptpath := cmd_to_script_path(job.cmd)!
		os.execvp(scriptpath, [])!
		return job
	}
	if !cmd.async {
		job.execute_retry() or { 
			//println(err)
			return err
		}
	}
	return job
}

// execute the job and wait on result
// will retry as specified
pub fn (mut job Job) execute_retry() ! {
	for x in 0 .. job.cmd.retry + 1 {
		job.execute() or {
			if x == job.cmd.retry {
				//println(job)		
				return err
			}
		}
		//println(job)
		if job.status == .done {
			//means we could execute we can stop
			return
		}
	}
	job.close()!
}

// execute the job, start process, process will not be closed .
// important you need to close the process later by job.close()! otherwise we get zombie processes
pub fn (mut job Job) execute() ! {
	job.runnr += 1
	job.start = time.now()
	job.status = .running

	job.cmd.scriptpath = cmd_to_script_path(job.cmd)!

	// console.print_debug(" - process execute ${process_args[0]}")
	mut p := os.new_process(job.cmd.scriptpath)

	if job.cmd.work_folder.len > 0 {
		p.set_work_folder(job.cmd.work_folder)
	}
	if job.cmd.environment.len > 0 {
		p.set_environment(job.cmd.environment)
	}
	p.set_redirect_stdio()
	// console.print_debug("process setargs ${process_args[1..process_args.len]}")
	// p.set_args(process_args[1..process_args.len])
	if job.cmd.stdout {
		console.print_debug('')
	}
	p.run()
	job.process = p
	job.wait()!
}

// ORDER IS
// EXECUTE
// LOOP -> WAIT -> PROCESS -> READ
// -> CLOSE

// wait till the job finishes or goes in error
pub fn (mut job Job) wait() ! {
	// if job.status != .running && job.status != .init {
	// 	return error('can only wait for running job')
	// }

	for {
		job.process()!
		// console.print_debug(result)
		if job.status == .done {
			// console.print_stderr("wait done")
			job.close()!
			return
		}
		time.sleep(10 * time.millisecond)
	}
	job.close()!
}

// process (read std.err and std.out of process)
pub fn (mut job Job) process() ! {
	// $if debug{console.print_debug(" - job process: $job")}
	if job.status == .init {
		panic('should not be here')
		// job.execute()!
	}
	mut p := job.process or { return error('there is not process on job') }

	// mut result := job.read()!

	job.read()!
	if p.is_alive() {
		job.read()!
		// result=job.read()!
		if time.now().unix() > job.start.unix() + job.cmd.timeout * 1000 {
			// console.print_stderr("TIMEOUT TIMEOUT TIMEOUT TIMEOUT")
			p.signal_pgkill()
			p.close()
			job.exit_code = 9999
			job.end = time.now()
			job.status = .error_timeout
			if job.cmd.raise_error {
				return JobError{
					job: job
					error_type: .timeout
				}
			}
		}
	} else {
		// console.print_stderr(" - process stopped")
		job.read()!
		job.read()!
		job.status = .done
		// result.done = true
		if p.code > 0 {
			// console.print_stderr(' ########## Process CODE IS > 0')
			job.exit_code = p.code
			job.status = .error_exec
			job.cmd.scriptkeep = true
			job.close()!
		}
	}
}

fn (mut job Job) read() ! {
	mut p := job.process or { return error('there is no process on job') }

	// console.print_debug("READ STDOUT")
	out_std := p.pipe_read(.stdout) or { '' }
	// console.print_debug(" OK")
	if out_std.len > 0 {
		if job.cmd.stdout {
			console.print_stdout(out_std)
		}
		job.output += out_std
	}
	// console.print_debug("READ ERROR")
	out_error := p.pipe_read(.stderr) or { '' }
	// console.print_debug(" OK")
	if out_error.len > 0 {
		if job.cmd.stdout {
			console.print_stderr(out_error)
		}
		job.error += out_error
	}
}

// will wait & close
pub fn (mut job Job) close() ! {
	mut p := job.process or { return error('there is no process on job') }
	// console.print_debug("CLOSE")
	p.signal_pgkill()
	p.wait()
	p.close()
	job.end = time.now()
	if job.exit_code > 0 && job.exit_code !in job.cmd.ignore_error_codes {
		if !job.cmd.ignore_error {
			errorpath := job.cmd.scriptpath.all_before_last('.sh') + '_error.json'
			errorjson := json.encode_pretty(job)
			os.write_file(errorpath, errorjson) or {
				msg := 'cannot write errorjson to ${errorpath}'
				return error(msg)
			}

			errorpath2 := job.cmd.scriptpath.all_before_last('.sh') + '_error.log'
			mut errortxt := '# ERROR:\n\n'
			errortxt += job.cmd.cmd + '\n'
			errortxt += '## OUTPUT:\n\n'
			errortxt += job.output
			os.write_file(errorpath2, errortxt) or {
				msg := 'cannot write error to ${errorpath2}'
				return error(msg)
			}

			je := JobError{
				job: job
				error_type: .exec
			}
			if job.cmd.stdout {
				console.print_debug('Job Error')
				console.print_debug(je.msg())
			}
			if job.cmd.raise_error {
				return je
			}
		}
	}

	if job.exit_code == 0 && job.cmd.scriptkeep == false && os.exists(job.cmd.scriptpath) {
		// console.print_debug(job.cmd.scriptpath)	
		os.rm(job.cmd.scriptpath)!
	}
	if job.cmd.ignore_error == false && job.cmd.scriptkeep == false && os.exists(job.cmd.scriptpath) {
		os.rm(job.cmd.scriptpath)!
	}
	// job.status = .done

	if job.cmd.raise_error && job.exit_code > 0 {
		return JobError{
			job: job
			error_type: .exec
		}
	}
}

// shortcut to execute a job silent
pub fn execute_silent(cmd string) !string {
	job := exec(cmd: cmd, stdout: false)!
	return job.output
}

pub fn execute_debug(cmd string) !string {
	job := exec(cmd: cmd, stdout: true, debug: true)!
	return job.output
}

// shortcut to execute a job to stdout
pub fn execute_stdout(cmd string) !string {
	job := exec(cmd: cmd, stdout: true)!
	return job.output
}

// shortcut to execute a job interactive means in shell
pub fn execute_interactive(cmd string) ! {
	exec(cmd: cmd, stdout: true, shell: true)!
}

// executes a cmd, if not error return true
pub fn execute_ok(cmd string) bool {
	res := os.execute(cmd)
	if res.exit_code > 0 {
		return false
	}
	return true
}

pub fn cmd_exists(cmd string) bool {
	cmd1 := 'which ${cmd}'
	res := os.execute(cmd1)
	if res.exit_code > 0 {
		return false
	}
	return true
}

pub fn cmd_exists_profile(cmd string) bool {
	cmd1 := '${profile_path_source_and()} which ${cmd}'
	res := os.execute(cmd1)
	if res.exit_code > 0 {
		return false
	}
	return true
}

// cmd is the cmd to execute can use ' ' and spaces
// if \n in cmd it will write it to ext and then execute with bash
// if die==false then will just return returncode,out but not return error
// if stdout will show stderr and stdout
//
// if cmd starts with find or ls, will give to bash -c so it can execute
// if cmd has no path, path will be found
// $... are remplaced by environment arguments TODO:implement
//
// Command argument:
//   cmd string
//   timeout int = 600
//   stdout bool = true
//   die bool = true
//	 debug bool
//
// return what needs to be executed can give it to bash -c ...
pub fn exec_string(cmd Command) !string {
	mut job := Job{
		cmd: cmd
	}
	job.start = time.now()
	job.cmd.scriptpath = cmd_to_script_path(job.cmd)!
	return job.cmd.scriptpath
}
