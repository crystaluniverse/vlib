module docsorter
import freeflowuniverse.crystallib.ui.console
import os
import json
import freeflowuniverse.crystallib.lang.python

@[heap]
pub struct Doc {
pub mut:
    id              string
    path            string
    name            string
    description     string
    collection_name string
}

pub struct DocSorter {
pub mut:
    docs []&Doc
    args Params 
    py   ?python.PythonEnv @[skip]
}

@[params]
pub struct Params {
pub mut:
    path            string
    instructions    string 
    export_path     string
    reset bool
    slides bool //if we exctract slides out of the pdfs
}

pub fn sort(_args Params)! DocSorter {
    mut p := _args

	if p.instructions == ""{
		p.instructions = '${p.path}/instructions.txt'
	}
	
    if !os.exists(p.path) {
        return error('Path: ${p.path} does not exist.')
    }
    if !os.exists(p.instructions) {
        return error('Instructions file: ${p.instructions} does not exist.')
    }
    

    mut cl:= DocSorter{
        docs: []&Doc{}
        args: p
    }

    if p.slides{
        cl.py = python.new(name: 'slides')! // a python env with name test
        mut mypython := cl.py or { panic("can't find python env, was not initializaed") }
        mypython.pip('ipython,pymupdf')!
    }

    console.print_debug("args:\n${p}")
    cl.instruct()!
    cl.do()!
    return cl
}

fn (mut pc DocSorter) instruct()! {
    content := os.read_file(pc.args.instructions)!
    lines := content.split_into_lines()

    for line in lines {
        if line.trim_space() == '' {
            continue
        }

        parts := line.split(':')
        if parts.len < 2 {
            continue
        }

        mut doc := Doc{
            id: parts[0]
            collection_name: parts[1]
            name: parts[2]
        }

        if parts.len > 3 {
            doc.description = parts[3]
        }

        pc.docs << &doc
        //console.print_debug(pc.docs)
    }
    
}

fn (mut pc DocSorter) doc_get(id string)! &Doc {
    for doc in pc.docs {
        if doc.id == id {
            return doc
        }
    }
    return error('Document with id ${id} not found.')
}

pub fn (pc DocSorter) doc_exists(id string) bool {
    //console.print_debug('Checking if document with ID "${id}" exists')
    for doc in pc.docs {
        if doc.id == id {
            //console.print_debug('Found document with ID "${id}"')
            return true
        }
    }
    //console.print_debug('Document with ID "${id}" not found')
    return false
}

fn (mut pc DocSorter) do()! {
    mut files := []string{}
    pc.walk_dir(pc.args.path, mut files)!

    for file in files {
        base := os.base(file)
        if !base.contains('[') || !base.contains(']') {
            continue
        }
        id := pc.extract_id(base)!
        if !pc.doc_exists(id) {
            console.print_stderr('Skipping file ${file} - no matching document found for ID ${id}')
            continue
        }
        mut doc := pc.doc_get(id)!
        doc.path = file
    }

    pc.export()!
}

fn (mut pc DocSorter) walk_dir(path string, mut files []string)! {
    items := os.ls(path)!
    for item in items {
        full_path := os.join_path(path, item)
        if os.is_dir(full_path) {
            pc.walk_dir(full_path, mut files)!
        } else if item.to_lower().ends_with('.pdf') {
            files << full_path
        }
    }
}

fn (pc DocSorter) extract_id(filename string)! string {
    if !filename.contains('[') || !filename.contains(']') {
        return error('Filename does not contain brackets')
    }
    id_with_closing := filename.all_after_first('[')
    return id_with_closing.all_before_last(']')
}

fn (mut pc DocSorter) export()! {

    // If reset is true, remove the collection directory if it exists
    if pc.args.reset && os.exists(pc.args.export_path) {
        os.rmdir_all(pc.args.export_path)!
    }
            
    for doc in pc.docs {
        if doc.path == '' {
            continue  // Skip docs without path
        }

        collection_dir := os.join_path(pc.args.export_path, doc.collection_name)
        

        os.mkdir_all(collection_dir)!

        new_name := doc.name + '.pdf'
        new_path := os.join_path(collection_dir, new_name)
        os.cp(doc.path, new_path)!
        console.print_green('Copy ${doc.path} -> ${new_path}')

        // Create JSON file with Doc content
        json_content := json.encode(doc)
        json_path := os.join_path(collection_dir, doc.name + '.json')
        os.write_file(json_path, json_content)!

        // Check if filename starts with slide_ and call slides_process if it does
        if pc.args.slides && doc.name.starts_with('slide') {
            pc.slides_process(new_path)!
        }
    }
}
