module model

import json

type OptionU64 = EmptyOption | u64
type OptionBool = EmptyOption | bool

@[params]
pub struct FarmFilter {
pub mut:
	page               OptionU64  = EmptyOption{}
	size               OptionU64  = EmptyOption{}
	ret_count          OptionBool = EmptyOption{}
	randomize          OptionBool = EmptyOption{}
	free_ips           OptionU64  = EmptyOption{}
	total_ips          OptionU64  = EmptyOption{}
	stellar_address    string
	pricing_policy_id  OptionU64 = EmptyOption{}
	farm_id            OptionU64 = EmptyOption{}
	twin_id            OptionU64 = EmptyOption{}
	name               string
	name_contains      string
	certification_type string
	dedicated          OptionBool = EmptyOption{}
	country            string
	node_free_mru      OptionU64 = EmptyOption{}
	node_free_hru      OptionU64 = EmptyOption{}
	node_free_sru      OptionU64 = EmptyOption{}
	node_status        string
	node_rented_by     OptionU64  = EmptyOption{}
	node_available_for OptionU64  = EmptyOption{}
	node_has_gpu       OptionBool = EmptyOption{}
	node_certified     OptionBool = EmptyOption{}
}

// serialize FarmFilter to map
pub fn (f &FarmFilter) to_map() map[string]string {
	mut m := map[string]string{}

	match f.page {
		EmptyOption {}
		u64 {
			m['page'] = f.page.str()
		}
	}
	match f.size {
		EmptyOption {}
		u64 {
			m['size'] = f.size.str()
		}
	}
	match f.ret_count {
		EmptyOption {}
		bool {
			m['ret_count'] = f.ret_count.str()
		}
	}
	match f.randomize {
		EmptyOption {}
		bool {
			m['randomize'] = f.randomize.str()
		}
	}
	match f.free_ips {
		EmptyOption {}
		u64 {
			m['free_ips'] = f.free_ips.str()
		}
	}
	match f.total_ips {
		EmptyOption {}
		u64 {
			m['total_ips'] = f.total_ips.str()
		}
	}
	if f.stellar_address != '' {
		m['stellar_address'] = f.stellar_address
	}
	match f.pricing_policy_id {
		EmptyOption {}
		u64 {
			m['pricing_policy_id'] = f.pricing_policy_id.str()
		}
	}
	match f.farm_id {
		EmptyOption {}
		u64 {
			m['farm_id'] = f.farm_id.str()
		}
	}
	match f.twin_id {
		EmptyOption {}
		u64 {
			m['twin_id'] = f.twin_id.str()
		}
	}

	if f.name != '' {
		m['name'] = f.name
	}
	if f.name_contains != '' {
		m['name_contains'] = f.name_contains
	}
	if f.certification_type != '' {
		m['certification_type'] = f.certification_type
	}
	if f.country != '' {
		m['country'] = f.country
	}
	match f.dedicated {
		EmptyOption {}
		bool {
			m['dedicated'] = f.dedicated.str()
		}
	}
	match f.node_available_for {
		EmptyOption {}
		u64 {
			m['node_available_for'] = f.node_available_for.str()
		}
	}
	match f.node_free_hru {
		EmptyOption {}
		u64 {
			m['node_free_hru'] = f.node_free_hru.str()
		}
	}
	match f.node_free_mru {
		EmptyOption {}
		u64 {
			m['node_free_mru'] = f.node_free_mru.str()
		}
	}
	match f.node_free_sru {
		EmptyOption {}
		u64 {
			m['node_free_sru'] = f.node_free_sru.str()
		}
	}
	match f.node_rented_by {
		EmptyOption {}
		u64 {
			m['node_rented_by'] = f.node_rented_by.str()
		}
	}
	match f.node_has_gpu {
		EmptyOption {}
		bool {
			m['node_has_gpu'] = f.node_has_gpu.str()
		}
	}
	match f.node_certified {
		EmptyOption {}
		bool {
			m['node_certified'] = f.node_certified.str()
		}
	}
	if f.node_status != '' {
		m['node_status'] = f.node_status
	}
	return m
}

@[params]
pub struct ContractFilter {
pub mut:
	page                 OptionU64  = EmptyOption{}
	size                 OptionU64  = EmptyOption{}
	ret_count            OptionBool = EmptyOption{}
	randomize            OptionBool = EmptyOption{}
	contract_id          OptionU64  = EmptyOption{}
	twin_id              OptionU64  = EmptyOption{}
	node_id              OptionU64  = EmptyOption{}
	contract_type        string
	state                string
	name                 string
	number_of_public_ips OptionU64 = EmptyOption{}
	deployment_data      string
	deployment_hash      string
}

