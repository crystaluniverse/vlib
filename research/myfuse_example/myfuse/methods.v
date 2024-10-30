module myfuse

import os

// Input parameters for filesystem operations
@[params]
pub struct MountParams {
pub:
    mountpoint string
    foreground bool = true
    allow_other bool = false
    default_permissions bool = true
    fsname string = 'myfs'
    subtype string = ''
}

@[params]
pub struct EntryParams {
pub:
    ino u64
    generation u64 = 1
    attr Stat
    attr_timeout f64 = 1.0
    entry_timeout f64 = 1.0
}

@[params]
pub struct StatParams {
pub:
    ino u64
    mode Mode
    uid Uid = u32(os.getuid())
    gid Gid = u32(os.getgid())
    size i64
    blocks i64
    atime Timespec
    mtime Timespec
    ctime Timespec
}

@[params]
pub struct DirEntryParams {
pub:
    ino Ino
    offset i64
    type_ Mode
    name string
}

// V wrapper for fuse_reply_err
pub fn reply_err(req FuseReq, err int) int {
    return C.fuse_reply_err(req, err)
}

// V wrapper for fuse_reply_none
pub fn reply_none(req FuseReq) {
    C.fuse_reply_none(req)
}

// V wrapper for fuse_reply_entry
pub fn reply_entry(req FuseReq, params EntryParams) int {
    entry := EntryParam{
        ino: params.ino
        generation: params.generation
        attr: params.attr
        attr_timeout: params.attr_timeout
        entry_timeout: params.entry_timeout
    }
    return C.fuse_reply_entry(req, &entry)
}

// V wrapper for fuse_reply_attr
pub fn reply_attr(req FuseReq, attr Stat, timeout f64) int {
    return C.fuse_reply_attr(req, &attr, timeout)
}

// V wrapper for fuse_reply_readlink
pub fn reply_readlink(req FuseReq, link string) int {
    return C.fuse_reply_readlink(req, link.str)
}

// V wrapper for fuse_reply_open
pub fn reply_open(req FuseReq, fi FileInfo) int {
    return C.fuse_reply_open(req, &fi)
}

// V wrapper for fuse_reply_write
pub fn reply_write(req FuseReq, count u64) int {
    return C.fuse_reply_write(req, count)
}

// V wrapper for fuse_reply_buf
pub fn reply_buf(req FuseReq, data string) int {
    return C.fuse_reply_buf(req, data.str, u64(data.len))
}

// V wrapper for fuse_reply_statfs
pub fn reply_statfs(req FuseReq, stbuf Statvfs) int {
    return C.fuse_reply_statfs(req, &stbuf)
}

// V wrapper for fuse_reply_xattr
pub fn reply_xattr(req FuseReq, count u64) int {
    return C.fuse_reply_xattr(req, count)
}

// V wrapper for fuse_reply_create
pub fn reply_create(req FuseReq, params EntryParams, fi FileInfo) int {
    entry := EntryParam{
        ino: params.ino
        generation: params.generation
        attr: params.attr
        attr_timeout: params.attr_timeout
        entry_timeout: params.entry_timeout
    }
    return C.fuse_reply_create(req, &entry, &fi)
}

// Helper function to create a new filesystem session
pub fn new_fs_session(params MountParams, ops &LowlevelOps) !(FuseSession, &myfuse.FuseChan) {
    // Build mount options
    mut args := []string{}
    args << os.args[0]
    if params.foreground {
        args << '-f'
    }
    if params.fsname != '' {
        args << '-o fsname=${params.fsname}'
    }
    if params.subtype != '' {
        args << '-o subtype=${params.subtype}'
    }
    args << params.mountpoint

    // Create mount point if it doesn't exist
    if !os.exists(params.mountpoint) {
        os.mkdir(params.mountpoint) or { return error('Failed to create mount point: ${err}') }
    }

    mut fuse_args := FuseArgs{
        argc: args.len
        argv: args.data
        allocated: 0
    }

    // Mount filesystem
    chan2 := C.fuse_mount(params.mountpoint.str, &fuse_args)
    if  chan2 == 0 {
        return error('Failed to mount filesystem')
    }

    // Create session
    se := C.fuse_lowlevel_new(&fuse_args, ops, sizeof(LowlevelOps), 0)
    if se == 0 {
        C.fuse_unmount(params.mountpoint.str,  chan2)
        return error('Failed to create FUSE session')
    }

    // Add channel to session
    C.fuse_session_add_chan(se,  chan2)

    return se,  &chan2
}

// Helper function to create a directory entry
pub fn new_dir_entry(params DirEntryParams) DirEntry {
    return DirEntry{
        ino: params.ino
        off: params.offset
        namelen: u32(params.name.len)
        type_: u32(params.type_ >> 12)
        name: params.name.str
    }
}

// Helper function to create file attributes
pub fn new_stat(params StatParams) Stat {
    return Stat{
        st_ino: params.ino
        st_mode: params.mode
        st_nlink: if (params.mode & s_ifdir) != 0 { 2 } else { 1 }
        st_uid: params.uid
        st_gid: params.gid
        st_size: params.size
        st_blocks: params.blocks
        st_atime: params.atime
        st_mtime: params.mtime
        st_ctime: params.ctime
    }
}
