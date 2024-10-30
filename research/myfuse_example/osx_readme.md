on osx its more something like

```

#flag darwin -I/usr/local/include/osxfuse
#flag darwin -L/usr/local/lib
#flag darwin -losxfuse
#flag darwin -D_FILE_OFFSET_BITS=64
#flag darwin -D_DARWIN_USE_64_BIT_INODE

#flag linux -D_FILE_OFFSET_BITS=64
#flag linux -lfuse

#include <fuse.h>

$if darwin {
    #include <fuse/fuse.h>
}

// Rest of the code remains the same as previous implementation


```