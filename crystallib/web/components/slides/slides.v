module slides

import json

pub struct Slideshow {
pub:
	url string
	name string
	log_endpoint string
	format SlideFormat
	data SlidesViewData
}

pub enum SlideFormat {
	pdf
	png
}

pub fn (s Slideshow) html() string {
	dollar := '$'
	if s.format == .png {
		slides_info := json.encode(s.data)
		return $tmpl('templates/slides_png.html')
	}
	return $tmpl('templates/slides.html')
}