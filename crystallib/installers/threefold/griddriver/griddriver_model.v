module griddriver

pub const version = 'v0.1.0'
const singleton = true
const default = true

pub struct GridDriverInstaller {
pub mut:
	name string = 'default'
}

fn obj_init(obj_ GridDriverInstaller) !GridDriverInstaller {
	// never call get here, only thing we can do here is work on object itself
	mut obj := obj_
	return obj
}

fn configure() ! {
}
