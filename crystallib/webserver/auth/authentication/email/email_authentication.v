module email

import time
import crypto.hmac
import crypto.sha256
import encoding.hex
import encoding.base64
import freeflowuniverse.crystallib.clients.mailclient {MailClient}

pub struct StatelessAuthenticator {
pub:
	secret string
pub mut:
 	mail_client MailClient
}

 pub fn new_stateless_authenticator(authenticator StatelessAuthenticator) !StatelessAuthenticator {
	// TODO: do some checks
 	return StatelessAuthenticator {...authenticator}
}

pub struct AuthenticationMail {
	RedirectURLs
pub:
	to string // email address being authentcated
 	from    string = 'email_authenticator@crystallib.tf'
 	subject string = 'Verify your email'
 	body    string = 'Please verify your email by clicking the link below'
	callback string // callback url of authentication link
	success_url string // where the user will be redirected upon successful authentication
	failure_url string // where the user will be redirected upon failed authentication
}

pub fn (mut a StatelessAuthenticator) send_authentication_mail(mail AuthenticationMail) ! {
	link := a.new_authentication_link(mail.to, mail.callback, mail.RedirectURLs)!
	button := '<a href="${link}" style="display:inline-block; padding:10px 20px; font-size:16px; color:white; background-color:#4CAF50; text-decoration:none; border-radius:5px;">Verify Email</a>'

 	// send email with link in body
 	a.mail_client.send(
		to: mail.to
 		from: mail.from
 		subject: mail.subject
 		body_type: .html
 		body: $tmpl('./templates/mail.html')
	) or { return error('Error resolving email address $err') }
}

@[params]
pub struct RedirectURLs {
pub:
	success_url string
	failure_url string
}

fn (a StatelessAuthenticator) new_authentication_link(email string, callback string, urls RedirectURLs) !string {
	if urls.failure_url != '' {
		panic('implement')
	}

	// sign email address and expiration of authentication link
	expiration := time.now().add(5 * time.minute)
 	data := '${email}.${expiration}' // data to be signed

	// QUESTION? should success url also be signed for security?
 	signature := hmac.new(
 		hex.decode(a.secret)!,
 		data.bytes(),
 		sha256.sum,
 		sha256.block_size
 	)
 	encoded_signature := base64.url_encode(signature.bytestr().bytes())
	mut queries := ''
	if urls.success_url != '' {
		encoded_url := base64.url_encode(urls.success_url.bytes())
		queries += '?success_url=${encoded_url}'
	}
	return "${callback}/${email}/${expiration.unix_time()}/${encoded_signature}${queries}"
}

pub struct AuthenticationAttempt {
pub:
 	email string
 	expiration time.Time
 	signature string
}

// sends mail with login link
pub fn (auth StatelessAuthenticator) authenticate(attempt AuthenticationAttempt) ! {	
 	if time.now() > attempt.expiration {
 		return error('link expired')
 	}

 	data := '${attempt.email}.${attempt.expiration}' // data to be signed
 	signature_mirror := hmac.new(
 		hex.decode(auth.secret) or {panic(err)},
 		data.bytes(),
 		sha256.sum,
 		sha256.block_size
 	).bytestr().bytes()

 	decoded_signature := base64.url_decode(attempt.signature)

 	if !hmac.equal(decoded_signature, signature_mirror) {
 		return error('signature mismatch')
 	}
}
