module jobmanager

import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.data.encoder

pub struct JobLog {
pub mut:
	id           u32             @[required]
	job          string          @[required] // References Job ID
	log_sequence int             @[required]
	message      string          @[required]
	category     string          @[required]
	log_time     ourtime.OurTime @[required]
}

// encode encodes the JobLog struct to binary format
pub fn (j JobLog) encode() ![]u8 {
	mut e := encoder.new()

	// Add version byte (v1)
	e.add_u8(1)

	// Encode all fields
	e.add_u32(j.id)
	e.add_string(j.job)
	e.add_int(j.log_sequence)
	e.add_string(j.message)
	e.add_string(j.category)
	e.add_u64(u64(j.log_time.unixt))

	return e.data
}

// decode decodes binary data into a JobLog struct
pub fn (mut j JobLog) decode(data []u8) ! {
	if data.len == 0 {
		return error('empty data')
	}

	mut d := encoder.decoder_new(data)

	// Read and verify version
	version := d.get_u8()
	if version != 1 {
		return error('unsupported version ${version}')
	}

	// Decode all fields
	j.id = d.get_u32()
	j.job = d.get_string()
	j.log_sequence = d.get_int()
	j.message = d.get_string()
	j.category = d.get_string()
	j.log_time = ourtime.OurTime{
		unixt: i64(d.get_u64())
	}
}
