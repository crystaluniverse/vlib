module buildah

pub const version = '1.38.0'
const singleton = true
const default = true

pub struct BuildahInstaller {
pub mut:
	name string = 'default'
}

fn obj_init(obj_ BuildahInstaller) !BuildahInstaller {
	mut obj := obj_
	return obj
}

fn configure() ! {
}
