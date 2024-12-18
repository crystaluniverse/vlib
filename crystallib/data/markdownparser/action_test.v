module markdownparser

import freeflowuniverse.crystallib.data.paramsparser { Param, Params }
import freeflowuniverse.crystallib.data.markdownparser.elements { Action }
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console

fn test_action_empty_params() {
	mut docs := new(
		content: '
!!farmerbot_powermanager.poweroff
'
	)!
	// console.print_debug(docs.children)
	assert docs.children.len == 2
	action := docs.children[1]
	if action is Action {
		assert action.action.actor == 'farmerbot_powermanager'
		assert action.action.name == 'poweroff'
		assert action.action.params == Params{
			params: []
			args:   []
		}
	} else {
		assert false, 'element ${docs.children[0]} is not an action'
	}
}

fn test_action_some_params_multiline() {
	mut docs := new(
		content: '
!!farmerbot_nodemanager.define
	id:15
	twinid:20
	has_public_ip:yes
	has_public_config:1
'
	)!

	assert docs.children.len == 2
	action := docs.children[1]
	// assert action.children.len == 3
	if action is Action {
		assert action.action.actor == 'farmerbot_nodemanager'
		assert action.action.name == 'define'
		assert action.action.params == Params{
			params: [Param{
				key:   'twinid'
				value: '20'
			}, Param{
				key:   'has_public_ip'
				value: 'yes'
			}, Param{
				key:   'has_public_config'
				value: '1'
			}]
			args:   []
		}
	} else {
		assert false, 'element ${action} is not an action'
	}
}

fn test_action_some_params_inline() {
	mut docs := new(
		content: '
!!farmerbot_nodemanager.define id:15 twinid:20 has_public_ip:yes has_public_config:1
'
	)!

	assert docs.children.len == 2
	action := docs.children[1]
	if action is Action {
		assert action.action.actor == 'farmerbot_nodemanager'
		assert action.action.name == 'define'
		assert action.action.params == Params{
			params: [Param{
				key:   'twinid'
				value: '20'
			}, Param{
				key:   'has_public_ip'
				value: 'yes'
			}, Param{
				key:   'has_public_config'
				value: '1'
			}]
			args:   []
		}
	} else {
		assert false, 'element ${action} is not an action'
	}
}

fn test_action_some_params_some_arguments_multi_line() {
	mut docs := new(
		content: '
!!farmerbot_nodemanager.define
	id:15
	has_public_config
	has_public_ip:yes
	is_dedicated
'
	)!

	assert docs.children.len == 2
	action := docs.children[1]
	if action is Action {
		assert action.action.actor == 'farmerbot_nodemanager'
		assert action.action.name == 'define'
		assert action.action.params == Params{
			params: [Param{
				key:   'has_public_ip'
				value: 'yes'
			}]
			args:   ['has_public_config', 'is_dedicated']
		}
	} else {
		assert false, 'element ${action} is not an action'
	}
}

fn test_action_some_params_some_arguments_single_line() {
	mut docs := new(
		content: '
!!farmerbot_nodemanager.define id:15 has_public_config has_public_ip:yes is_dedicated
'
	)!

	assert docs.children.len == 2
	action := docs.children[1]
	if action is Action {
		assert action.action.actor == 'farmerbot_nodemanager'
		assert action.action.name == 'define'
		assert action.action.params == Params{
			params: [Param{
				key:   'has_public_ip'
				value: 'yes'
			}]
			args:   ['has_public_config', 'is_dedicated']
		}
	} else {
		assert false, 'element ${action} is not an action'
	}
}

fn test_action() {
	mut c := '
	# header

	some text

	!!farmerbot.nodemanager_define
		id:15
		twinid:20
		has_public_ip:yes
		has_public_config:1

	a line

	```
	//in codeblock
	!!farmerbot.nodemanager_delete
		id:16	
	```

	another line

	```js
	!!farmerbot.nodemanager_start id:17
	```
	

	'
	c = texttools.dedent(c)

	mut doc := new(content: c)!
	assert doc.actions().len == 3
	actions := doc.actions()
	assert actions[0].actor == 'farmerbot'
	assert actions[0].name == 'nodemanager_define'

	assert actions[1].actor == 'farmerbot'
	assert actions[1].name == 'nodemanager_delete'

	assert actions[2].actor == 'farmerbot'
	assert actions[2].name == 'nodemanager_start'
}
