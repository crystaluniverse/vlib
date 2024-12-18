module vfsnested

import freeflowuniverse.crystallib.vfs.vfscore

// NestedVFS represents a VFS that can contain multiple nested VFS instances
pub struct NestedVFS {
mut:
	vfs_map map[string]vfscore.VFSImplementation // Map of path prefixes to VFS implementations
}

// new creates a new NestedVFS instance
pub fn new() &NestedVFS {
	return &NestedVFS{
		vfs_map: map[string]vfscore.VFSImplementation{}
	}
}

// add_vfs adds a new VFS implementation at the specified path prefix
pub fn (mut self NestedVFS) add_vfs(prefix string, impl vfscore.VFSImplementation) ! {
	if prefix in self.vfs_map {
		return error('VFS already exists at prefix: ${prefix}')
	}
	self.vfs_map[prefix] = impl
}

// find_vfs finds the appropriate VFS implementation for a given path
fn (self &NestedVFS) find_vfs(path string) !(vfscore.VFSImplementation, string) {
	// Sort prefixes by length (longest first) to match most specific path
	mut prefixes := self.vfs_map.keys()
	prefixes.sort(a.len > b.len)

	for prefix in prefixes {
		if path.starts_with(prefix) {
			relative_path := path[prefix.len..]
			if relative_path.starts_with('/') {
				return self.vfs_map[prefix], relative_path[1..]
			}
			return self.vfs_map[prefix], relative_path
		}
	}
	return error('No VFS found for path: ${path}')
}

// Implementation of VFSImplementation interface
pub fn (mut self NestedVFS) root_get() !vfscore.FSEntry {
	// Return a special root entry that represents the nested VFS
	return &RootEntry{
		metadata: vfscore.Metadata{
			name:        ''
			file_type:   .directory
			size:        0
			created_at:  0
			modified_at: 0
			accessed_at: 0
		}
	}
}

pub fn (mut self NestedVFS) file_create(path string) !vfscore.FSEntry {
	mut impl, rel_path := self.find_vfs(path)!
	return impl.file_create(rel_path)
}

pub fn (mut self NestedVFS) file_read(path string) ![]u8 {
	mut impl, rel_path := self.find_vfs(path)!
	return impl.file_read(rel_path)
}

pub fn (mut self NestedVFS) file_write(path string, data []u8) ! {
	mut impl, rel_path := self.find_vfs(path)!
	return impl.file_write(rel_path, data)
}

pub fn (mut self NestedVFS) file_delete(path string) ! {
	mut impl, rel_path := self.find_vfs(path)!
	return impl.file_delete(rel_path)
}

pub fn (mut self NestedVFS) dir_create(path string) !vfscore.FSEntry {
	mut impl, rel_path := self.find_vfs(path)!
	return impl.dir_create(rel_path)
}

pub fn (mut self NestedVFS) dir_list(path string) ![]vfscore.FSEntry {
	// Special case for root directory
	if path == '' || path == '/' {
		mut entries := []vfscore.FSEntry{}
		for prefix, mut impl in self.vfs_map {
			root := impl.root_get() or { continue }
			entries << &MountEntry{
				metadata: vfscore.Metadata{
					name:        prefix
					file_type:   .directory
					size:        0
					created_at:  0
					modified_at: 0
					accessed_at: 0
				}
				impl:     impl
			}
		}
		return entries
	}

	mut impl, rel_path := self.find_vfs(path)!
	return impl.dir_list(rel_path)
}

pub fn (mut self NestedVFS) dir_delete(path string) ! {
	mut impl, rel_path := self.find_vfs(path)!
	return impl.dir_delete(rel_path)
}

pub fn (mut self NestedVFS) exists(path string) !bool {
	mut impl, rel_path := self.find_vfs(path)!
	return impl.exists(rel_path)
}

pub fn (mut self NestedVFS) get(path string) !vfscore.FSEntry {
	mut impl, rel_path := self.find_vfs(path)!
	return impl.get(rel_path)
}

pub fn (mut self NestedVFS) rename(old_path string, new_path string) ! {
	mut old_impl, old_rel_path := self.find_vfs(old_path)!
	mut new_impl, new_rel_path := self.find_vfs(new_path)!

	if old_impl != new_impl {
		return error('Cannot rename across different VFS implementations')
	}

	return old_impl.rename(old_rel_path, new_rel_path)
}

pub fn (mut self NestedVFS) copy(src_path string, dst_path string) ! {
	mut src_impl, src_rel_path := self.find_vfs(src_path)!
	mut dst_impl, dst_rel_path := self.find_vfs(dst_path)!

	if src_impl == dst_impl {
		return src_impl.copy(src_rel_path, dst_rel_path)
	}

	// Copy across different VFS implementations
	data := src_impl.file_read(src_rel_path)!
	dst_impl.file_create(dst_rel_path)!
	return dst_impl.file_write(dst_rel_path, data)
}

pub fn (mut self NestedVFS) link_create(target_path string, link_path string) !vfscore.FSEntry {
	mut impl, rel_path := self.find_vfs(link_path)!
	return impl.link_create(target_path, rel_path)
}

pub fn (mut self NestedVFS) link_read(path string) !string {
	mut impl, rel_path := self.find_vfs(path)!
	return impl.link_read(rel_path)
}

pub fn (mut self NestedVFS) destroy() ! {
	for _, mut impl in self.vfs_map {
		impl.destroy()!
	}
}

// Special entry types for the nested VFS
struct RootEntry {
	metadata vfscore.Metadata
}

fn (e &RootEntry) get_metadata() vfscore.Metadata {
	return e.metadata
}

fn (e &RootEntry) get_path() string {
	return '/'
}

pub struct MountEntry {
pub mut:
	metadata vfscore.Metadata
	impl     vfscore.VFSImplementation
}

fn (e &MountEntry) get_metadata() vfscore.Metadata {
	return e.metadata
}

fn (e &MountEntry) get_path() string {
	return '/${e.metadata.name}'
}
