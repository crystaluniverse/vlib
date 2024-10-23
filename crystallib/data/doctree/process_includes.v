module doctree

// import freeflowuniverse.crystallib.data.doctree.collection.data
import freeflowuniverse.crystallib.data.doctree.pointer
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.ui.console

fn (mut tree Tree) process_includes() ! {
	console.print_green('Processing page includes')
	graph := tree.generate_pages_graph()!

	mut indegree := map[string]int{}
	for _, c in tree.collections {
		for _, p in c.pages {
			indegree[p.key()] = 0
		}
	}

	for _, children in graph {
		for child in children.keys() {
			indegree[child] += 1
		}
	}

	mut queue := []string{}
	for key, degree in indegree {
		if degree == 0 {
			queue << key
		}
	}

	for queue.len > 0 {
		front := queue[0]
		queue = queue[1..]

		mut page := tree.page_get(front)!
		mut col := tree.get_collection(page.collection_name)!

		// process page
		for element in page.get_include_actions()! {
			page_pointer := tree.get_include_page_pointer(col.name, element.action) or { continue }

			mut include_page := tree.get_page_with_pointer(page_pointer) or { continue }

			page.set_element_content_no_reparse(element.id, include_page.get_markdown()!)!
		}

		// update indegree
		for child in graph[page.key()].keys() {
			indegree[child] -= 1
			if indegree[child] == 0 {
				queue << child
			}
		}
	}

	for key, degree in indegree {
		if degree == 0 {
			continue
		}

		mut page := tree.page_get(key)!
		mut col := tree.get_collection(page.collection_name)!
		col.error(
			path: page.path
			msg: 'page ${key} is in an include cycle'
			cat: .circular_import
		)
	}
}

fn (mut tree Tree) get_include_page_pointer(collection_name string, a playbook.Action) !pointer.Pointer {
	mut page_pointer_str := a.params.get('page')!

	// handle includes
	mut page_pointer := pointer.pointer_new(collection: collection_name, text: page_pointer_str)!
	if page_pointer.collection == '' {
		page_pointer.collection = collection_name
	}

	return page_pointer
}

fn (mut tree Tree) generate_pages_graph() !map[string]map[string]bool {
	mut graph := map[string]map[string]bool{}
	for _, mut collection in tree.collections {
		for _, mut page in collection.pages {
			mut current_page := page
			_ := graph[current_page.key()] or {
				map[string]bool{}
			}
			include_action_elements := current_page.get_include_actions()!
			for element in include_action_elements {
				page_pointer := tree.get_include_page_pointer(collection.name, element.action) or {
					collection.error(
						path: current_page.path
						msg: 'failed to get page pointer for include ${element.action.heroscript()}: ${err}'
						cat: .include
					)
					continue
				}

				include_page := tree.get_page_with_pointer(page_pointer) or {
					collection.error(
						path: current_page.path
						msg: 'failed to get page for include ${element.action.heroscript()}: ${err}'
						cat: .include
					)
					continue
				}

				graph[include_page.key()][current_page.key()] = true
			}
		}
	}

	return graph
}
