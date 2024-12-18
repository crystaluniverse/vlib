#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.osal.ufw

ufw.enable()!
println(ufw.ufw_status()!)

mut ruleset := ufw.new()

// Allow HTTP traffic from a specific IPv4 address
ruleset.allow(
	port: 80
	from: '192.168.1.100'
)

// Allow HTTPS traffic from any IPv6 address
ruleset.allow(
	port: 443
	ipv6: true
)

// Deny SMTP traffic from a specific IPv4 subnet
ruleset.deny(
	port: 25
	from: '10.0.0.0/24'
)

// Deny FTP traffic from a specific IPv6 address
ruleset.deny(
	port: 21
	from: '2001:db8::1'
	udp:  true
	tcp:  false
	ipv6: true
)

// Apply the ruleset
ufw.apply(ruleset) or { panic('Error applying ruleset: ${err}') }

ufw.reset()!
ufw.enable()!
