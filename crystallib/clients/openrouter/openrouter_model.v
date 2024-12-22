module openrouter
import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.playbook
import os

pub fn heroscript_default() !string {
    heroscript:="
    !!openrouter.configure
        name: 'default'
        openrouter_apikey: ''
        your_site_url: ''
        your_site_name: ''
    "
    return heroscript
}

@[heap]
pub struct OpenRouterClient {
pub mut:
    name string = 'default'
    openrouter_apikey string @[secret]
    your_site_url string
    your_site_name string
}

pub fn play_openrouter(mut plbook playbook.PlayBook) ! {
    actions := plbook.find(filter: 'openrouter.')!
    for action in actions {
        if action.name == "configure" {
            mut p := action.params
            mut obj := OpenRouterClient{
                name: p.get_default('name', 'default')!
                openrouter_apikey: p.get('openrouter_apikey')!
                your_site_url: p.get_default('your_site_url', '')!
                your_site_name: p.get_default('your_site_name', '')!
            }
            //console.print_debug(obj)
        }
    }
}

fn obj_init(obj_ OpenRouterClient)!OpenRouterClient {
    mut obj := obj_
    return obj
}


pub fn (mut client OpenRouterClient) connection() !&httpconnection.HTTPConnection {
	mut c := client.conn or {
		mut c2 := httpconnection.new(
			name:  'openrouterclient_${client.name}'
			url:   'https://openrouter.ai/api/v1/chat/completions'
			cache: false
			retry: 0
		)!
		c2
	}
    // see https://modules.vlang.io/net.http.html#CommonHeader
    // -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    c.default_header.set(.authorization, 'Bearer ${client.openaikey}')
    c.default_header.add_custom("HTTP-Referer",client.your_site_url)!
    c.default_header.add_custom("X-Title",client.your_site_name)!
    client.conn = c
    return c
}
