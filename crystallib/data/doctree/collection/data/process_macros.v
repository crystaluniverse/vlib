module data

import freeflowuniverse.crystallib.core.playmacros
import freeflowuniverse.crystallib.data.markdownparser.elements { Action }

pub fn (mut page Page) process_macros() ! {
	mut mydoc := page.doc()!
	for mut element in mydoc.children_recursive() {
		if mut element is Action {
			if element.action.actiontype == .macro {
				content := playmacros.play_macro(element.action)!
				page.changed = true
				if content.len > 0 {
					element.content = content
				}
			}
		}
	}

	if page.changed {
		page.reparse_doc(page.doc.markdown()!)!
		page.process_macros()!
	}
}
