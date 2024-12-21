module hetzner

// TODO: couldn't get ssh lib to work

// pub fn (h HetznerManager) server_prepare(name string) !bool {
// 	srvs := h.servers_list()!

// 	// console.print_debug(srvs)
// 	mut srvid := 0
// 	mut srvip := ""

// 	for s in srvs {
// 		if s.server.server_name == name {
// 			// console.print_debug(s)
// 			srvid = s.server.server_number
// 			srvip = s.server.server_ip
// 		}
// 	}

// 	if srvid == 0 {
// 		panic("could not find server")
// 	}

// 	console.print_debug("[+] request rescue mode")
// 	resc := h.server_rescue(srvid)!
// 	password := resc.rescue.password
// 	console.print_debug("[+] rescue password: $password")
// 	// console.print_debug(resc)

// 	console.print_debug("[+] fetching server information")
// 	boot := h.server_boot(srvid)!
// 	// console.print_debug(boot)

// 	console.print_debug("[+] forcing reboot")
// 	reset := h.server_reset(srvid)!
// 	// console.print_debug(reset)

// 	time.sleep(30000 * time.millisecond)

// 	console.print_debug("[+] waiting for rescue to be ready")
// 	for {
// 		target := vssh.new(srvip, 22) or {
// 			console.print_debug("$err")
// 			time.sleep(30000 * time.millisecond)
// 			continue
// 		}

// 		// rescue doesn't support keyboard-interactive, fallback to password
// 		target.authenticate(.password, "root", password)!
// 		check := target.execute("grep 'Hetzner Rescue System.' /etc/motd")!
// 		if check.exitcode == 0 {
// 			console.print_debug("[+] we are logged in on the rescue system !")

// 			// executing deployment binary
// 			target.upload(os.args[0], "/tmp/deployment")!
// 			target.stream("stdbuf -i0 -o0 -e0 /tmp/deployment")!

// 			exit(0)
// 		}
// 	}

// 	return true
// }
