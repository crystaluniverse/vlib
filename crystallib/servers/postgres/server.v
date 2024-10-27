module postgres

import os

pub struct Server {
    config PostgresConfig
}

// Function to start the PostgreSQL server
pub fn (server Server) start() ! {
    cmd := '${server.config.pg_bin}/pg_ctl start -D ${server.config.data_dir} -l ${server.config.log_file} -o "-p ${server.config.port}"'
    result := os.execute(cmd)
    if result.exit_code != 0 {
        return error('Failed to start PostgreSQL server: $result.output')
    }
    println('PostgreSQL server started successfully.')
}

// Function to stop the PostgreSQL server
pub fn (server Server) stop() ! {
    cmd := '${server.config.pg_bin}/pg_ctl stop -D ${server.config.data_dir}'
    result := os.execute(cmd)
    if result.exit_code != 0 {
        return error('Failed to stop PostgreSQL server: $result.output')
    }
    println('PostgreSQL server stopped successfully.')
}

// Function to initialize the PostgreSQL database
pub fn (server Server) initdb() ! {
    cmd := '${server.config.pg_bin}/initdb -D ${server.config.data_dir}'
    result := os.execute(cmd)
    if result.exit_code != 0 {
        return error('Failed to initialize PostgreSQL database: $result.output')
    }
    println('PostgreSQL database initialized successfully.')
}

// Function to create a new database
pub fn (server Server) create_db(db_name string) ! {
    cmd := '${server.config.pg_bin} createdb -h localhost -p ${server.config.port} ${db_name}'
    result := os.execute(cmd)
    if result.exit_code != 0 {
        return error('Failed to create database ${db_name}: ${result.output}')
    }
    println('Database $db_name created successfully.')
}

// Function to create a new user
pub fn (server Server) create_user(username string, password string) ! {
    cmd := '${server.config.pg_bin}/psql -c "CREATE USER $username WITH PASSWORD \'$password\';" -h localhost -p ${server.config.port}'
    result := os.execute(cmd)
    if result.exit_code != 0 {
        return error('Failed to create user $username: $result.output')
    }
    println('User $username created successfully.')
}

// Function to grant privileges to a user on a database
pub fn (server Server) grant_privileges(db_name string, username string) ! {
    cmd := '${server.config.pg_bin}/psql -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $username;" -h localhost -p ${server.config.port}'
    result := os.execute(cmd)
    if result.exit_code != 0 {
        return error('Failed to grant privileges to user ${username} on database ${db_name}: ${result.output}')
    }
    println('Privileges granted to user ${username} on database ${db_name}.')
}
