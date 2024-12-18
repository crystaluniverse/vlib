module spawner

import sync

pub struct OurThread {
pub mut:
	// ourthread thread
	ch_send   &sync.Channel // the channel used to send instructions to the thread
	ch_return &sync.Channel // the channel which returns the answers
}

// send a remote procecure call
pub fn (mut t OurThread) rpc(args RPCArg) !string {
	// println("send:\n$args")
	t.ch_send.push(&args)
	// println("send done")

	if args.async {
		return ''
	}
	// println("wait: return")
	t.ch_return.pop(&args)
	// println(args)

	if args.error.len > 0 {
		println('ERROR IN THREAD:\n${args.error}')
		return error(args.error)
	}

	return args.result
}

// will stop the mentioned thread
pub fn (mut t OurThread) stop() ! {
	mut a := RPCArg{
		method: 'STOP'
		async:  true
	}
	t.ch_send.push(&a)
}
