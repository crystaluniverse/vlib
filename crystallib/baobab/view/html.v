module view

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.webcomponents.htmx
import freeflowuniverse.webcomponents.view {Page, PageHeading, Section, SectionHeading, Button, table}
import net.http

pub fn list_object_page[U] (u []U, routes ObjectRoutes) Page {
	object_name := typeof[U]().all_after_last('.')
	return Page {
		heading: PageHeading {
			title: object_name.title()
			buttons: [
				Button{
					label: 'Manual'
				}
			]
		}
		content: Section {
			heading: SectionHeading {
				title: '${object_name.title()} List'
				description: ''
				buttons: [
					Button{
						label: 'Filter'
						get: '${routes.object_route}/filter'
						push_url: 'true'
					}
					Button{
						label: 'New ${object_name}'
						get: '${routes.object_route}/new'
						push_url: 'true'
						color: .violet
					}
				]
			}
			content: table(u).html()
		}.html()
	}
}

pub fn list_objectsection[U] (u []U) Section {
	object_name := typeof[U]().all_after_last('.')
	return Section {
		heading: SectionHeading {
			title: '${object_name.title()} List'
			description: ''
			buttons: [
				Button{label: 'Filter'}
				Button{label: 'New ${object_name}'}
			]
		}
		content: to_list(u)
	}
}

pub struct ObjectRoutes {
pub mut:
	object_route string
	new_object_route string
	filter_object_route string
	edit_object_route fn (string) string
	object_page_route fn (string) string
}

pub fn new_object_page[T]() Page {	
	return Page {
		heading: PageHeading {
			title: typeof[T]().title()
			description: ''
		}
		content: new_object_form[T]()
	}
}

pub fn new_object_form[T]() string {
	// object_list := to_list(u)

	object_name := texttools.name_fix(typeof[T]().all_after_last('.'))

	mut inputs := []string{}
	$for field in T.fields {
		$if field.typ is string {
			inputs << '
			<div class="col-span-full">
				<label for="${field.name}" class="block text-sm font-medium leading-6 text-white">${field.name.title()}</label>
				<div class="mt-2">
				<input type="text" name="${field.name}" id="${field.name}" class="block w-full rounded-md border-0 bg-white/5 py-1.5 text-white shadow-sm ring-1 ring-inset ring-white/10 focus:ring-2 focus:ring-inset focus:ring-indigo-500 sm:text-sm sm:leading-6"
					hx-post="/publisher/represent/${object_name}" 
					hx-trigger="input" 
					hx-target="#form-representation"
					hx-swap="innerHTML"
				>
				</div>
			</div>
			'
		} $else $if field.is_enum {
			inputs << '
					<div class="sm:col-span-3">
				<label for="country" class="block text-sm font-medium leading-6 text-white">Country</label>
				<div class="mt-2">
				<select id="country" name="country" autocomplete="country-name" class="block w-full rounded-md border-0 bg-white/5 py-1.5 text-white shadow-sm ring-1 ring-inset ring-white/10 focus:ring-2 focus:ring-inset focus:ring-indigo-500 sm:text-sm sm:leading-6 [&_*]:text-black">
					<option>United States</option>
					<option>Canada</option>
					<option>Mexico</option>
				</select>
				</div>
			</div>'
		}
	}
	title := typeof[T]().title()
	description := ''
	return $tmpl('../../../../webcomponents/webcomponents/baobab_templates/form.html')
}

pub fn filter_object_form[T](endpoint string) string {
	// object_list := to_list(u)

	object_name := texttools.name_fix(typeof[T]().all_after_last('.'))

	mut inputs := []string{}
	$for field in T.fields {
		$if field.typ is string {
			inputs << '
			<div class="col-span-full">
				<label for="${field.name}" class="block text-sm font-medium leading-6 text-white">${field.name.title()}</label>
				<div class="mt-2">
				<input type="text" name="${field.name}" id="${field.name}" class="block w-full rounded-md border-0 bg-white/5 py-1.5 text-white shadow-sm ring-1 ring-inset ring-white/10 focus:ring-2 focus:ring-inset focus:ring-indigo-500 sm:text-sm sm:leading-6"
					hx-post="${endpoint}" 
					hx-trigger="input" 
					hx-target="#form-representation"
					hx-swap="innerHTML"
				>
				</div>
			</div>
			'
		} $else $if field.is_enum {
			inputs << '
					<div class="sm:col-span-3">
				<label for="country" class="block text-sm font-medium leading-6 text-white">Country</label>
				<div class="mt-2">
				<select id="country" name="country" autocomplete="country-name" class="block w-full rounded-md border-0 bg-white/5 py-1.5 text-white shadow-sm ring-1 ring-inset ring-white/10 focus:ring-2 focus:ring-inset focus:ring-indigo-500 sm:text-sm sm:leading-6 [&_*]:text-black">
					<option>United States</option>
					<option>Canada</option>
					<option>Mexico</option>
				</select>
				</div>
			</div>'
		}
	}
	title := typeof[T]().title()
	description := ''
	return $tmpl('../../../../webcomponents/webcomponents/baobab_templates/form.html')
}

pub struct Response {
	target string
	html string
}



