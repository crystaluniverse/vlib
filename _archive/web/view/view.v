module view

import vweb
import freeflowuniverse.crystallib.web.auth.identity

pub struct Controller {
	vweb.Context
mut:
	identity identity.Client @[vweb_global]
}

pub fn (mut c Controller) before_request() {
	// c.authorize()!
	hx_request := c.get_header('Hx-Request') == 'true'
	if !hx_request && c.req.url != '/admin' {
		c.index()
	}
}

pub fn (mut c Controller) index() vweb.Result {
	route := if c.req.url == '/admin' {
		'home'
	} else {
		c.req.url
	}

	return $vweb.html()
}

pub fn (mut c Controller) users() vweb.Result {
	users := c.identity.get_users() or {
		c.set_status(500, '')
		return c.text('error: ${err}')
	}
	return $vweb.html()
}

pub fn (mut c Controller) groups() vweb.Result {
	groups := c.identity.get_groups() or {
		c.set_status(500, '')
		return c.text('error: ${err}')
	}
	return $vweb.html()
}

// pub fn (mut c Controller) analytics() vweb.Result {
// 	users := c.identity.get_users() or { return c.server_error(500) }
// 	return c.html('')
// }

// pub fn (mut c Controller) add_user_form() vweb.Result {
// 	return c.html($tmpl('./templates/add_user_form.html'))
// }
