module meilisearch

import freeflowuniverse.crystallib.clients.httpconnection
import x.json2
import json

// health checks if the server is healthy
pub fn (mut client MeilisearchClient) health() !Health {
	req := httpconnection.Request{
		prefix: 'health'
	}
	mut http := client.httpclient()!
	response := http.get_json(req)!
	return json2.decode[Health](response)
}

// version gets the version of the Meilisearch server
pub fn (mut client MeilisearchClient) version() !Version {
	req := httpconnection.Request{
		prefix: 'version'
	}
	mut http := client.httpclient()!
	response := http.get_json(req)!
	return json2.decode[Version](response)
}

// create_index creates a new index with the given UID
pub fn (mut client MeilisearchClient) create_index(args CreateIndexArgs) !CreateIndexResponse {
	req := httpconnection.Request{
		prefix: 'indexes'
		method: .post
		data:   json2.encode(args)
	}
	mut http := client.httpclient()!
	response := http.post_json_str(req)!
	return json2.decode[CreateIndexResponse](response)
}

// get_index retrieves information about an index
pub fn (mut client MeilisearchClient) get_index(uid string) !GetIndexResponse {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}'
	}
	mut http := client.httpclient()!
	response := http.get_json(req)!
	return json2.decode[GetIndexResponse](response)
}

// list_indexes retrieves all indexes
pub fn (mut client MeilisearchClient) list_indexes(args ListIndexArgs) ![]GetIndexResponse {
	req := httpconnection.Request{
		prefix: 'indexes?limit=${args.limit}&offset=${args.offset}'
	}
	mut http := client.httpclient()!
	response := http.get_json(req)!
	list_response := json.decode(ListResponse[GetIndexResponse], response)!
	return list_response.results
}

// delete_index deletes an index
pub fn (mut client MeilisearchClient) delete_index(uid string) !DeleteIndexResponse {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}'
	}
	mut http := client.httpclient()!
	response := http.delete(req)!
	return json2.decode[DeleteIndexResponse](response)
}

// get_settings retrieves all settings of an index
pub fn (mut client MeilisearchClient) get_settings(uid string) !IndexSettings {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings'
	}
	mut http := client.httpclient()!
	response := http.get_json_dict(req)!

	mut settings := IndexSettings{}
	if ranking_rules := response['rankingRules'] {
		settings.ranking_rules = ranking_rules.arr().map(it.str())
	}
	if distinct_attribute := response['distinctAttribute'] {
		settings.distinct_attribute = distinct_attribute.str()
	}
	if searchable_attributes := response['searchableAttributes'] {
		settings.searchable_attributes = searchable_attributes.arr().map(it.str())
	}
	if displayed_attributes := response['displayedAttributes'] {
		settings.displayed_attributes = displayed_attributes.arr().map(it.str())
	}
	if stop_words := response['stopWords'] {
		settings.stop_words = stop_words.arr().map(it.str())
	}
	if filterable_attributes := response['filterableAttributes'] {
		settings.filterable_attributes = filterable_attributes.arr().map(it.str())
	}
	if sortable_attributes := response['sortableAttributes'] {
		settings.sortable_attributes = sortable_attributes.arr().map(it.str())
	}

	return settings
}

// update_settings updates all settings of an index
pub fn (mut client MeilisearchClient) update_settings(uid string, settings IndexSettings) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings'
		method: .patch
		data:   json2.encode(settings)
	}
	mut http := client.httpclient()!
	return http.post_json_str(req)
}

// reset_settings resets all settings of an index to default values
pub fn (mut client MeilisearchClient) reset_settings(uid string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings'
		method: .delete
	}
	mut http := client.httpclient()!
	return http.delete(req)
}

// get_ranking_rules retrieves ranking rules of an index
pub fn (mut client MeilisearchClient) get_ranking_rules(uid string) ![]string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/ranking-rules'
	}
	mut http := client.httpclient()!
	response := http.get_json_dict(req)!
	return response['rankingRules']!.arr().map(it.str())
}

// update_ranking_rules updates ranking rules of an index
pub fn (mut client MeilisearchClient) update_ranking_rules(uid string, rules []string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/ranking-rules'
		method: .put
		data:   json2.encode({
			'rankingRules': rules
		})
	}
	mut http := client.httpclient()!
	return http.post_json_str(req)
}

