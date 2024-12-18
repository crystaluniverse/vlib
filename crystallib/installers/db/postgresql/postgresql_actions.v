module postgresql

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.osal.zinit

fn installed() !bool {
	return true
}

fn install() ! {
	osal.execute_silent('podman pull docker.io/library/postgres:latest')!
}

fn startupcmd() ![]zinit.ZProcessNewArgs {
	mut cfg := get()!
	mut res := []zinit.ZProcessNewArgs{}
	db_user := 'root'
	cmd := "
    mkdir -p ${cfg.path}
    podman run --name ${cfg.name} -e POSTGRES_USER=${db_user} -e POSTGRES_PASSWORD=\"${cfg.passwd}\" -v ${cfg.path}:/var/lib/postgresql/data -p 5432:5432 --health-cmd=\"pg_isready -U ${db_user}\" postgres:latest
    "

	res << zinit.ZProcessNewArgs{
		name:        'postgresql'
		cmd:         cmd
		workdir:     cfg.path
		startuptype: .zinit
	}
	return res
}

fn running() !bool {
	mut mydb := get()!
	mydb.check() or { return false }
	return true
}

fn start_pre() ! {
}

fn start_post() ! {
}

fn stop_pre() ! {
}

fn stop_post() ! {
}

fn destroy() ! {
	mut mydb := get()!
	mydb.destroy()!

	// mut cfg := get()!
	// osal.rm("
	//     ${cfg.path}
	//     /etc/postgresql/
	//     /etc/postgresql-common/
	//     /var/lib/postgresql/
	//     /etc/systemd/system/multi-user.target.wants/postgresql
	//     /lib/systemd/system/postgresql.service
	//     /lib/systemd/system/postgresql@.service
	// ")!

	// c := '

	// #dont die
	// set +e

	// # Stop the PostgreSQL service
	// sudo systemctl stop postgresql

	// # Purge PostgreSQL packages
	// sudo apt-get purge -y postgresql* pgdg-keyring

	// # Remove all data and configurations
	// sudo userdel -r postgres
	// sudo groupdel postgres

	// # Reload systemd configurations and reset failed systemd entries
	// sudo systemctl daemon-reload
	// sudo systemctl reset-failed

	// echo "PostgreSQL has been removed completely"

	// '
	// osal.exec(cmd: c)!
}
