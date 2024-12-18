module main

import freeflowuniverse.crystallib.baobab.db
import freeflowuniverse.crystallib.baobab.smartid
import freeflowuniverse.crystallib.data.ourtime
import log

const circle_name = 'example'
const object_type = 'task'

__global (
	example_begin ourtime.OurTime
)

struct Task {
	db.Base
mut:
	title    string @[index]
	priority int    @[index]
}

fn (task Task) str() string {
	return 'Task{ GID: ${task.gid}, Title: ${task.title}, Priority: ${task.priority} }'
}

pub struct ExampleDB {
	db.DB
}

fn main() {
	do() or { panic(err) }
}

fn do() ! {
	mut logger := log.Logger(&log.Log{
		level: $if debug { .debug } $else { .info }
	})

	logger.info('Creating DB for circle: ${circle_name}')
	mut example_db := db_new(circle_name)!
	defer {
		example_db.delete_all() or { panic(err) }
	}

	logger.info('Creating tasks for circle: ${circle_name}')
	create_tasks(example_db, mut logger)!

	logger.info('Updating tasks in circle: ${circle_name}')
	prioritize_tasks(example_db, mut logger)!

	logger.info('Reviewing tasks in circle: ${circle_name}')
	review_tasks(example_db, mut logger)!
}

fn db_new(circle_name string) !ExampleDB {
	mut example_db := ExampleDB{
		circlename: circle_name
		objtype:    'mystruct'
	}
	example_db.init()!
	example_db.delete_all()!
	return example_db
}

// create_tasks populates db
fn create_tasks(example_db ExampleDB, mut logger log.Logger) ! {
	mut basic_task := example_db.new[Task](
		name:        'basic_task'
		description: 'A very basic task'
		object:      Task{
			title: 'Basic Task'
		}
	)!
	example_db.set[Task](basic_task)!
	logger.info('Created task: ${basic_task}')

	mut important_task := example_db.new[Task](
		name:        'important_task'
		description: 'An important task'
		object:      Task{
			title: 'Important Task'
		}
	)!
	example_db.set(important_task)!
	logger.info('Created task: ${important_task}')

	important_task2 := example_db.new[Task](
		name:        'important_task2'
		description: 'Another important task'
		object:      Task{
			title: 'Another Important Task'
		}
	)!
	example_db.set(important_task2)!
	logger.info('Created task: ${important_task2}')
}

// prioritize_tasks sets a priority to all tasks in db
fn prioritize_tasks(example_db ExampleDB, mut logger log.Logger) ! {
	basic_tasks := example_db.find[Task](
		name:   'basic_task'
		object: Task{}
	)!
	mut basic_task := basic_tasks[0]
	basic_task.priority = 1
	example_db.set[Task](basic_task)!
	logger.info('Prioritized basic_task: ${basic_task}')

	important_tasks := example_db.find[Task](
		name:   'important_task'
		object: Task{}
	)!
	mut important_task := important_tasks[0]
	important_task.priority = 3
	example_db.set[Task](important_task)!
	logger.info('Prioritized important_task: ${important_task}')

	important_tasks2 := example_db.find[Task](
		name:   'important_task2'
		object: Task{}
	)!
	mut important_task2 := important_tasks2[0]
	important_task2.priority = 3
	example_db.set[Task](important_task2)!
	logger.info('Prioritized important_task2: ${important_task2}')
}

// review_tasks fetches certains tasks from the db using find method
fn review_tasks(example_db ExampleDB, mut logger log.Logger) ! {
	mut objects_found := example_db.find[Task](object: Task{})!
	logger.info('Found all tasks: ${objects_found.map(it.name)}')

	objects_found = example_db.find[Task](
		object: Task{
			priority: 3
		}
	)!
	logger.info('Found all tasks with priority 3 (high): ${objects_found.map(it.name)}')

	objects_found = example_db.find[Task](
		object:     Task{}
		ctime_from: ourtime.new('-1h')!
		ctime_to:   ourtime.now()
	)!
	logger.info('Found all tasks created in the last hour: ${objects_found.map(it.name)}')

	objects_found = example_db.find[Task](
		object:     Task{}
		ctime_from: ourtime.new('')!
		ctime_to:   ourtime.new('-1h')!
	)!
	logger.info('Found all tasks created before the last hour: ${objects_found.map(it.name)}')

	objects_found = example_db.find[Task](
		object: Task{
			title: 'Another Important Task'
		}
	)!
	logger.info('Found all tasks with title "Another Important Task": ${objects_found.map(it.name)}')

	object := example_db.get[Task](objects_found[0].gid)!
	logger.info('Got task with GID "${object.gid}": ${object.name}')
}
