module knowledgetree

import freeflowuniverse.crystallib.gittools

// TODO: need to get this to work, needs basic tooling to be able to use 3script

// ! Use booksrunner in ./actionrunner

import freeflowuniverse.crystallib.actionsparser

// find all actions & process, this works inclusive
pub fn actions_process(mut parser actionsparser.ActionsParser, actions_done map[string]string) ?map[string]string {
	// $if debug {
	// 	println("+++++")
	// 	println(actions)
	// 	println("-----")
	// }

	// QUESTION: what is this
	//mut sites := books.sites_new()
	//books.books_new(&sites)

	// sites.scan(path + '/content')?
	// books.scan(path + '/books')?

	mut gt := gittools.get()?

	for mut action in parser.actions {
		$if debug {
			println(' --------ACTION BOOKS:\n$action\n--------')
		}

		if action.name == 'books.add' {
			book_url := action.params.get('url')?
			book_name := action.params.get_default('name', '')?
			book_pull := action.params.get_default_false('pull')
			book_reset := action.params.get_default_false('reset')
			$if debug {
				eprintln(@FN + ': books add pull: $book_url')
			}
			mut gr := gt.repo_get_from_url(
				url: book_url
				pull: book_pull
				reset: book_reset
				name: book_name
			)?
			book_path := gr.path_content_get()
			books.site_new(path: book_path, name: book_name)?
		}

		if action.name == 'books.mdbook_develop' {
			books.scan()?
			name := action.params.get('name')?
			mut book := books.get(name)?
			book.mdbook_develop()?
		}

		//? Currently can only export book by name, is that ok?
		if action.name == 'books.mdbook_export' {
			books.scan()?
			name := action.params.get('name')?
			dest_path := action.params.get('path')?

			mut book := books.get(name)?
			//? What do book_pull and book_reset do?
			// mut gr := gt.repo_get_from_url(url: export_url, pull: book_pull, reset: book_reset)?
			// mut export_repo := gt.repo_get_from_url(url: export_url)?
			// export_path := export_repo.path_content_get()
			site := books.site_new(path: book.path.path)?
			site.mdbook_export(dest_path)?
		}
	}
	return actions_done
}
