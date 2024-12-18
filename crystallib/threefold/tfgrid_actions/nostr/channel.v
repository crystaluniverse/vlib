module nostr

import freeflowuniverse.crystallib.core.playbook { Action }

fn (mut n NostrHandler) channel(action Action) ! {
	match action.name {
		'create' {
			// create a new channel
			name := action.params.get('name')!
			about := action.params.get_default('description', '')!
			pic_url := action.params.get_default('picture', '')!

			channel_id := n.client.create_channel(name: name, about: about, picture: pic_url)!
			n.logger.info('Channel ID ${channel_id}')
		}
		'send' {
			// send message to channel
			channel_id := action.params.get('channel')!
			content := action.params.get('content')!
			message_id := action.params.get_default('reply_to', '')!
			public_key := action.params.get_default('public_key_author', '')!

			n.client.create_channel_message(
				channel_id: channel_id
				content:    content
				message_id: message_id
				public_key: public_key
			)!
		}
		'read_sub' {
			// read subscription messages
			channel_id := action.params.get('channel')!
			mut id := action.params.get_default('id', '')!
			if id == '' {
				id = n.client.subscribe_channel_message(id: channel_id)!
				n.logger.info('Subscription ID: ${id}')
			}
			count := action.params.get_u32_default('count', 10)!

			messages := n.client.get_subscription_events(id: id, count: count)!
			n.logger.info('Channel Messages: ${messages}')
		}
		'read' {
			// read all channel messages
			channel_id := action.params.get('channel')!

			messages := n.client.get_channel_message(channel_id: channel_id)!
			n.logger.info('Channel Messages: ${messages}')
		}
		'list' {
			// list all channels on relay
			channels := n.client.list_channels()!
			n.logger.info('Channels: ${channels}')
		}
		else {
			return error('operation ${action.name} is not supported on nostr groups')
		}
	}
}
