module zos

struct IPNet {
	ip   IP     // network number
	mask IPMask // network mask
}

// Peer is the description of a peer of a NetResource
struct Peer {
	subnet        IPNet
	wg_public_key string
	allowed_ips   []IPNet
	endpoint      string
}

type IP = []byte // TODO: this is a weird format, not usable for our customers
type IPMask = []byte

// Unit defines a capacity unit in "bytes"
// Any "value" of type Unit must be in bytes only
// hence use the Unit mutliplies below to set the
// write value
type Unit = u64

// Capacity the expected capacity of a workload
struct Capacity {
	cru   u64
	sru   Unit
	hru   Unit
	mru   Unit
	ipv4u u64
}

type GPU = string

struct Mount {
	name  string
	point string
}

struct QuantumSafeMeta {
	typ_   string            @[json: 'type']
	config QuantumSafeConfig
}

struct QuantumSafeConfig {
	prefix     string
	encryption Encryption
	backends   []ZDBBackend
}

struct Encryption {
	algorithm EncryptionAlgorithm
	key       EncryptionKey
}

type EncryptionAlgorithm = string
type EncryptionKey = []byte

struct QuantumCompression {
	algorithm string
}
