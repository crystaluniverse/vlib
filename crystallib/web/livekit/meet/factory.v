module meet

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.pathlib
import veb
import rand
import os
import json
import freeflowuniverse.crystallib.web.auth.jwt
import time

// Context struct embedding `veb.Context`
pub struct Context {
	veb.Context
}

// App struct with `livekit.Client`, API keys, and other shared data
pub struct App {
	veb.StaticHandler
pub:
	build_url string = 'https://freeflowuniverse.github.io/livekit_meet' // the url in which the next.js application is built
	asset_prefix string = '/static'
	livekit_url string @[required]
	api_key        string
	api_secret     string
}

pub struct AppConfig {
pub:
	livekit_url string @[required]
	livekit_api_key string @[required]
	livekit_api_secret string @[required]
}

// Main entry point
pub fn new(config AppConfig) &App {
	mut app := &App{
		livekit_url: config.livekit_url
		api_key:  config.livekit_api_key
		api_secret: config.livekit_api_secret
	}
	
	app.install() or {
		panic(err)
	}

	// Start the Veb web server on port 8080
	app.static_mime_types['.map'] = 'txt/plain'
	app.static_mime_types['.meta'] = 'text/markdown'

	app.mount_static_folder_at('${os.dir(@FILE)}/static','/static') or {
		panic(err)
	}

	return app
}

pub fn (app App) install() ! {
	app.download_static()!
	app.download_templates()!
	update_templates()!
}

pub fn (app App) download_static() ! {
	// Get the path to the static folder relative to this script
    static_dir := os.join_path(os.dir(@FILE), 'static')
    
    // Ensure the static directory exists
    if !os.exists(static_dir) {
        os.mkdir_all(static_dir)!
    }

    // URL to fetch the file list
    flist_url := '${app.build_url}/flist.txt'
    mut flist_file := osal.download(osal.DownloadArgs{
		reset: true
        url: flist_url
		minsize_kb: 0
        dest: '/tmp/flist.txt'
    })!

	// Download the file list
    file_list := flist_file.read()!.split_into_lines()

    // Iterate over the file list and download each file
    for file in file_list {
        if file.ends_with('.css') || file.ends_with('.js') {
            // Construct the destination path in the static directory
            dest_path := os.join_path(static_dir, file)
			mut dest_file := pathlib.get_file(path: dest_path)!

			if dest_file.exists() {
				continue
			}

            // Construct the full URL for the file
            file_url := '${app.build_url}/${file}'

            // Download the file using your downloader module
            osal.download(osal.DownloadArgs{
                url: file_url
                dest: dest_path
				minsize_kb: 0
            })!
        }
    }
}

pub fn (app App) download_templates() ! {
    template_dir := os.join_path(os.dir(@FILE), 'templates')
	templates := ['index.html', 'custom.html', 'rooms/room.html']
	// Iterate over the file list and download each file
    for file in templates {
		// Construct the full URL for the file
		file_url := '${app.build_url}/${file}'
		// Construct the destination path in the static directory
		dest_path := os.join_path(template_dir, file)

		// Download the file using your downloader module
		osal.download(osal.DownloadArgs{
			url: file_url
			reset: true
			dest: dest_path
			minsize_kb: 0
		})!
    }
}

pub fn update_templates() !{
    template_dir := os.join_path(os.dir(@FILE), 'templates')
	templates := ['index.html', 'custom.html', 'rooms/room.html']
	for template in templates {
		mut file := pathlib.get_file(path: os.join_path(template_dir, template))!
		content := file.read()!
		mut fixed := content.replace('@{asset_prefix}', '#{app.asset_prefix}')
		fixed = fixed.replace('@@', '@') // escape templating syntax
		fixed = fixed.replace('@', '@@') // escape templating syntax
		fixed = fixed.replace('#{app.asset_prefix}', '@{app.asset_prefix}')
		fixed = fixed.replace('$', '@{dollar}')
		fixed = fixed.replace('@@{dollar}', '@{dollar}')
		file.write(fixed)!
	}
}

@[params]
pub struct RunParams {
pub:
	port int = 8080
}

pub fn (mut app App) run(params RunParams) {
	veb.run[App, Context](mut app, params.port)
}
