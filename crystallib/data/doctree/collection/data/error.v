module data

import freeflowuniverse.crystallib.core.pathlib { Path }

pub enum PageErrorCat {
	unknown
	file_not_found
	image_not_found
	page_not_found
	def
}

pub struct PageMultiError {
	Error
pub mut:
	errs []PageError
}

pub fn (err PageMultiError) msg() string {
	return 'Failed in processing page with one or multiple errors: ${err.errs}'
}

pub struct PageError {
	Error
pub mut:
	path Path
	msg  string
	cat  PageErrorCat
}
