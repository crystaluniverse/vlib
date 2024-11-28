set -e
cd ${book.path_build.path}
mdbook build --dest-dir ${book.path_publish.path}
