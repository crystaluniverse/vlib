module natsclient

const msg_ping = 'PING\r\n'
const msg_pong = 'PONG\r\n'

pub struct NATSMessage {
pub mut:
	subject  string
	sid      string
	reply_to string
	message  string
}

pub struct NATSMessageParser {
mut:
	data           string
	i              int
	subject        string
	sid            string
	reply_to       string
	message_length int
	message        string
	header_length  int
	headers        map[string]string
pub mut:
	on_nats_message fn (message NATSMessage, headers map[string]string) = fn (message NATSMessage, headers map[string]string) {}
	on_nats_info    fn (data string)  = fn (data string) {}
	on_nats_ping    fn ()             = fn () {}
	on_nats_pong    fn ()             = fn () {}
	on_nats_error   fn (error string) = fn (error string) {}
}

pub fn (mut n NATSMessageParser) parse(data string) ! {
	n.data = data
	n.i = 0
	for n.i < n.data.len {
		n.subject = ''
		n.sid = ''
		n.reply_to = ''
		n.message_length = 0
		n.message = ''
		n.header_length = 0
		n.headers = map[string]string{}
		match n.data[n.i] {
			72 { // "HMSG"
				n.parse_hmsg()!
				n.on_nats_message(NATSMessage{
					subject:  n.subject
					sid:      n.sid
					reply_to: n.reply_to
					message:  n.message
				}, n.headers)
			}
			73 { //"INFO"
				// TODO parse to actual info object
				info := n.parse_info()!
				n.on_nats_info(info)
			}
			77 { // MSG
				n.parse_msg()!
				n.on_nats_message(NATSMessage{
					subject:  n.subject
					sid:      n.sid
					reply_to: n.reply_to
					message:  n.message
				}, n.headers)
			}
			80 { // PING or PONG
				if n.data[n.i..].starts_with(msg_ping) {
					n.i += msg_ping.len
					n.on_nats_ping()
				} else if n.data[n.i..].starts_with(msg_pong) {
					n.i += msg_pong.len
					n.on_nats_pong()
				}
			}
			43 { // +OK
			}
			45 { // -ERR
				// TODO parse to actual error object
				err := n.parse_err()!
				n.on_nats_error(err)
			}
			else {
				return error('Message <${data}> not supported!')
			}
		}
	}
}

// -------------------------------------------------------------
pub fn (mut n NATSMessageParser) parse_err() !string {
	n.should_find_error()!
	j := n.find_next_new_line()!

	data := n.data[n.i..j]

	n.i = j + 2
	return data
}

fn (mut n NATSMessageParser) should_find_error() ! {
	if n.i + 5 >= n.data.len || n.data[n.i..n.i + 5] != '-ERR ' {
		return error('invalid: should_find_error: not starting with -ERR')
	}
	n.i = n.i + 5
}

// -------------------------------------------------------------
pub fn (mut n NATSMessageParser) parse_info() !string {
	n.should_find_info()!
	j := n.find_next_new_line()!

	data := n.data[n.i..j]

	n.i = j + 2
	return data
}

fn (mut n NATSMessageParser) should_find_info() ! {
	if n.i + 5 >= n.data.len || n.data[n.i..n.i + 5] != 'INFO ' {
		return error('invalid: should_find_info: not starting with INFO')
	}
	n.i = n.i + 5
}

pub fn (mut n NATSMessageParser) parse_hmsg() ! {
	n.eat_hmsg()!
	n.eat_spaces()!
	n.subject = n.eat_data_till_space_or_newline()!
	n.eat_spaces()!
	n.sid = n.eat_data_till_space_or_newline()!
	n.eat_spaces()!
	// can be reply_to or payload length
	data1 := n.eat_data_till_space_or_newline()!
	n.eat_spaces()!
	mut data2 := n.eat_data_till_space_or_newline()!
	if n.try_eat_spaces() {
		// we were able to eat spaces which means prior data1 was reply_to
		n.reply_to = data1
		n.header_length = data2.int()
		data2 = n.eat_data_till_space_or_newline()!
	} else {
		n.header_length = data1.int()
	}
	n.message_length = data2.int() - n.header_length
	n.eat_newline()!
	header_raw := n.eat_n_bytes(n.header_length)!
	n.parse_header(header_raw)
	n.message = n.eat_n_bytes(n.message_length)!
	n.eat_newline()!
}

fn (mut n NATSMessageParser) eat_hmsg() ! {
	if n.i + 4 >= n.data.len || n.data[n.i..n.i + 4] != 'HMSG' {
		return error('invalid: should_find_hmsg: not starting with HMSG')
	}
	n.i = n.i + 4
}

