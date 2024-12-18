module processor

import freeflowuniverse.crystallib.baobab.client
import freeflowuniverse.crystallib.baobab.jobs
import log
import rand

const default_timeout_waiting_queues = 1.0

// The representation of the Processor. It contains a
// client that is used to get jobs from redis, a logger
// to log usefull information and an attribute running
// that can be used to stop a running processor.
@[noinit]
pub struct Processor {
mut:
	client client.Client
	logger &log.Logger
pub mut:
	running                bool
	timeout_waiting_queues f64 = default_timeout_waiting_queues
}

// Factory method for creating a new processor.
pub fn new(redis_address string, logger &log.Logger) !Processor {
	return Processor{
		client: client.new(redis_address)!
		logger: unsafe { logger }
	}
}

// Runs the processor. It will loop until the attribute
// running is set to false. It will listen for incoming
// jobs in 4 different queues. Whenever there is a new
// job it will distribute it to the right actor.
// Whenever the actor finishes the job it will return
// it.
pub fn (mut p Processor) run() {
	p.logger.info('Processor is running')
	p.running = true
	mut queues := ['msgbus.execute_job', 'jobs.processor.in', 'jobs.processor.error',
		'jobs.processor.result']
	for p.running {
		rand.shuffle[string](mut queues) or { p.logger.error('Failed to shuffle queues') }
		res := p.client.redis.brpop(queues, p.timeout_waiting_queues) or {
			if '${err}' != 'timeout on brpop' {
				p.logger.error('Failed to brpop queues: ${err}')
			}
			continue
		}
		if res.len != 2 || res[1] == '' {
			continue
		}
		match res[0] {
			'msgbus.execute_job' {
				if guid_rmb := p.get_rmb_job(res[1]) {
					// get msg from rmb queue, parse job, assign to actor
					p.logger.debug('Received job with guid ${guid_rmb} from RMB')
					p.assign_job(guid_rmb) or { p.handle_error(err) }
				}
			}
			'jobs.processor.in' {
				// get guid from processor.in queue and assign job to actor
				p.logger.debug('Received job with guid ${res[1]}')
				p.assign_job(res[1]) or { p.handle_error(err) }
			}
			'jobs.processor.error' {
				// get guid from processor.error queue and move to return queue
				p.logger.debug('Received error response for job with guid ${res[1]} ')
				p.return_job(res[1]) or { p.handle_error(err) }
			}
			'jobs.processor.result' {
				// get guid from processor.result queue and move to return queue
				p.logger.debug('Received result for job with guid ${res[1]}')
				p.return_job(res[1]) or { p.handle_error(err) }
			}
			else {
				p.logger.error('Unknown queue ${res[0]}')
			}
		}
	}
}

// Places guid to correct actor queue, and to the processor.active queue
fn (mut p Processor) assign_job(guid string) ! {
	mut job := p.client.job_get(guid)!

	if !job.check_timeout_ok() {
		return jobs.JobError{
			msg:      'Job timeout reached'
			job_guid: guid
		}
	}

	// push guid to active queue
	mut q_active := p.client.redis.queue_get('jobs.processor.active')
	q_active.add(guid)!

	// push guid to queue of actor which will handle job
	q_key := 'jobs.actors.${job.action.all_before_last('.')}'
	mut q_actor := p.client.redis.queue_get(q_key)
	q_actor.add(guid)!

	p.logger.debug('Assigned job ${guid} to ${q_key}:')
	p.logger.debug('${job}\n')
}

// Returns a job by placing it to the correct redis return queue
fn (mut p Processor) return_job(guid string) ! {
	if p.client.redis.hexists('rmb.db', guid)! {
		p.return_job_rmb(guid)!
	} else {
		mut q_return := p.client.redis.queue_get('jobs.return.${guid}')
		q_return.add(guid)!
	}
	p.logger.debug('Returned job ${guid}')
}

// Places guid to jobs.return queue with an error
fn (mut p Processor) handle_error(error IError) {
	if error is jobs.JobError {
		mut job := p.client.job_get(error.job_guid) or {
			eprintln('Failed getting the job with id ${error.job_guid}: ${err}')
			return
		}
		p.client.job_error_set(mut job, error.msg) or {
			eprintln('Failed modifying the status of the job ${error.job_guid} to error: ${err}')
			return
		}
		p.return_job(error.job_guid) or {
			eprintln('Failed returning the job ${error.job_guid}: ${err}')
			return
		}
	} else {
		eprintln('Not a JobError: ${error}')
	}
}

// Helper function to reset the queues of the processor.
pub fn (mut p Processor) reset() ! {
	p.client.redis.flushall()!
	p.client.redis.disconnect()
	p.client.redis.socket_connect()!
}

// todo: fix if needed
// fn (mut p Processor) restart()! {
// 	p.client.redis.save()!
// 	p.client.redis.shutdown()!
// 	// os.execute('redis-server --daemonize yes &')
// 	time.sleep(1000000)
// 	p.client.redis.socket_connect()!
// }
