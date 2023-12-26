module markdownparser

import freeflowuniverse.crystallib.data.paramsparser { Param, Params }
import freeflowuniverse.crystallib.data.markdownparser.elements { Action, Codeblock, Header, Link, Paragraph, Table, Text }

const text = "
# Farmerbot

Welcome to the farmerbot. The farmerbot is a service that a farmer can run allowing him to automatically manage the nodes of his farm.

The key feature of the farmerbot is powermanagement. The farmerbot will automatically shutdown nodes from its farm whenever possible and bring them back on when they are needed using Wake-on-Lan (WOL). It will try to maximize downtime as much as possible by recommending which nodes to use, this is one of the requests that the farmerbot can handle (asking for a node to deploy on).

The behavior of the farmerbot is customizable through markup definition files. You can find an example [here](example_data/nodes.md).

## Under the hood

The farmerbot has been implemented using the actor model principles. It contains two actors that are able to execute jobs (actions that need to be executed by a specific actor).

The first actor is the nodemanager which is in charge of executing jobs related to nodes (e.g. finding a suitable node). The second actor is the powermanager which allows us to power on and off nodes in the farm.

Actors can schedule the execution of jobs for other actors which might or might not be running on the same system. For example, the nodemanager might schedule the execution of a job to power on a node (which is meant for the powermanager). The repository [baobab](https://github.com/freeflowuniverse/baobab) contains the logic for scheduling jobs.

Jobs don't have to originate from the system running the farmerbot. It may as well be scheduled from another system (with another twin id). The job to find a suitable node for example will come from the TSClient (which is located on another system). These jobs will be send from the TSClient to the farmerbot via [RMB](https://github.com/threefoldtech/rmb-rs).

## Configuration

As mentioned before the farmerbot can be configured through markup definition files. This section will guide you through the possibilities.

| nodeid | twinid | configured |
|----|---|-----|
| 51 | 2 | nope|
| 52 | 3 | yes |
| 53 | 4 | nope |
| 54 | 5 | yes |

### Nodes

The farmerbot requires you to setup the nodes that the farmerbot should handle.
Required attributes:
- id
- twinid

Optional attributes:
- cpuoverprovision => a value between 1 and 4 defining how much the cpu can be overprovisioned (2 means double the amount of cpus)
- public_config => true or false telling the farmerbot whether or not the node has a public config
- dedicated => true or false telling the farmerbot whether or not the node is dedicated (only allow renting the full node)
- certified => true or false telling the farmerbot whether or not the node is certified

Example:

!!farmerbot.nodemanager_define
	certified:yes
	cpuoverprovision:1
	dedicated:1
	id:
	public_config:true
	twinid:105
"

fn test_wiki_headers_paragraphs() {
	content := '
	
# TMUX

tmux library provides functions for managing local / remote tmux sessions

## Getting started

To initialize tmux on a local or [remote node](mysite:page.md), simply build the [node](defs:node.md), install tmux, and run start

- test1
- test 2
    - yes
    - no

### something else
'
	mut docs := new(content: content)!
	assert docs.children.len == 5
	assert docs.children[0] is Header
	paragraph1 := docs.children[1]
	if paragraph1 is Paragraph {
		assert paragraph1.children.len == 1
		assert paragraph1.children[0] is Text
	} else {
		assert false, 'element ${docs.children[1]} is not a paragraph'
	}

	assert docs.children[2] is Header
	paragraph2 := docs.children[3]
	if paragraph2 is Paragraph {
		assert paragraph2.children.len == 5
		assert paragraph2.children[0] is Text
		assert paragraph2.children[1] is Link
		assert paragraph2.children[2] is Text
		assert paragraph2.children[3] is Link
		assert paragraph2.children[4] is Text
	} else {
		assert false, 'element ${docs.children[3]} is not a paragraph'
	}

	assert docs.children[4] is Header

	// assert docs.markdown().trim_space() == content.trim_space()
}

fn test_wiki_headers_and_table() {
	content := '

# TMUX

tmux library provides functions for managing local / remote tmux sessions

## Getting started

| nodeid | twinid | configured |
| :-- | :-: | --: |
| 51 | 2 | nope |
| 52 | 3 | yes |

some extra text

'
	mut docs := new(content: content)!

	assert docs.children.len == 5
	assert docs.children[0] is Header
	paragraph1 := docs.children[1]
	if paragraph1 is Paragraph {
		assert paragraph1.children.len == 1
		assert paragraph1.children[0] is Text
	}

	assert docs.children[2] is Header
	assert docs.children[3] is Table
	table1 := docs.children[3]
	if table1 is Table {
		assert table1.num_columns == 3
		assert table1.header.len == 3
		assert table1.alignments.len == 3
		assert table1.rows.len == 2
		for row in table1.rows {
			assert row.cells.len == 3
		}
	}

	assert docs.children[4] is Paragraph
	paragraph2 := docs.children[4]
	if paragraph2 is Paragraph {
		assert paragraph2.children.len == 1
		assert paragraph2.children[0] is Text
	}

	// assert content.trim_space() == docs.markdown().trim_space()
}

fn test_wiki_action() {
	content := '
# This is an action

!!farmerbot.nodemanager_define
	has_public_config:1
	has_public_ip:yes
	id:15
	twinid:20
'
	mut docs := new(content: content)!

	assert docs.children.len == 2
	assert docs.children[0] is Header
	assert docs.children[1] is Action

	action := docs.children[1]
	if action is Action {
		assert action.action.actor == 'farmerbot'
		assert action.action.name == 'nodemanager_define'
		assert action.action.params == Params{
			params: [Param{
				key: 'has_public_config'
				value: '1'
			}, Param{
				key: 'has_public_ip'
				value: 'yes'
			}, Param{
				key: 'id'
				value: '15'
			}, Param{
				key: 'twinid'
				value: '20'
			}]
			args: []
		}
	}
	// assert content.trim_space() == docs.markdown().trim_space()
}

fn test_wiki_code() {
	content := '
# This is some code

```v
for x in list {
	println(x)
}
```

# This is an action in a piece of code

```
!!farmerbot.nodemanager_define
	id:15
	twinid:20
	has_public_ip:yes
	has_public_config:1
```

# This is some header
'
	mut docs := new(content: content)!

	assert docs.children.len == 5
	assert docs.children[0] is Header
	assert docs.children[1] is Codeblock
	codeblock1 := docs.children[1]
	if codeblock1 is Codeblock {
		assert codeblock1.category == 'v'
	}

	assert docs.children[2] is Header
	assert docs.children[3] is Codeblock
	assert docs.children[4] is Header
	// assert content.trim_space() == docs.markdown().trim_space()
}

fn test_wiki_links() {
	content := '
# this is a test

- [this is link](something.md)
- ![this is link2](something.jpg)

## ts

![this is link2](something.jpg)
'
	mut docs := new(content: content)!

	assert docs.children.len == 4
	assert docs.children[0] is Header
	assert docs.children[1] is Paragraph

	paragraph1 := docs.children[1]
	if paragraph1 is Paragraph {
		assert paragraph1.children.len == 4
		assert paragraph1.children[0] is Text
		assert paragraph1.children[1] is Link
		assert paragraph1.children[2] is Text
		assert paragraph1.children[3] is Link
	}

	assert docs.children[2] is Header
	assert docs.children[3] is Paragraph

	paragraph2 := docs.children[3]
	if paragraph2 is Paragraph {
		assert paragraph2.children.len == 1
		assert paragraph2.children[0] is Link
	}
	// assert content.trim_space() == docs.markdown().trim_space()
}

fn test_wiki_header_too_long() {
	content := '
##### Is ok

###### Should not be ok
'
	mut docs := new(content: content)!

	expected_wiki := '
##### Is ok
'

	assert docs.children.len == 1
	assert docs.children[0] is Header
	// assert expected_wiki.trim_space() == docs.markdown().trim_space()
}

fn test_wiki_all_together() {
	content := markdownparser.text
	mut docs := new(content: content)!
	assert docs.children.len == 10
	assert docs.children[0] is Header
	assert docs.children[1] is Paragraph
	assert docs.children[2] is Header
	assert docs.children[3] is Paragraph
	assert docs.children[4] is Header
	assert docs.children[5] is Paragraph
	assert docs.children[6] is Table
	assert docs.children[7] is Header
	assert docs.children[8] is Paragraph
	assert docs.children[9] is Action
	// assert content.trim_space() == docs.markdown().trim_space()
}

fn test_deterministic_output() {
	mut doc1 := new(
		content: markdownparser.text
	)!
	content1 := doc1.markdown()

	mut doc2 := new(content: content1)!
	content2 := doc2.markdown()

	assert content1 == content2
}