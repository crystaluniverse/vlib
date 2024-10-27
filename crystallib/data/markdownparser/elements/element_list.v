module elements

@[heap]
pub struct List {
	DocBase
pub mut:
	cat            ListCat
	interlinespace int // nr of lines in between
}

pub enum ListCat {
	bullet
	star
	nr
}

pub fn (mut self List) process() !int {
	if self.processed {
		return 0
	}

	self.content = ''
	self.processed = true
	return 1
}

pub fn (mut self List) add_list_item(line string) !&ListItem {
	if !line_is_list(line) {
		return error('line is not a list item')
	}

	mut list_item := ListItem{
		content: line
		type_name: 'listitem'
		parent_doc_: self.parent_doc_
	}
	list_item.process()!

	self.determine_list_item_indentation(mut list_item)!

	return &list_item
}

fn (mut self List) determine_list_item_indentation(mut list_item ListItem) ! {
	if self.children.len == 0 {
		list_item.indent = 0
		self.children << list_item
		return
	}

	for i := self.children.len - 1; i >= 0; i-- {
		mut parent_li := self.children[i]
		if mut parent_li is ListItem {
			if list_item.depth - parent_li.depth < -1 {
				continue
			}
			if list_item.depth - parent_li.depth >= -1 && list_item.depth - parent_li.depth < 2 {
				// same indentation
				list_item.indent = parent_li.indent
				if parent_order := parent_li.order {
					list_item.order = parent_order + 1
				}
				self.children << list_item
			} else if list_item.depth - parent_li.depth >= 2
				&& list_item.depth - parent_li.depth < 6 {
				// increase indentation
				list_item.indent = parent_li.indent + 1
				self.children << list_item
			} else {
				// add content to last list item
				parent_li.content += ' ${list_item.content}'
				parent_li.processed = false
				parent_li.process()!
			}

			return
		}
	}

	return error('current list item ${list_item.content} has less depth/indentation than first list item')
}

pub fn (self List) markdown() !string {
	mut out := ''
	for child in self.children {
		if child is ListItem {
			mut h := ''
			for _ in 0 .. child.indent * 4 {
				h += ' '
			}

			mut pre := '-'
			if order := child.order {
				pre = '${order}.'
			}

			out += '${h}${pre} ${child.markdown()!}\n'
			continue
		}

		out += child.markdown()!
	}

	return out
}

pub fn (self List) pug() !string {
	return error('cannot return pug, not implemented')
}

pub fn (self List) html() !string {
	mut out := ''

	// Determine the type of list based on `ListCat`
	match self.cat {
		.bullet {
			out += '<ul>\n'
		}
		.star {
			out += '<ul style="list-style-type:star;">\n'
		}
		.nr {
			out += '<ol>\n'
		}
	}

	// Iterate over the children to generate the list items
	for child in self.children {
		if child is ListItem {
			// Generate indentation for sublist items
			mut h := ''
			for _ in 0 .. child.indent * 4 {
				h += ' '  // Add spacing for indentation
			}

			mut pre := ''
			if self.cat == .nr && child.order != none {
				pre = '<li value="${child.order}">'
			} else {
				pre = '<li>'
			}

			out += '${h}${pre}${child.html()!}</li>\n'
		}
	}

	// Close the list based on the type
	match self.cat {
		.bullet, .star {
			out += '</ul>\n'
		}
		.nr {
			out += '</ol>\n'
		}
	}

	out = parse_lines_to_html(out.split_into_lines())
	return out
}

fn parse_lines_to_html(lines []string) string {
    mut output := ''
    mut indent_stack := []int{cap: 10} // Tracks indentation levels to manage <ul> and <li>
    mut previous_indent := 0

    for i, line in lines {
        indent := count_leading_whitespace(line)
        clean_line := line.trim_space()

		if i < lines.len - 1 {
			next_indent := count_leading_whitespace(lines[i+1])
			if next_indent > indent {
				// output = output.trim_space().trim_string_right('</li>')
				output = output.trim_space()
				output += '<details>'
				output += '<summary>${line.trim_string_left('<li>').trim_string_left('<li>').trim_string_right('</li>').trim_string_right('</li>')}</summary><ul>'
			}
			else if next_indent < indent {
                output += '</ul></details></li>'
			}
		}

        // Check if we need to open or close <ul> based on indentation
        if indent > previous_indent {
            // More indented, open a new <ul> inside the previous <li>
            // output = output.trim_space().trim_string_right('</li>')
			// output += '<details class="dropdown">'
            indent_stack << indent
        } else if indent < previous_indent {
            // Close previous <ul> and <li> tags when indentation decreases
            for indent_stack.len > 0 && indent < indent_stack.last() {
                // output += '</details></li>'
                indent_stack.pop()
            }
        } 
		// else if indent == previous_indent && indent_stack.len > 0 {
        //     // Close the previous <li> if we're at the same level of indentation
        //     output += '</li>'
        // }

        // Add the cleaned line (the list item) as it is, starting with <li>
        // output += '<li>' + clean_line
        output += clean_line
        previous_indent = indent
    }

    // Close any remaining open <ul> and <li> tags
    for _ in indent_stack {
        output += '</ul></li>'
    }

    return output
}

// Helper function to count leading whitespace (indentation)
fn count_leading_whitespace(line string) int {
    return line.len - line.trim_left(' ').len
}

pub fn line_is_list(line string) bool {
	ltrim := line.trim_space()
	if ltrim == '' {
		return false
	}

	return is_list_item_start(ltrim)
}

pub fn is_list_item_start(line string) bool {
	if line.starts_with('- ') {
		return true
	}

	if line.starts_with('* ') {
		return true
	}

	if line.contains('.') {
		return txt_is_nr(line.all_before('.'))
	}

	return false
}

pub fn txt_is_nr(txt_ string) bool {
	txt := txt_.trim_space()
	for u in txt {
		if u > 47 && u < 58 { // see https://www.charset.org/utf-8
			continue
		}
		return false
	}
	return true
}
