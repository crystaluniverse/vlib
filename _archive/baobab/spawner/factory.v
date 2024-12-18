module spawner

import sync

@[heap]
pub struct Spawner {
pub mut:
	threads map[string]&OurThread
}

@[params]
pub struct RPCArg {
pub mut:
	tname  string // name of the thread
	method string // the method to be called in the thread
	val    string
	result string
	error  string
	async  bool
}

pub fn new() Spawner {
	return Spawner{}
}

type ThreadType = fn (&sync.Channel, &sync.Channel)

pub fn (mut s Spawner) thread_add(name string, op fn (&sync.Channel, &sync.Channel)) !&OurThread {
	n := u32(100000)
	mut ch_send := sync.new_channel[RPCArg](n) // question: don't understand the n...
	mut ch_return := sync.new_channel[RPCArg](n)

	spawn op(ch_send, ch_return)

	return s.channels_add(name, mut ch_send, mut ch_return)!
}

///spawn the process and wait for heroscripts to be fed
pub fn (mut s Spawner) channels_add(name string, mut ch_send sync.Channel, mut ch_return sync.Channel) !&OurThread {
	mut ot := OurThread{
		// ourthread:t
		ch_send:   ch_send
		ch_return: ch_return
	}

	s.threads[name] = &ot

	return &ot
}

// send a remote procecure call
pub fn (mut s Spawner) rpc(mut args RPCArg) !string {
	mut t := s.threads[args.tname] or {
		return error('cannot find thread with name: ${args.tname}')
	}

	return t.rpc(args)
}

// will stop the mentioned thread
pub fn (mut s Spawner) stop(tname string) ! {
	mut t := s.threads[tname] or { return error('cannot find thread with name: ${tname}') }

	t.stop()!
}
