module gittools

pub enum GitStructureStatus {
	init
	loaded
	error
}

pub enum GitStatus {
	unknown
	changes
	ok
	error
}

[heap]
struct GitStructure {
pub mut:
	multibranch bool
	root        string
	repos       []GitRepo
	status      GitStructureStatus
	light       bool = true // if set then will clone only last history for all branches	
}

struct GitRepo {
	id int [skip]
	// only use when custom path
	path string
pub mut:
	addr  GitAddr
	state GitStatus
}

struct GitAddr {
pub mut:
	// root string
	provider string
	account  string
	name     string // is the name of the repository
	path     string // path in the repo (not on filesystem)
	branch   string
	anker    string // position in the file
	depth    int    // 0 means we have all depth
}
