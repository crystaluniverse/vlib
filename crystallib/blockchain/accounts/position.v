module accounts

import freeflowuniverse.crystallib.pathlib
import encoding.binary as bin

pub struct Position {
pub mut:
	asset    u16
	instance u32
	part     u16
}

pub fn (p Position) serialize() []u8 {
	mut data := []u8{len: 8}
	bin.little_endian_put_u16_at(mut data, p.asset, 0)
	bin.little_endian_put_u32_at(mut data, p.instance, 2)
	bin.little_endian_put_u16_at(mut data, p.part, 6)
	return data
}

pub fn deserialize(data []u8) !Position {
	p := Position{
		asset:    bin.little_endian_u16_at(data, 0)
		instance: bin.little_endian_u32_at(data, 2)
		part:     bin.little_endian_u16_at(data, 6)
	}
	return p
}
