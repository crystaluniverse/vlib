module zola

import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.data.doctree.collection.data

// Blog section for Zola site
pub struct Blog {
	Section
mut:
	posts map[string]Post
}

pub struct Post {
pub:
	cid         string          @[required]
	title       string
	name        string
	image       ?&data.File
	page        ?&data.Page
	date        ourtime.OurTime
	biography   string
	description string
	tags        []string
	categories  []string
	authors     []string
	countries   []string
	cities      []string
}

@[params]
pub struct BlogAddArgs {
	Section
}

// adds a blog section to the zola site
pub fn (mut site ZolaSite) blog_add(args BlogAddArgs) ! {
	blog_section := Section{
		...args.Section
		name: 'blog'
		title: if args.title != '' { args.title } else { 'Blog' }
		sort_by: if args.sort_by != .@none { args.sort_by } else { .date }
		template: if args.template != '' { args.template } else { 'layouts/blog.html' }
		page_template: if args.page_template != '' {
			args.page_template
		} else {
			'partials/postCard.html'
		}
		paginate_by: if args.paginate_by != 0 { args.paginate_by } else { 3 }
	}
	site.add_section(blog_section)!
}

pub struct PostAddArgs {
pub mut:
	name       string
	page       string
	collection string
	file       string
	pointer    string
	image      string
}

pub fn (mut site ZolaSite) post_add(args_ PostAddArgs) ! {
	args := site.check_post_add_args(args_)!

	if 'blog' !in site.sections {
		site.blog_add()!
	}
	post := site.get_post(args)!
	image := post.image or { return error('Post must have an image') }
	mut post_page := new_page(
		Page: post.page or { return error('post page not attached') }
		title: post.title
		date: post.date.time()
		description: post.description
		taxonomies: {
			'people':     post.authors
			'tags':       post.tags
			'categories': post.categories
		}
		assets: [post.image?.path]
		extra: {
			'imgPath': image.file_name()
		}
	)!
	post_page.name = post.name
	site.sections['blog'].page_add(post_page)!
}

fn (site ZolaSite) check_post_add_args(args_ PostAddArgs) !PostAddArgs {
	if args_.pointer == '' && (args_.collection == '' || args_.page == '') {
		return error('Either pointer or post collection and page must be specified in order to add post')
	}

	mut args := args_
	if args.collection == '' {
		args.collection = args.pointer.split(':')[0]
	}

	// check collection exists
	_ = site.tree.get_collection(args.collection) or {
		return error('Collection ${args.collection} not found.')
	}

	if args.pointer == '' {
		args.pointer = '${args.collection}:${args.name}'
	}
	return args
}

fn (site ZolaSite) get_post(args PostAddArgs) !Post {
	mut page := site.tree.page_get('${args.pointer}') or { return err }
	page_action_elements := page.get_all_actions()!
	mut actions := []playbook.Action{}
	for item in page_action_elements {
		actions << item.action
	}

	post_definitions := actions.filter(it.name == 'post_define')
	if post_definitions.len == 0 {
		return error('specified file does not include a post definition.')
	}
	if post_definitions.len > 1 {
		return error('specified file includes multiple post definitions')
	}
	definition := post_definitions[0]
	name := definition.params.get_default('name', '')!
	image_ := definition.params.get_default('image_path', '')!
	mut post := Post{
		name: name
		page: page
		date: definition.params.get_time_default('date', ourtime.now())!
		cid: definition.params.get_default('cid', '')!
		title: definition.params.get_default('title', '')!
		description: definition.params.get_default('description', '')!
		tags: definition.params.get_list_default('tags', [])!
		categories: definition.params.get_list_default('categories', [])!
		authors: definition.params.get_list_default('authors', [])!
	}

	if post.cid == '' {
		return error('posts cid cant be empty')
	}

	// add image and page to article if they exist
	page_ := definition.params.get_default('page_path', '')!
	if page_ != '' {
		post = Post{
			...post
			page: site.tree.page_get(page_) or { return err }
		}
	}

	// // add image and page to post if they exist
	if image_ != '' {
		post = Post{
			...post
			image: site.tree.get_image('${args.collection}:${image_}') or { return err }
		}
	}

	return post
}
