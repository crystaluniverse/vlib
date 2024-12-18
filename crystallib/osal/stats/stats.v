module stats

import os
import json

fn get_memory_gb() f64 {
	mem_info := os.read_file('/proc/meminfo') or { return 0 }
	for line in mem_info.split_into_lines() {
		if line.starts_with('MemTotal:') {
			kb := line.all_after('MemTotal:').trim_space().all_before(' ').int()
			return kb / 1024 / 1024
		}
	}
	return 0
}

fn get_cpu_info() (CPUType, string, int) {
	cpu_info := os.read_file('/proc/cpuinfo') or { return .intel_core9, '', 0 }
	mut model_name := ''
	mut cpu_cores := 0
	for line in cpu_info.split_into_lines() {
		if line.starts_with('model name') {
			model_name = line.all_after(':').trim_space()
		} else if line.starts_with('cpu cores') {
			cpu_cores = line.all_after(':').trim_space().int()
		}
	}
	cpu_type := if model_name.to_lower().contains('xeon') {
		CPUType.intel_xeon
	} else if model_name.to_lower().contains('epyc') {
		CPUType.amd_epyc
	} else {
		CPUType.intel_core9
	}
	return cpu_type, model_name, cpu_cores
}

fn get_disk_info() []Disk {
	mut disks := []Disk{}
	block_devices := os.ls('/sys/block') or { return disks }
	for device in block_devices {
		if device.starts_with('sd') || device.starts_with('nvme') {
			size_bytes := os.read_file('/sys/block/${device}/size') or { continue }
			size_gb := size_bytes.trim_space().u64() * 512 / 1024 / 1024 / 1024
			rotational := os.read_file('/sys/block/${device}/queue/rotational') or { continue }
			is_ssd := rotational.trim_space() == '0'
			disks << Disk{
				size_gb:   size_gb
				disk_type: if is_ssd { DiskType.ssd } else { DiskType.hdd }
			}
		}
	}
	return disks
}
