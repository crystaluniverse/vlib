module myfuse

#flag -D_FILE_OFFSET_BITS=64
#flag darwin -I/usr/local/include/osxfuse
#flag darwin -L/usr/local/lib
#flag darwin -losxfuse

// Required C headers
#include <fuse/fuse_lowlevel.h>
#include <fuse/fuse_opt.h>
#include <sys/stat.h>
#include <sys/statvfs.h>
#include <sys/xattr.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>

// Basic FUSE types
pub type Ino = u64
pub type FuseReq = voidptr
pub type FuseBufVec = voidptr
pub type FuseSession = voidptr
pub type FuseChan = voidptr
pub type Dev = u64
pub type Mode = u32
pub type Nlink = u32
pub type Uid = u32
pub type Gid = u32
pub type Pid = u32

// FUSE argument structure
@[typedef]
pub struct C.fuse_args {
pub mut:
	argc      int
	argv      &charptr
	allocated int
}

pub type FuseArgs = C.fuse_args

// Time specifications
@[attr]
pub struct Timespec {
pub:
	tv_sec  i64
	tv_nsec i64
}

// File system statistics
@[attr]
pub struct Statvfs {
pub:
	f_bsize   u64 // Block size
	f_frsize  u64 // Fragment size
	f_blocks  u64 // Total blocks
	f_bfree   u64 // Free blocks
	f_bavail  u64 // Available blocks
	f_files   u64 // Total inodes
	f_ffree   u64 // Free inodes
	f_favail  u64 // Available inodes
	f_fsid    u64 // Filesystem ID
	f_flag    u64 // Mount flags
	f_namemax u64 // Maximum filename length
}

// File attributes
@[attr]
pub struct Stat {
pub:
	st_dev     Dev      // Device ID
	st_ino     Ino      // Inode number
	st_mode    Mode     // Protection and file type
	st_nlink   Nlink    // Number of hard links
	st_uid     Uid      // User ID of owner
	st_gid     Gid      // Group ID of owner
	st_rdev    Dev      // Device ID (if special file)
	st_size    i64      // Total size in bytes
	st_blksize i32      // Block size
	st_blocks  i64      // Number of blocks allocated
	st_atime   Timespec // Time of last access
	st_mtime   Timespec // Time of last modification
	st_ctime   Timespec // Time of last status change
	st_crtime  Timespec // Time of creation (macOS specific)
	st_flags   u32      // User defined flags (macOS specific)
}

// Directory entry
@[attr]
pub struct DirEntry {
pub:
	ino     Ino   // Inode number
	off     i64   // Offset to next entry
	namelen u32   // Name length
	type_   u32   // File type
	name    &char // Null terminated name
}

// File information
@[attr]
pub struct FileInfo {
pub mut:
	flags       int // Open flags
	fh          u64 // File handle
	lock_owner  u64 // Lock owner
	direct_io   u32 // Direct I/O flag
	keep_cache  u32 // Keep cache flag
	flush       u32 // Flush flag
	nonseekable u32 // Non-seekable flag
	padding     u32 // Padding
}

// Entry parameters
@[packed]
pub struct EntryParam {
pub mut:
	ino           Ino  // Inode number
	generation    u64  // Inode generation
	attr          Stat // Attributes
	attr_timeout  f64  // Attribute timeout
	entry_timeout f64  // Entry timeout
}

// Connect info
@[attr]
pub struct ConnInfo {
pub:
	proto_major u32 // Protocol major version
	proto_minor u32 // Protocol minor version
	max_write   u32 // Max write buffer size
	max_read    u32 // Max read buffer size
	capable     u32 // Capability flags
	want        u32 // Wanted flags
}

