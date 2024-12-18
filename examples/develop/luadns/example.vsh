#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.develop.luadns

fn main() {
	mut lua_dns := luadns.load('https://github.com/Incubaid/dns') or {
		eprintln('Failed to parse LuaDNS files: ${err}')
		return
	}

	lua_dns.set_domain('test.protocol.me', '65.21.132.119') or {
		eprintln('Failed to set domain: ${err}')
		return
	}

	lua_dns.set_domain('example.protocol.me', '65.21.132.119') or {
		eprintln('Failed to set domain: ${err}')
		return
	}

	for config in lua_dns.configs {
		println(config)
	}

	for config in lua_dns.configs {
		println(config)
	}
}
