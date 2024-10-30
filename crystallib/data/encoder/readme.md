# crystal binary encoder protocol

Made for performance and smallest possible binary size

Its a very simple implementation, it just follows the order of the object and concatenate binary representations of the original information. This should lead in very fast serialization and smallest possible binary format

downsides

- if mistakes are made in encoding, data will be lost, its very minimal


example

```go

import import freeflowuniverse.crystallib.data.encoder

mut e := encoder.new()
a := AStruct{
    items: ['a', 'b']
    nr: 10
    privkey: []u8{len: 5, init: u8(0xf8)}
}

.. TODO

assert a == aa
```