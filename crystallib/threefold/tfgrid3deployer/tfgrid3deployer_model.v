module tfgrid3deployer

import freeflowuniverse.crystallib.data.paramsparser
import os

pub const version = '1.0.0'
const singleton = false
const default = true

pub fn heroscript_default() !string {
	ssh_key := os.getenv_opt('SSH_KEY') or { '' }
	mnemonic := os.getenv_opt('TFGRID_MNEMONIC') or { '' }
	network := os.getenv_opt('TFGRID_NETWORK') or { 'main' } // main,test,dev,qa
	heroscript := "
    !!tfgrid3deployer.configure name:'default'
        ssh_key: '${ssh_key}'
        mnemonic: '${mnemonic}'
        network: ${network}

    "
	if ssh_key.len == 0 || mnemonic.len == 0 || network.len == 0 {
		return error('please configure the tfgrid deployer or set SSH_KEY, TFGRID_MNEMONIC, and TFGRID_NETWORK.')
	}
	return heroscript
}

pub enum Network {
	dev
	main
	test
	qa
}

pub struct TFGridDeployer {
pub mut:
	name     string = 'default'
	ssh_key  string
	mnemonic string
	network  Network
}

fn cfg_play(p paramsparser.Params) !TFGridDeployer {
	network_str := p.get_default('network', 'main')!
	network := match network_str {
		'dev' { Network.dev }
		'test' { Network.test }
		'qa' { Network.qa }
		else { Network.main }
	}

	mut mycfg := TFGridDeployer{
		ssh_key:  p.get_default('ssh_key', '')!
		mnemonic: p.get_default('mnemonic', '')!
		network:  network
	}
	return mycfg
}

fn obj_init(obj_ TFGridDeployer) !TFGridDeployer {
	// never call get here, only thing we can do here is work on object itself
	mut obj := obj_
	return obj
}
