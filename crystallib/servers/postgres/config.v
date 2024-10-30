module postgres

pub struct PostgresConfig {
    pg_bin    string
    data_dir  string
    log_file  string
    port      int = 5432
}
