module meilisearch

import rand
import time

struct MeiliDocument {
pub mut:
	id      int
	title   string
	content string
}

// Set up a test client instance
fn setup_client() !MeilisearchClient {
	config := ClientConfig{
		host:    'http://localhost:7700'
		api_key: 'be61fdce-c5d4-44bc-886b-3a484ff6c531'
	}
	factory := new_factory(config)
	mut client := factory.get()!
	return client
}

fn test_add_document() {
	mut client := setup_client()!
	index_name := rand.string(5)
	documents := [
		MeiliDocument{
			id:      1
			content: 'Shazam is a 2019 American superhero film based on the DC Comics character of the same name.'
			title:   'Shazam'
		},
	]

	mut doc := client.add_documents(index_name, documents)!
	assert doc.index_uid == index_name
	assert doc.type_ == 'documentAdditionOrUpdate'
}

fn test_get_document() {
	mut client := setup_client()!
	index_name := rand.string(5)

	documents := [
		MeiliDocument{
			id:      1
			title:   'Shazam'
			content: 'Shazam is a 2019 American superhero film based on the DC Comics character of the same name.'
		},
	]

	mut doc := client.add_documents(index_name, documents)!
	assert doc.index_uid == index_name
	assert doc.type_ == 'documentAdditionOrUpdate'

	time.sleep(500 * time.millisecond)

	doc_ := client.get_document[MeiliDocument](
		uid:         index_name
		document_id: 1
		fields:      ['id', 'title']
	)!

	assert doc_.title == 'Shazam'
	assert doc_.id == 1
}

fn test_get_documents() {
	mut client := setup_client()!
	index_name := rand.string(5)

	documents := [
		MeiliDocument{
			id:      1
			title:   'The Kit kat'
			content: 'The kit kat is an Egypton film that was released in 2019.'
		},
		MeiliDocument{
			id:      2
			title:   'Elli Bali Balak'
			content: 'Elli Bali Balak is an Egyptian film that was released in 2019.'
		},
	]

	q := DocumentsQuery{
		fields: ['title', 'id']
	}

	mut doc := client.add_documents(index_name, documents)!
	assert doc.index_uid == index_name
	assert doc.type_ == 'documentAdditionOrUpdate'

	time.sleep(500 * time.millisecond)

	mut docs := client.get_documents[MeiliDocument](index_name, q)!

	assert docs.len > 0
	assert docs[0].title == 'The Kit kat'
	assert docs[0].id == 1
	assert docs[1].title == 'Elli Bali Balak'
	assert docs[1].id == 2
}

fn test_delete_document() {
	mut client := setup_client()!
	index_name := rand.string(5)

	documents := [
		MeiliDocument{
			id:      1
			title:   'Shazam'
			content: 'Shazam is a 2019 American superhero film based on the DC Comics character of the same name.'
		},
	]

	mut doc := client.add_documents(index_name, documents)!
	assert doc.index_uid == index_name
	assert doc.type_ == 'documentAdditionOrUpdate'

	time.sleep(500 * time.millisecond)

	mut doc_ := client.delete_document(
		uid:         index_name
		document_id: 1
	)!

	assert doc_.index_uid == index_name
	assert doc_.type_ == 'documentDeletion'
}

fn test_delete_documents() {
	mut client := setup_client()!
	index_name := rand.string(5)

	documents := [
		MeiliDocument{
			id:      1
			title:   'Shazam'
			content: 'Shazam is a 2019 American superhero film based on the DC Comics character of the same name.'
		},
		MeiliDocument{
			id:      2
			title:   'Shazam2'
			content: 'Shazam2 is a 2019 American superhero film based on the DC Comics character of the same name.'
		},
	]

	mut doc := client.add_documents(index_name, documents)!
	assert doc.index_uid == index_name
	assert doc.type_ == 'documentAdditionOrUpdate'

	time.sleep(500 * time.millisecond)

	mut doc_ := client.delete_all_documents(index_name)!

	assert doc_.index_uid == index_name
	assert doc_.type_ == 'documentDeletion'

	time.sleep(500 * time.millisecond)

	q := DocumentsQuery{
		fields: ['title', 'id']
	}

	mut docs := client.get_documents[MeiliDocument](index_name, q)!

	assert docs.len == 0
}

fn test_search() {
	mut client := setup_client()!
	index_name := rand.string(5)

	documents := [
		MeiliDocument{
			id:      1
			title:   'Power of rich people'
			content: 'Power of rich people is an American film.'
		},
		MeiliDocument{
			id:      2
			title:   'Capten America'
			content: 'Capten America is an American film.'
		},
		MeiliDocument{
			id:      3
			title:   'Coldplay'
			content: 'Coldplay is a british rock band.'
		},
	]

	mut doc := client.add_documents(index_name, documents)!
	assert doc.index_uid == index_name
	assert doc.type_ == 'documentAdditionOrUpdate'

	time.sleep(500 * time.millisecond)

	mut doc_ := client.search[MeiliDocument](index_name, q: 'Coldplay')!

	assert doc_.hits[0].id == 3
}

// Delete all created indexes
fn test_delete_index() {
	mut client := setup_client()!
	mut index_list := client.list_indexes(limit: 100)!

	for index in index_list {
		client.delete_index(index.uid)!
		time.sleep(500 * time.millisecond)
	}

	index_list = client.list_indexes(limit: 100)!
	assert index_list.len == 0
}
