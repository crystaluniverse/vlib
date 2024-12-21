module hetzner
import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.clients.httpconnection

pub const version = '1.14.3'
const singleton = false
const default = true

pub fn heroscript_default() !string {
    heroscript := "
    !!hetzner.configure 
        name:'default'
        url:'https://robot-ws.your-server.de'
        user:''
        password:''
        whitelist:''
        "
    return heroscript
}

//THIS IS THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED

@[heap]
pub struct HetznerManager {
pub mut:
    name        string = 'default'
	description string
	baseurl     string 
	whitelist   string // comma separated list of servers we whitelist to work on    
    user        string
    password    string
    conn        ?&httpconnection.HTTPConnection
}

fn cfg_play(p paramsparser.Params) !HetznerManager {
    mut mycfg := HetznerManager{
        name: p.get_default('name', 'default')!
        baseurl: p.get_default('url', 'https://robot-ws.your-server.de')!
        //TODO: whitelist
        user: p.get('user')!
        password: p.get('password')!
    }
    return mycfg
}     


fn obj_init(obj_ HetznerManager)!HetznerManager{
    //never call get here, only thing we can do here is work on object itself
    mut obj:=obj_
    // Initialize connection with caching enabled
    return obj

}

pub fn (mut h HetznerManager) connection() !&httpconnection.HTTPConnection {

    mut c := h.conn or { 
        mut c2 := httpconnection.new(
            name: 'hetzner_${h.name}'
            url: h.baseurl
            cache: true
            retry: 3
        )!
        c2.basic_auth(h.user,h.password)
        c2
    }
	return c
}

