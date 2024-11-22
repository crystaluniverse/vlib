module accounts
import freeflowuniverse.crystallib.pathlib
import encoding.binary as bin
import crypto.ed25519

pub struct Account{
pub mut:
	uid u32
	pubkey ed25519.PublicKey
	positions []Position
}


// fn (p Position) serialize() []u8 {
// 	mut data = []u8{len: 8}
// 	bin.little_endian_put_u16_at(mut data, p.asset,0)
// 	bin.little_endian_put_u32_at(mut data, p.instance,2)
// 	bin.little_endian_put_u16_at(mut data, p.part,6)
// 	return data
// }

// fn deserialize(data []u8{}len:8) !Position {
// 	p:=Position{
// 		asset:little_endian_u16_at(data,0)
// 		instance:little_endian_u32_at(data,2)
// 		part:little_endian_u16_at(data,6)
// 	}
// 	return p
// }
