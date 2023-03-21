module builder

import rand
import ipaddress { IPAddress }

// Assuming this function runs first (which is the case)
// This generates ssh keys on local machine to use for
// connecting to local host over ssh and test executor
fn testsuite_begin() {
	mut e := ExecutorLocal{}
	e.exec("yes | ssh-keygen -t rsa  -f ~/.ssh/id_rsa_test -N ''")!
	e.exec('chmod 0600 ~/.ssh/id_rsa_test && chmod 0644 ~/.ssh/id_rsa_test.pub')!
	e.exec('cat ~/.ssh/id_rsa_test.pub >> ~/.ssh/authorized_keys')!
	e.exec('chmod og-wx ~/.ssh/authorized_keys')!
}

fn test_exec() {
	mut e := ExecutorSSH{
		sshkey: '~/.ssh/id_rsa_test'
	}
	e.ipaddr = IPAddress{
		addr: '127.0.0.1'
		port: 22
	}
	res := e.exec('ls  /')!
	println(res)
}

fn test_file_operations() {
	mut e := ExecutorSSH{
		sshkey: '~/.ssh/id_rsa_test'
	}
	e.ipaddr = IPAddress{
		addr: '127.0.0.1'
		port: 22
		cat: .ipv4
	}
	mut filepath := '/tmp/${rand.uuid_v4()}'
	e.file_write(filepath, 'ssh')!
	mut text := e.file_read(filepath)!
	assert text == 'ssh'
	mut exists := e.file_exists(filepath)
	assert exists == true
	e.delete(filepath)!
	exists = e.file_exists(filepath)
	assert exists == false
}

fn test_environ_get() {
	mut e := ExecutorSSH{
		sshkey: '~/.ssh/id_rsa_test'
	}
	e.ipaddr = IPAddress{
		addr: '127.0.0.1'
		port: 22
		cat: .ipv4
	}
	mut env := e.environ_get()!
	println(env)
}

// fn test_remote_machine() {
// 	mut e := ExecutorSSH {
// 		sshkey: "~/.ssh/id_rsa_test",
// 		user: "root",
// 		ipaddr: IPAddress{
// 			addr: "104.236.53.191",
// 			port: Port{
// 				number: 22,
// 				cat: PortType.tcp
// 			},
// 			cat: IpAddressType.ipv4
// 		}
// 	}
// 	res := e.exec("ls  /root")!
// 	println(res)
// }
