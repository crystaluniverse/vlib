module tfrobot

const test_ssh_key = ''
const test_mneumonic = ''
const test_flist = 'https://hub.grid.tf/mariobassem1.3bot/threefolddev-holochain-latest.flist'

fn test_job_new() {
	mut bot := new()!
	bot.job_new(
		name:      'test_job'
		mneumonic: test_mneumonic
	)!
}

fn test_job_run() {
	mut bot := new()!
	mut job := bot.job_new(
		name:      'test_job'
		mneumonic: test_mneumonic
	)!

	job.add_ssh_key('my_key', test_ssh_key)
	vm_config := VMConfig{
		name:      'holo_vm'
		region:    'europe'
		nrcores:   4
		memory_mb: 4096
		ssh_key:   'my_key'
		flist:     test_flist
		pub_ip:    true
	}

	job.deploy_vms(vm_config, 10)
	job.run()!
}
