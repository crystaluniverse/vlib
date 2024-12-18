module raw

import os
import json
import freeflowuniverse.crystallib.ui.console

pub fn list() ![]VM {
	// console.print_debug(" - list vm")
	cmd := 'limactl list --json'
	res := os.execute(cmd)
	if res.exit_code > 0 || res.output.contains('error=') {
		return error("can't list the lima vm's\nCommand was: 'limactl list --json'\nerror:\n${res.output}")
	}
	if res.output.contains('No instance found') {
		return []VM{}
	}
	mut vms := []VM{}
	for line in res.output.split_into_lines() {
		if line.trim_space().trim('.') == '' {
			continue
		}
		vm := json.decode(VM, line) or { return error("can't decode json for.\n'${line}'") }
		vms << vm
	}
	return vms
}

@[heap]
pub struct VM {
pub mut:
	name            string
	status          string
	dir             string
	vm_type         string @[json: vmType]
	arch            string
	cpu_type        string @[json: cpuType]
	cpus            int
	memory          i64
	disk            i64
	ssh_local_port  int    @[json: sshLocalPort]
	ssh_config_file string @[json: sshConfigFile]
	host_agent_pid  int    @[json: hostAgentPID]
	driver_pid      int    @[json: driverPID]
	// config         Config
	ssh_address   string @[json: sshAddress]
	protected     bool
	host_os       string @[json: HostOS]
	host_arch     string @[json: HostArch]
	lima_home     string @[json: LimaHome]
	identity_file string @[json: IdentityFile]
}

pub struct Config {
pub mut:
	vm_type              string @[json: vmType]
	os                   string
	arch                 string
	images               []Image
	cpu_type             CPUType @[json: cpuType]
	cpus                 int
	memory               string
	disk                 string
	mounts               []Mount
	mount_type           string @[json: mountType]
	ssh                  SSH
	firmware             Firmware
	audio                map[string]string
	video                Video
	containerd           Containerd
	guest_install_prefix string       @[json: guestInstallPrefix]
	host_resolver        HostResolver @[json: hostResolver]
	propagate_proxy_env  bool         @[json: propagateProxyEnv]
	ca_certs             CaCerts      @[json: caCerts]
	rosetta              Rosetta
	plain                bool
}

pub struct Image {
pub mut:
	location string
	arch     string
	digest   string @[json: digest]
}

pub struct CPUType {
pub mut:
	aarch64 string
	armv7l  string
	riscv64 string
	x86_64  string
}

pub struct SSHFS {
pub mut:
	cache           bool
	follow_symlinks bool   @[json: followSymlinks]
	sftp_driver     string @[json: sftpDriver]
}

pub struct NineP {
pub mut:
	security_model   string @[json: securityModel]
	protocol_version string @[json: protocolVersion]
	msize            string
	cache            string
}

pub struct Mount {
pub mut:
	location    string
	mount_point string @[json: mountPoint]
	writable    bool
	sshfs       SSHFS
	// _9p        NineP [json: 9p]
	virtiofs map[string]string
}

pub struct SSH {
pub mut:
	local_port            int  @[json: localPort]
	load_dot_ssh_pub_keys bool @[json: loadDotSSHPubKeys]
	forward_agent         bool @[json: forwardAgent]
	forward_x11           bool @[json: forwardX11]
	forward_x11_trusted   bool @[json: forwardX11Trusted]
}

pub struct FirmwareImage {
pub mut:
	location string
	arch     string
	digest   string @[json: digest]
	vm_type  string @[json: vmType]
}

pub struct Firmware {
pub mut:
	legacy_bios bool @[json: legacyBIOS]
	images      []FirmwareImage
}

pub struct VNC {
pub mut:
	display string
}

pub struct Video {
pub mut:
	display string
	vnc     VNC
}

pub struct Archive {
pub mut:
	location string
	arch     string
	digest   string @[json: digest]
}

pub struct Containerd {
pub mut:
	system   bool
	user     bool
	archives []Archive
}

pub struct HostResolver {
pub mut:
	enabled bool
	ipv6    bool
}

pub struct CaCerts {
pub mut:
	remove_defaults bool @[json: removeDefaults]
}

pub struct Rosetta {
pub mut:
	enabled bool
	binfmt  bool
}