// reset_ranking_rules resets ranking rules of an index to default values
pub fn (mut client MeilisearchClient) reset_ranking_rules(uid string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/ranking-rules'
		method: .delete
	}
	mut http := client.httpclient()!
	return http.delete(req)
}

// get_distinct_attribute retrieves distinct attribute of an index
pub fn (mut client MeilisearchClient) get_distinct_attribute(uid string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/distinct-attribute'
	}
	mut http := client.httpclient()!
	response := http.get_json_dict(req)!
	return response['distinctAttribute']!.str()
}

// update_distinct_attribute updates distinct attribute of an index
pub fn (mut client MeilisearchClient) update_distinct_attribute(uid string, attribute string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/distinct-attribute'
		method: .put
		data:   json2.encode({
			'distinctAttribute': attribute
		})
	}
	mut http := client.httpclient()!
	return http.post_json_str(req)
}

// reset_distinct_attribute resets distinct attribute of an index
pub fn (mut client MeilisearchClient) reset_distinct_attribute(uid string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/distinct-attribute'
		method: .delete
	}
	mut http := client.httpclient()!
	return http.delete(req)
}

// get_searchable_attributes retrieves searchable attributes of an index
pub fn (mut client MeilisearchClient) get_searchable_attributes(uid string) ![]string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/searchable-attributes'
	}
	mut http := client.httpclient()!
	response := http.get_json_dict(req)!
	return response['searchableAttributes']!.arr().map(it.str())
}

// update_searchable_attributes updates searchable attributes of an index
pub fn (mut client MeilisearchClient) update_searchable_attributes(uid string, attributes []string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/searchable-attributes'
		method: .put
		data:   json2.encode({
			'searchableAttributes': attributes
		})
	}
	mut http := client.httpclient()!
	return http.post_json_str(req)
}

// reset_searchable_attributes resets searchable attributes of an index
pub fn (mut client MeilisearchClient) reset_searchable_attributes(uid string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/searchable-attributes'
		method: .delete
	}
	mut http := client.httpclient()!
	return http.delete(req)
}

// get_displayed_attributes retrieves displayed attributes of an index
pub fn (mut client MeilisearchClient) get_displayed_attributes(uid string) ![]string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/displayed-attributes'
	}
	mut http := client.httpclient()!
	response := http.get_json_dict(req)!
	return response['displayedAttributes']!.arr().map(it.str())
}

// update_displayed_attributes updates displayed attributes of an index
pub fn (mut client MeilisearchClient) update_displayed_attributes(uid string, attributes []string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/displayed-attributes'
		method: .put
		data:   json2.encode({
			'displayedAttributes': attributes
		})
	}
	mut http := client.httpclient()!
	return http.post_json_str(req)
}

// reset_displayed_attributes resets displayed attributes of an index
pub fn (mut client MeilisearchClient) reset_displayed_attributes(uid string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/displayed-attributes'
		method: .delete
	}
	mut http := client.httpclient()!
	return http.delete(req)
}

// get_stop_words retrieves stop words of an index
pub fn (mut client MeilisearchClient) get_stop_words(uid string) ![]string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/stop-words'
	}
	mut http := client.httpclient()!
	response := http.get_json_dict(req)!
	return response['stopWords']!.arr().map(it.str())
}

// update_stop_words updates stop words of an index
pub fn (mut client MeilisearchClient) update_stop_words(uid string, words []string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/stop-words'
		method: .put
		data:   json2.encode({
			'stopWords': words
		})
	}
	mut http := client.httpclient()!
	return http.post_json_str(req)
}

// reset_stop_words resets stop words of an index
pub fn (mut client MeilisearchClient) reset_stop_words(uid string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/stop-words'
		method: .delete
	}
	mut http := client.httpclient()!
	return http.delete(req)
}

// get_synonyms retrieves synonyms of an index
pub fn (mut client MeilisearchClient) get_synonyms(uid string) !map[string][]string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/synonyms'
	}
	mut http := client.httpclient()!
	response := http.get_json_dict(req)!
	mut synonyms := map[string][]string{}
	for key, value in response['synonyms']!.as_map() {
		synonyms[key] = value.arr().map(it.str())
	}
	return synonyms
}

// update_synonyms updates synonyms of an index
pub fn (mut client MeilisearchClient) update_synonyms(uid string, synonyms map[string][]string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/synonyms'
		method: .put
		data:   json2.encode({
			'synonyms': synonyms
		})
	}
	mut http := client.httpclient()!
	return http.post_json_str(req)
}

