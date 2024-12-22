module osinstaller

import os
import freeflowuniverse.crystallib.ui.console

pub fn (s ServerManager) raid_stop() !bool {
	if !os.exists('/proc/mdstat') {
		return false
	}

	md := os.read_file('/proc/mdstat')!
	lines := md.split_into_lines()

	for line in lines {
		if line.contains('active') {
			dev := line.split(' ')[0]
			console.print_debug('[+] stopping raid device: ${dev}')

			r := os.execute('mdadm --stop /dev/${dev}')
			if r.exit_code != 0 {
				console.print_debug(r.output)
			}
		}
	}

	return true
}

pub fn (s ServerManager) disks_list() ![]string {
	blocks := os.ls('/sys/class/block')!
	mut disks := []string{}

	for block in blocks {
		if os.is_link('/sys/class/block/${block}/device') {
			// discard cdrom
			events := os.read_file('/sys/class/block/${block}/events')!
			if events.contains('eject') {
				continue
			}

			// that should be good
			disks << block
		}
	}

	return disks
}

pub fn (s ServerManager) disk_erase(disk string) bool {
	// make it safe via wipefs
	r := os.execute('wipefs -a /dev/${disk}')
	if r.exit_code != 0 {
		console.print_debug(r.output)
		return false
	}

	return true
}

fn (s ServerManager) disk_partitions(disk string) ![]string {
	mut files := os.ls('/sys/class/block/${disk}')!
	mut parts := []string{}

	files.sort()
	for file in files {
		if file.starts_with(disk) {
			parts << file
		}
	}

	return parts
}

pub fn (s ServerManager) disk_main_layout(disk string) !map[string]string {
	s.execute('parted /dev/${disk} mklabel msdos')
	s.execute('parted -a optimal /dev/${disk} mkpart primary 0% 768MB')
	s.execute('parted -a optimal /dev/${disk} mkpart primary 768MB 100GB')
	s.execute('parted -a optimal /dev/${disk} mkpart primary linux-swap 100GB 104GB')
	s.execute('parted -a optimal /dev/${disk} mkpart primary 104GB 100%')
	s.execute('parted /dev/${disk} set 1 boot on')

	s.execute('partprobe')

	parts := s.disk_partitions(disk)!
	if parts.len < 4 {
		return error("partitions found doesn't match expected map")
	}

	mut diskmap := map[string]string{}
	diskmap['/'] = parts[1]
	diskmap['/boot'] = parts[0]
	diskmap['swap'] = parts[2]
	diskmap['/disk1'] = parts[3]

	boot := '/dev/' + parts[0]
	root := '/dev/' + parts[1]
	swap := '/dev/' + parts[2]
	more := '/dev/' + parts[3]

	console.print_debug('[+] partition map:')
	console.print_debug('[+]   /       -> ${root}  [ext2]')
	console.print_debug('[+]   /boot   -> ${boot}  [ext4]')
	console.print_debug('[+]   [swap]  -> ${swap}  [swap]')
	console.print_debug('[+]   [extra] -> ${more}  [btrfs]')

	console.print_debug('[+] creating boot partition')
	s.execute('mkfs.ext2 ${boot}')

	console.print_debug('[+] creating root partition')
	s.execute('mkfs.ext4 ${root}')

	console.print_debug('[+] creating swap partition')
	s.execute('mkswap ${swap}')

	console.print_debug('[+] creating storage partition')
	s.execute('mkfs.btrfs -f ${more}')

	return diskmap
}

pub fn (s ServerManager) disk_create_btrfs(disk string) !bool {
	console.print_debug('[+] creating btrfs on disk: /dev/${disk}')
	s.execute('mkfs.btrfs -f /dev/${disk}')

	return true
}
