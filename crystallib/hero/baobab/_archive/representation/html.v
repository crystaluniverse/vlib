module representation

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.webcomponents.htmx
import net.http

pub fn decode_form[T](data string) T {
	data_map := http.parse_form(data)
	mut t := T{}
	$for field in T.fields {
		if field.name in data_map {
			$if field.typ is string {
				t.$(field.name) = data_map[field.name]
			} $else $if field.typ is int {
				t.$(field.name) = int(data_map[field.name])
			}
		}
	}
	return t
}

pub fn (page Page) html() string {
	return $tmpl('../../../../webcomponents/webcomponents/baobab_templates/page.html')
}

pub fn (section Section) html() string {
	return $tmpl('../../../../webcomponents/webcomponents/baobab_templates/section.html')
}

pub fn (heading PageHeading) html() string {
	return $tmpl('../../../../webcomponents/webcomponents/baobab_templates/page_heading.html')
}

pub fn (heading SectionHeading) html() string {
	return $tmpl('../../../../webcomponents/webcomponents/baobab_templates/section_heading.html')
}

pub fn (button Button) html() string {
	return $tmpl('../../../../webcomponents/webcomponents/baobab_templates/button.html')
}

pub fn (element Element) html() string {
	return element.HTMX.str()
}

pub struct Section {
pub mut:
	heading SectionHeading
	content string
}

pub struct SectionHeading {
pub mut:
	title       string
	description string
	buttons     []Button
}

pub fn list_object_page[U](u []U, routes ObjectRoutes) Page {
	object_name := typeof[U]().all_after_last('.')
	return Page{
		heading: PageHeading{
			title: object_name.title()
			buttons: [
				Button{
					label: 'Manual'
				},
			]
		}
		content: Section{
			heading: SectionHeading{
				title: '${object_name.title()} List'
				description: ''
				buttons: [
					Button{
						label: 'Filter'
						get: '${routes.object_route}/filter'
						push_url: 'true'
					},
					Button{
						label: 'New ${object_name}'
						get: '${routes.object_route}/new'
						push_url: 'true'
						color: .violet
					},
				]
			}
			content: table(u).html()
		}.html()
	}
}

pub enum Color {
	violet
	zinc
}

pub fn list_objectsection[U](u []U) Section {
	object_name := typeof[U]().all_after_last('.')
	return Section{
		heading: SectionHeading{
			title: '${object_name.title()} List'
			description: ''
			buttons: [
				Button{
					label: 'Filter'
				},
				Button{
					label: 'New ${object_name}'
				},
			]
		}
		content: to_list(u)
	}
}

pub struct ObjectRoutes {
pub mut:
	object_route        string
	new_object_route    string
	filter_object_route string
	edit_object_route   fn (string) string
	object_page_route   fn (string) string
}

pub fn new_object_page[T]() Page {
	return Page{
		heading: PageHeading{
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

pub fn form[T](endpoint string) string {
	// object_list := to_list(u)

	object_name := texttools.name_fix(typeof[T]().all_after_last('.'))

	mut inputs := []string{}
	mut t := T{}
	$for field in T.fields {
		inputs << input(field, t.$(field.name)).html()
	}
	title := typeof[T]().title()
	description := ''
	return $tmpl('../../../../webcomponents/webcomponents/baobab_templates/form.html')
}

pub struct Input {
pub mut:
	label    string
	typ      InputType
	endpoint string
	name     string
}

pub enum InputType {
	input
	dropdown
}

pub fn input[T](field FieldData, t T) Input {
	mut input := Input{}

	input.name = texttools.name_fix(field.name)
	input.label = input.name.title()
	if field.typ == 21 {
		input.typ = .input
	} else if field.is_enum {
		input.typ = .dropdown
	}
	return input
}

pub fn (input Input) html() string {
	if input.typ == .input {
		return $tmpl('../../../../webcomponents/webcomponents/baobab_templates/input.html')
	} else if input.typ == .dropdown {
		return $tmpl('../../../../webcomponents/webcomponents/baobab_templates/dropdown.html')
	}
	return ''
}

pub struct Shell {
pub mut:
	page    Page
	sidebar Sidebar
}

pub struct Page {
	// Element
pub mut:
	heading PageHeading
	content string
}

pub struct PageHeading {
pub mut:
	title       string
	description string
	buttons     []Button
}

pub struct Sidebar {
pub mut:
	items []Item
}

pub struct Element {
	htmx.HTMX
pub mut:
	color Color
}

pub struct Button {
	Element
pub mut:
	label string
	route string
}

pub struct Item {
pub mut:
	label string
	icon  string
	route string
}

pub fn (shell Shell) html() string {
	url := ''
	sidebar := shell.sidebar.html()
	return $tmpl('../../../../webcomponents/webcomponents/baobab_templates/shell.html')
}

pub struct Response {
	target string
	html   string
}

pub fn (shell Shell) difference(prev_shell Shell) string {
	if shell.page != prev_shell.page {
		page := shell.page
		return $tmpl('../../../../webcomponents/webcomponents/baobab_templates/page.html')
	}
	return $tmpl('../../../../webcomponents/webcomponents/baobab_templates/shell.html')
}

pub fn (sidebar Sidebar) html() string {
	url := ''
	return $tmpl('../../../../webcomponents/webcomponents/baobab_templates/sidebar.html')
}

pub fn to_component[T](t T) string {
	$if t.is_array {
		return to_list(t)
	}
	return ''
	//  $else {
	// 	return "$tmpl('../../../../webcomponents/webcomponents/baobab_templates/objects_table.html')"
	// }
}

pub fn card[T](t T) string {
	mut top_fields := []string{}
	mut fields := []string{}
	object_name := texttools.name_fix(typeof[T]().all_after_last('.'))

	name := t.name
	title := t.title
	description := t.description

	$for field in T.fields {
		value := t.$(field.name)
		fields << '<dd class="mt-1 text-base font-semibold leading-6 text-gray-900">${field.name}: ${value}</dd>'
	}
	return $tmpl('../../../../webcomponents/webcomponents/baobab_templates/card2.html')
}

pub fn table[U](u []U) Table {
	mut headers := []string{}
	$for field in U.fields {
		if !field.name.is_capital() && !field.is_array {
			headers << field.name.title()
		}
	}
	rows := u.map(row(it))

	return Table{
		title: typeof[T]().title()
		description: ''
		headers: headers
		rows: rows
	}
}

pub struct Table {
pub mut:
	title       string
	description string
	headers     []string
	rows        []Row
}

pub struct Row {
pub mut:
	route   string
	items   []string
	buttons []Button
}

pub fn (table Table) html() string {
	return $tmpl('../../../../webcomponents/webcomponents/baobab_templates/table.html')
}

pub fn (row Row) html() string {
	return $tmpl('../../../../webcomponents/webcomponents/baobab_templates/row.html')
}

pub fn row[T](t T) Row {
	mut items := []string{}
	$for field in T.fields {
		if !field.name.is_capital() && !field.is_array {
			val := t.$(field.name)
			items << '${val}'
		}
	}
	return Row{
		route: '${t.id}'
		items: items
		buttons: [
			Button{
				label: 'Edit'
				route: '/publisher/website/${t.id}'
			},
		]
	}
}
