module slides

import freeflowuniverse.crystallib.web.components {Row, Cell}

pub struct SlideshowPreview {
pub mut:
	name  string
	title string
	description string
	slides []SlidePreview
	paths   []string
}

pub struct SlidePreview {
pub mut:
	name  string //is the filename
	collection string
	title string
	description string
	notes string
	thumbnail_url string
}

pub fn (slideshow SlideshowPreview) html() string {
	// Define the table structure
	table := Table{
		headers: ['', 'Slideshow', 'Tags', '']
		rows:    rows
	}
	return $tmpl('templates/slideshow_preview.html')
}

pub fn (slide SlidePreview) html() string {
	// Generate table rows based on filtered documents
	row := Row{
		cells: [
			Cell{
				Image{
					typ: .thumbnail
					url: slide.thumbnail_url
				}
			}, // Insert icon HTML directly
			Cell{'<div>
				<a href="" target="_blank">${slide.title}</a>
				<p>${slide.description}</p>
				</div>'},
			// Cell{action_cell(it.name)},
		]
	}

	return row.html()
}