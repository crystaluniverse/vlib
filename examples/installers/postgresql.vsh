#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -cg -d use_openssl -enable-globals run

import time
import freeflowuniverse.crystallib.installers.db.postgresql

mut db := postgresql.get()!

// db.destroy()!
db.start()!

// db.db_create('my_new_db')!
// db.stop()!
// db.start()!
