module meilisearch

import freeflowuniverse.crystallib.clients.httpconnection { HTTPConnection, Request }
import x.json2

// health checks if the server is healthy
pub fn (mut client MeiliClient) health() !Health {
	req := Request{
		prefix: 'health'
	}
	response := client.http.get_json_dict(req)!
	
	return Health{
		status: response['status'].str()
	}
}

// version gets the version of the Meilisearch server
pub fn (mut client MeiliClient) version() !Version {
	req := Request{
		prefix: 'version'
	}
	response := client.http.get_json_dict(req)!
	
	return Version{
		pkg_version: response['pkgVersion'].str()
		commit_sha: response['commitSha'].str()
		build_date: response['buildDate'].str()
	}
}

// create_index creates a new index with the given UID
pub fn (mut client MeiliClient) create_index(uid string) !string {
	req := Request{
		prefix: 'indexes'
		method: .post
		data: json2.encode({
			'uid': uid
		})
	}
	return client.http.post_json_str(req)
}

// get_index retrieves information about an index
pub fn (mut client MeiliClient) get_index(uid string) !string {
	req := Request{
		prefix: 'indexes/${uid}'
	}
	return client.http.get_json(req)
}

// list_indexes retrieves all indexes
pub fn (mut client MeiliClient) list_indexes() !string {
	req := Request{
		prefix: 'indexes'
	}
	return client.http.get_json(req)
}

// delete_index deletes an index
pub fn (mut client MeiliClient) delete_index(uid string) !string {
	req := Request{
		prefix: 'indexes/${uid}'
	}
	return client.http.delete(req)
}

// get_settings retrieves all settings of an index
pub fn (mut client MeiliClient) get_settings(uid string) !IndexSettings {
	req := Request{
		prefix: 'indexes/${uid}/settings'
	}
	response := client.http.get_json_dict(req)!
	
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
pub fn (mut client MeiliClient) update_settings(uid string, settings IndexSettings) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings'
		method: .patch
		data: json2.encode({
			'rankingRules': settings.ranking_rules
			'distinctAttribute': settings.distinct_attribute
			'searchableAttributes': settings.searchable_attributes
			'displayedAttributes': settings.displayed_attributes
			'stopWords': settings.stop_words
			'synonyms': settings.synonyms
			'filterableAttributes': settings.filterable_attributes
			'sortableAttributes': settings.sortable_attributes
			'typoTolerance': {
				'enabled': settings.typo_tolerance.enabled
				'minWordSizeForTypos': {
					'oneTypo': settings.typo_tolerance.min_word_size_for_typos.one_typo
					'twoTypos': settings.typo_tolerance.min_word_size_for_typos.two_typos
				}
				'disableOnWords': settings.typo_tolerance.disable_on_words
				'disableOnAttributes': settings.typo_tolerance.disable_on_attributes
			}
		})
	}
	return client.http.post_json_str(req)
}

// reset_settings resets all settings of an index to default values
pub fn (mut client MeiliClient) reset_settings(uid string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings'
		method: .delete
	}
	return client.http.delete(req)
}

// get_ranking_rules retrieves ranking rules of an index
pub fn (mut client MeiliClient) get_ranking_rules(uid string) ![]string {
	req := Request{
		prefix: 'indexes/${uid}/settings/ranking-rules'
	}
	response := client.http.get_json_dict(req)!
	return response['rankingRules'].arr().map(it.str())
}

// update_ranking_rules updates ranking rules of an index
pub fn (mut client MeiliClient) update_ranking_rules(uid string, rules []string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/ranking-rules'
		method: .put
		data: json2.encode({
			'rankingRules': rules
		})
	}
	return client.http.post_json_str(req)
}

// reset_ranking_rules resets ranking rules of an index to default values
pub fn (mut client MeiliClient) reset_ranking_rules(uid string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/ranking-rules'
		method: .delete
	}
	return client.http.delete(req)
}

// get_distinct_attribute retrieves distinct attribute of an index
pub fn (mut client MeiliClient) get_distinct_attribute(uid string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/distinct-attribute'
	}
	response := client.http.get_json_dict(req)!
	return response['distinctAttribute'].str()
}

// update_distinct_attribute updates distinct attribute of an index
pub fn (mut client MeiliClient) update_distinct_attribute(uid string, attribute string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/distinct-attribute'
		method: .put
		data: json2.encode({
			'distinctAttribute': attribute
		})
	}
	return client.http.post_json_str(req)
}

// reset_distinct_attribute resets distinct attribute of an index
pub fn (mut client MeiliClient) reset_distinct_attribute(uid string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/distinct-attribute'
		method: .delete
	}
	return client.http.delete(req)
}

// get_searchable_attributes retrieves searchable attributes of an index
pub fn (mut client MeiliClient) get_searchable_attributes(uid string) ![]string {
	req := Request{
		prefix: 'indexes/${uid}/settings/searchable-attributes'
	}
	response := client.http.get_json_dict(req)!
	return response['searchableAttributes'].arr().map(it.str())
}

// update_searchable_attributes updates searchable attributes of an index
pub fn (mut client MeiliClient) update_searchable_attributes(uid string, attributes []string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/searchable-attributes'
		method: .put
		data: json2.encode({
			'searchableAttributes': attributes
		})
	}
	return client.http.post_json_str(req)
}

// reset_searchable_attributes resets searchable attributes of an index
pub fn (mut client MeiliClient) reset_searchable_attributes(uid string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/searchable-attributes'
		method: .delete
	}
	return client.http.delete(req)
}

