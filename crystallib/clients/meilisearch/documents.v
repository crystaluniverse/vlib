module meilisearch

import freeflowuniverse.crystallib.clients.httpconnection
import x.json2
import json

// add_documents adds documents to an index
pub fn (mut client MeilisearchClient) add_documents[T](uid string, documents []T) !AddDocumentResponse {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/documents'
		method: .post
		data:   json2.encode(documents)
	}

	response := client.http.post_json_str(req)!
	return json2.decode[AddDocumentResponse](response)!
}

@[params]
struct GetDocumentArgs {
pub mut:
	uid              string @[required]
	document_id      int    @[required]
	fields           []string
	retrieve_vectors bool @[json: 'retrieveVectors']
}

// get_document retrieves one document by its id
pub fn (mut client MeilisearchClient) get_document[T](args GetDocumentArgs) !T {
	mut params := map[string]string{}
	if args.fields.len > 0 {
		params['fields'] = args.fields.join(',')
	}

	params['retrieveVectors'] = args.retrieve_vectors.str()

	req := httpconnection.Request{
		prefix: 'indexes/${args.uid}/documents/${args.document_id}'
		params: params
	}

	response := client.http.get_json(req)!
	return json.decode(T, response)
}

// get_documents retrieves documents with optional parameters
pub fn (mut client MeilisearchClient) get_documents[T](uid string, query DocumentsQuery) ![]T {
	mut params := map[string]string{}
	params['limit'] = query.limit.str()
	params['offset'] = query.offset.str()

	if query.fields.len > 0 {
		params['fields'] = query.fields.join(',')
	}
	if query.filter.len > 0 {
		params['filter'] = query.filter
	}
	if query.sort.len > 0 {
		params['sort'] = query.sort.join(',')
	}

	req := httpconnection.Request{
		prefix: 'indexes/${uid}/documents'
		params: params
	}

	response := client.http.get_json(req)!
	decoded := json.decode(ListResponse[T], response)!
	return decoded.results
}

@[params]
struct DeleteDocumentArgs {
pub mut:
	uid         string @[required]
	document_id int    @[required]
}

// delete_document deletes one document by its id
pub fn (mut client MeilisearchClient) delete_document(args DeleteDocumentArgs) !DeleteDocumentResponse {
	req := httpconnection.Request{
		prefix: 'indexes/${args.uid}/documents/${args.document_id}'
		method: .delete
	}

	response := client.http.delete(req)!
	return json2.decode[DeleteDocumentResponse](response)!
}

// delete_all_documents deletes all documents in an index
pub fn (mut client MeilisearchClient) delete_all_documents(uid string) !DeleteDocumentResponse {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/documents'
		method: .delete
	}

	response := client.http.delete(req)!
	return json2.decode[DeleteDocumentResponse](response)!
}

// update_documents updates documents in an index
pub fn (mut client MeilisearchClient) update_documents(uid string, documents string) !TaskInfo {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/documents'
		method: .put
		data:   documents
	}

	response := client.http.post_json_str(req)!
	return json2.decode[TaskInfo](response)!
}

@[params]
struct SearchArgs {
pub mut:
	q                          string 			@[json: 'q'; required]
	offset                     int    			@[json: 'offset']
	limit                      int = 20    		@[json: 'limit']
	hits_per_page              int = 1    		@[json: 'hitsPerPage']
	page                       int = 1    		@[json: 'page']
	filter                     ?string
	facets                     ?[]string
	attributes_to_retrieve     []string = ['*'] @[json: 'attributesToRetrieve']
	attributes_to_crop         ?[]string 		@[json: 'attributesToCrop']
	crop_length                int    = 10      @[json: 'cropLength']
	crop_marker                string = '...'   @[json: 'cropMarker']
	attributes_to_highlight    ?[]string 		@[json: 'attributesToHighlight']
	highlight_pre_tag          string = '<em>'  @[json: 'highlightPreTag']
	highlight_post_tag         string = '</em>' @[json: 'highlightPostTag']
	show_matches_position      bool      		@[json: 'showMatchesPosition']
	sort                       ?[]string
	matching_strategy          string = 'last'  @[json: 'matchingStrategy']
	show_ranking_score         bool     		@[json: 'showRankingScore']
	show_ranking_score_details bool     		@[json: 'showRankingScoreDetails']
	ranking_score_threshold    ?f64     		@[json: 'rankingScoreThreshold']
	attributes_to_search_on    []string = ['*'] @[json: 'attributesToSearchOn']
	hybrid                     ?map[string]string
	vector                     ?[]f64
	retrieve_vectors           bool 			@[json: 'retrieveVectors']
	locales                    ?[]string
}

// search performs a search query on an index
pub fn (mut client MeilisearchClient) search[T](uid string, args SearchArgs) !SearchResponse[T] {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/search'
		method: .post
		data:   json.encode(args)
	}
	rsponse := client.http.post_json_str(req)!
	return json.decode(SearchResponse[T], rsponse)
}
