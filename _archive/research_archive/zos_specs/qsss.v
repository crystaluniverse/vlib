struct QsfsParams {
	deployment_name       string             // deployment name
	name                  string             // qsfs name
	version               u32                // deployment version
	cache                 Unit               // qsfs cache
	minimal_shards        u32                // qsfs minimal shards
	expected_shards       u32                // qsfs expected shards
	redundant_groups      u32                // qsfs redundant groups
	redundant_nodes       u32                // qsfs redundant nodes
	max_zdb_data_dir_size u32                // qsfs max zdb data dir size
	encryption            Encryption         // qsfs encryption
	metadata              QuantumSafeMeta    // qsfs metadata
	groups                []ZDBGroup         // qsfs groups
	compression           QuantumCompression // qsfs compression
}

pub fn (client ZOSClient) zos_deployment_qsfs_create(params QsfsParams) {
}

pub fn (client ZOSClient) zos_deployment_qsfs_update(params QsfsParams) {
}

struct QsfsGetParams {
	deployment_name string // deployment name
	name            string // qsfs name
}

pub fn (client ZOSClient) zos_deployment_qsfs_get(params QsfsGetParams) {
}