// get_displayed_attributes retrieves displayed attributes of an index
pub fn (mut client MeiliClient) get_displayed_attributes(uid string) ![]string {
	req := Request{
		prefix: 'indexes/${uid}/settings/displayed-attributes'
	}
	response := client.http.get_json_dict(req)!
	return response['displayedAttributes'].arr().map(it.str())
}

// update_displayed_attributes updates displayed attributes of an index
pub fn (mut client MeiliClient) update_displayed_attributes(uid string, attributes []string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/displayed-attributes'
		method: .put
		data: json2.encode({
			'displayedAttributes': attributes
		})
	}
	return client.http.post_json_str(req)
}

// reset_displayed_attributes resets displayed attributes of an index
pub fn (mut client MeiliClient) reset_displayed_attributes(uid string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/displayed-attributes'
		method: .delete
	}
	return client.http.delete(req)
}

// get_stop_words retrieves stop words of an index
pub fn (mut client MeiliClient) get_stop_words(uid string) ![]string {
	req := Request{
		prefix: 'indexes/${uid}/settings/stop-words'
	}
	response := client.http.get_json_dict(req)!
	return response['stopWords'].arr().map(it.str())
}

// update_stop_words updates stop words of an index
pub fn (mut client MeiliClient) update_stop_words(uid string, words []string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/stop-words'
		method: .put
		data: json2.encode({
			'stopWords': words
		})
	}
	return client.http.post_json_str(req)
}

// reset_stop_words resets stop words of an index
pub fn (mut client MeiliClient) reset_stop_words(uid string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/stop-words'
		method: .delete
	}
	return client.http.delete(req)
}

// get_synonyms retrieves synonyms of an index
pub fn (mut client MeiliClient) get_synonyms(uid string) !map[string][]string {
	req := Request{
		prefix: 'indexes/${uid}/settings/synonyms'
	}
	response := client.http.get_json_dict(req)!
	mut synonyms := map[string][]string{}
	for key, value in response['synonyms'].as_map() {
		synonyms[key] = value.arr().map(it.str())
	}
	return synonyms
}

// update_synonyms updates synonyms of an index
pub fn (mut client MeiliClient) update_synonyms(uid string, synonyms map[string][]string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/synonyms'
		method: .put
		data: json2.encode({
			'synonyms': synonyms
		})
	}
	return client.http.post_json_str(req)
}

// reset_synonyms resets synonyms of an index
pub fn (mut client MeiliClient) reset_synonyms(uid string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/synonyms'
		method: .delete
	}
	return client.http.delete(req)
}

// get_filterable_attributes retrieves filterable attributes of an index
pub fn (mut client MeiliClient) get_filterable_attributes(uid string) ![]string {
	req := Request{
		prefix: 'indexes/${uid}/settings/filterable-attributes'
	}
	response := client.http.get_json_dict(req)!
	return response['filterableAttributes'].arr().map(it.str())
}

// update_filterable_attributes updates filterable attributes of an index
pub fn (mut client MeiliClient) update_filterable_attributes(uid string, attributes []string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/filterable-attributes'
		method: .put
		data: json2.encode({
			'filterableAttributes': attributes
		})
	}
	return client.http.post_json_str(req)
}

// reset_filterable_attributes resets filterable attributes of an index
pub fn (mut client MeiliClient) reset_filterable_attributes(uid string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/filterable-attributes'
		method: .delete
	}
	return client.http.delete(req)
}

// get_sortable_attributes retrieves sortable attributes of an index
pub fn (mut client MeiliClient) get_sortable_attributes(uid string) ![]string {
	req := Request{
		prefix: 'indexes/${uid}/settings/sortable-attributes'
	}
	response := client.http.get_json_dict(req)!
	return response['sortableAttributes'].arr().map(it.str())
}

// update_sortable_attributes updates sortable attributes of an index
pub fn (mut client MeiliClient) update_sortable_attributes(uid string, attributes []string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/sortable-attributes'
		method: .put
		data: json2.encode({
			'sortableAttributes': attributes
		})
	}
	return client.http.post_json_str(req)
}

// reset_sortable_attributes resets sortable attributes of an index
pub fn (mut client MeiliClient) reset_sortable_attributes(uid string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/sortable-attributes'
		method: .delete
	}
	return client.http.delete(req)
}

// get_typo_tolerance retrieves typo tolerance settings of an index
pub fn (mut client MeiliClient) get_typo_tolerance(uid string) !TypoTolerance {
	req := Request{
		prefix: 'indexes/${uid}/settings/typo-tolerance'
	}
	response := client.http.get_json_dict(req)!
	
	mut typo_tolerance := TypoTolerance{
		enabled: response['enabled'].bool()
		min_word_size_for_typos: MinWordSizeForTypos{
			one_typo: response['minWordSizeForTypos']['oneTypo'].int()
			two_typos: response['minWordSizeForTypos']['twoTypos'].int()
		}
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
pub fn (mut client MeiliClient) update_typo_tolerance(uid string, typo_tolerance TypoTolerance) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/typo-tolerance'
		method: .patch
		data: json2.encode({
			'enabled': typo_tolerance.enabled
			'minWordSizeForTypos': {
				'oneTypo': typo_tolerance.min_word_size_for_typos.one_typo
				'twoTypos': typo_tolerance.min_word_size_for_typos.two_typos
			}
			'disableOnWords': typo_tolerance.disable_on_words
			'disableOnAttributes': typo_tolerance.disable_on_attributes
		})
	}
	return client.http.post_json_str(req)
}

// reset_typo_tolerance resets typo tolerance settings of an index
pub fn (mut client MeiliClient) reset_typo_tolerance(uid string) !string {
	req := Request{
		prefix: 'indexes/${uid}/settings/typo-tolerance'
		method: .delete
	}
	return client.http.delete(req)
}
