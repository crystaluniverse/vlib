module builder


pub struct SSHPingArgs {
pub mut:
	ipaddr string
	user   string = 'root'
	timeout int = 60
}


//- format ipaddr: 192.168.6.6:7777
//- format ipaddr: 192.168.6.6
//- format ipadd6: [666:555:555:...]
pub fn sshping(args SSHPingArgs)!{
	executor_new(ipaddr:args.ipaddr, user:args.user,checkconnect:args.timeout)!
}