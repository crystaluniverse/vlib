module sshagent
import console
import os
import path
import process

fn listsplit(key string) string{
	if key.trim(" ")==""{
		return ""
	}
	if key.contains(" "){
		splitted := key.split(" ")
		return splitted[splitted.len].replace(".pub","")
	}
	return key
}

//will see if there is one ssh key in sshagent
// or if not, if there is 1 ssh key in ~/.ssh/ if yes will load
// if we were able to define the key to use, it will be returned here
// will return the key which will be used
pub fn load_interactive() ?string {
	mut pubkeys := pubkeys_get()
	pubkeys.map(listsplit)	
	if pubkeys.len == 1{
		console.ask_yesno(description:"We found sshkey ${pubkeys[0]} in sshagent, want to use this one?"){
			key_load(pubkeys[0])?
			return pubkeys[0]
		}
	}
	if pubkeys.len > 1{
		if console.ask_yesno(description:"We found more than 1 sshkey in sshagent, want to use one of those?"){
			keytouse := console.ask_dropdown(items:pubkeys, description:"Please choose the ssh key you want to use")
			key_load(keytouse)?
			return keytouse
		}
	}

	//now means nothing in ssh-agent, lets see if we find 1 key in .ssh directory
	mut sshdirpath := path.get_dir('$os.home_dir()/.ssh',true)?

	pubkeys = []string{}

	for p in sshdirpath.file_list(".pub",false)?{
		pubkeys << p.path.replace(".pub","")
	}
	// println(keypaths)

	if pubkeys.len == 1{
		if console.ask_yesno(description:"We found sshkey ${pubkeys[0]} in ~/.ssh dir, want to use this one?"){
			key_load(pubkeys[0])?
			return pubkeys[0]
		}
	}
	if pubkeys.len > 1{
		if console.ask_yesno(description:"We found more than 1 sshkey in ~/.ssh dir, want to use one of those?"){			
			keytouse := console.ask_dropdown(items:pubkeys, description:"Please choose the ssh key you want to use")
			key_load(keytouse)?
			return keytouse
		}
	}

	if console.ask_yesno(description:"Would you like to generate a new key?"){	
		name := console.ask_question(question:"name",minlen:3)
		passphrase := console.ask_question(question:"passphrase",minlen:5)

		keytouse := key_generate(name,passphrase)?

		// if console.ask_yesno(description:"Please acknowledge you will remember your passphrase for ever (-: ?"){
		// 	key_load(keytouse)?
		// 	return keytouse
		// }else{
		// 	return error("Cannot continue, did not find sshkey to use")
		// }
		key_load_with_passphrase(keytouse,passphrase)?

	}
	return error("Cannot continue, did not find sshkey to use")

	// url_github_add := "https://library.threefold.me/info/publishtools/#/sshkey_github"
	
	// process.execute_interactive("open $url_github_add")?

	// if console.ask_yesno(description:"Did you manage to add the github key to this repo ?"){
	// 	println( " - CONGRATS: your sshkey is now loaded.")
	// }

	// return keytouse


}

//will see if there is one ssh key in sshagent
// or if not, if there is 1 ssh key in ~/.ssh/ if yes will return
// if we were able to define the key to use, it will be returned here
pub fn pubkey_guess() ?string {

	pubkeys := pubkeys_get()
	if pubkeys.len == 1{
		return pubkeys[0]
	}
	if pubkeys.len > 1{
		return error("There is more than 1 ssh-key loaded in ssh-agent, cannot identify which one to use.")
	}
	//now means nothing in ssh-agent, lets see if we find 1 key in .ssh directory
	mut sshdirpath := path.get_dir('$os.home_dir()/.ssh',true)?

	mut keypaths := sshdirpath.file_list(".pub",false)?
	// println(keypaths)

	if keypaths.len==1{
		keycontent := keypaths[0].read()?
		privkeypath := keypaths[0].path.replace(".pub","")
		key_load(privkeypath)?
		return keycontent
	}
	if keypaths.len>1{
		return error("There is more than 1 ssh-key in your ~/.ssh dir, could not automatically load.")
	}
	return error("Could not find sshkey in your ssh-agent as well as in your ~/.ssh dir, please generate an ssh-key")
}

//see which sshkeys are loaded in ssh-agent
pub fn pubkeys_get() []string {
	mut pubkeys := []string{}
	res := os.execute('ssh-add -L')
	if res.exit_code == 0 {
		for line in res.output.split('\n') {
			if line.trim(' ') == '' {
				continue
			}
			if line.contains('/.ssh/') {
				//this way we know its an ssh line
				pubkeys << line.trim(" ")
			}
		}
	}
	return pubkeys	
}

//is the ssh-agent loaded?
pub fn loaded() bool {
	res := os.execute('ssh-add -l')
	if res.exit_code == 0 {
		return true
	} else {
		return false
	}
}

//returns path to sshkey
pub fn key_generate(name string, passphrase string)?string{
	dest := "${os.environ()["HOME"]}/.ssh/$name"
	if os.exists(dest){
		os.rm(dest)?
	}
	cmd := "ssh-keygen -t ed25519 -f $dest -P $passphrase -q"
	println(cmd)
	rc := os.execute(cmd)
	if ! (rc.exit_code == 0){
		return error("Could not generated sshkey,\n$rc")
	}
	return "${os.environ()["HOME"]}/.ssh/$name"
}

pub fn reset() ? {
	_ := os.execute('ssh-add -D')
}

pub fn key_load(keypath string) ? {
	_ := os.execute('ssh-add $keypath')
}

pub fn key_load_with_passphrase(keypath string, passphrase string) ? {
	_ := os.execute('ssh-add $keypath')
}



// pub fn ssh_agent_keys() []string{
// 	res := os. execute("ssh-add -l")
// 	if res.exit_code==0{
// 		println(res)
// 		panic("sA")
// 		return []string{}
// 	}else{
// 		println(res)
// 		panic("sB")		
// 		return []string{}
// 	}
// }

// check if key loaded
// return if key found, and how many ssh keys found in general
pub fn key_loaded(name string) (bool, int) {
	mut counter := 0
	mut exists := false
	res := os.execute('ssh-add -l')
	if res.exit_code == 0 {
		for line in res.output.split('\n') {
			if line.trim(' ') == '' {
				continue
			}
			counter++
			if line.contains('.ssh/$name ') {
				// space at end is needed because then we know its not partial part of ssh key
				exists = true
			}
		}
	}
	return exists, counter
}
