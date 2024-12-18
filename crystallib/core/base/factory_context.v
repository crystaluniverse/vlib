module base

import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.ui
import freeflowuniverse.crystallib.ui.console
import crypto.md5

@[params]
pub struct ContextConfigArgs {
pub mut:
	id           u32
	name         string = 'default'
	params       string
	coderoot     string
	interactive  bool
	secret       string
	encrypt      bool
	priv_key_hex string // hex representation of private key
}

// configure a context object
// params: .
// ```
// id		   u32 //if not set then redis will get a new context id
// name        string = 'default'
// params      string
// coderoot    string
// interactive bool
// secret      string
// priv_key_hex string //hex representation of private key
// ```
pub fn context_new(args_ ContextConfigArgs) !&Context {
	mut args := ContextConfig{
		id:          args_.id
		name:        args_.name
		params:      args_.params
		coderoot:    args_.coderoot
		interactive: args_.interactive
		secret:      args_.secret
		encrypt:     args_.encrypt
	}

	if args.encrypt && args.secret == '' && args.interactive {
		mut myui := ui.new()!
		console.clear()
		args.secret = myui.ask_question(question: 'Please enter your hero secret string:')!
	}

	if args.encrypt && args.secret.len > 0 {
		args.secret = md5.hexhash(args.secret)
	}

	mut c := Context{
		config: args
	}

	// if args_.priv_key_hex.len > 0 {
	// 	c.privkey_set(args_.priv_key_hex)!
	// }

	// c.save()!

	if args.params.len > 0 {
		mut p := paramsparser.new('')!
		c.params_ = &p
	}

	c.save()!
	contexts[args.id] = &c

	return contexts[args.id] or { panic('bug') }
}

pub fn context_get(id u32) !&Context {
	context_current = id

	if id in contexts {
		return contexts[id] or { panic('bug') }
	}

	mut mycontext := Context{
		config: ContextConfig{
			id: id
		}
	}

	if mycontext.cfg_redis_exists()! {
		mycontext.load()!
		return &mycontext
	}

	mut mycontext2 := context_new(id: id)!
	return mycontext2
}

pub fn context_select(id u32) !&Context {
	context_current = id
	return context()!
}

pub fn context() !&Context {
	return context_get(context_current)!
}
