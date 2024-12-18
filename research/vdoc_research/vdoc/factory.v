module vdoc

// VDocFactory holds documentation for V modules containing both V and markdown files
pub struct VDocFactory {
pub mut:
	modules   []VModule
	scan_root string // root path where scanning started
}

// create_factory initializes a new VDocFactory
pub fn new() VDocFactory {
	return VDocFactory{
		modules:   []VModule{}
		scan_root: ''
	}
}

// get_module returns a module by its path if it exists
pub fn (factory VDocFactory) get_module(path string) ?&VModule {
	for i, mod in factory.modules {
		if mod.path == path {
			return &factory.modules[i]
		}
	}
	return none
}

// exists_module checks if a module exists by path
pub fn (factory VDocFactory) exists_module(path string) bool {
	return factory.get_module(path) != none
}
