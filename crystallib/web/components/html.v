module components

pub struct IFrame {
pub mut:
	source string
}

pub fn (iframe IFrame) html() string {
	return '<iframe style="width: 100%; height: 100%"src="${iframe.source}"/>'
}

pub struct Image {
pub:
    typ ImageType
    source string
}

pub enum ImageType {
    @none
    thumbnail
}

pub fn (image Image) html() string {
    style := if image.typ == .thumbnail {
        'border-radius: 5px; height: 80px;'
    } else {
        'height: 40px;'
    }
    return '<img src="${image.source}" alt="Logo" style="${style}">'
}