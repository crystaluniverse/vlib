module playbook

const text3 = "
//select the circle, can come from context as has been set before
//
//now every person added will be added in this circle
//
!!select_actor people
!!select_circle aaa

//delete everything as found in current circle
!!person.delete cid:1g

!!person.define
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
    comment:'
      this is a comment
      can be multiline 
	  '

!!circle.comment cid:'1g' 
    comment:
      another comment

!!digital_payment.add 
	person:fatayera
	name: 'TF Wallet'
	blockchain: 'stellar'
	account: ''
	description: 'TF Wallet for TFT' 
	preferred: false

!!test.myaction
	key: value

!!person.define
  cid: 'eg'
  name: despiegk //this is a remark

"

// test filter with only two names in filter
fn test_filter1() ! {
	mut plbook := new(
		text: text3
	)!

	assert plbook.actions.len == 10

	assert plbook.hashkey() == '6936aafcd18b2d839e6b5c5f20b8817243c237da'

	plbook.filtersort(
		priorities: {
			2: 'digital_payment:*'
		}
	)!
	assert plbook.priorities[2].len == 1

	mut asorted := plbook.actions_sorted()!

	assert asorted.map('${it.actor}:${it.name}') == ['digital_payment:add', 'core:select_actor',
		'core:select_circle', 'person:delete', 'person:define', 'core:circle_link',
		'people:circle_comment', 'circle:comment', 'test:myaction', 'person:define']
}
