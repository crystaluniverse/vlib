# dbfs

a  key value stor on filesystem, can work with id's as well as with keys.

The algo's used have been optimized for scalability and human readability, the idea is that the data files need to be small, efficient and be well usable on a e.g. git based storage system.

- dbcollection, can linked to a context of hero (can be a circle or another area worth remembering things for)
- db, there can be more than 1 db per dbcollection
- the secret is specified per dbcollection 
- each subdb inherits the secret from the dbcollection but needs to be configured as encrypted

```v

> TODO: fix, we refactored

import freeflowuniverse.crystallib.core.dbfs

mut dbcollection := get(context: 'test', secret: '123456')!

mut db := dbcollection.get_encrypted("db_a")!

db.set('a', 'bbbb')!
assert 'bbbb' == db.get('a')!


```

## dbname 

DBName has functionality to efficiently store millions of names and generate a unique id for it, each name gets a unique id, and based on the id the name can be found back easily.

Some string based data can be attached to one name so it becomes a highly efficient key value stor, can be used for e.g. having DB of pubkeys, for a nameserver, ...

## dbfs examples

Each session has such a DB attached to it, data is stored on filesystem, 

e.g. ideal for config sessions (which are done on context level)


```golang

> TODO: fix, we refactored

import freeflowuniverse.crystallib.core.dbfs

mut dbcollection := get(context: 'test', secret: '123456')!

mut db := dbcollection.get_encrypted("db_a")!


>> TODO: need to be updated, is now based on key and id

//get the value
fn (mut db DB) get(name_ string) !string {

//set the key/value will go to filesystem, is organzed per context and each db has a name
fn (mut db DB) set(name_ string, data_ string) !

//check if entry exists based on keyname
fn (mut db DB) exists(name_ string) bool
	
//delete an entry
fn (mut db DB) delete(name_ string) !

//get all keys of the db (e.g. per session)
fn (mut db DB) keys(prefix string) ![]string

// delete all data
fn (mut db DB) destroy() !

```