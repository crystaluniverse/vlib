#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import myfuse
import os
import time

// Global state for our filesystem
struct MyFS {
mut:
    root_stat myfuse.Stat
}

__global my_fs MyFS

fn init(ci &myfuse.ConnInfo, cfg &voidptr) {
    now := time.now().unix_time()
    // Initialize root directory stats
    my_fs.root_stat = myfuse.new_stat(
        ino: 1
        mode: myfuse.s_ifdir | 0o755
        size: 0
        blocks: 1
        atime: myfuse.Timespec{tv_sec: now, tv_nsec: 0}
        mtime: myfuse.Timespec{tv_sec: now, tv_nsec: 0}
        ctime: myfuse.Timespec{tv_sec: now, tv_nsec: 0}
    )
}

fn lookup(req myfuse.FuseReq, parent myfuse.Ino, name &char) {
    if parent != 1 {
        myfuse.reply_err(req, myfuse.enoent)
        return
    }

    // Convert C string to V string for comparison
    name_str := unsafe { cstring_to_vstring(name) }
    
    if name_str == "hello.txt" {
        now := time.now().unix_time()
        // Create file attributes
        attr := myfuse.new_stat(
            ino: 2
            mode: myfuse.s_ifreg | 0o444
            size: 13  // length of "Hello, World!"
            blocks: 1
            atime: myfuse.Timespec{tv_sec: now, tv_nsec: 0}
            mtime: myfuse.Timespec{tv_sec: now, tv_nsec: 0}
            ctime: myfuse.Timespec{tv_sec: now, tv_nsec: 0}
        )

        // Reply with entry
        myfuse.reply_entry(req, 
            ino: 2
            attr: attr
        )
    } else {
        myfuse.reply_err(req, myfuse.enoent)
    }
}

fn getattr(req myfuse.FuseReq, ino myfuse.Ino, fi &myfuse.FileInfo) {
    if ino == 1 {
        // Root directory
        myfuse.reply_attr(req, my_fs.root_stat, 1.0)
    } else if ino == 2 {
        // hello.txt file
        now := time.now().unix_time()
        attr := myfuse.new_stat(
            ino: 2
            mode: myfuse.s_ifreg | 0o444
            size: 13
            blocks: 1
            atime: myfuse.Timespec{tv_sec: now, tv_nsec: 0}
            mtime: myfuse.Timespec{tv_sec: now, tv_nsec: 0}
            ctime: myfuse.Timespec{tv_sec: now, tv_nsec: 0}
        )
        myfuse.reply_attr(req, attr, 1.0)
    } else {
        myfuse.reply_err(req, myfuse.enoent)
    }
}

fn readdir(req myfuse.FuseReq, ino myfuse.Ino, size u64, off i64, fi &myfuse.FileInfo) {
    if ino != 1 {
        myfuse.reply_err(req, myfuse.enoent)
        return
    }

    mut entries := []myfuse.DirEntry{}

    if off == 0 {
        // Add "." entry
        entries << myfuse.new_dir_entry(
            ino: 1
            offset: 1
            type_: myfuse.s_ifdir
            name: "."
        )

        // Add ".." entry
        entries << myfuse.new_dir_entry(
            ino: 1
            offset: 2
            type_: myfuse.s_ifdir
            name: ".."
        )

        // Add "hello.txt" entry
        entries << myfuse.new_dir_entry(
            ino: 2
            offset: 3
            type_: myfuse.s_ifreg
            name: "hello.txt"
        )
    }

    // Build directory buffer
    mut buf := []u8{len: int(size)}
    mut offset := 0

    for entry in entries {
        unsafe {
            C.memcpy(buf.data + offset, &entry, sizeof(entry))
            offset += sizeof(entry)
        }
    }

    myfuse.reply_buf(req, string(buf[..offset]))
}

fn read(req myfuse.FuseReq, ino myfuse.Ino, size u64, off i64, fi &myfuse.FileInfo) {
    if ino != 2 {
        myfuse.reply_err(req, myfuse.enoent)
        return
    }

    content := "Hello, World!"
    content_len := content.len

    if off >= content_len {
        myfuse.reply_buf(req, "")
        return
    }

    mut read_size := int(size)
    if off + read_size > content_len {
        read_size = content_len - off
    }

    myfuse.reply_buf(req, content[off..off+read_size])
}

fn main() {
    // Initialize operations
    mut ops := myfuse.LowlevelOps{
        init: init
        lookup: lookup
        getattr: getattr
        readdir: readdir
        read: read
    }

    // Create and mount filesystem
    mount_params := myfuse.MountParams{
        mountpoint: "/tmp/mymount"
        foreground: true
        fsname: "hellofs"
    }

    se, chan := myfuse.new_fs_session(mount_params, &ops) or {
        eprintln('Failed to create filesystem: ${err}')
        return
    }

    // Set up signal handlers
    C.fuse_set_signal_handlers(se)

    // Run FUSE session
    println('Filesystem mounted at ${mount_params.mountpoint}')
    println('Press Ctrl+C to stop')
    
    if C.fuse_session_loop(se) != 0 {
        C.fuse_remove_signal_handlers(se)
        C.fuse_session_destroy(se)
        C.fuse_unmount(mount_params.mountpoint.str, chan)
        eprintln('Failed to run FUSE session')
        return
    }

    // Clean up
    C.fuse_remove_signal_handlers(se)
    C.fuse_session_destroy(se)
    C.fuse_unmount(mount_params.mountpoint.str, chan)
}
