The processor requires a redis server running at local port 6379. 

It is the entity that uses a couple of queues to allow messaging of ActionJob's between external clients and internal actors:

* jobs.actors.$domain_name.$actorname
* jobs.return.$guid
* jobs.processor.in
* jobs.processor.result
* jobs.processor.error
* jobs.processor.active

## jobs.actors.$domain_name.$actorname
The processor puts job guids into those queues so that the actors know that there is something to do.

## jobs.return.$guid
There will be one queue per job, the processor will put jobs that are finished in those queues for the client to notice. 

## jobs.processor.in
The client will put jobs into that queue for the processor to handle. The processor will pull it and distribute it to the right actor's queue. 

## jobs.processor.result
This queue is used by the processor to know when a job has successfully finished and thus can be returned to the client. 

## jobs.processor.error
Just as with the *jobs.processor.result* queue the processor knows when to return a job, except that this time the job failed. 

## jobs.processor.active
The processor keeps a list of active jobs in this queue.