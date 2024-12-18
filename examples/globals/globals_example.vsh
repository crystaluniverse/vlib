#!/usr/bin/env -S v -enable-globals run

import rand
import os
import time

__global (
	bizmodels shared map[string]BizModel
)

pub struct SubItem {
pub mut:
	name    string
	intlist []int
	intstr  []string
}

pub struct BizModel {
pub mut:
	name    string
	intlist []int
	intstr  []string
	mymap   map[string]SubItem
}

pub fn biz_model_example(name string) BizModel {
	mut biz_model := BizModel{
		name:    name
		intlist: []int{len: 10, init: rand.intn(100) or { 0 }}
		intstr:  []string{len: 10, init: rand.string(5)}
		mymap:   map[string]SubItem{}
	}

	for i in 0 .. 100 {
		sub_item := SubItem{
			name:    'SubItem ${i}'
			intlist: []int{len: 5, init: rand.intn(50) or { 0 }}
			intstr:  []string{len: 5, init: rand.string(3)}
		}
		biz_model.mymap['item_${i}'] = sub_item
	}

	return biz_model
}

pub fn get(name string) !BizModel {
	rlock bizmodels {
		if name !in bizmodels {
			return error("can't find bizmodel: ${name}")
		}
		return bizmodels[name] or { panic('bug') }
	}
	return error('bug')
}

pub fn getset(name string) BizModel {
	lock bizmodels {
		if name !in bizmodels {
			set(biz_model_example(name))
		}
		return bizmodels[name] or { panic('bug') }
	}
	return BizModel{} // weird we need to do this
}

pub fn set(bizmodel BizModel) {
	lock bizmodels {
		bizmodels[bizmodel.name] = bizmodel
	}
}

fn fill_biz_models(nr int) {
	for i in 0 .. nr {
		getset('bm${i}')
	}
	rlock bizmodels {
		// check we have enough bizmodels in mem
		assert bizmodels.len == nr
	}
}

fn get_memory_usage() i64 {
	pid := os.getpid()
	res := os.execute('ps -o rss= -p ${pid}')
	return res.output.trim_space().i64()
}

fn main() {
	sw := time.new_stopwatch()

	nr := 100
	nr_new := 100000 // make small changes, the garbage collector should keep it clean

	fill_biz_models(nr)

	memory_usage_1 := get_memory_usage()
	println('Memory usage after creating ${nr} BizModels: ${memory_usage_1} KB')
	println('Time taken: ${sw.elapsed().milliseconds()} ms')

	for _ in 0 .. nr_new {
		currentnr := rand.intn(nr - 1) or { panic(err) }
		mut new_model := get('bm${currentnr}')!
		// new_model.intlist = new_model.intlist.map(it + rand.intn(10) or { 0 })		
		new_model.intstr = new_model.intstr.map(it + rand.string(2))
		mut new_model2 := get('bm${currentnr}')!
		assert new_model2.intstr != new_model.intstr // should be different because was not a reference
		set(new_model)
		mut new_model3 := get('bm${currentnr}')!
		assert new_model3.intstr == new_model.intstr // should be different because was not a reference
	}

	rlock bizmodels {
		// check we have enough bizmodels in mem
		assert bizmodels.len == nr
	}

	println('wait 1 sec')
	// lets make sure garbage collector works
	time.sleep(1 * time.second)

	memory_usage_2 := get_memory_usage()
	println('Memory usage after creating ${nr_new} random BizModels: ${memory_usage_2} KB')
	println('Time taken: ${sw.elapsed().milliseconds()} ms')

	println("QUESTION: why does memory go up?, we didn't add to the memory should have been equal...")
}
