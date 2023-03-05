module markdowndocs

// DO NOT CHANGE THE WAY HOW THIS WORKS, THIS HAS BEEN DONE AS A STATEFUL PARSER BY DESIGN
// THIS ALLOWS FOR EASY ADOPTIONS TO DIFFERENT RELIALITIES
fn (mut doc Doc) parse() ! {
	mut parser := parser_line_new(mut &doc)!

	for {
		if parser.eof() {
			// println("---end")
			break
		}
		// go out of loop if end of file
		line := parser.line_current()
		// println(line)

		mut llast := parser.lastitem()
		// println(llast)

		// if mut llast is Comment {
		// 	if llast.prefix == .short {
		// 		if line.trim_space().starts_with('//') {
		// 			llast.content += line.all_after_first('//') + '\n'
		// 			parser.next()
		// 			continue
		// 		}
		// 		parser.next_start()
		// 	} else {
		// 		if line.trim_space().ends_with('-->') {
		// 			llast.content += line.all_before_last('-->') + '\n'
		// 			parser.next_start()
		// 		} else {
		// 			llast.content += line + '\n'
		// 			parser.next()
		// 		}
		// 		continue
		// 	}
		// }

		if mut llast is Action {
			if line.starts_with(' ') || line.starts_with('\t') {
				// starts with tab or space, means block continues for action
				llast.content += '${line}\n'
			} else {
				parser.next_start()
				continue
			}
			parser.next()
			continue
		}

		if mut llast is Html {
			if line.trim_space().to_lower().starts_with('</html') {
				parser.next_start()
				continue
			}
		}

		if mut llast is CodeBlock {
			if line.starts_with('```') || line.starts_with('"""') || line.starts_with("'''") {
				parser.next_start()
				continue
			} else {
				llast.content += '${line}\n'
			}
			parser.next()
			continue
		}

		if mut llast is Paragraph {
			if line.starts_with('!!') {
				doc.items << Action{
					content: line.all_after_first('!!')
				}
				parser.next()
				continue
			}

			// find codeblock or actions
			if line.starts_with('```') || line.starts_with('"""') || line.starts_with("'''") {
				doc.items << CodeBlock{
					category: line.substr(3, line.len).to_lower().trim_space()
				}
				parser.next()
				continue
			}

<<<<<<< HEAD
			// process headers
			if line.starts_with('###### ') {
				parser.error_add('header should be max 5 deep')
				parser.next_start()
				continue
			}
			if line.starts_with('##### ') {
				doc.items << Header{
					content: line.all_after_first('#####').trim_space()
					depth: 5
				}
				parser.next_start()
				continue
			}
			if line.starts_with('#### ') {
				doc.items << Header{
					content: line.all_after_first('####').trim_space()
					depth: 4
=======
			// process headers (# is 35)
			if line.len > 0 && line[0] == 35 {
				mut d := 0
				for d < line.len && line[d] == 35 {
					d += 1
				}
				if d < line.len && line[d] == 32 {
					if d >= 6 {
						parser.error_add('header should be max 5 deep')
						parser.next_start()
						continue
					}
					doc.items << Header{
						content: line.all_after_first(line[..d]).trim_space()
						depth: d
					}
					parser.next_start()
					continue
>>>>>>> 667df183094470ef5dbeba569d84a1ac2b27784e
				}
			}
<<<<<<< HEAD
			if line.starts_with('### ') {
				doc.items << Header{
					content: line.all_after_first('###').trim_space()
					depth: 3
				}
				parser.next_start()
				continue
			}
			if line.starts_with('## ') {
				doc.items << Header{
					content: line.all_after_first('##').trim_space()
					depth: 2
				}
				parser.next_start()
				continue
			}
			if line.starts_with('# ') {
				doc.items << Header{
					content: line.all_after_first('#').trim_space()
					depth: 1
				}
				parser.next_start()
				continue
			}
=======
>>>>>>> 667df183094470ef5dbeba569d84a1ac2b27784e

			if line.trim_space().to_lower().starts_with('<html') {
				doc.items << Html{}
				parser.next()
				continue
			}

			// if line.trim_space().starts_with('//') {
			// 	doc.items << Comment{
			// 		content: line.all_after_first('//').trim_space() + '\n'
			// 		// prefix: .short

			// 	}
			// 	parser.next()
			// 	continue
			// }
			// if line.trim_space().starts_with('<!--') {
			// 	doc.items << Comment{
			// 		content: line.all_after_first('<!--').trim_space() + '\n'
			// 		prefix: .multi

			// 	}
			// 	parser.next()
			// 	continue
			// }
		}

		if mut llast is Paragraph || mut llast is Html || mut llast is CodeBlock {
			if parser.endlf == false && parser.next_is_eof() {
				llast.content += line
			} else {
				llast.content += line + '\n'
			}
		} else {
			println(line)
			println(llast)
			panic('parser error, means we got element which is not supported')
		}

		parser.next()
	}

	// paragraph is used as separator so the empty ones need to be removed
<<<<<<< HEAD

=======
>>>>>>> 667df183094470ef5dbeba569d84a1ac2b27784e
	mut toremovelist := []int{}
	mut counter := 0
	for mut item in doc.items {
		match mut item {
			Table {
				item.process()!
			}
			Action {
				item.process()!
			}
			Actions {
				item.process()!
			}
			Header {
				item.process()!
			}
			Paragraph {
				item.process()!
<<<<<<< HEAD
				if item.content.trim(' \n') == '' {
=======
				if item.content.trim(' \r\n') == '' {
>>>>>>> 667df183094470ef5dbeba569d84a1ac2b27784e
					toremovelist << counter
				} else if item.items.len == 0 {
					toremovelist << counter
				}
			}
			Html {
				item.process()!
			}
			// Comment { item.process()! }
			CodeBlock {
				item.process()!
			}
			Link {
				item.process()!
			}
		}
		counter += 1
	}
	for toremove in toremovelist.reverse() {
		doc.items.delete(toremove)
	}
}

// // walk backwards over the objects, if equal with what we have we keep on walking back
// // if we find one which is same type as specified will return
// fn (mut parser Parser) item_get_previous(tocheck_ string, ignore_ []string) &DocItem {
// 	mut ignore := ignore_.clone()
// 	mut itemnr := doc.items.len - 1
// 	mut itemname_start := doc.items[itemnr].type_name().all_after_last('.').to_lower()
// 	tocheck := tocheck_.to_lower().trim_space()
// 	// walk backwards till previous state is not the current
// 	// the original itemname
// 	// print(" .. previous $tocheck $ignore")
// 	if itemname_start == tocheck {
// 		// print(" *R0.$itemname_start\n")
// 		return &doc.items[itemnr]
// 	}
// 	for {
// 		mut itemname_current := doc.items[itemnr].type_name().all_after_last('.').to_lower()
// 		if itemnr == 0 {
// 			// print(" *B.$itemname_current")
// 			break
// 		}
// 		if itemname_current in ignore {
// 			itemnr -= 1
// 			// print(" *I.$itemname_current")
// 			continue
// 		}
// 		if itemname_current == tocheck {
// 			// print(" *R.$itemname_current\n")
// 			return &doc.items[itemnr]
// 		}
// 		// print(" *B.$itemname_current")
// 		break
// 	}
// 	// print(" *NO\n")
// 	return &Doc{}
// }

// // go further over lines, see if we can find one which has one of the to_find items in but we didn't get tostop item before
// fn (mut parser Parser) look_forward_find(tofind []string, tostop []string) bool {
// 	mut found := false
// 	for line in parser.lines[parser.linenr + 1..parser.lines.len] {
// 		// println(" +++ " +line)
// 		for item in tostop {
// 			if line.trim_space().starts_with(item) {
// 				// println("found:$found")
// 				return found
// 			}
// 		}
// 		for item2 in tofind {
// 			if line.trim_space().starts_with(item2) {
// 				found = true
// 			}
// 		}
// 	}
// 	// println("NOTFOUND")
// 	return false
// }
