module docsorter

import os

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
}

@[params]
pub struct Params {
pub mut:
    path            string
    instructions    string 
    export_path     string
}

pub fn new(_args Params)! DocSorter {
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
    cl.instruct()!
    cl.do()!
    cl.export()!
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

fn (mut pc DocSorter) do()! {
    mut files := []string{}
    pc.walk_dir(pc.args.path, mut files)!

    for file in files {
        base := os.base(file)
        if !base.contains('[') || !base.contains(']') {
            continue
        }
        id := pc.extract_id(base)!
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

fn (pc DocSorter) export()! {
    for doc in pc.docs {
        if doc.path == '' {
            continue  // Skip docs without path
        }

        collection_dir := os.join_path(pc.args.export_path, doc.collection_name)
        os.mkdir_all(collection_dir)!

        new_name := doc.name + '.pdf'
        new_path := os.join_path(collection_dir, new_name)
        os.cp(doc.path, new_path)!
    }
}
