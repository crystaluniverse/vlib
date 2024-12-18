module rclone

import freeflowuniverse.crystallib.data.paramsparser

pub const version = '1.67.0'
const singleton = false
const default = false

pub fn heroscript_default() !string {
	heroscript := "
	!!rclone.configure
		name: 'default'
		cat: 'b2' 
		s3_account: ''
		s3_key: ''
		s3_secret: ''
		hard_delete: false
		endpoint: ''
        "

	return heroscript
}

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
pub struct RClone {
pub mut:
	name        string = 'default'
	cat         RCloneCat
	s3_account  string
	s3_key      string
	s3_secret   string
	hard_delete bool // hard delete a file when delete on server, not just hide
	endpoint    string
}

pub enum RCloneCat {
	b2
	s3
	ftp
}

fn cfg_play(p paramsparser.Params) !RClone {
	mut mycfg := RClone{
		name:        p.get_default('name', 'default')!
		cat:         match p.get_default('cat', 'b2')! {
			'b2' { RCloneCat.b2 }
			's3' { RCloneCat.s3 }
			'ftp' { RCloneCat.ftp }
			else { return error('Invalid RCloneCat') }
		}
		s3_account:  p.get_default('s3_account', '')!
		s3_key:      p.get_default('s3_key', '')!
		s3_secret:   p.get_default('s3_secret', '')!
		hard_delete: p.get_default_false('hard_delete')
		endpoint:    p.get_default('endpoint', '')!
	}
	return mycfg
}

fn obj_init(obj_ RClone) !RClone {
	mut obj := obj_
	return obj
}
