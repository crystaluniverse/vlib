import freeflowuniverse.crystallib.web.asset_server { Asset }
import freeflowuniverse.crystallib.web.auth
import vweb
import os
import log

const assets_dir = '${os.dir(@FILE)}/assets'
const email = 'example.com'

fn main() {
	do() or { panic(err) }
}

fn do() ! {
	mut logger := log.Log{
		level: .debug
	}

	mut authenticator := auth.new()!
	mut server := asset_server.new(
		auth: authenticator
		assets: [
			create_asset('alice'),
			create_asset('bob'),
		]
		logger: logger
	)!

	alice := authenticator.identity.register_user('alice@${email}')
	bob := authenticator.identity.register_user('bob@${email}')

	alice_tokens := server.auth.new_auth_tokens(
		user_id: alice.id
	)
	bob_tokens := server.auth.new_auth_tokens(
		user_id: bob.id
	)

	logger.info('Alice tokens: ${alice_tokens}')
	logger.info('Bob tokens: ${bob_tokens}')
	vweb.run(server, 8081)
}

// create_asset creates the asset structures used in this example
fn create_asset(name string) Asset {
	return Asset{
		name: name
		path: '${assets_dir}/${name}'
		acl: auth.AccessControlList{
			entries: [
				auth.AccessControlEntry{
					accessor: '${name}@${email}'
					permissions: [.read]
				},
			]
		}
	}
}
