module main

import freeflowuniverse.crystallib.data.gdrive

fn do() ! {
	mut drive := gdrive.new(name: 'test', reset: false)!
	drive.slides_download(presentation_id: '1-FGxyXKR_jcEU891J4QlYU-_548i-xdsNyFauBYSZ7M')!
}

fn main() {
	do() or { panic(err) }
}
