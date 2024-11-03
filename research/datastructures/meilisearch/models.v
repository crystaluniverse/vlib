module meilisearch

import freeflowuniverse.crystallib.clients.httpconnection

// MeiliClient is the main client for interacting with Meilisearch
pub struct MeiliClient {
pub:
	config ClientConfig
mut:
	http &httpconnection.HTTPConnection
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
	ranking_rules         []string @[json: 'rankingRules']
	distinct_attribute    string @[json: 'distinctAttribute']
	searchable_attributes []string @[json: 'searchableAttributes']
	displayed_attributes  []string @[json: 'displayedAttributes']
	stop_words           []string @[json: 'stopWords']
	synonyms             map[string][]string @[json: 'synonyms']
	filterable_attributes []string @[json: 'filterableAttributes']
	sortable_attributes   []string @[json: 'sortableAttributes']
	typo_tolerance       TypoTolerance @[json: 'typoTolerance']
}

// TypoTolerance settings for controlling typo behavior
pub struct TypoTolerance {
pub mut:
	enabled              bool = true @[json: 'enabled']
	min_word_size_for_typos MinWordSizeForTypos @[json: 'minWordSizeForTypos']
	disable_on_words     []string @[json: 'disableOnWords']
	disable_on_attributes []string @[json: 'disableOnAttributes']
}

// MinWordSizeForTypos controls minimum word sizes for one/two typos
pub struct MinWordSizeForTypos {
pub mut:
	one_typo  int = 5 @[json: 'oneTypo']
	two_typos int = 9 @[json: 'twoTypos']
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
	uid        int @[json: 'taskUid']
	index_uid  string @[json: 'indexUid']
	status     string @[json: 'status']
	task_type  string @[json: 'type']
	details    map[string]string @[json: 'details']
	error      string @[json: 'error']
	duration   string @[json: 'duration']
	enqueued_at string @[json: 'enqueuedAt']
	started_at  string @[json: 'startedAt']
	finished_at string @[json: 'finishedAt']
}
