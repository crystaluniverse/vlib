module main

__global (
	connections shared []Connection
)

pub fn main() {
	lock_function()

	lock connections {
		println(@FN + ': locked connections')
	}
	println('Exited connections lock')
	lock connections {
		println(@FN + ': locked connections again')
	}
	println('Exited the second connections lock again')
}

pub fn lock_function() {
	lock connections {
		println(@FN + ': locked connections')
		nested_lock_function()
	}
}

pub fn nested_lock_function() {
	lock connections {
		println(@FN + ': locked connections')
	}
}
