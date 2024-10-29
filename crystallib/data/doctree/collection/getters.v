module collection

import freeflowuniverse.crystallib.data.doctree.collection.data

// gets page with specified name from collection
pub fn (collection Collection) page_get(name string) !&data.Page {
	return collection.pages[name] or {
		return ObjNotFound{
			collection: collection.name
			name: name
		}
	}
}

pub fn (collection Collection) page_exists(name string) bool {
	return name in collection.pages
}

// gets image with specified name from collection
pub fn (collection Collection) get_image(name string) !&data.File {
	return collection.images[name] or {
		return ObjNotFound{
			collection: collection.name
			name: name
		}
	}
}

pub fn (collection Collection) image_exists(name string) bool {
	return name in collection.images
}

// gets file with specified name form collection
pub fn (collection Collection) get_file(name string) !&data.File {
	return collection.files[name] or {
		return ObjNotFound{
			collection: collection.name
			name: name
		}
	}
}

pub fn (collection Collection) file_exists(name string) bool {
	return name in collection.files
}
