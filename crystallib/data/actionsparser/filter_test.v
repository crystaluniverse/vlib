module actionsparser

const text2 = "
//select the circle, can come from context as has been set before
//now every person added will be added in this circle
!!select_actor people
!!select_circle aaa

//delete everything as found in current circle
!!person_delete cid:1g

!!person_define
  //is optional will be filled in automatically, but maybe we want to update
  cid: '1gt' 
  //name as selected in this group, can be used to find someone back
  name: fatayera
	firstname: 'Adnan'
	lastname: 'Fatayerji'
	description: 'Head of Business Development'
  email: 'adnan@threefold.io,fatayera@threefold.io'

!!circle_link
//can define as cid or as name, name needs to be in same circle
  person: '1gt'
  //can define as cid or as name
  circle:tftech         
  role:'stakeholder'
	description:''
  //is the name as given to the link
	name:'vpsales'        

!!people.circle_comment cid:'1g' 
    comment:
      this is a comment
      can be multiline 

!!circle_comment cid:'1g' 
    comment:
      another comment

!!digital_payment_add 
  person:fatayera
	name: 'TF Wallet'
	blockchain: 'stellar'
	account: ''
	description: 'TF Wallet for TFT' 
	preferred: false

!!select_actor test

!!test_action
	key: value

!!select_circle bbb
!!select_actor people

!!person_define
  cid: 'eg'
  name: despiegk

"

// QUESTION: how to better organize these tests
// ANSWER: split them up, this test is testing too much, tests should be easy to read and easy to modify

fn test_filter_on_circle_aaa() ! {
	// test filter circle:aaa
	mut actions := new(default_cid_int: 1, text: actionsparser.text2)!
	assert actions.items.len == 8
	sorted := actions.filtersort(circle: 'aaa')!
	assert sorted.len == 7
}

fn test_filter_on_actor_people_and_circle_aaa() ! {
	// test filter circle:aaa actor:people
	mut actions := new(default_cid_int: 1, text: actionsparser.text2)!
	assert actions.items.len == 8
	sorted := actions.filtersort(actor: 'people', circle: 'aaa')! // QUESTION: can you leave actor blank? ANSWER: Yes you can, I added a test on top
	assert sorted.len == 6
}

fn test_filter_on_actor_people_and_circle_bbb() ! {
	// test filter actor:people
	mut actions := new(default_cid_int: 1, text: actionsparser.text2)!
	assert actions.items.len == 8
	sorted := actions.filtersort(actor: 'people', circle: 'bbb')!
	assert sorted.len == 1
}

fn test_filter_on_actor_people_and_circle_ccc() ! {
	// test filter circle:ccc actor:people
	mut actions := new(default_cid_int: 1, text: actionsparser.text2)!
	assert actions.items.len == 8
	sorted := actions.filtersort(actor: 'people', circle: 'ccc')!
	assert sorted.len == 0
}

// test filter circle:aaa actor:test
fn test_filter_on_actor_test_and_circle_aaa() ! {
	mut actions := new(default_cid_int: 1, text: actionsparser.text2)!
	assert actions.items.len == 8
	sorted := actions.filtersort(actor: 'test', circle: 'aaa')!
	assert sorted.len == 1
}

// test filter with names:[*]
fn test_filter_with_names_asterix() ! {
	mut actions := new(default_cid_int: 1, text: actionsparser.text2)!
	assert actions.items.len == 8
	assert actions.items.map(it.name) == ['person_delete', 'person_define', 'circle_link',
		'circle_comment', 'circle_comment', 'digital_payment_add', 'test_action', 'person_define']

	sorted := actions.filtersort(actor: 'people', circle: 'aaa', names_filter: ['*'])!
	assert sorted.len == 6
	assert sorted.map(it.name) == ['person_delete', 'person_define', 'circle_link', 'circle_comment',
		'circle_comment', 'digital_payment_add']
}

// test filtering with names_filter with one empty string
fn test_filter_with_names_list_with_empty_string() ! {
	// QUESTION: should this return empty list?
	// ANSWER: I think yes as you technically want the actions where the name is an empty string
	mut actions := new(
		default_cid_int: 1
		text: actionsparser.text2
	)!

	assert actions.items.map(it.name) == ['person_delete', 'person_define', 'circle_link',
		'circle_comment', 'circle_comment', 'digital_payment_add', 'test_action', 'person_define']

	sorted := actions.filtersort(actor: 'people', circle: 'aaa', names_filter: [''])!
	assert sorted.len == 0
	assert sorted.map(it.name) == []
}

// test filter with names in same order as actions
fn test_filter_with_names_in_same_order() ! {
	mut actions := new(
		default_cid_int: 1
		text: actionsparser.text2
	)!

	sorted := actions.filtersort(
		actor: 'people'
		circle: 'aaa'
		names_filter: [
			'person_delete',
			'person_define',
			'circle_link',
			'circle_comment',
			'digital_payment_add',
		]
	)!
	assert sorted.len == 6
	assert sorted.map(it.name) == ['person_delete', 'person_define', 'circle_link', 'circle_comment',
		'circle_comment', 'digital_payment_add']
}

// test filter with names in different order than actions
fn test_filter_with_names_in_different_order() ! {
	mut actions := new(
		default_cid_int: 1
		text: actionsparser.text2
	)!

	sorted := actions.filtersort(
		actor: 'people'
		circle: 'aaa'
		names_filter: [
			'circle_comment',
			'person_define',
			'digital_payment_add',
			'person_delete',
			'circle_link',
		]
	)!
	assert sorted.len == 6
	assert sorted.map(it.name) == ['circle_comment', 'circle_comment', 'person_define',
		'digital_payment_add', 'person_delete', 'circle_link']
}

// test filter with only two names in filter
fn test_filter_with_only_two_names_in_filter() ! {
	// QUESTION: if we only have one name, is it just that action?
	// ANSWER: yes
	mut actions := new(
		default_cid_int: 1
		text: actionsparser.text2
	)!

	sorted := actions.filtersort(
		actor: 'people'
		circle: 'aaa'
		names_filter: [
			'person_define',
			'person_delete',
		]
	)!
	assert sorted.len == 2
	assert sorted.map(it.name) == ['person_define', 'person_delete']
}
