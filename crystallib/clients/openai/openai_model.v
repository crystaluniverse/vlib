module openai
import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.clients.httpconnection

pub const version = '1.0.0'
const singleton = false
const default = true

pub fn heroscript_default() !string {
    heroscript := "
    !!openai.configure 
        name:'openai'
        openaikey:'your-api-key-here'
        description:'OpenAI API Client'
        url:'' //default is openai endpoint
    "
    return heroscript
}

@[heap]
pub struct OpenAIClient {
pub mut:
    name        string = 'default'
    openaikey   string @[secret]
    description string
    url string
    conn        ?&httpconnection.HTTPConnection
}

fn cfg_play(p paramsparser.Params) ! {
    mut mycfg := OpenAIClient{
        name: p.get_default('name', 'default')!
        openaikey: p.get('openaikey')!
        description: p.get_default('description', '')!
        url: p.get_default('url', 'https://api.openai.com/v1')!
    }
    set(mycfg)!
}     

fn obj_init(obj_ OpenAIClient)!OpenAIClient {
    mut obj := obj_
    return obj
}


pub fn (mut client OpenAIClient) connection() !&httpconnection.HTTPConnection {
	mut c := client.conn or {
		mut c2 := httpconnection.new(
			name:  'openaiclient_${client.name}'
			url:   client.url
			cache: false
			retry: 0
		)!
		c2
	}
    c.default_header.set(.authorization, 'Bearer ${client.openaikey}')
    // see https://modules.vlang.io/net.http.html#CommonHeader
    client.conn = c
    return c
}
