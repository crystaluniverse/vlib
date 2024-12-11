module zola

fn test_section_export() {
	mut section := Section{}
	section.export('test')!
}
