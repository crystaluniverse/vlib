module components

pub struct PDFViewer {
pub:
	name string
	pdf_url string
	log_endpoint string
}

pub fn (component PDFViewer) html() string {
	return $tmpl('./templates/pdf_viewer.html')
}