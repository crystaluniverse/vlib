module accounts
import freeflowuniverse.crystallib.pathlib
import encoding.binary as bin
import crypto.ed25519

struct MoneyDB{

}

pub fn db_get(path0 string)! MoneyDB {
	//use the fsdb to get/set the required info, in the future we should check encryption can be turned on
}
