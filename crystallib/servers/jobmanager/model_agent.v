module jobmanager

import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.data.encoder

pub struct Agent {
pub mut:
	id          u32    @[required]
	name        string @[required]
	description string
	ipaddr      string
	pubkey      string
	location    string
	create_date ourtime.OurTime
}

// encode encodes the Agent struct to binary format
pub fn (a Agent) encode() ![]u8 {
	mut e := encoder.new()

	// Add version byte (v1)
	e.add_u8(1)

	// Encode all fields
	e.add_u32(a.id)
	e.add_string(a.name)
	e.add_string(a.description)
	e.add_string(a.ipaddr)
	e.add_string(a.pubkey)
	e.add_string(a.location)
	e.add_u64(u64(a.create_date.unixt))

	return e.data
}

// decode decodes binary data into an Agent struct
pub fn (mut a Agent) decode(data []u8) ! {
	if data.len == 0 {
		return error('empty data')
	}

	mut d := encoder.decoder_new(data)

	// Read and verify version
	version := d.get_u8()
	if version != 1 {
		return error('unsupported version ${version}')
	}

	// Decode all fields in same order as encoded
	a.id = d.get_u32()
	a.name = d.get_string()
	a.description = d.get_string()
	a.ipaddr = d.get_string()
	a.pubkey = d.get_string()
	a.location = d.get_string()
	unix := d.get_u64()
	a.create_date = ourtime.OurTime{
		unixt: i64(unix)
	}
}
