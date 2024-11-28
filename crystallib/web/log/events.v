module log

import time

@[params]
pub struct ViewEvent {
pub mut:
	page string
	duration time.Duration
}