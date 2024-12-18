module model

import time

pub struct Base {
pub mut:
	id                 u32
	name               string @[index; tag]
	description        string
	remarks            string
	timestamp_creation time.Time
	timestamp_modified time.Time
	guid               string
}
