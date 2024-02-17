module zola

import freeflowuniverse.crystallib.installers.web.tailwind as tailwindinstaller
import freeflowuniverse.crystallib.installers.web.zola as zolainstaller
import freeflowuniverse.crystallib.core.play
import os

@[params]
@[heap]
pub struct Zola {
	play.Base
pub mut:
	path_build   string 
	path_publish string
	tailwindcss bool = true
	install bool = true
	reset bool
	sites map[string]&ZolaSite

}

pub fn new(zola_ Zola) !Zola {
	mut zola:=zola_

	if zola.install && zola.tailwindcss{
		tailwindinstaller.install()!
	}
	
	if zola.install {
		zolainstaller.install()!
	}	

	if zola.path_build==""{
		zola.path_build='${os.home_dir()}/hero/var/wsbuild'
	}

	if zola.path_publish==""{
		zola.path_publish='${os.home_dir()}/hero/www'
	}

	return zola
}

