module osis

import os
import db.sqlite
import db.pg
import freeflowuniverse.crystallib.data.dbfs
import freeflowuniverse.crystallib.data.encoderhero

pub fn (mut o OSIS) generic_new[T](obj T) !u32 {
	id := o.indexer.generic_new[T](obj)!
	o.storer.generic_new[T](obj)!
	return id
}

pub fn (mut o OSIS) generic_get[T](id u32) !T {
	return o.storer.generic_get[T](id)!
}

pub fn (mut o OSIS) generic_set[T](obj T) ! {
	o.indexer.generic_set[T](obj) or { return error('Failed to set new indices:\n${err}') }
	o.storer.generic_set[T](obj)!
}

pub fn (mut o OSIS) generic_delete[T](id u32) ! {
	o.indexer.generic_delete[T](id)!
	o.storer.generic_delete[T](id)!
}

pub fn (mut o OSIS) generic_list[T]() ![]T {
	ids := o.indexer.generic_list[T]()!
	return o.storer.generic_list[T](ids)!
}

pub fn (mut o OSIS) generic_filter[T, D](filter D, params FilterParams) ![]T {
	ids := o.indexer.generic_filter[T, D](filter, params)!
	return o.storer.generic_list[T](ids)!
}

pub fn (mut o OSIS) generic_reset[T]() ! {
	o.indexer.generic_reset[T]()!
	o.storer.generic_reset[T]()!
}
