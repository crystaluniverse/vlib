module meilisearch

import x.json2

// add_documents adds documents to an index
pub fn (mut client MeiliClient) add_documents(uid string, documents string) !TaskInfo {
	req := Request{
		prefix: 'indexes/${uid}/documents'
		method: .post
		data: documents
	}
	response := client.http.post_json_dict(req)!
	return parse_task_info(response)
}

// add_documents_in_batches adds documents to an index in batches
pub fn (mut client MeiliClient) add_documents_in_batches(uid string, documents string, batch_size int) !TaskInfo {
	req := Request{
		prefix: 'indexes/${uid}/documents'
		method: .post
		data: documents
		params: {
			'batchSize': batch_size.str()
		}
	}
	response := client.http.post_json_dict(req)!
	return parse_task_info(response)
}

// get_document retrieves one document by its id
pub fn (mut client MeiliClient) get_document(uid string, document_id string, fields []string) !string {
	mut params := map[string]string{}
	if fields.len > 0 {
		params['fields'] = fields.join(',')
	}

	req := Request{
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

	req := Request{
		prefix: 'indexes/${uid}/documents'
		params: params
	}
	return client.http.get_json(req)
}

// delete_document deletes one document by its id
pub fn (mut client MeiliClient) delete_document(uid string, document_id string) !TaskInfo {
	req := Request{
		prefix: 'indexes/${uid}/documents/${document_id}'
		method: .delete
	}
	response := client.http.delete_json_dict(req)!
	return parse_task_info(response)
}

// delete_documents deletes multiple documents by their ids
pub fn (mut client MeiliClient) delete_documents(uid string, document_ids []string) !TaskInfo {
	req := Request{
		prefix: 'indexes/${uid}/documents/delete-batch'
		method: .post
		data: json2.encode(document_ids)
	}
	response := client.http.post_json_dict(req)!
	return parse_task_info(response)
}

// delete_all_documents deletes all documents in an index
pub fn (mut client MeiliClient) delete_all_documents(uid string) !TaskInfo {
	req := Request{
		prefix: 'indexes/${uid}/documents'
		method: .delete
	}
	response := client.http.delete_json_dict(req)!
	return parse_task_info(response)
}

// update_documents updates documents in an index
pub fn (mut client MeiliClient) update_documents(uid string, documents string) !TaskInfo {
	req := Request{
		prefix: 'indexes/${uid}/documents'
		method: .put
		data: documents
	}
	response := client.http.put_json_dict(req)!
	return parse_task_info(response)
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

	req := Request{
		prefix: 'indexes/${uid}/search'
		method: .post
		data: json2.encode(params)
	}
	return client.http.post_json_str(req)
}

// Helper function to parse TaskInfo from response
fn parse_task_info(response map[string]json2.Any) TaskInfo {
	return TaskInfo{
		uid: response['taskUid'].int()
		index_uid: response['indexUid'].str()
		status: response['status'].str()
		task_type: response['type'].str()
		details: response['details'].as_map().map(it.str())
		error: if 'error' in response { response['error'].str() } else { '' }
		duration: if 'duration' in response { response['duration'].str() } else { '' }
		enqueued_at: response['enqueuedAt'].str()
		started_at: if 'startedAt' in response { response['startedAt'].str() } else { '' }
		finished_at: if 'finishedAt' in response { response['finishedAt'].str() } else { '' }
	}
}
