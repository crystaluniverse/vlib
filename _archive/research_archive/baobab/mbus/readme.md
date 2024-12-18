# Mycelium Bus

## RPC

## redis queues and hsets used

redis queues:
* rpc.db = hset
  * key is the id of the model (is hash of the encoded object so is unique)
  * data is the serialized rpc,acceptance,result object
* rpc.active.$twiniddest = hset
    * this makes it easy to know to where messages are being sent, which twin will receive
    * key = rpcid = hash of msg
    * data = $start,$timeout,$retrynr,$state
      * start is in "YYYY-MM-DD HH:mm" format (24h) (iso8601)
      * timeout is in seconds since start
      * retrynr is 1 for first time, if error, will try again this will go up
      * state is N:new,S:send,R:retry,T:timeout,A:accepted,D:result
* rpc.processor.in, is a queue asking processor to work on it
    * every time there is something to do for the processor there will be record inserted
    * data:  $twiniddest,$rpcid
* rpc.result.$rpcid, is a queue tells the mbus that result is back
    * data:  $twiniddest,$rpcid

