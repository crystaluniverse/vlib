module example_actor

import os
import freeflowuniverse.crystallib.hero.baobab.actor {IActor, RunParams}
import freeflowuniverse.crystallib.web.openapi
import time

const openapi_spec_path = '${os.dir(@FILE)}/specs/openapi.json'
const openapi_spec_json = os.read_file(openapi_spec_path) or { panic(err) }
const openapi_specification = openapi.json_decode(openapi_spec_json)!

struct ExampleActor {
    actor.Actor
}

fn new() !ExampleActor {
    return ExampleActor{
        actor.new('example')
    }
}

pub fn run() ! {
    mut a_ := new()!
    mut a := IActor(a_)
    a.run()!
}

pub fn run_server(params RunParams) ! {
    mut a := new()!
    mut server := actor.new_server(
        redis_url: 'localhost:6379'
        redis_queue: a.name
        openapi_spec: openapi_specification
    )!
    server.run(params)
}