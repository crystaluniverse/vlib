module elements

import regex

@[heap]
pub struct Text {
	DocBase // pub mut:
	// 	replaceme string
}

pub fn (mut self Text) process() !int {
	self.processed = true
	return 0
}

pub fn (self Text) markdown() !string {
	return self.content
}

pub fn (self Text) pug() !string {
	return error('cannot return pug, not implemented')
}

pub fn (self Text) html() !string {
	split := self.content.trim_space().split('\n\n')
	mut out := if split.len > 1 {
		split.map('<p>${it}</p>').join('\n')
	} else {self.content}
	out += self.DocBase.html()!

	mut html := out

	// Replace **text** with <strong>text</strong>
    mut bold_re := regex.regex_opt(r'\*\*(.+)\*\*') or { panic(err) }
    html = bold_re.replace_by_fn(html, fn (re regex.RE, in_txt string, start int, end int) string {
        // Extract the matched group
        matched_text := re.get_group_by_id(in_txt, 0)
        return '<strong>$matched_text</strong>'
    })

    // Replace __text__ with <strong>text</strong>
    mut underline_bold_re := regex.regex_opt(r'__(.+)__') or { panic(err) }
    html = underline_bold_re.replace_by_fn(html, fn (re regex.RE, in_txt string, start int, end int) string {
        matched_text := re.get_group_by_id(in_txt, 0)
        return '<strong>$matched_text</strong>'
    })

    // Optionally handle *text* as <em>text</em>
    mut italic_re := regex.regex_opt(r'\*(.+)\*') or { panic(err) }
    html = italic_re.replace_by_fn(html, fn (re regex.RE, in_txt string, start int, end int) string {
        matched_text := re.get_group_by_id(in_txt, 0)
        return '<em>$matched_text</em>'
    })

    // Optionally handle _text_ as <em>text</em>
    mut underline_italic_re := regex.regex_opt(r'_(.+)_') or { panic(err) }
    html = underline_italic_re.replace_by_fn(html, fn (re regex.RE, in_txt string, start int, end int) string {
        matched_text := re.get_group_by_id(in_txt, 0)
        return '<em>$matched_text</em>'
    })

	return html
}
