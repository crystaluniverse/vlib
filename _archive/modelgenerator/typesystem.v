module modelgenerator

import encoding.binary as bin
import time

type PrimTypeSum = []i64
	| []int
	| []string
	| []time.Time
	| []u16
	| []u32
	| []u64
	| []u8
	| i64
	| int
	| string
	| time.Time
	| u16
	| u32
	| u64
	| u8

enum CRTypeCat {
	u64
	u32
	u16
	u8
	int
	i64
	string
	time
	object
}

pub struct CRType {
pub mut:
	list  bool      // if true then is a list
	cat   CRTypeCat // is for item in list or the item itself
	size  u32       // in bytes per item (if no list), or 1 item of a list if list
	model &Model    // the model linked to this field
}

pub struct CRTypeInstance {
pub mut:
	data   []u8
	crtype CRType
}

pub fn new_primitive(data PrimTypeSum) CRTypeInstance {
	mut o := CRTypeInstance{
		crtype: CRType{
			model: &Model{}
		}
	}
	match data {
		u8 {
			o.crtype = CRType{
				cat:   .u8
				size:  u32(1)
				model: &Model{}
			}
			o.data = [data]
		}
		u16 {
			o.data = []u8{len: 2}
			o.crtype = CRType{
				cat:   .u16
				size:  u32(2)
				model: &Model{}
			}
			bin.little_endian_put_u16(mut o.data, data)
		}
		u32 {
			o.data = []u8{len: 4}
			o.crtype = CRType{
				cat:   .u32
				size:  u32(4)
				model: &Model{}
			}
			bin.little_endian_put_u32(mut o.data, data)
		}
		int {
			o.data = []u8{len: 4}
			o.crtype = CRType{
				cat:   .int
				size:  u32(4)
				model: &Model{}
			}
			bin.little_endian_put_u32(mut o.data, u32(data)) // is wrong: TODO:
		}
		i64 {
			o.data = []u8{len: 8}
			o.crtype = CRType{
				cat:   .u64
				size:  u32(8)
				model: &Model{}
			}
			bin.little_endian_put_u64(mut o.data, u64(data)) // is wrong: TODO:
		}
		string {
			o.data = data.bytes()
			o.crtype = CRType{
				cat:   .string
				model: &Model{}
			}
		}
		time.Time {
			epoch := u64(data.unix_time()) // need to think this through, is ok for now, but no dates < 1970
			o.data = []u8{len: 8}
			bin.little_endian_put_u64(mut o.data, epoch)
			o.crtype = CRType{
				cat:   .time
				size:  u32(8)
				model: &Model{}
			}
		}
		[]u8 {
			for childdata in data {
				mut primitive_obj := new_primitive(childdata)
				o.crtype = CRType{
					list:  true
					cat:   .u8
					size:  u32(1)
					model: &Model{}
				}
				o.data << primitive_obj.data
			}
		}
		[]u16 {
			for childdata in data {
				mut primitive_obj := new_primitive(childdata)
				o.crtype = CRType{
					list:  true
					cat:   .u16
					size:  u32(2)
					model: &Model{}
				}
				o.data << primitive_obj.data
			}
		}
		[]u32 {
			for childdata in data {
				mut primitive_obj := new_primitive(childdata)
				o.crtype = CRType{
					list:  true
					cat:   .u32
					size:  u32(4)
					model: &Model{}
				}
				o.data << primitive_obj.data
			}
		}
		[]int {
			for childdata in data {
				mut primitive_obj := new_primitive(childdata)
				o.crtype = CRType{
					list:  true
					cat:   .u32
					size:  u32(4)
					model: &Model{}
				}
				o.data << primitive_obj.data
			}
		}
		[]i64 {
			for childdata in data {
				mut primitive_obj := new_primitive(childdata)
				o.crtype = CRType{
					list:  true
					cat:   .u64
					size:  u32(8)
					model: &Model{}
				}
				o.data << primitive_obj.data
			}
		}
		[]string {
			for childdata in data {
				mut primitive_obj := new_primitive(childdata)
				o.crtype = CRType{
					list:  true
					cat:   .string
					model: &Model{}
				}
				o.data << primitive_obj.data
			}
		}
		[]time.Time {
			for childdata in data {
				mut primitive_obj := new_primitive(childdata)
				o.crtype = CRType{
					list:  true
					cat:   .time
					size:  u32(8)
					model: &Model{}
				}
				o.data << primitive_obj.data
			}
		}
		else {
			panic("can't find type for : ${data}")
		}
	}
	return o
}

// TODO: need to do decode
// TODO: need to complement for all know types
