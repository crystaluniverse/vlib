module rpcsocket

import json
import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.data.encoder

pub struct Job {
pub mut:
	id            u32              @[required]
	actor         string          @[required]
	action        string          @[required]
	params        string                     // JSON string
	job_type      string          @[required]
	create_date   ourtime.OurTime @[required]
	schedule_date ourtime.OurTime @[required]
	finish_date    ourtime.OurTime
	locked_until   ourtime.OurTime
	completed      bool         
	state         JobState        @[required]
	error         string
	recurring     string        
	deadline      ourtime.OurTime
	signature     string
	executor       u32
	agent         u32                    // References Agent.name
}

// Get params as a JSON object
pub fn (j Job) params_get[T]() !T {
	if j.params == '' {
		return error('No params set')
	}
	return json.decode(T, j.params)!
}

// Set params from a JSON-serializable object
pub fn (mut j Job) params_set[T](params T) ! {
	j.params = json.encode(params)
}

pub enum JobState {
	init
	running
	error
	halted
	completed
	cancelled
}

// encode encodes the Job struct to binary format
pub fn (j Job) encode() ![]u8 {
	mut e := encoder.new()
	
	// Add version byte (v1)
	e.add_u8(1)
	
	// Encode all fields
	e.add_u32(j.id)
	e.add_string(j.actor)
	e.add_string(j.action)
	e.add_string(j.params)
	e.add_string(j.job_type)
	
	// Encode OurTime fields as unix timestamps
	e.add_u64(u64(j.create_date.unixt))
	e.add_u64(u64(j.schedule_date.unixt))
	e.add_u64(u64(j.finish_date.unixt))
	e.add_u64(u64(j.locked_until.unixt))
	e.add_u64(u64(j.deadline.unixt))
	
	e.add_u8(u8(if j.completed { 1 } else { 0 }))
	unsafe { e.add_u8(u8(j.state)) }
	e.add_string(j.error)
	e.add_string(j.recurring)
	e.add_string(j.signature)
	e.add_u32(j.executor)
	e.add_u32(j.agent)
	
	return e.data
}

// decode decodes binary data into a Job struct
pub fn (mut j Job) decode(data []u8) ! {
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
	j.actor = d.get_string()
	j.action = d.get_string()
	j.params = d.get_string()
	j.job_type = d.get_string()
	
	// Decode OurTime fields from unix timestamps
	j.create_date = ourtime.OurTime{unixt: i64(d.get_u64())}
	j.schedule_date = ourtime.OurTime{unixt: i64(d.get_u64())}
	j.finish_date = ourtime.OurTime{unixt: i64(d.get_u64())}
	j.locked_until = ourtime.OurTime{unixt: i64(d.get_u64())}
	j.deadline = ourtime.OurTime{unixt: i64(d.get_u64())}
	
	j.completed = d.get_u8() == 1
	unsafe { j.state = JobState(d.get_u8()) }
	j.error = d.get_string()
	j.recurring = d.get_string()
	j.signature = d.get_string()
	j.executor = d.get_u32()
	j.agent = d.get_u32()
}
