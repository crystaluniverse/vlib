FROM ubuntu:latest

# Add metadata
LABEL maintainer="FreeFlow Universe"
LABEL version="Latest"
LABEL description="Environment for Hero and Crystallib frameworks"
LABEL org.opencontainers.image.source="https://github.com/freeflowuniverse/crystallib"
LABEL org.opencontainers.image.licenses="Apache 2.0"

ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisites
RUN apt-get update -y && \
    apt-get install -y \
    git \
    curl \
    nano \
    openssh-client \
    libsqlite3-dev \
    python3-venv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create directory structure
RUN mkdir -p /root/code/github/freeflowuniverse

# Set working directory
WORKDIR /root/code/github/freeflowuniverse

# Clone repository
RUN git clone https://github.com/freeflowuniverse/crystallib

# Download installation scripts
RUN curl https://raw.githubusercontent.com/freeflowuniverse/crystallib/development/scripts/install_hero.sh > /tmp/hero_install.sh && \
    curl https://raw.githubusercontent.com/freeflowuniverse/crystallib/development/scripts/installer.sh > /tmp/install.sh

# Run installation scripts
RUN bash /tmp/hero_install.sh && \
    bash /tmp/install.sh

# Clean up
RUN rm /tmp/hero_install.sh /tmp/install.sh

# Set default command
CMD ["/bin/bash"]