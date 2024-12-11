# verasure - Jerasure made simple in V

This is a V implementation of Jerasure2, with a custom wrapper.

In V, there is a wrapper to make call pure-v style.

# Example

```v
module main

import freeflowuniverse.crystallib.data.verasure

fn main() {
	mut e := verasure.new(16, 4)
	shards := e.encode("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer consectetur accumsan augue, at pharetra".bytes())
	println(shards)

	data := e.decode(shards)
	println(data.len)
	println(data.bytestr())
}
```

1. Create a new Verasure object, with data and parity amount
2. Encode any bytes data
3. Decode shards to get bytes back

# Disclamer

This is still in progress, memory management is not yet there. There is still a bug on parity missing.
