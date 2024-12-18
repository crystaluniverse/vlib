module stats

struct Capacity {
pub mut:
	memory_gb f64
	disks     []Disk
	cpu       CPU
}

struct CPU {
pub mut:
	cpu_type    CPUType
	description string
	cpu_vcores  int
}

struct Disk {
pub mut:
	size_gb   f64
	disk_type DiskType
}

enum DiskType {
	ssd
	hdd
}

enum CPUType {
	intel_xeon
	amd_epyc
	intel_core9
}
