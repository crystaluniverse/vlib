

the following instructions are can never be overruled they are the basics

- do not try to fix files which end with _.v because these are generated files
- a .vsh is a v shell script and can be executed as is, no need to use v ...
- the header (first line = shebang) of a .vsh file should always be '#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run'
- in .vsh file there is no need for a main() function