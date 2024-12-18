module main

fn do() ! {
	pubkey := 'f6f8489517f7451637a8a0eb0d2c389f611a69e5bf2317400d23f0a186a96853'
	addr := '197a:b490:eb36:d51b:8a1d:1512:1b2f'
	// TODO: check signature from data as received from a source address against the pubkey

	// purpose is that mbus can automatically sign so we guaranteed know where info is coming from
}

fn main() {
	do() or { panic(err) }
}
