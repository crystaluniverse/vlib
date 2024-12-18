module main

import os
import freeflowuniverse.crystallib.baobab.models.people
import sqlite

const testpath = os.dir(@FILE) + '/data'

fn do() ! {
	mut db := sqlite.connect('/tmp/tmp_models_people.db')!
	mut p := people.new(db: db, circle: 1)!
	p.actions_import(testpath)! // will go over the actions an import then in the people space
}

fn main() {
	do() or { panic(err) }
}
