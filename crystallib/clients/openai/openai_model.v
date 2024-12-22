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
    "
    return heroscript
}

@[heap]
pub struct OpenAIClient {
pub mut:
    name        string = 'default'
    openaikey   string @[secret]
    description string
    conn        ?&httpconnection.HTTPConnection
}

fn cfg_play(p paramsparser.Params) ! {
    mut mycfg := OpenAIClient{
        name: p.get_default('name', 'default')!
        openaikey: p.get('openaikey')!
        description: p.get_default('description', '')!
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
			url:   'https://api.openai.com/v1'
			cache: false
			retry: 0
		)!
		c2.basic_auth(h.user, h.password)
		c2
	}
    c.headers['Authorization'] = 'Bearer ${client.openaikey}'
    client.conn = c
    return c
}
