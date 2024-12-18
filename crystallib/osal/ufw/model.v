module ufw

pub struct UFWStatus {
pub mut:
	active bool
	rules  []Rule
}

@[heap]
pub struct RuleSet {
pub mut:
	rules []Rule
	ssh   bool = true // leave this on, its your backdoor to get in the system
	reset bool = true
}

pub struct Rule {
pub mut:
	ipv6  bool
	port  int
	from  string = 'any'
	tcp   bool
	udp   bool
	allow bool // if not then is denied
}

@[params]
pub struct RuleArgs {
pub mut:
	ipv6 bool
	port int
	from string = 'any'
	tcp  bool   = true
	udp  bool
}

// Allow incoming traffic to a specific port or service
pub fn (mut rs RuleSet) allow(args RuleArgs) {
	rs.rules << Rule{
		port:  args.port
		tcp:   args.tcp
		udp:   args.udp
		allow: true
		from:  args.from
		ipv6:  args.ipv6
	}
}

// Deny incoming traffic to a specific port or service
pub fn (mut rs RuleSet) deny(args RuleArgs) {
	rs.rules << Rule{
		port:  args.port
		tcp:   args.tcp
		from:  args.from
		udp:   args.udp
		allow: false
		ipv6:  args.ipv6
	}
}
