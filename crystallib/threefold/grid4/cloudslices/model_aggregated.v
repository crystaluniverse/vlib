module cloudslices

import time

pub struct NodeTotal {
pub mut:
	id           int
	name         string
	cost         f64
	deliverytime time.Time
	description  string
	cpu_brand    string
	cpu_version  string
	inca_reward  int
	image        string
	mem          string
	hdd          string
	ssd          string
	url          string
	reputation   int
	uptime       int
	continent    string
	country      string

	storage_gb       f64
	mem_gb           f64
	mem_gb_gpu       f64
	price_simulation f64
	passmark         int
	vcores           int
}

pub fn (n Node) node_total() NodeTotal {
	mut total := NodeTotal{
		id:           n.id
		name:         n.name
		cost:         n.cost
		deliverytime: n.deliverytime
		description:  n.description
		cpu_brand:    n.cpu_brand
		cpu_version:  n.cpu_version
		inca_reward:  n.inca_reward
		image:        n.image
		mem:          n.mem
		hdd:          n.hdd
		ssd:          n.ssd
		url:          n.url
		reputation:   n.reputation
		uptime:       n.uptime
		continent:    n.continent
		country:      n.country
	}
	for box in n.cloudbox {
		total.storage_gb += box.storage_gb * f64(box.amount)
		total.mem_gb += box.mem_gb * f64(box.amount)
		total.price_simulation += box.price_simulation * f64(box.amount)
		total.passmark += box.passmark * box.amount
		total.vcores += box.vcores * box.amount
	}

	for box in n.aibox {
		total.storage_gb += box.storage_gb * f64(box.amount)
		total.mem_gb += box.mem_gb * f64(box.amount)
		total.mem_gb_gpu += box.mem_gb_gpu * f64(box.amount)
		total.price_simulation += box.price_simulation * f64(box.amount)
		total.passmark += box.passmark * box.amount
		total.vcores += box.vcores * box.amount
	}

	for box in n.storagebox {
		total.price_simulation += box.price_simulation * f64(box.amount)
	}

	return total
}
