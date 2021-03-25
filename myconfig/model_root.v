module myconfig

import os
import process

pub struct ConfigRoot {
pub mut:
	root   string
	paths  Paths
	sites  []SiteConfig
	nodejs NodejsConfig
	reset  bool
	pull   bool
	debug  bool
	redis  bool
	port   int = 9998
	web_hostnames bool
	javascriptfiles map[string]string
}

pub struct Paths {
pub mut:
	base    string
	code    string
	publish string
}

// NOT WORKING YET
// //return code path for wiki
// pub fn (mut config ConfigRoot) path_code_wiki_get(name string)? string {
// 	config_site := config.site_wiki_get(name)?
// 	return "${config.paths.code}/${config_site.name}"
// }

pub fn (mut config ConfigRoot) path_publish_wiki_get(name string) ?string {
	config_site := config.site_wiki_get(name) ?
	return '$config.paths.publish/wiki_$config_site.shortname'
}

// NOT WORKING YET
// //return code path for web
// pub fn (mut config ConfigRoot) path_code_web_get(name string)? string {
// 	config_web := config.site_web_get(name)?
// 	return "${config.paths.code}/${config_web.name}"
// }

pub fn (mut config ConfigRoot) path_publish_web_get(name string) ?string {
	config_web := config.site_web_get(name) ?
	return '$config.paths.publish/$config_web.name'
}

pub fn (mut config ConfigRoot) path_publish_web_get_domain(domain string) ?string {
	for s in config.sites {
		if domain in s.domains {
			return config.path_publish_web_get(s.shortname)
		}
	}
	return error('Cannot find wiki site with domain: $domain')
}

pub fn (mut config ConfigRoot) name_web_get(domain string) ?string {
	for s in config.sites {
		if domain in s.domains {
			return s.shortname
		}
	}
	return error('Cannot find wiki site with domain: $domain')
}

pub fn(mut config ConfigRoot) update_javascript_files(force bool)?{
	println("Updating Javascript files in cache")
	mut p := os.join_path(config.paths.code, ".cache")
	process.execute_silent('mkdir -p $p') or {panic("can not create dir $p")}
	for file, link in config.javascriptfiles{
		mut dest := os.join_path(p, file)
		if !os.exists(dest) || (os.exists(dest) && force){
			process.execute_silent('curl -L -o $dest $link') or {panic("can not  download $link")}
			println(' - downloaded $link')
		}
	}
}

