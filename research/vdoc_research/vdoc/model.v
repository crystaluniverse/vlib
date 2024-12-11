module vdoc

// MDoc represents a markdown document with its path and content
@[heap]
pub struct MDoc {
pub mut:
    path    string  // relative path from module root
    content string
}

// VFile represents a V source file with its path and content
@[heap]
pub struct VFile {
pub mut:
    path    string  // relative path from module root
    content string
    structs []VStruct
}
