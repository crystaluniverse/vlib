module accounts
import freeflowuniverse.crystallib.pathlib
import freeflowuniverse.crystallib.encoder
import encoding.binary as bin
import crypto.ed25519
import libsodium

pub struct PrivKeysSafe{
pub mut:	
	path pathlib.Path
	secret string
	privatekeys map[int]PrivKey
}

pub: struct PrivKey{
pub:
	id   u16
	name string
	privkey libsodium.PrivateKey
	signkey	ed25519.PrivateKey
}

pub (pk PrivKey) serialize(){
	mut e := encoder.encoder_new()
	e.add_u16(pk.id)
	e.add_string(pk.name)
	e.add_bytes(pk.privkey.)
	e.add_bytes(pk.signkey)
}


pub fn keysafe_get(path0 string,secret string)! PrivKeysSafe {
	mut safe:=PrivKeysSafe{path:pathlib.get(path0),secret:secret}
	return safe
}

pub (mut ks PrivKeysSafe) generate(count int){
	mut e := encoder.encoder_new()
	ks.privatekeys
	for i in 0..count{
		pubkey,privkey:=ed25519.generate_key()!
		pk:=PrivKey{
			id:i
			name:"name${id}"
			privkey:privkey
			signkey:
		}
		ks.privatekeys[i]=pk
	}

}

pub (mut ks PrivKeysSafe) serialize(){
	mut out:=[]u8{}
	for key,item in ks.privatekeys{
		out << 
	}
}