module blockchain

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.data.encoder
import freeflowuniverse.crystallib.data.dbfs

@[heap]
pub struct AssetPosition {
pub mut:
	amount    f64
	assettype u32
}

pub fn (self AssetPosition) name(db dbfs.DB) AssetPosition {
	return self.assettype.name
}
