module osis

import os
import db.sqlite
import db.pg
import freeflowuniverse.crystallib.data.dbfs
import freeflowuniverse.crystallib.data.encoderhero

pub struct OSIS {
pub mut:
	indexer Indexer // storing indeces
	storer  Storer
}

@[params]
pub struct OSISConfig {
pub:
	directory string
	name      string
	secret    string
	reset     bool
}

pub fn (mut backend OSIS) reset_all() ! {
	panic('implement')
}
