import postgres_server

fn main() {
    config := postgres_server.PostgresConfig{
        pg_bin: '/usr/local/pgsql/bin',
        data_dir: '/usr/local/pgsql/data',
        log_file: '/usr/local/pgsql/logfile',
        port: 5432
    }
    server := postgres_server.PostgresServer{
        config: config
    }

    // Initialize the database
    server.initdb() or {
        println('Error initializing database: $err')
        return
    }

    // Start the server
    server.start() or {
        println('Error starting server: $err')
        return
    }

    // Create a new database
    server.create_db('test_db') or {
        println('Error creating database: $err')
        return
    }

    // Create a new user
    server.create_user('test_user', 'test_password') or {
        println('Error creating user: $err')
        return
    }

    // Grant privileges to the new user on the new database
    server.grant_privileges('test_db', 'test_user') or {
        println('Error granting privileges: $err')
        return
    }

    // Stop the server
    server.stop() or {
        println('Error stopping server: $err')
        return
    }
}
