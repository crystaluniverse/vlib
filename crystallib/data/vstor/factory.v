module vstor

pub fn new() !VSTOR {
	mut spread := ZDBCurrentSpread{
		// spread:[]u32{}
		parts:            3        // nr of parts data needs to be cut in e.g. 16
		parity:           2        // size of parity e.g. 4
		last_check:       0        // 0 means not checked yet
		slice_size_kb:    1024 * 4 // default 4 MB
		compression_type: .nothing
		encryption_type:  .nothing
	}
	mut vstor := VSTOR{
		current_spread: spread
	}
	return vstor
}
