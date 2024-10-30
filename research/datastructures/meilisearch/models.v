module meilisearch

import freeflowuniverse.crystallib.clients.httpconnection { HTTPConnection }

// MeiliClient is the main client for interacting with Meilisearch
pub struct MeiliClient {
pub:
	config ClientConfig
mut:
	http HTTPConnection
}

// ClientConfig holds configuration for MeiliClient
pub struct ClientConfig {
pub:
	host      string // Base URL of Meilisearch server (e.g., "http://localhost:7700")
	api_key   string // Master key or API key for authentication
	timeout   int = 30 // Request timeout in seconds
	max_retry int = 3  // Maximum number of retries for failed requests
}

// Health represents the health status of the Meilisearch server
pub struct Health {
pub:
	status string
}

// Version represents version information of the Meilisearch server
pub struct Version {
pub:
	pkg_version    string
	commit_sha    string
	build_date    string
}

// IndexSettings represents all configurable settings for an index
pub struct IndexSettings {
pub mut:
	ranking_rules         []string
	distinct_attribute    string
	searchable_attributes []string
	displayed_attributes  []string
	stop_words           []string
	synonyms             map[string][]string
	filterable_attributes []string
	sortable_attributes   []string
	typo_tolerance       TypoTolerance
}

// TypoTolerance settings for controlling typo behavior
pub struct TypoTolerance {
pub mut:
	enabled              bool = true
	min_word_size_for_typos MinWordSizeForTypos
	disable_on_words     []string
	disable_on_attributes []string
}

// MinWordSizeForTypos controls minimum word sizes for one/two typos
pub struct MinWordSizeForTypos {
pub mut:
	one_typo  int = 5
	two_typos int = 9
}

// DocumentsQuery represents query parameters for document operations
pub struct DocumentsQuery {
pub mut:
	limit          int = 20
	offset         int
	fields         []string
	filter         string
	sort          []string
}

// TaskInfo represents information about an asynchronous task
pub struct TaskInfo {
pub:
	uid        int
	index_uid  string
	status     string
	task_type  string
	details    map[string]string
	error      string
	duration   string
	enqueued_at string
	started_at  string
	finished_at string
}