// serialize ContractFilter to map
pub fn (f &ContractFilter) to_map() map[string]string {
	mut m := map[string]string{}
	match f.page {
		EmptyOption {}
		u64 {
			m['page'] = f.page.str()
		}
	}
	match f.size {
		EmptyOption {}
		u64 {
			m['size'] = f.size.str()
		}
	}
	match f.ret_count {
		EmptyOption {}
		bool {
			m['ret_count'] = f.ret_count.str()
		}
	}
	match f.randomize {
		EmptyOption {}
		bool {
			m['randomize'] = f.randomize.str()
		}
	}
	match f.contract_id {
		EmptyOption {}
		u64 {
			m['contract_id'] = f.contract_id.str()
		}
	}
	match f.twin_id {
		EmptyOption {}
		u64 {
			m['twin_id'] = f.twin_id.str()
		}
	}
	match f.node_id {
		EmptyOption {}
		u64 {
			m['node_id'] = f.node_id.str()
		}
	}
	if f.contract_type != '' {
		m['type'] = f.contract_type
	}
	if f.state != '' {
		m['state'] = f.state
	}
	if f.name != '' {
		m['name'] = f.name
	}
	match f.number_of_public_ips {
		EmptyOption {}
		u64 {
			m['number_of_public_ips'] = f.number_of_public_ips.str()
		}
	}
	if f.deployment_data != '' {
		m['deployment_data'] = f.deployment_data
	}
	if f.deployment_hash != '' {
		m['deployment_hash'] = f.deployment_hash
	}
	return m
}

@[params]
pub struct NodeFilter {
pub mut:
	page               OptionU64  = EmptyOption{}
	size               OptionU64  = EmptyOption{}
	ret_count          OptionBool = EmptyOption{}
	randomize          OptionBool = EmptyOption{}
	free_mru           OptionU64  = EmptyOption{}
	free_sru           OptionU64  = EmptyOption{}
	free_hru           OptionU64  = EmptyOption{}
	free_ips           ?u64
	total_mru          OptionU64 = EmptyOption{}
	total_sru          OptionU64 = EmptyOption{}
	total_hru          OptionU64 = EmptyOption{}
	total_cru          OptionU64 = EmptyOption{}
	city               string
	city_contains      string
	country            string
	country_contains   string
	farm_name          string
	farm_name_contains string
	ipv4               OptionBool = EmptyOption{}
	ipv6               OptionBool = EmptyOption{}
	domain             OptionBool = EmptyOption{}
	status             string
	dedicated          OptionBool = EmptyOption{}
	healthy            OptionBool = EmptyOption{}
	rentable           OptionBool = EmptyOption{}
	rented_by          OptionU64  = EmptyOption{}
	rented             OptionBool = EmptyOption{}
	available_for      OptionU64  = EmptyOption{}
	farm_ids           []u64
	node_ids           []u64
	node_id            ?u32
	twin_id            OptionU64 = EmptyOption{}
	certification_type string
	has_gpu            OptionBool = EmptyOption{}
	has_ipv6           ?bool
	gpu_device_id      string
	gpu_device_name    string
	gpu_vendor_id      string
	gpu_vendor_name    string
	gpu_available      OptionBool = EmptyOption{}
	features           []string
}

