## Parser

Parser is used to parse actor code into a `generator.Actor` struct, so that OpenRPC can be generated from custom actor code.


- Default actor methods: CRUD+list+filter methods for base objects

## Conventions

### Actor Methods

All default actor methods must be defined in files that follow the naming convention `<actor_name>_<base_object_name>.v`

### Base Objects
- Base Objects should be defined in separate files named `model_<object_name>.v`. 
- All children objects and methods defined on the base object should be in the same file.