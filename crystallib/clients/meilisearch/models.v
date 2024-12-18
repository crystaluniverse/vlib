module meilisearch

// ClientConfig holds configuration for MeilisearchClient
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
	status string @[json: 'status']
}

// Version represents version information of the Meilisearch server
pub struct Version {
pub:
	pkg_version string @[json: 'pkgVersion']
	commit_sha  string @[json: 'commitSha']
	commit_date string @[json: 'commitDate']
}

// IndexSettings represents all configurable settings for an index
pub struct IndexSettings {
pub mut:
	ranking_rules         []string            @[json: 'rankingRules']
	distinct_attribute    string              @[json: 'distinctAttribute']
	searchable_attributes []string            @[json: 'searchableAttributes']
	displayed_attributes  []string            @[json: 'displayedAttributes']
	stop_words            []string            @[json: 'stopWords']
	synonyms              map[string][]string @[json: 'synonyms']
	filterable_attributes []string            @[json: 'filterableAttributes']
	sortable_attributes   []string            @[json: 'sortableAttributes']
	typo_tolerance        TypoTolerance       @[json: 'typoTolerance']
}

// TypoTolerance settings for controlling typo behavior
pub struct TypoTolerance {
pub mut:
	enabled                 bool = true                @[json: 'enabled']
	min_word_size_for_typos MinWordSizeForTypos @[json: 'minWordSizeForTypos']
	disable_on_words        []string            @[json: 'disableOnWords']
	disable_on_attributes   []string            @[json: 'disableOnAttributes']
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
	limit  int = 20
	offset int
	fields []string
	filter string
	sort   []string
}

// TaskInfo represents information about an asynchronous task
pub struct TaskInfo {
pub:
	uid         int               @[json: 'taskUid']
	index_uid   string            @[json: 'indexUid']
	status      string            @[json: 'status']
	task_type   string            @[json: 'type']
	details     map[string]string @[json: 'details']
	error       string            @[json: 'error']
	duration    string            @[json: 'duration']
	enqueued_at string            @[json: 'enqueuedAt']
	started_at  string            @[json: 'startedAt']
	finished_at string            @[json: 'finishedAt']
}

// CreateIndexArgs represents the arguments for creating an index
@[params]
pub struct CreateIndexArgs {
pub mut:
	uid         string
	primary_key string @[json: 'primaryKey']
}

// IndexCreation represents information about the index creation
pub struct CreateIndexResponse {
pub mut:
	uid         int    @[json: 'taskUid']
	index_uid   string @[json: 'indexUid']
	status      string @[json: 'status']
	type_       string @[json: 'type']
	enqueued_at string @[json: 'enqueuedAt']
}

// IndexCreation represents information about the index creation
pub struct GetIndexResponse {
pub mut:
	uid         string @[json: 'uid']
	created_at  string @[json: 'createdAt']
	updated_at  string @[json: 'updatedAt']
	primary_key string @[json: 'primaryKey']
}

// ListIndexResponse represents information about the index list
pub struct ListResponse[T] {
pub mut:
	results []T
	total   int
	offset  int
	limit   int
}

// ListIndexArgs represents the arguments for listing indexes
@[params]
pub struct ListIndexArgs {
pub mut:
	limit  int = 20
	offset int
}

// DeleteIndexResponse represents information about the index deletion
pub struct DeleteIndexResponse {
pub mut:
	uid         int    @[json: 'taskUid']
	index_uid   string @[json: 'indexUid']
	status      string @[json: 'status']
	type_       string @[json: 'type']
	enqueued_at string @[json: 'enqueuedAt']
}

struct AddDocumentResponse {
pub mut:
	task_uid    int    @[json: 'taskUid']
	index_uid   string @[json: 'indexUid']
	status      string
	type_       string @[json: 'type']
	enqueued_at string @[json: 'enqueuedAt']
}

struct DeleteDocumentResponse {
pub mut:
	task_uid    int    @[json: 'taskUid']
	index_uid   string @[json: 'indexUid']
	status      string
	type_       string @[json: 'type']
	enqueued_at string @[json: 'enqueuedAt']
}

struct SearchResponse[T] {
pub mut:
	hits                 []T                       @[json: 'hits']
	offset               int                       @[json: 'offset']
	limit                int                       @[json: 'limit']
	estimated_total_hits int                       @[json: 'estimatedTotalHits']
	total_hits           int                       @[json: 'totalHits']
	total_pages          int                       @[json: 'totalPages']
	hits_per_page        int                       @[json: 'hitsPerPage']
	page                 int                       @[json: 'page']
	facet_stats          map[string]map[string]f64 @[json: 'facetStats']
	processing_time_ms   int                       @[json: 'processingTimeMs']
	query                string                    @[json: 'query']
}
