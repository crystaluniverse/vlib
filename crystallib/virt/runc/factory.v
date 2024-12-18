module runc

fn example() {
	root := Root{
		path:     '/rootfs'
		readonly: true
	}

	process := Process{
		terminal:     true
		user:         User{
			uid:             0
			gid:             0
			additional_gids: [u32(0)]
		}
		args:         ['/bin/bash']
		env:          ['PATH=/usr/bin']
		cwd:          '/'
		capabilities: Capabilities{
			bounding:    [Capability.cap_chown, Capability.cap_dac_override]
			effective:   [Capability.cap_chown]
			inheritable: []
			permitted:   [Capability.cap_chown]
			ambient:     []
		}
		rlimits:      [
			Rlimit{
				typ:  .rlimit_nofile
				hard: 1024
				soft: 1024
			},
		]
	}

	linux := Linux{
		namespaces: [
			LinuxNamespace{
				typ:  'pid'
				path: ''
			},
		]
		resources:  LinuxResource{
			blkio_weight: 1000
			cpu_period:   100000
			cpu_quota:    50000
			cpu_shares:   1024
			devices:      []
			memory_limit: 1024 * 1024 * 1024 // 1GB
		}
		devices:    []
	}

	spec := Spec{
		version:  '1.0.0'
		platform: Platform{
			os:   .linux
			arch: .amd64
		}
		process:  process
		root:     root
		hostname: 'my-container'
		mounts:   []
		linux:    linux
		hooks:    Hooks{}
	}

	println(spec)
}
