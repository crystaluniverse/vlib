module deploy

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.clients.httpconnection
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.osal.zinit
import freeflowuniverse.crystallib.installers.threefold.griddriver    

import os

// checks if a certain version or above is installed
fn installed() !bool {
	// griddriver.build()!

	res := os.execute('${osal.profile_path_source_and()} griddriver version')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.trim_space().len > 0)
		if r.len != 1 {
			return error("couldn't parse griddriver version.\n${res.output}")
		}
		if texttools.version(version) > texttools.version(r[0]) {
			return false
		}
	} else {
		return false
	}
	return true
}

fn install() ! {
	console.print_header('install tfdeployer')
	griddriver.install()!
}



//user needs to us switch to make sure we get the right object
fn configure() ! {
    //mut cfg := get()! 
}




fn running() !bool {
    //mut cfg := get()!
    return true
}



fn destroy() ! {
}


fn obj_init()!{
	mut args := get()!
	myenv := os.environ()
	println("mnemonic: ${args.mnemonic}")

	if args.mnemonic == "" && 'TFGRID_MNEMONIC' in myenv{
		args.mnemonic = myenv["TFGRID_MNEMONIC"]
	}

	if args.ssh_key == "" && 'SSH_KEY' in myenv{
		args.ssh_key = myenv["SSH_KEY"]
	}

	if args.mnemonic.len == 0 {
		return error('Please export the `TFGRID_MNEMONIC` and point it to your wallet secret.')
	}

	// Ensure SSH key is provided
	if args.ssh_key.len == 0 {
		return error('SSH key is missing. Please export the `SSH_KEY` environment variable.')
	}

}


fn start_pre()!{
    
}

fn start_post()!{
    
}

fn stop_pre()!{
    
}

fn stop_post()!{
    
}