fn (mut n NATSMessageParser) parse_header(header_raw string) {
	headers := header_raw.split('\r\n')
	if headers.len == 0 {
		return
	}
	for header in headers[1..] {
		if header != '' {
			key_val := header.split_nth(': ', 2)
			n.headers[key_val[0]] = if key_val.len == 2 { key_val[1] } else { '' }
		}
	}
}

// -------------------------------------------------------------
pub fn (mut n NATSMessageParser) parse_msg() ! {
	n.eat_msg()!
	n.eat_spaces()!
	n.subject = n.eat_data_till_space_or_newline()!
	n.eat_spaces()!
	n.sid = n.eat_data_till_space_or_newline()!
	n.eat_spaces()!
	// can be reply_to or payload length
	mut data := n.eat_data_till_space_or_newline()!
	if n.try_eat_spaces() {
		// we were able to eat spaces which means prior data was the reply_to
		n.reply_to = data
		data = n.eat_data_till_space_or_newline()!
	}
	n.message_length = data.int()
	n.eat_newline()!
	n.message = n.eat_n_bytes(n.message_length)!
	n.eat_newline()!
}

fn (mut n NATSMessageParser) eat_msg() ! {
	if n.i + 3 >= n.data.len || n.data[n.i..n.i + 3] != 'MSG' {
		return error('invalid: eat_msg: not starting with MSG')
	}
	n.i = n.i + 3
}

fn (mut n NATSMessageParser) eat_data_till_space_or_newline() !string {
	mut j := n.i
	for j + 1 < n.data.len && n.data[j] != 32 && n.data[j..j + 2] != '\r\n' {
		j += 1
	}
	data := n.data[n.i..j]
	n.i = j
	return data
}

fn (mut n NATSMessageParser) try_parse_reply_to() ! {
	mut location_new_line := 0
	mut location_space := 0
	mut j := n.i
	for j + 1 < n.data.len {
		if n.data[j..j + 2] == '\r\n' && location_new_line == 0 {
			location_new_line = j
			break
		}
		if n.data[j] == 32 {
			location_space = j
		}
		j += 1
	}
	if j + 1 >= n.data.len {
		return error('invalid: try_parse_reply_to: no more data')
	}
	if location_space != 0 && location_space < location_new_line {
		// there is a reply_to specified
		n.reply_to = n.data[n.i..location_space]
		n.i = location_space + 1
	} else {
		// no reply_to specified and we know the message length now
		n.message_length = n.data[n.i..location_new_line].int()
		n.i = location_new_line + 2
	}
	// j := n.find_next_space()!
	// if n.i < j {
	// 	n.reply_to = n.data[n.i .. j]
	// }
	// n.i = j + 1
}

fn (mut n NATSMessageParser) parse_message() ! {
	if n.message_length == -1 {
		j := n.find_next_new_line()!
		n.message_length = n.data[n.i..j].int()
		n.i = j + 2
	}

	if n.i + n.message_length > n.data.len {
		return error('invalid: parse_message: no more data')
	}
	if n.message_length > 0 {
		n.message = n.data[n.i..n.i + n.message_length]
		n.i += n.message_length
	}
	if n.i + 1 >= n.data.len || n.data[n.i..n.i + 2] != '\r\n' {
		return error('invalid: parse_message: no new line')
	}
	n.i += 2
}

// -------------------------------------------------------------

fn (mut n NATSMessageParser) find_next_space() !int {
	mut j := n.i
	for j < n.data.len && n.data[j] != 32 {
		j += 1
	}
	if n.data[j] != 32 {
		return error('invalid: find_next_space: no space found')
	}
	return j
}

fn (mut n NATSMessageParser) eat_spaces() ! {
	mut i := n.i
	for i < n.data.len && n.data[i] == 32 {
		i += 1
	}
	if i == n.i {
		return error('invalid: eat_spaces: no spaces found at location ${n.i}')
	}
	n.i = i
}

fn (mut n NATSMessageParser) try_eat_spaces() bool {
	n.eat_spaces() or { return false }
	return true
}

fn (mut n NATSMessageParser) eat_newline() ! {
	if n.i + 1 >= n.data.len || n.data[n.i..n.i + 2] != '\r\n' {
		return error('invalid: eat_newline: no new line found: ${n}')
	}
	n.i += 2
}

fn (mut n NATSMessageParser) eat_n_bytes(l int) !string {
	if n.i + l >= n.data.len {
		return error('invalid: eat_n_bytes: not enough data left')
	}
	data := n.data[n.i..n.i + l]
	n.i += l
	return data
}

fn (mut n NATSMessageParser) find_next_new_line() !int {
	mut j := n.i
	for j + 1 < n.data.len && n.data[j..j + 2] != '\r\n' {
		j += 1
	}
	if j + 1 >= n.data.len || n.data[j..j + 2] != '\r\n' {
		return error('invalid: find_next_new_line: no new line found')
	}
	return j
}
