module accounts

import freeflowuniverse.crystallib.pathlib
import encoding.binary as bin

pub struct Asset {
pub mut:
	uid          u16
	name         string
	maxinstances u32
	maxparts     u16 // how many max parts per instance e.g. an art piece can be owned 1/8, so 8 parts. 	
}
