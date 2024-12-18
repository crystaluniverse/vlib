see

https://github.com/xingyif/raft/tree/master

> purpose is to make a raft version in V, we might be able to base it on this python implementation
>

## option 1

- the raft.v here is a port from python (not compiling yet)
- idea would be for first version just make a message bus e.g. on redis based queues to simulate multiple raft nodes
- e.g. each raft node has an in and out queue, and you can talk to the other node by sending to in queue of that node and then read back from out queue ... 

## option 2

use a rust library, implement an example key value stor using that library

https://docs.rs/openraft/latest/openraft/docs/getting_started/index.html

rust will have to be bound to V

