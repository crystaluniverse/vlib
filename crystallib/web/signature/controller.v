module signature

import veb
import db.sqlite
import crypto.hmac
import crypto.sha256
import time

// Struct to represent the user root keys and signatures
pub struct Context {
    veb.Context
}

pub struct App {
    veb.StaticHandler
	veb.Middleware[Context]
pub mut:
	signer &Signer
}

struct DocumentSignature {
    filename string
    hash string
    user_signature string
    server_signature string
}

// Endpoint to generate a root key for the user
@['/generate_root_key'; get]
pub fn (app &App) generate_root_key(mut ctx Context) veb.Result {
    root_key := app.signer.generate_root_key('user')
    return ctx.text('Your root key: $root_key')
}

// Endpoint to derive a key from the root key
@['/derive_key'; post]
pub fn (app &App) derive_key(mut ctx Context) veb.Result {
    root_key := ctx.form['root_key'] or { return ctx.request_error('missing root key') }
    key_index := ctx.form['index'] or { return ctx.request_error('missing index') }
    derived_key := app.signer.derive_key(root_key, key_index)
    return ctx.text('Derived key: $derived_key')
}

// Endpoint to sign a document hash and timestamp
@['/sign_document'; post]
pub fn (app &App) sign_document(mut ctx Context) veb.Result {
    derived_key := ctx.form['derived_key'] or { return ctx.request_error('missing derived key') }
    filename := ctx.form['filename'] or { return ctx.request_error('missing filename') }
    file_hash := ctx.form['hash'] or { return ctx.request_error('missing hash') }

	app.signer.sign_document(derived_key, filename, file_hash) or {
		ctx.server_error(err.msg())
	}
	
    return ctx.text('Document signed and stored')
}

// Endpoint to verify a signature
@['/verify_signature'; post]
pub fn (app &App) verify_signature(mut ctx Context) veb.Result {
    filename := ctx.form['filename'] or { return ctx.request_error('missing filename') }
    user_signature := ctx.form['user_signature'] or { return ctx.request_error('missing user signature') }

	app.signer.verify_signature(filename, user_signature) or {
		return ctx.server_error(err.msg())
	}
    return ctx.text('Signature is valid')
}

pub fn (app &App) index(mut ctx Context) veb.Result {
	return ctx.html($tmpl('./templates/signature.html'))
}

pub fn run() {
    // Initialize app
    mut app := &App{
		signer: signature.new()
	}

	app.use(handler: debug)

    veb.run[App, Context](mut app, 8081)
}

pub fn debug(mut ctx Context) bool {
    println('debugzo middleware')
    return true
}