// serialize NodeFilter to map
pub fn (p &NodeFilter) to_map() map[string]string {
	mut m := map[string]string{}
	match p.page {
		EmptyOption {}
		u64 {
			m['page'] = p.page.str()
		}
	}
	match p.size {
		EmptyOption {}
		u64 {
			m['size'] = p.size.str()
		}
	}
	match p.ret_count {
		EmptyOption {}
		bool {
			m['ret_count'] = p.ret_count.str()
		}
	}
	match p.randomize {
		EmptyOption {}
		bool {
			m['randomize'] = p.randomize.str()
		}
	}
	match p.free_mru {
		EmptyOption {}
		u64 {
			m['free_mru'] = p.free_mru.str()
		}
	}
	match p.free_sru {
		EmptyOption {}
		u64 {
			m['free_sru'] = p.free_sru.str()
		}
	}
	match p.free_hru {
		EmptyOption {}
		u64 {
			m['free_hru'] = p.free_hru.str()
		}
	}

	if v := p.free_ips {
		m['free_ips'] = v.str()
	}

	if v := p.has_ipv6 {
		m['has_ipv6'] = v.str()
	}

	match p.total_cru {
		EmptyOption {}
		u64 {
			m['total_cru'] = p.total_cru.str()
		}
	}
	match p.total_hru {
		EmptyOption {}
		u64 {
			m['total_hru'] = p.total_hru.str()
		}
	}
	match p.total_mru {
		EmptyOption {}
		u64 {
			m['total_mru'] = p.total_mru.str()
		}
	}
	match p.total_sru {
		EmptyOption {}
		u64 {
			m['total_sru'] = p.total_sru.str()
		}
	}
	if p.status != '' {
		m['status'] = p.status
	}
	if p.city != '' {
		m['city'] = p.city
	}
	if p.city_contains != '' {
		m['city_contains'] = p.city_contains
	}
	if p.country != '' {
		m['country'] = p.country
	}
	if p.country_contains != '' {
		m['country_contains'] = p.country_contains
	}
	if p.farm_name != '' {
		m['farm_name'] = p.farm_name
	}
	if p.farm_name_contains != '' {
		m['farm_name_contains'] = p.farm_name_contains
	}
	match p.ipv4 {
		EmptyOption {}
		bool {
			m['ipv4'] = p.ipv4.str()
		}
	}
	match p.ipv6 {
		EmptyOption {}
		bool {
			m['ipv6'] = p.ipv6.str()
		}
	}
	match p.healthy {
		EmptyOption {}
		bool {
			m['healthy'] = p.healthy.str()
		}
	}
	match p.domain {
		EmptyOption {}
		bool {
			m['domain'] = p.domain.str()
		}
	}
	match p.dedicated {
		EmptyOption {}
		bool {
			m['dedicated'] = p.dedicated.str()
		}
	}
	match p.rentable {
		EmptyOption {}
		bool {
			m['rentable'] = p.rentable.str()
		}
	}
	match p.rented_by {
		EmptyOption {}
		u64 {
			m['rented_by'] = p.rented_by.str()
		}
	}
	match p.rented {
		EmptyOption {}
		bool {
			m['rented'] = p.rented.str()
		}
	}
	match p.available_for {
		EmptyOption {}
		u64 {
			m['available_for'] = p.available_for.str()
		}
	}
	if p.features.len > 0 {
		m['features'] = json.encode(p.features).all_after('[').all_before(']')
	}
	if p.farm_ids.len > 0 {
		m['farm_ids'] = json.encode(p.farm_ids).all_after('[').all_before(']')
	}
	if p.node_ids.len > 0 {
		m['node_ids'] = json.encode(p.node_ids).all_after('[').all_before(']')
	}
	if n := p.node_id {
		m['node_id'] = n.str()
	}
	match p.twin_id {
		EmptyOption {}
		u64 {
			m['twin_id'] = p.twin_id.str()
		}
	}
	if p.certification_type != '' {
		m['certification_type'] = p.certification_type
	}
	match p.has_gpu {
		EmptyOption {}
		bool {
			m['has_gpu'] = p.has_gpu.str()
		}
	}
	if p.gpu_device_id != '' {
		m['gpu_device_id'] = p.gpu_device_id
	}
	if p.gpu_device_name != '' {
		m['gpu_device_name'] = p.gpu_device_name
	}
	if p.gpu_vendor_id != '' {
		m['gpu_vendor_id'] = p.gpu_vendor_id
	}
	if p.gpu_vendor_name != '' {
		m['gpu_vendor_name'] = p.gpu_vendor_name
	}
	match p.gpu_available {
		EmptyOption {}
		bool {
			m['gpu_available'] = p.gpu_available.str()
		}
	}
	return m
}

pub enum NodeStatus {
	all
	online
}

@[params]
pub struct ResourceFilter {
pub mut:
	free_mru_gb u64
	free_sru_gb u64
	free_hru_gb u64
	free_cpu    u64
	free_ips    u64
}

@[params]
pub struct StatFilter {
pub mut:
	status NodeStatus
}

@[params]
pub struct TwinFilter {
pub mut:
	page       OptionU64  = EmptyOption{}
	size       OptionU64  = EmptyOption{}
	ret_count  OptionBool = EmptyOption{}
	randomize  OptionBool = EmptyOption{}
	twin_id    OptionU64  = EmptyOption{}
	account_id string
	relay      string
	public_key string
}

// serialize TwinFilter to map
pub fn (p &TwinFilter) to_map() map[string]string {
	mut m := map[string]string{}
	match p.page {
		EmptyOption {}
		u64 {
			m['page'] = p.page.str()
		}
	}
	match p.size {
		EmptyOption {}
		u64 {
			m['size'] = p.size.str()
		}
	}
	match p.ret_count {
		EmptyOption {}
		bool {
			m['ret_count'] = p.ret_count.str()
		}
	}
	match p.randomize {
		EmptyOption {}
		bool {
			m['randomize'] = p.randomize.str()
		}
	}
	match p.twin_id {
		EmptyOption {}
		u64 {
			m['twin_id'] = p.twin_id.str()
		}
	}
	if p.account_id != '' {
		m['account_id'] = p.account_id
	}
	if p.relay != '' {
		m['relay'] = p.relay
	}
	if p.public_key != '' {
		m['public_key'] = p.public_key
	}
	return m
}
