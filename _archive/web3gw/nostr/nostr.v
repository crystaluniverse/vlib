module nostr

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }

const default_timeout = 500000

@[openrpc: exclude]
@[noinit]
pub struct NostrClient {
mut:
	client &RpcWsClient
}

@[openrpc: exclude]
pub fn new(mut client RpcWsClient) NostrClient {
	return NostrClient{
		client: &client
	}
}

// load the nostr client with a secret
pub fn (mut n NostrClient) load(secret string) ! {
	_ := n.client.send_json_rpc[[]string, string]('nostr.Load', [secret], default_timeout)!
}

// connect to a relay given a url
pub fn (mut n NostrClient) connect_to_relay(relay_url string) ! {
	_ := n.client.send_json_rpc[[]string, string]('nostr.ConnectRelay', [relay_url], default_timeout)!
}

// connect to the authenticated relay
pub fn (mut n NostrClient) connect_to_auth_relay(relay_url string) ! {
	_ := n.client.send_json_rpc[[]string, string]('nostr.ConnectAuthRelay', [
		relay_url,
	], default_timeout)!
}

// generate a keypair
pub fn (mut n NostrClient) generate_keypair() !string {
	return n.client.send_json_rpc[[]string, string]('nostr.GenerateKeyPair', []string{},
		default_timeout)!
}

// get the nostr encoded id
pub fn (mut n NostrClient) get_id() !string {
	return n.client.send_json_rpc[[]string, string]('nostr.GetId', []string{}, default_timeout)!
}

// get public key
pub fn (mut n NostrClient) get_public_key() !string {
	return n.client.send_json_rpc[[]string, string]('nostr.GetPublicKey', []string{},
		default_timeout)!
}

// publish a text note to the relay
pub fn (mut n NostrClient) publish_text_note(args TextNote) ! {
	_ := n.client.send_json_rpc[[]TextNote, string]('nostr.PublishTextNote', [args], default_timeout)!
}

// publish metadata to the relay
pub fn (mut n NostrClient) publish_metadata(args Metadata) ! {
	_ := n.client.send_json_rpc[[]Metadata, string]('nostr.PublishMetadata', [args], default_timeout)!
}

// publish a direct message to the relay given a receiver
pub fn (mut n NostrClient) publish_direct_message(args DirectMessage) ! {
	_ := n.client.send_json_rpc[[]DirectMessage, string]('nostr.PublishDirectMessage',
		[args], default_timeout)!
}

// subscribe to the relays for text notes
pub fn (mut n NostrClient) subscribe_text_notes() ! {
	_ := n.client.send_json_rpc[[]string, string]('nostr.SubscribeTextNotes', []string{},
		default_timeout)!
}

// subscribe to the relays for direct messages
pub fn (mut n NostrClient) subscribe_to_direct_messages() !string {
	return n.client.send_json_rpc[[]string, string]('nostr.SubscribeDirectMessages', []string{},
		default_timeout)!
}

// subscribe to relays for stall creation
pub fn (mut n NostrClient) subscribe_to_stall_creation() ! {
	_ := n.client.send_json_rpc[[]string, string]('nostr.SubscribeStallCreation', []string{},
		default_timeout)!
}

// subscribe to relays for product creation
pub fn (mut n NostrClient) subscribe_to_product_creation() ! {
	_ := n.client.send_json_rpc[[]string, string]('nostr.SubscribeProductCreation', []string{},
		default_timeout)!
}

// get all the events for the subscriptions
pub fn (mut n NostrClient) get_events() ![]Event {
	return n.client.send_json_rpc[[]string, []Event]('nostr.GetEvents', []string{}, default_timeout)!
}

// get all the events for the subscription with the specified id
pub fn (mut n NostrClient) get_subscription_events(args GetSubscriptionEvents) ![]Event {
	return n.client.send_json_rpc[[]GetSubscriptionEvents, []Event]('nostr.GetSubscriptionEvents',
		[args], default_timeout)!
}

// close a subscription given an id
pub fn (mut n NostrClient) close_subscription(id string) ! {
	_ := n.client.send_json_rpc[[]string, string]('nostr.CloseSubscription', [id], default_timeout)!
}

// get all the subscription ids
pub fn (mut n NostrClient) get_subscription_ids() ![]string {
	return n.client.send_json_rpc[[]string, []string]('nostr.GetSubscriptionIds', []string{},
		default_timeout)!
}

// publixh_stall publishes a new stall to the relay
pub fn (mut n NostrClient) publish_stall(args StallCreateInput) ! {
	_ := n.client.send_json_rpc[[]StallCreateInput, string]('nostr.PublishStall', [
		args,
	], default_timeout)!
}

// publish_product publishes a new product to the relay
pub fn (mut n NostrClient) publish_product(args ProductCreateInput) ! {
	_ := n.client.send_json_rpc[[]ProductCreateInput, string]('nostr.PublishProduct',
		[args], default_timeout)!
}

// create_channel creates a new channel
pub fn (mut n NostrClient) create_channel(args CreateChannelInput) !string {
	return n.client.send_json_rpc[[]CreateChannelInput, string]('nostr.CreateChannel',
		[
		args,
	], default_timeout)!
}

// subscribe_channel_creation subsribes to channel creation events
pub fn (mut n NostrClient) subscribe_channel_creation() !string {
	return n.client.send_json_rpc[[]string, string]('nostr.SubscribeChannelCreation',
		[]string{}, default_timeout)!
}

// create_channel_message creates a new channel message event
pub fn (mut n NostrClient) create_channel_message(args CreateChannelMessageInput) ! {
	_ := n.client.send_json_rpc[[]CreateChannelMessageInput, string]('nostr.CreateChannelMessage',
		[
		args,
	], default_timeout)!
}

// subscribe_channel_message creates a subscription to channel or message events based on the provided id
pub fn (mut n NostrClient) subscribe_channel_message(args SubscribeChannelMessageInput) !string {
	return n.client.send_json_rpc[[]SubscribeChannelMessageInput, string]('nostr.SubscribeChannelMessage',
		[
		args,
	], default_timeout)!
}

// list_channels lists all channels on the connected relay
pub fn (mut n NostrClient) list_channels() ![]RelayChannel {
	return n.client.send_json_rpc[[]string, []RelayChannel]('nostr.ListChannels', []string{},
		default_timeout)!
}

// get_channel_message fetches all messages sent to a channel
pub fn (mut n NostrClient) get_channel_message(args FetchChannelMessageInput) ![]RelayChannelMessage {
	return n.client.send_json_rpc[[]FetchChannelMessageInput, []RelayChannelMessage]('nostr.GetChannelMessages',
		[
		args,
	], default_timeout)!
}
