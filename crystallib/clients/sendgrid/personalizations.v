module sendgrid

@[params]
pub struct Personalizations {
pub mut:
	to                    []Recipient @[required]
	from                  ?Recipient
	cc                    ?[]Recipient
	bcc                   ?[]Recipient
	subject               ?string
	headers               ?map[string]string
	substitutions         ?map[string]string
	dynamic_template_data ?map[string]string
	custom_args           ?map[string]string
	send_at               ?i64
}

// add_to adds a list of recipients to which this email should be sent.
fn (mut p Personalizations) add_to(r []Recipient) {
	p.to << r
}

// set_from assigns the from field in the email.
fn (mut p Personalizations) set_from(r Recipient) {
	p.from = r
}

// add_cc adds an array of recipients who will receive a copy of your email.
fn (mut p Personalizations) add_cc(r []Recipient) {
	p.cc or {
		p.cc = r
		return
	}

	for item in r {
		p.cc << item
	}
}

// set_subject assigns the subject of the email.
fn (mut p Personalizations) set_subject(s string) {
	p.subject = s
}

// add_headers adds a playbook of key/value pairs to specify handling instructions for your email.
// if some of the new headers already existed, their values are overwritten.
fn (mut p Personalizations) add_headers(new_headers map[string]string) {
	p.headers or {
		p.headers = new_headers.clone()
		return
	}

	for k, v in new_headers {
		p.headers[k] = v
	}
}

// add_substitution adds a playbook of key/value pairs to allow you to insert data without using Dynamic Transactional Templates.
// if some of the keys already existed, their values are overwritten.
fn (mut p Personalizations) add_substitution(new_subs map[string]string) {
	p.substitutions or {
		p.substitutions = new_subs.clone()
		return
	}

	for k, v in new_subs {
		p.substitutions[k] = v
	}
}

// add_dynamic_template_data adds a playbook of key/value pairs to dynamic template data.
// Dynamic template data is available using Handlebars syntax in Dynamic Transactional Templates.
// if some of the keys already existed, their values are overwritten.
fn (mut p Personalizations) add_dynamic_template_data(new_dynamic_template_data map[string]string) {
	p.dynamic_template_data or {
		p.dynamic_template_data = new_dynamic_template_data.clone()
		return
	}

	for k, v in new_dynamic_template_data {
		p.dynamic_template_data[k] = v
	}
}

// add_custom_args adds a playbook of key/value pairs to custom_args.
// custom args are values that are specific to this personalization that will be carried along with the email and its activity data.
// if some of the keys already existed, their values are overwritten.
fn (mut p Personalizations) add_custom_args(new_custom_args map[string]string) {
	p.custom_args or {
		p.custom_args = new_custom_args.clone()
		return
	}

	for k, v in new_custom_args {
		p.custom_args[k] = v
	}
}

// set_send_at specifies when your email should be delivered. scheduling delivery more than 72 hours in advance is forbidden.
fn (mut p Personalizations) set_send_at(send_at i64) {
	p.send_at = send_at
}
