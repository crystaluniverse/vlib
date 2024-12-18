module stats

import json

fn get_perf() {
	cpu_type_, description_, cpu_vcores_ := get_cpu_info()
	mut capacity := Capacity{
		memory_gb: get_memory_gb()
		cpu:       CPU{
			cpu_type:    cpu_type_
			description: description_
			cpu_vcores:  cpu_vcores_
		}
		disks:     get_disk_info()
	}
	mut registration := map[string]json.Any{}
	registration['capacity'] = capacity
	registration['pub_key'] = 'dummy_public_key'
	registration['mycelium_address'] = 'dummy_mycelium_address'
	registration['pub_key_signature'] = 'dummy_signature'
	println(json.encode(registration))
}
