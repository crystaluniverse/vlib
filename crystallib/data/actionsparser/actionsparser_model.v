module actionsparser

fn cid_check(c string, block string) ! {
	if c.len == 0 {
		return error('cid not specified\nFor block: ${block}')
	}

	if c.len < 5 && c != 'core' {
		return error("cid bad specified (len min 5), found '${c}'.\nFor block: ${block}")
	}
	if c.len > 20 {
		return error("cid bad specified (len max 20), found '${c}'.\nFor block: ${block}")
	}
}

fn circle_check(c string, block string) ! {
	if c.len == 0 {
		return error('circle not specified\nFor block: ${block}')
	}

	if c.len < 3 {
		return error("circle bad specified (len min 3), found '${c}'.\nFor block: ${block}")
	}
	if c.len > 30 {
		return error("circle bad specified (len max 30), found '${c}'.\nFor block: ${block}")
	}
}

fn actor_check(c string, block string) ! {
	if c.len == 0 {
		return error('actor not specified\nFor block: ${block}')
	}

	if c.len < 2 {
		return error("actor bad specified (len min 2), found '${c}'.\nFor block: ${block}")
	}
	if c.len > 20 {
		return error("actor bad specified (len max 20), found '${c}'.\nFor block: ${block}")
	}
}

fn name_check(c string, block string) ! {
	if c.len == 0 {
		return error('name not specified\nFor block: ${block}')
	}

	if c.len < 2 {
		return error("name bad specified (len min 2), found '${c}'.\nFor block: ${block}")
	}
	if c.len > 40 {
		return error("name bad specified (len max 40), found '${c}'.\nFor block: ${block}")
	}
}
