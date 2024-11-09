module flist

@[table: 'route']
pub struct Route {
pub mut:
	start u8
	end   u8
	url   string
}

// get_routes returns all flist routes
pub fn (mut f Flist) get_routes() ![]Route {
	routes := sql f.con {
		select from Route
	}!
	return routes
}

fn (mut f Flist) add_route(route Route) ! {
	sql f.con {
		insert route into Route
	}!
}

fn (mut f Flist) delete_all_routes() ! {
	f.con.exec('delete from route;')!
}
