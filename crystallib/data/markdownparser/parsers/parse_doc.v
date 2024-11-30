module parsers

import freeflowuniverse.crystallib.data.markdownparser.elements
// import freeflowuniverse.crystallib.ui.console

// DO NOT CHANGE THE WAY HOW THIS WORKS, THIS HAS BEEN DONE AS A STATEFUL PARSER BY DESIGN
// THIS ALLOWS FOR EASY ADOPTIONS TO DIFFERENT RELIALITIES
pub fn parse_doc(mut doc elements.Doc) ! {
	mut parser := parser_line_new(mut doc)!
	doc.type_name = 'doc'

	for {
		if parser.eof() {
			// go out of loop if end of file
			// console.print_debug('+++ end')
			break
		}

		mut line := parser.line_current()
		trimmed_line := line.trim_space()

		mut llast := parser.lastitem()!

		// console.print_header('- line: ${llast.type_name} \'${line}\'')

		if mut llast is elements.List {
			if _ := llast.add_list_item(line) {
				parser.next()
				continue
			}

			parser.ensure_last_is_paragraph()!
			continue
		}

		if mut llast is elements.Table {
			if trimmed_line != '' {
				llast.content += '\n${line}'
				parser.next()
				continue
			}
			parser.next_start_lf()!
			continue
		}

		if mut llast is elements.Action {
			if line.starts_with(' ') {
				// starts with tab or space, means block continues for action
				llast.content += '${line}\n'
				parser.next()
				continue
			}

			parser.ensure_last_is_paragraph()!
			continue
		}

		if mut llast is elements.Html {
			if line.trim_space().to_lower().starts_with('</html>') {
				parser.next_start_lf()!
				continue
			}
			llast.content += '${line}\n'
			parser.next()
			continue
		}

		if mut llast is elements.Codeblock {
			if trimmed_line == '```' || trimmed_line == "'''" {
				parser.next_start_lf()!
				continue
			}
			llast.content += '${line}\n'
			parser.next()
			continue
		}

		if mut llast is elements.Paragraph {
			if elements.line_is_list(line) {
				doc.list_new(mut &doc, line)!
				parser.next()
				continue
			}

			// parse action
			if line.starts_with('!!') {
				doc.action_new(mut &doc, '${line}\n')
				parser.next()
				continue
			}

			// find codeblock
			if line.starts_with('```') || line.starts_with("'''") {
				mut e := doc.codeblock_new(mut &doc, '')
				e.category = line.substr(3, line.len).to_lower().trim_space()
				parser.next()
				continue
			}

			// process headers (# is 35)
			if line.len > 0 && line[0] == 35 {
				mut d := 0
				for d < line.len && line[d] == 35 {
					d += 1
				}
				if d < line.len && line[d] == 32 {
					if d >= 6 {
						parser.error_add('header should be max 5 deep')
						parser.next_start_lf()!
						continue
					}
					mut e := doc.header_new(mut &doc, line.all_after_first(line[..d]).trim_space())
					e.depth = d
					parser.next_start_lf()!
					continue
				}
				parser.next()
				continue
			}

			if trimmed_line.starts_with('|') && trimmed_line.ends_with('|') {
				if !parser.next_is_eof() {
					trimmed_next := parser.line_next().trim_space()
					// single row doesn't make a table
					if trimmed_next.starts_with('|') && trimmed_next.ends_with('|') {
						doc.table_new(mut &doc, '${line}')
						parser.next()
						continue
					}
				}
			}

			if trimmed_line.to_lower().starts_with('<html>') {
				doc.html_new(mut &doc, trimmed_line.after('<html>'))
				parser.next()
				continue
			}

			if trimmed_line.starts_with('<!--') && trimmed_line.ends_with('-->') {
				mut comment := trimmed_line.all_after_first('<!--')
				comment = comment.all_before('-->')
				doc.comment_new(mut &doc, comment)
				parser.next_start_lf()!
				continue
			}

			llast.content += line
		}

		match mut llast {
			elements.Paragraph {
				if !parser.next_is_eof() {
					// console.print_debug("LFLFLFLFLF")
					llast.content += '\n'
				}
			}
			else {
				panic('parser error, means we got element which is not supported')
			}
		}

		parser.next()
	}
	mut llast2 := parser.lastitem()!
	// console.print_debug("parser lf end:${parser.endlf}")
	if parser.endlf {
		llast2.content += '\n'
	}
	// match mut llast2 {
	// 	elements.List {}
	// 	elements.Paragraph {
	// 		if parser.endlf {
	// 			llast2.content +=  '\n'
	// 		}
	// 	}
	// 	else {
	// 		console.print_debug(llast2)
	// 		panic('parser error for last of last, means we got element which is not supported')
	// 	}
	// }

	doc.process()!
}
