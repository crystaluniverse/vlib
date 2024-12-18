import freeflowuniverse.crystallib.threefold.twinclient as tw
import net.websocket as ws
import term
import json

fn main1() {
	mut s := ws.new_server(.ip6, 8081, '/')
	s.on_connect(fn (mut s ws.ServerClient) !bool {
		if s.resource_name != '/' {
			return false
		}
		println('Client has connected...')
		return true
	})!
	s.on_message(fn (mut ws_client ws.Client, msg &tw.RawMessage) ! {
		handle_events(msg, mut ws_client)!
	})
	s.on_close(fn (mut ws ws.Client, code int, reason string) ! {
		println(term.green('client (${ws.id}) closed connection'))
	})
	s.listen() or { println(term.red('error on server listen: ${err}')) }
	unsafe {
		s.free()
	}
}

fn handle_events(raw_msg &tw.RawMessage, mut ws_client ws.Client) ! {
	if raw_msg.payload.len == 0 {
		return
	}

	mut transport := tw.WSTwinClient{}
	transport.init(mut ws_client)!
	mut grid := tw.grid_client(transport)!
	msg := json.decode(tw.Message, raw_msg.payload.bytestr()) or {
		println('cannot decode message')
		return
	}

	if msg.event == 'sum_balances' {
		spawn fn [mut grid] () ! {
			// List all algorand accounts.
			grid.algorand_list()!

			// Deploy new machine
			machines := tw.MachinesModel{
				name:     'ms1'
				network:  tw.Network{
					ip_range:   '10.200.0.0/16'
					name:       'net'
					add_access: false
				}
				machines: [
					tw.Machine{
						name:        'm1'
						node_id:     2
						public_ip:   false
						planetary:   true
						cpu:         1
						memory:      1024
						rootfs_size: 1
						flist:       'https://hub.grid.tf/tf-official-apps/base:latest.flist'
						entrypoint:  '/sbin/zinit init'
						env:         tw.Env{
							ssh_key: 'ADD_YOUR_SSH'
						}
					},
				]
			}
			grid.machines_deploy(machines)!
		}()
	} else {
		println('got a new message: ${msg.event}')
	}
}
