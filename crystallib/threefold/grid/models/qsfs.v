module models

pub struct QuantumSafeFS {
	cache  u64
	config QuantumSafeFSConfig
}

pub struct QuantumSafeFSConfig {
	minimal_shards        u32
	expected_shards       u32
	redundant_groups      u32
	redundant_nodes       u32
	max_zdb_data_dir_size u32
	encryption            Encryption
	meta                  QuantumSafeMeta
	goups                 []ZDBGroup
	compression           QuantumCompression
}

pub struct Encryption {
	algorithm string = 'AES' // configuration to use for the encryption stage. Currently only AES is supported.
	key       []u8 // 64 long hex encoded encryption key (e.g. 0000000000000000000000000000000000000000000000000000000000000000).
}

pub struct QuantumSafeMeta {
	type_  string = 'ZDB' @[json: 'type']         // configuration for the metadata store to use, currently only ZDB is supported.
	config QuantumSafeConfig
}

pub struct ZDBGroup {
	backends []ZDBBackend
}

pub struct ZDBBackend {
	address   string // Address of backend ZDB (e.g. [300:a582:c60c:df75:f6da:8a92:d5ed:71ad]:9900 or 60.60.60.60:9900).
	namespace string // ZDB namespace.
	password  string // Namespace password.
}

pub struct QuantumCompression {
	algorithm string = 'snappy' // configuration to use for the compression stage. Currently only snappy is supported.
}

pub struct QuantumSafeConfig {
	prefix     string // Data stored on the remote metadata is prefixed with.
	encryption Encryption
	backends   []ZDBBackend
}

pub fn (qsfs QuantumSafeFS) challenge() string {
	return ''
}
