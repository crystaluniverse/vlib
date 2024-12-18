module runc

struct LinuxNamespace {
	typ  string
	path string
}

struct LinuxIDMapping {
	container_id u32
	host_id      u32
	size         u32
}

struct LinuxResource {
	blkio_weight                     u16
	blkio_weight_device              []string
	blkio_throttle_read_bps_device   []string
	blkio_throttle_write_bps_device  []string
	blkio_throttle_read_iops_device  []string
	blkio_throttle_write_iops_device []string
	cpu_period                       u64
	cpu_quota                        i64
	cpu_shares                       u64
	cpuset_cpus                      string
	cpuset_mems                      string
	devices                          []string
	memory_limit                     u64
	memory_reservation               u64
	memory_swap_limit                u64
	memory_kernel_limit              u64
	memory_swappiness                i64
	pids_limit                       i64
}

struct LinuxDevice {
	typ         string
	major       int
	minor       int
	permissions string
	file_mode   u32
	uid         u32
	gid         u32
}

struct Hooks {
	prestart  []string
	poststart []string
	poststop  []string
}

// see https://github.com/opencontainers/runtime-spec/blob/main/config.md#process
struct Process {
	terminal     bool
	user         User
	args         []string
	env          []string // do as dict
	cwd          string
	capabilities Capabilities
	rlimits      []Rlimit
}

// Enum for Rlimit types
enum RlimitType {
	rlimit_cpu
	rlimit_fsize
	rlimit_data
	rlimit_stack
	rlimit_core
	rlimit_rss
	rlimit_nproc
	rlimit_nofile
	rlimit_memlock
	rlimit_as
	rlimit_lock
	rlimit_sigpending
	rlimit_msgqueue
	rlimit_nice
	rlimit_rtprio
	rlimit_rttime
}

// Struct for Rlimit using enumerator
struct Rlimit {
	typ  RlimitType
	hard u64
	soft u64
}

struct User {
	uid             u32
	gid             u32
	additional_gids []u32
}

struct Root {
	path     string
	readonly bool
}

struct Linux {
	namespaces []LinuxNamespace
	resources  LinuxResource
	devices    []LinuxDevice
}

struct Spec {
	version  string
	platform Platform
	process  Process
	root     Root
	hostname string
	mounts   []Mount
	linux    Linux
	hooks    Hooks
}

// Enum for supported operating systems
enum OSType {
	linux
	windows
	darwin
	solaris
	// Add other OS types as needed
}

// Enum for supported architectures
enum ArchType {
	amd64
	arm64
	arm
	ppc64
	s390x
	// Add other architectures as needed
}

// Struct for Platform using enums
struct Platform {
	os   OSType
	arch ArchType
}

// Enum for mount types
enum MountType {
	bind
	tmpfs
	nfs
	overlay
	devpts
	proc
	sysfs
	// Add other mount types as needed
}

// Enum for mount options
enum MountOption {
	rw
	ro
	noexec
	nosuid
	nodev
	rbind
	relatime
	// Add other options as needed
}

// Struct for Mount using enums
struct Mount {
	destination string
	typ         MountType
	source      string
	options     []MountOption
}

enum Capability {
	cap_chown
	cap_dac_override
	cap_dac_read_search
	cap_fowner
	cap_fsetid
	cap_kill
	cap_setgid
	cap_setuid
	cap_setpcap
	cap_linux_immutable
	cap_net_bind_service
	cap_net_broadcast
	cap_net_admin
	cap_net_raw
	cap_ipc_lock
	cap_ipc_owner
	cap_sys_module
	cap_sys_rawio
	cap_sys_chroot
	cap_sys_ptrace
	cap_sys_pacct
	cap_sys_admin
	cap_sys_boot
	cap_sys_nice
	cap_sys_resource
	cap_sys_time
	cap_sys_tty_config
	cap_mknod
	cap_lease
	cap_audit_write
	cap_audit_control
	cap_setfcap
	cap_mac_override
	cap_mac_admin
	cap_syslog
	cap_wake_alarm
	cap_block_suspend
	cap_audit_read
}

struct Capabilities {
	bounding    []Capability
	effective   []Capability
	inheritable []Capability
	permitted   []Capability
	ambient     []Capability
}
