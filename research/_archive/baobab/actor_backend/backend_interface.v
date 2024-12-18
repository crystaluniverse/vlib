module actionsexecutor

import json
import db.sqlite
import freeflowuniverse.crystallib.clients.redisclient

// IActorDatabase, database interface for actor. Supports get, set, new, delete, list methods for root objects.
pub interface IActorBackend {
	get(int) !T // gets a root object of type T by its ID
	list() []T  // returns a list of root objects of type T
mut:
	// updates a root object of type T by its ID with a new object
	set(int, T) !
	// creates a root object and returns its ID
	new(T) !int
	// deletes a root object of type T with a given ID
	delete(int) !
}