// reset_synonyms resets synonyms of an index
pub fn (mut client MeilisearchClient) reset_synonyms(uid string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/synonyms'
		method: .delete
	}
	mut http := client.httpclient()!
	return http.delete(req)
}

// get_filterable_attributes retrieves filterable attributes of an index
pub fn (mut client MeilisearchClient) get_filterable_attributes(uid string) ![]string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/filterable-attributes'
	}
	mut http := client.httpclient()!
	response := http.get_json_dict(req)!
	return response['filterableAttributes']!.arr().map(it.str())
}

// update_filterable_attributes updates filterable attributes of an index
pub fn (mut client MeilisearchClient) update_filterable_attributes(uid string, attributes []string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/filterable-attributes'
		method: .put
		data: json.encode(attributes)
	}
	mut http := client.httpclient()!
	response := http.send(req)!
	return response.data
}

// reset_filterable_attributes resets filterable attributes of an index
pub fn (mut client MeilisearchClient) reset_filterable_attributes(uid string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/filterable-attributes'
		method: .delete
	}
	mut http := client.httpclient()!
	return http.delete(req)
}

// get_sortable_attributes retrieves sortable attributes of an index
pub fn (mut client MeilisearchClient) get_sortable_attributes(uid string) ![]string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/sortable-attributes'
	}
	mut http := client.httpclient()!
	response := http.get_json_dict(req)!
	return response['sortableAttributes']!.arr().map(it.str())
}

// update_sortable_attributes updates sortable attributes of an index
pub fn (mut client MeilisearchClient) update_sortable_attributes(uid string, attributes []string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/sortable-attributes'
		method: .put
		data:   json2.encode({
			'sortableAttributes': attributes
		})
	}
	mut http := client.httpclient()!
	return http.post_json_str(req)
}

// reset_sortable_attributes resets sortable attributes of an index
pub fn (mut client MeilisearchClient) reset_sortable_attributes(uid string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/sortable-attributes'
		method: .delete
	}
	mut http := client.httpclient()!
	return http.delete(req)
}

// get_typo_tolerance retrieves typo tolerance settings of an index
pub fn (mut client MeilisearchClient) get_typo_tolerance(uid string) !TypoTolerance {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/typo-tolerance'
	}

	mut http := client.httpclient()!
	response := http.get_json_dict(req)!
	min_word_size_for_typos := json2.decode[MinWordSizeForTypos](response['minWordSizeForTypos']!.json_str())!
	mut typo_tolerance := TypoTolerance{
		enabled:                 response['enabled']!.bool()
		min_word_size_for_typos: min_word_size_for_typos
	}

	if disable_on_words := response['disableOnWords'] {
		typo_tolerance.disable_on_words = disable_on_words.arr().map(it.str())
	}
	if disable_on_attributes := response['disableOnAttributes'] {
		typo_tolerance.disable_on_attributes = disable_on_attributes.arr().map(it.str())
	}

	return typo_tolerance
}

// update_typo_tolerance updates typo tolerance settings of an index
pub fn (mut client MeilisearchClient) update_typo_tolerance(uid string, typo_tolerance TypoTolerance) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/typo-tolerance'
		method: .patch
		data:   json2.encode(typo_tolerance)
	}
	mut http := client.httpclient()!
	return http.post_json_str(req)
}

// reset_typo_tolerance resets typo tolerance settings of an index
pub fn (mut client MeilisearchClient) reset_typo_tolerance(uid string) !string {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/settings/typo-tolerance'
		method: .delete
	}
	mut http := client.httpclient()!
	return http.delete(req)
}


@[params]
pub struct EperimentalFeaturesArgs{
pub mut:
	vector_store 				bool @[json: 'vectorStore']
	metrics 					bool @[json: 'metrics']
	logs_route 					bool @[json: 'logsRoute']
	contains_filter 			bool @[json: 'containsFilter']
	edit_documents_by_function 	bool @[json: 'editDocumentsByFunction']
}

pub fn (mut client MeilisearchClient) enable_eperimental_feature(args EperimentalFeaturesArgs) !EperimentalFeaturesArgs {
	req := httpconnection.Request{
		prefix: 'experimental-features'
		method: .patch,
		data: json.encode(args)
	}

	mut http := client.httpclient()!
	response := http.send(req)!
	return json.decode(EperimentalFeaturesArgs, response.data)
}