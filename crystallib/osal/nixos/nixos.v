module vserver

import os
import freeflowuniverse.crystallib.ui.console
// import json
// import maxux.vssh

struct NixosManager {
	root string
}

pub fn new() NixosManager {
	sm := NixosManager{}
	return sm
}

fn (s NixosManager) execute(command string) bool {
	// console.print_debug(command)

	r := os.execute(command)
	// console.print_debug(r)

	return true
}

pub fn (s NixosManager) nixos_prepare(diskmap map[string]string) !bool {
	// mounting
	// console.print_debug(diskmap)
	root := diskmap['/']
	boot := diskmap['/boot']
	more := diskmap['/disk1']

	// mandatory on the host
	console.print_debug('[+] creating required user, groups and directories')
	s.execute('groupadd -g 30000 nixbld')
	s.execute('useradd -u 30000 -g nixbld -G nixbld nixbld')

	os.mkdir('/nix')!
	os.mkdir('/mnt/nix')!

	console.print_debug('[+] mounting target disks')
	// mounting our extra disk for setup nix store
	s.execute('mount /dev/${more} /nix')
	s.execute('mount /dev/${root} /mnt/nix')

	os.mkdir('/mnt/nix/boot')!
	s.execute('mount /dev/${boot} /mnt/nix/boot')

	return true
}

pub fn (s NixosManager) nixos_install(bootdisk string, sshkey string) !bool {
	console.print_debug('[+] installing nix tools on the host')
	os.execute('curl -L https://nixos.org/nix/install | sh')
	// . /root/.nix-profile/etc/profile.d/nix.sh

	version := '23.11'
	console.print_debug('[+] updating channels, using version: ${version}')
	s.execute('/root/.nix-profile/bin/nix-channel --add https://nixos.org/channels/nixos-${version} nixpkgs')
	s.execute('/root/.nix-profile/bin/nix-channel --update')

	console.print_debug('[+] installing nixos install tools scripts')
	s.execute("/root/.nix-profile/bin/nix-env -f '<nixpkgs>' -iA nixos-install-tools")

	console.print_debug('[+] generating default configuration')
	s.execute('/root/.nix-profile/bin/nixos-generate-config --root /mnt/nix/')

	// /mnt/nix/etc/nixos/configuration.nix

	config := '
{ config, lib, pkgs, ... }:

{

    boot.loader.grub.device = "${bootdisk}";
    time.timeZone = "Europe/Brussels";

    environment.systemPackages = with pkgs; [
        vim
        wget
    ];

    services.openssh.enable = true;
    users.users.root.openssh.authorizedKeys.keys = [
        "${sshkey}"
    ];

}
'

	console.print_debug('[+] applying custom modification to configuration')
	os.write_file('/mnt/nix/etc/nixos/threefold.nix', config)!

	original := os.read_file('/mnt/nix/etc/nixos/configuration.nix')!
	updated := original.replace('./hardware-configuration.nix', './hardware-configuration.nix\n      ./threefold.nix')

	os.write_file('/mnt/nix/etc/nixos/configuration.nix', updated)!

	console.print_debug('[+] committing... installing nixos')

	// to specify environment variable set by nix, the easier solution
	// is using a temporary shell script
	script := '
. /root/.nix-profile/etc/profile.d/nix.sh
/root/.nix-profile/bin/nixos-install --no-root-passwd --root /mnt/nix
	'

	os.write_file('/tmp/nix-setup', script)!

	// apply configuration and install stuff
	os.execute('bash /tmp/nix-setup')

	return true
}

pub fn (s NixosManager) nixos_finish() !bool {
	console.print_debug('[+] cleaning up, unmounting filesystem')
	s.execute('umount -R /mnt/nix')
	s.execute('umount -R /nix')

	return true
}
