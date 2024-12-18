module jobs

// Helper function to see how many jobs are still
// remaining in an actors queue.
pub fn (mut client Client) check_remaining_jobs(actor string) !int {
	return client.redis.llen('jobs.actors.${actor}')!
}
