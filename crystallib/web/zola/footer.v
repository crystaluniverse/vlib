module zola

import freeflowuniverse.crystallib.core.pathlib

pub struct Footer {
	template string
	logo     string
pub mut:
	links []Link
}

pub struct FooterAddArgs {
pub:
	links    []Link
	template string
	logo     string
}

pub fn (mut site ZolaSite) footer_add(args FooterAddArgs) ! {
	site.footer = Footer{
		logo: args.logo
		template: args.template
	}
}

pub fn (mut site ZolaSite) footer_link_add(args Link) ! {
	mut footer := site.footer or { return error('footer needs to be defined') }
	footer.links << args
	site.footer = footer
}

pub fn (mut footer Footer) export(content_dir string) ! {
	// footer.Page.export(dest: '${content_dir}/footer.md')!
	mut content := '---
---
!!flowrift.footer
	logo: ${footer.logo}
'
	for item in footer.links {
		content += "\n\n!!flowrift.footer_item	
	type:'link'
	label:${item.label}
	url: '${item.page}'"
	}

	mut footer_file := pathlib.get_file(path: '${content_dir}/footer.md')!
	footer_file.write(content)!
}
