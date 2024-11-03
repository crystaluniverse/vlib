module meilisearch

import freeflowuniverse.crystallib.clients.httpconnection
import x.json2

// add_documents adds documents to an index
pub fn (mut client MeiliClient) add_documents(uid string, documents string) !TaskInfo {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/documents'
		method: .post
		data: documents
	}

	response := client.http.post_json_str(req)!
	return json2.decode[TaskInfo](response)!
}

// add_documents_in_batches adds documents to an index in batches
pub fn (mut client MeiliClient) add_documents_in_batches(uid string, documents string, batch_size int) !TaskInfo {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/documents'
		method: .post
		data: documents
		params: {
			'batchSize': batch_size.str()
		}
	}

	response := client.http.post_json_str(req)!
	return json2.decode[TaskInfo](response)!
}

// get_document retrieves one document by its id
pub fn (mut client MeiliClient) get_document(uid string, document_id string, fields []string) !string {
	mut params := map[string]string{}
	if fields.len > 0 {
		params['fields'] = fields.join(',')
	}

	req := httpconnection.Request{
		prefix: 'indexes/${uid}/documents/${document_id}'
		params: params
	}
	return client.http.get_json(req)
}

// get_documents retrieves documents with optional parameters
pub fn (mut client MeiliClient) get_documents(uid string, query DocumentsQuery) !string {
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
	return client.http.get_json(req)
}

// delete_document deletes one document by its id
pub fn (mut client MeiliClient) delete_document(uid string, document_id string) !TaskInfo {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/documents/${document_id}'
		method: .delete
	}

	response := client.http.post_json_str(req)!
	return json2.decode[TaskInfo](response)!
}

// delete_documents deletes multiple documents by their ids
pub fn (mut client MeiliClient) delete_documents(uid string, document_ids []string) !TaskInfo {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/documents/delete-batch'
		method: .post
		data: json2.encode(document_ids)
	}

	response := client.http.post_json_str(req)!
	return json2.decode[TaskInfo](response)!
}

// delete_all_documents deletes all documents in an index
pub fn (mut client MeiliClient) delete_all_documents(uid string) !TaskInfo {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/documents'
		method: .delete
	}

	response := client.http.post_json_str(req)!
	return json2.decode[TaskInfo](response)!
}

// update_documents updates documents in an index
pub fn (mut client MeiliClient) update_documents(uid string, documents string) !TaskInfo {
	req := httpconnection.Request{
		prefix: 'indexes/${uid}/documents'
		method: .put
		data: documents
	}

	response := client.http.post_json_str(req)!
	return json2.decode[TaskInfo](response)!
}

// search performs a search query on an index
pub fn (mut client MeiliClient) search(uid string, query string, options map[string]string) !string {
	mut params := {
		'q': query
	}
	// Add any additional search parameters
	for key, value in options {
		params[key] = value
	}

	req := httpconnection.Request{
		prefix: 'indexes/${uid}/search'
		method: .post
		data: json2.encode(params)
	}
	return client.http.post_json_str(req)
}