// Operation callbacks structure
@[attr]
pub struct LowlevelOps {
pub mut:
	init        fn (ci &ConnInfo, cfg &voidptr)
	destroy     fn ()
	lookup      fn (req FuseReq, parent Ino, name &char)
	forget      fn (req FuseReq, ino Ino, nlookup u64)
	getattr     fn (req FuseReq, ino Ino, fi &FileInfo)
	setattr     fn (req FuseReq, ino Ino, attr &Stat, to_set int, fi &FileInfo)
	readlink    fn (req FuseReq, ino Ino)
	mknod       fn (req FuseReq, parent Ino, name &char, mode Mode, rdev Dev)
	mkdir       fn (req FuseReq, parent Ino, name &char, mode Mode)
	unlink      fn (req FuseReq, parent Ino, name &char)
	rmdir       fn (req FuseReq, parent Ino, name &char)
	symlink     fn (req FuseReq, link &char, parent Ino, name &char)
	rename      fn (req FuseReq, parent Ino, name &char, newparent Ino, newname &char, flags u32)
	link        fn (req FuseReq, ino Ino, newparent Ino, newname &char)
	open        fn (req FuseReq, ino Ino, fi &FileInfo)
	read        fn (req FuseReq, ino Ino, size u64, off i64, fi &FileInfo)
	write       fn (req FuseReq, ino Ino, buf &char, size u64, off i64, fi &FileInfo)
	flush       fn (req FuseReq, ino Ino, fi &FileInfo)
	release     fn (req FuseReq, ino Ino, fi &FileInfo)
	fsync       fn (req FuseReq, ino Ino, datasync int, fi &FileInfo)
	opendir     fn (req FuseReq, ino Ino, fi &FileInfo)
	readdir     fn (req FuseReq, ino Ino, size u64, off i64, fi &FileInfo)
	releasedir  fn (req FuseReq, ino Ino, fi &FileInfo)
	fsyncdir    fn (req FuseReq, ino Ino, datasync int, fi &FileInfo)
	statfs      fn (req FuseReq, ino Ino)
	setxattr    fn (req FuseReq, ino Ino, name &char, value &char, size u64, flags int)
	getxattr    fn (req FuseReq, ino Ino, name &char, size u64)
	listxattr   fn (req FuseReq, ino Ino, size u64)
	removexattr fn (req FuseReq, ino Ino, name &char)
	access      fn (req FuseReq, ino Ino, mask int)
	create      fn (req FuseReq, parent Ino, name &char, mode Mode, fi &FileInfo)
	fallocate   fn (req FuseReq, ino Ino, mode int, offset i64, length i64, fi &FileInfo)
}

// FUSE reply functions
fn C.fuse_reply_err(req FuseReq, err int) int
fn C.fuse_reply_none(req FuseReq)
fn C.fuse_reply_entry(req FuseReq, e &EntryParam) int
fn C.fuse_reply_attr(req FuseReq, attr &Stat, timeout f64) int
fn C.fuse_reply_readlink(req FuseReq, link &char) int
fn C.fuse_reply_open(req FuseReq, fi &FileInfo) int
fn C.fuse_reply_write(req FuseReq, count u64) int
fn C.fuse_reply_buf(req FuseReq, buf &char, size u64) int
fn C.fuse_reply_statfs(req FuseReq, stbuf &Statvfs) int
fn C.fuse_reply_xattr(req FuseReq, count u64) int
fn C.fuse_reply_create(req FuseReq, e &EntryParam, fi &FileInfo) int

// FUSE setup and teardown
fn C.fuse_parse_cmdline(args &C.fuse_args, mountpoint &&char, multithreaded &int, foreground &int) int
fn C.fuse_mount(mountpoint &char, args &C.fuse_args) &C.fuse_chan
fn C.fuse_lowlevel_new(args &C.fuse_args, ops &LowlevelOps, op_size u64, userdata voidptr) FuseSession
fn C.fuse_set_signal_handlers(se FuseSession) int
fn C.fuse_session_add_chan(se FuseSession, ch &C.fuse_chan)
fn C.fuse_session_loop(se FuseSession) int
fn C.fuse_session_remove_chan(ch &C.fuse_chan)
fn C.fuse_session_destroy(se FuseSession)
fn C.fuse_unmount(mountpoint &char, ch &C.fuse_chan)

// Constants
// File types
pub const s_ifmt = 0o170000 // File type mask

pub const s_ifreg = 0o100000 // Regular file

pub const s_ifdir = 0o040000 // Directory

pub const s_iflnk = 0o120000 // Symbolic link

pub const s_ifchr = 0o020000 // Character device

pub const s_ifblk = 0o060000 // Block device

pub const s_ififo = 0o010000 // FIFO

pub const s_ifsock = 0o140000 // Socket

// Permission bits
pub const s_irwxu = 0o700 // User read/write/execute

pub const s_irusr = 0o400 // User read

pub const s_iwusr = 0o200 // User write

pub const s_ixusr = 0o100 // User execute

pub const s_irwxg = 0o070 // Group read/write/execute

pub const s_irgrp = 0o040 // Group read

pub const s_iwgrp = 0o020 // Group write

pub const s_ixgrp = 0o010 // Group execute

pub const s_irwxo = 0o007 // Others read/write/execute

pub const s_iroth = 0o004 // Others read

pub const s_iwoth = 0o002 // Others write

pub const s_ixoth = 0o001 // Others execute

// Open flags
pub const o_rdonly = 0x0000 // Read only

pub const o_wronly = 0x0001 // Write only

pub const o_rdwr = 0x0002 // Read and write

pub const o_creat = 0x0200 // Create if not exists

pub const o_excl = 0x0800 // Exclusive create

pub const o_trunc = 0x0400 // Truncate

pub const o_append = 0x0008 // Append

// Error codes
pub const eperm = 1 // Operation not permitted

pub const enoent = 2 // No such file or directory

pub const eio = 5 // I/O error

pub const eacces = 13 // Permission denied

pub const eexist = 17 // File exists

pub const enotdir = 20 // Not a directory

pub const einval = 22 // Invalid argument

pub const enospc = 28 // No space left on device
