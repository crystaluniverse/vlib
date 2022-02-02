module terraform
import os
import crypto.md5

enum TerraformDeploymentStatus {
	init
	ok
	error
}


pub struct TerraformDeploymentArgs {
pub mut:
	name 		string
	mnemonic 	string
	tfnet 		string
	guid		string
	sshkey 		string
}

[heap]
struct TerraformDeployment {
pub:
	name 		string
	path 		string
	mnemonic 	string
	tfnet 		string
	sshkey 		string
	guid 		string
pub mut:
	status TerraformDeploymentStatus
	vms []TFVM
	network TFNet
}


//will put under ~/git3/terraform/$name
pub fn (mut f TerraformFactory) deployment_get(args_ TerraformDeploymentArgs) ?&TerraformDeployment {

	mut args := args_

	if args.sshkey == "" {
		if ! ("TFGRID_SSHKEY" in os.environ()){
			return error("Cannot continue, do 'export TFGRID_SSHKEY=...' ")
		}
		args.sshkey = os.environ()["TFGRID_SSHKEY"].trim_space()
	}
	args.guid = md5.hexhash(args.mnemonic).substr(0,8) //create unique id


	if args.mnemonic == "" {
		if ! ("TFGRID_MNEMONIC" in os.environ()){
			return error("Cannot continue, do 'export TFGRID_MNEMONIC=...' ")
		}
		args.mnemonic = os.environ()["TFGRID_MNEMONIC"].trim_space()
	}
	args.guid = md5.hexhash(args.mnemonic).substr(0,8) //create unique id

	if args.name == ""{
		return error ("specify name for deployment")
	}

	if ! (args.tfnet in ["dev","main","test"]){
		return error ("tfnet needs to be dev,main or test")
	}

	if args.name in f.deployments{
		return f.deployments[args.name]
	}

	mut path := "~/git3/terraform/$args.name"
	if path.contains("~"){
		home := os.real_path(os.environ()["HOME"])
		path = path.replace("~",home)
	}

	f.deployments[args.name] = &TerraformDeployment{
			name:args.name, 
			path:path,
			mnemonic:args.mnemonic,
			tfnet:args.tfnet, 
			sshkey:args.sshkey, 
			guid:args.guid
			}

	if ! os.exists(path){
		os.mkdir_all(path)?	
	}

	return f.deployments[args.name]

}

//execute all available terraform objects
pub fn (mut tfd TerraformDeployment) vm_ubuntu_add(name string, nodeid int) {	
	tfd.vms << TFVM{name:name,tfgrid_node_id:nodeid}
}


//execute all available terraform objects
pub fn (mut tfd TerraformDeployment) execute() ? {	
	tfd.network.execute(mut &tfd)?
	for mut vm in tfd.vms{
		vm.execute(mut &tfd)?
	}
}
