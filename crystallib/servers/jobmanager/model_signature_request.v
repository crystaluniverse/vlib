module jobmanager

import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.data.encoder

pub struct SignatureRequest {
pub mut:
	id        u32    @[required]
	job       u32    @[required] // References Job ID
	pubkey    string @[required]
	signature string
	date      ourtime.OurTime
	verified  bool
}

// encode encodes the SignatureRequest struct to binary format
pub fn (s SignatureRequest) encode() ![]u8 {
	mut e := encoder.new()

	// Add version byte (v1)
	e.add_u8(1)

	// Encode all fields
	e.add_u32(s.id)
	e.add_u32(s.job)
	e.add_string(s.pubkey)
	e.add_string(s.signature)
	e.add_u64(u64(s.date.unixt))
	e.add_u8(u8(if s.verified { 1 } else { 0 }))

	return e.data
}

// decode decodes binary data into a SignatureRequest struct
pub fn (mut s SignatureRequest) decode(data []u8) ! {
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
	s.id = d.get_u32()
	s.job = d.get_u32()
	s.pubkey = d.get_string()
	s.signature = d.get_string()
	s.date = ourtime.OurTime{
		unixt: i64(d.get_u64())
	}
	s.verified = d.get_u8() == 1
}
