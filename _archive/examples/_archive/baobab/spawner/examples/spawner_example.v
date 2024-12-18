import freeflowuniverse.crystallib.baobab.spawner
import sync
import time

fn channel_test(mut ch_in sync.Channel, mut ch_out sync.Channel) {
	println('thread start')
	mut rpcobj := spawner.RPCArg{}
	for i in 0 .. 10 {
		println(i)
		// ch_out.pop(&rpcobj)
		// println("received")
		ch_in.pop(&rpcobj)
		if rpcobj.method == 'STOP' {
			println('STOP')
			return
		}
		println(rpcobj)
		rpcobj.result = 'AVAL${i}'
		if rpcobj.async {
			continue
		}
		println('server push')
		ch_out.push(&rpcobj)
		println('server push done')
		time.sleep(time.Duration(time.second))
		println('next iteration in thread')
	}
}

fn do() ! {
	mut s := spawner.new()
	mut t := s.thread_add('athread', channel_test)!
	// time.sleep(time.Duration(time.second))

	mut res := t.rpc(method: 'ping', val: 'pong')!
	println(res)
	t.stop()!

	// time.sleep(time.Duration(10*time.second))
}

fn main() {
	do() or { panic(err) }
}
