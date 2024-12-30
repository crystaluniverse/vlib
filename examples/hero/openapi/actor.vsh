#!/usr/bin/env -S v -w -n -enable-globals run

import os
import time
import veb
import json
import x.json2
import net.http
import freeflowuniverse.crystallib.web.openapi {Server, Context, Request, Response}
import freeflowuniverse.crystallib.hero.processor {Processor, ProcedureCall, ProcedureResponse, ProcessParams}
import freeflowuniverse.crystallib.clients.redisclient

@[heap]
struct Actor {
mut:
    rpc redisclient.RedisRpc
    data_store DataStore
}

pub struct DataStore {
mut:
    pets   map[int]Pet
    orders map[int]Order
    users  map[int]User
}

struct Pet {
    id   int
    name string
    tag  string
}

struct Order {
    id        int
    pet_id    int
    quantity  int
    ship_date string
    status    string
    complete  bool
}

struct User {
    id       int
    username string
    email    string
    phone    string
}

// Entry point for the actor
fn main() {
    mut redis := redisclient.new('localhost:6379') or {panic(err)}
    mut rpc := redis.rpc_get('procedure_queue')

    mut actor := Actor{
        rpc: rpc
        data_store: DataStore{}
    }

    actor.listen() or {panic(err)}
}

// Actor listens to the Redis queue for method invocations
fn (mut actor Actor) listen() ! {
    println('Actor started and listening for tasks...')
    for {
        actor.rpc.process(actor.handle_method)!
        time.sleep(time.millisecond * 100) // Prevent CPU spinning
    }
}

// Handle method invocations
fn (mut actor Actor) handle_method(cmd string, data string) !string {
    println('debugzo received rpc ${cmd}:${data}')
    param_anys := json2.raw_decode(data)!.arr()
    match cmd {
        'listPets' {
            pets := if param_anys.len == 0 {
                actor.data_store.list_pets()
            } else {
                params := json.decode(ListPetParams, param_anys[0].str())!
                actor.data_store.list_pets(params)
            }
            return json.encode(pets)
        }
        'createPet' {
            response := if param_anys.len == 0 {
                return error('at least data expected')
            } else if param_anys.len == 1 {
                payload := json.decode(NewPet, param_anys[0].str())!
                actor.data_store.create_pet(payload)
            } else {
                return error('expected 1 param, found too many')
            }
            // data := json.decode(NewPet, data) or { return error('Invalid pet data: $err') }
            // created_pet := actor.data_store.create_pet(pet)
            return json.encode(response)
        }
        'getPet' {
            response := if param_anys.len == 0 {
                return error('at least data expected')
            } else if param_anys.len == 1 {
                payload := param_anys[0].int()
                actor.data_store.get_pet(payload)!
            } else {
                return error('expected 1 param, found too many')
            }
            
            return json.encode(response)
        }
        'deletePet' {
            params := json.decode(map[string]int, data) or { return error('Invalid params: $err') }
            actor.data_store.delete_pet(params['petId']) or { return error('Pet not found: $err') }
            return json.encode({'message': 'Pet deleted'})
        }
        'listOrders' {
            orders := actor.data_store.list_orders()
            return json.encode(orders)
        }
        'getOrder' {
            params := json.decode(map[string]int, data) or { return error('Invalid params: $err') }
            order := actor.data_store.get_order(params['orderId']) or {
                return error('Order not found: $err')
            }
            return json.encode(order)
        }
        'deleteOrder' {
            params := json.decode(map[string]int, data) or { return error('Invalid params: $err') }
            actor.data_store.delete_order(params['orderId']) or {
                return error('Order not found: $err')
            }
            return json.encode({'message': 'Order deleted'})
        }
        'createUser' {
            user := json.decode(NewUser, data) or { return error('Invalid user data: $err') }
            created_user := actor.data_store.create_user(user)
            return json.encode(created_user)
        }
        else {
            return error('Unknown method: $cmd')
        }
    }
}

@[params]
pub struct ListPetParams {
    limit u32
}

// DataStore methods for managing data
fn (mut store DataStore) list_pets(params ListPetParams) []Pet {
    if params.limit > 0 {
        if params.limit >= store.pets.values().len {
            return store.pets.values()
        }
        return store.pets.values()[..params.limit]
    }
    return store.pets.values()
}

fn (mut store DataStore) create_pet(new_pet NewPet) Pet {
    id := store.pets.keys().len + 1
    pet := Pet{id: id, name: new_pet.name, tag: new_pet.tag}
    store.pets[id] = pet
    return pet
}

fn (mut store DataStore) get_pet(id int) !Pet {
    return store.pets[id] or { 
        return error('Pet with id ${id} not found.')
    }
}

fn (mut store DataStore) delete_pet(id int) ! {
    if id in store.pets {
        store.pets.delete(id)
        return
    }
    return error('Pet not found')
}

fn (mut store DataStore) list_orders() []Order {
    return store.orders.values()
}

fn (mut store DataStore) get_order(id int) !Order {
    return store.orders[id] or { none }
}

fn (mut store DataStore) delete_order(id int) ! {
    if id in store.orders {
        store.orders.delete(id)
        return
    }
    return error('Order not found')
}

fn (mut store DataStore) create_user(new_user NewUser) User {
    id := store.users.keys().len + 1
    user := User{id: id, username: new_user.username, email: new_user.email, phone: new_user.phone}
    store.users[id] = user
    return user
}

// NewPet struct for creating a pet
struct NewPet {
    name string
    tag  string
}

// NewUser struct for creating a user
struct NewUser {
    username string
    email    string
    phone    string
}