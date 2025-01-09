<h1> Hero Docker Image </h1>

<h2>Table of Contents</h2>

- [Introduction](#introduction)
- [Features](#features)
- [Quick Start](#quick-start)
  - [Pull the Image](#pull-the-image)
  - [Run the Container](#run-the-container)
  - [Options Explained](#options-explained)
- [Development](#development)
- [Directory Structure](#directory-structure)
- [Publish the Image](#publish-the-image)
- [License](#license)

---

## Introduction

This Docker image provides an environment for Hero and Crystallib frameworks.

## Features

- Ubuntu-based environment
- Pre-installed Hero and Crystallib frameworks
- Development tools and dependencies
- Ready-to-use configuration

## Quick Start

### Pull the Image

```bash
docker pull logismosis/hero:latest
```

### Run the Container


```bash
docker run -it --net=host --name=hero-container -v ~/code:/root/code logismosis/hero:latest
```

> Note: Make sure to have a directory at `~/code`, e.g. by running (`mkdir -p ~/code`), if you want to use the volume.

### Options Explained

- `-it`: Interactive terminal
- `--net=host`: Use host networking
- `--name=hero-container`: Name the container
- `-v ~/code:/root/code`: Mount local code directory

## Development

The container comes with:

- Git
- Curl
- Nano editor
- SSH client
- SQLite3 development files
- Python3 virtual environment

## Directory Structure

Within the container, the directory structure will be as follows:

```
/root/code/
└── github/
    └── freeflowuniverse/
        └── crystallib/
```

## Publish the Image

- Build the image
    ```
    docker build -t your-dockerhub-username/hero:latest .
    ```
- Push both tags
    ```
    sudo docker push your-dockerhub-username/hero:latest
    ```

## License

This project is licensed under the Apache 2.0 License.