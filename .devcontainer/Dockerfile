FROM ubuntu:24.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install essential build tools and dependencies
RUN apt-get update && apt-get install -y \
    git gcc make clang libssl-dev sqlite3 libsqlite3-dev mc htop

# Install V
RUN git clone https://github.com/vlang/v /opt/vlang \
    && cd /opt/vlang \
    && make \
    && ln -s /opt/vlang/v /usr/local/bin/v

CMD ["redis-server"]