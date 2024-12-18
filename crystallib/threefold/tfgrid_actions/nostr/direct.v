module nostr

import freeflowuniverse.crystallib.core.playbook { Action }

fn (mut n NostrHandler) direct(action Action) ! {
	match action.name {
		'send' {
			// send direct message
			receiver := action.params.get('receiver')!
			content := action.params.get('content')!

			n.client.publish_direct_message(
				receiver: receiver
				content:  content
			)!
		}
		'read' {
			// reads and subscribes to direct messages
			mut id := action.params.get_default('subscription_id', '')!
			if id == '' {
				id = n.client.subscribe_to_direct_messages()!
				n.logger.info('subscription id: ${id}')
			}

			count := action.params.get_u32_default('count', 10)!

			events := n.client.get_subscription_events(id: id, count: count)!
			n.logger.info('Direct Message Events: ${events}')
		}
		else {
			return error('operation ${action.name} is not supported on nostr direct messages')
		}
	}
}
