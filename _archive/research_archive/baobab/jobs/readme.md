
# mbus = mycelium bus

Send job messages over our mycelium network, which is a peer2peer encrypted network.

Jobs use MBUS (change with before) to send the message.


## redis

The client uses a couple redis queues:
* jobs.db
* jobs.processor.in
* jobs.return.$guid

### jobs.db

This is an hset where we keep the jobs. The keys are the guids, the values the json serialized job.

### jobs.processor.in

This is how we tell the processor to start processing jobs. First, we add the job to the db and then add the guid to this queue. The processor will notice this and take action on it. 

### jobs.return.$guid

Once the job has been put into the queue *jobs.processor.in* the client can wait for jobs to finish. He or she should look into the queue *jobs.return.$guid* for that. The processor will put the finished job into that queue once it is finished.


## other languages

This is what needs to be re-developed for other languages, we kept it as easy as possible. You will find logic bound to clients here. This includes functions to submit jobs, wait for them or even schedule them. 

