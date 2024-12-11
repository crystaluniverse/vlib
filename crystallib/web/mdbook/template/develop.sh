set -e
cd ${book.path_build.path}
mdbook serve . -p 8884 -n localhost --open --dest-dir ${book.path_publish.path}
