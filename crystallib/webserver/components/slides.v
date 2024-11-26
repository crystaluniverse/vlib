module components

import freeflowuniverse.crystallib.webserver.components.slides
import json

pub struct Slides {
pub:
	url string
	name string
	log_endpoint string
	format SlideFormat
	data slides.SlidesViewData
}

pub enum SlideFormat {
	pdf
	png
}

pub fn (s Slides) html() string {
	dollar := '$'
	if s.format == .png {
		slides_info := json.encode(s.data)
		return $tmpl('templates/slides_png.html')
	}
	return $tmpl('templates/slides.html')
}