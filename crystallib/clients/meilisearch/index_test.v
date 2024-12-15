module meilisearch

import rand
import time

__global (
	created_indices []string
)

// Set up a test client instance
fn setup_client() !&MeilisearchClient {
	mut client := get()!
	return client
}

// Tests the health endpoint for server status
fn test_health() {
	mut client := setup_client()!
	health := client.health()!
	assert health.status == 'available'
}

// Tests the version endpoint to ensure version information is present
fn test_version() {
	mut client := setup_client()!
	version := client.version()!
	assert version.pkg_version.len > 0
	assert version.commit_sha.len > 0
	assert version.commit_date.len > 0
}

// Tests index creation and verifies if the index UID matches
fn test_create_index() {
	index_name := 'test_' + rand.string(4)
	mut client := setup_client()!

	index := client.create_index(uid: index_name)!
	created_indices << index_name

	assert index.index_uid == index_name
	assert index.type_ == 'indexCreation'
}

// Tests index retrieval and verifies if the retrieved index UID matches
fn test_get_index() {
	index_name := 'test_' + rand.string(4)
	indes_primary_key := 'id'
	mut client := setup_client()!

	created_index := client.create_index(uid: index_name, primary_key: indes_primary_key)!
	created_indices << index_name
	assert created_index.index_uid == index_name
	assert created_index.type_ == 'indexCreation'

	time.sleep(1 * time.second) // Wait for the index to be created.

	retrieved_index := client.get_index(index_name)!
	assert retrieved_index.uid == index_name
	assert retrieved_index.primary_key == indes_primary_key
}

// Tests listing all indexes to ensure the created index is in the list
fn test_list_indexes() {
	mut client := setup_client()!
	index_name := 'test_' + rand.string(4)

	mut index_list := client.list_indexes()!
	assert index_list.len > 0
}

// Tests deletion of an index and confirms it no longer exists
fn test_delete_index() {
	mut client := setup_client()!
	mut index_list := client.list_indexes(limit: 100)!

	for index in index_list {
		client.delete_index(index.uid)!
		time.sleep(500 * time.millisecond)
	}

	index_list = client.list_indexes(limit: 100)!
	assert index_list.len == 0

	created_indices.clear()
	assert created_indices.len == 0
}
