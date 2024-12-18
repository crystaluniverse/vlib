# Docker Module Documentation

The Docker module provides a comprehensive set of tools for working with Docker containers, images, and compose files in V. It offers high-level abstractions for common Docker operations while maintaining flexibility for advanced use cases.

## Core Components

### DockerEngine

The main entry point for Docker operations. It manages:
- Docker images and containers
- Build operations
- Registry interactions
- Platform-specific settings

```v
// Create a new Docker engine
mut engine := docker.new(
    name: 'myengine'
    localonly: true
)!
```

### DockerContainer

Represents a Docker container with operations for:
- Starting/stopping containers
- Shell access
- Port forwarding
- Volume mounting
- Container state management

```v
// Create and start a container
mut container := engine.container_create(
    name: 'mycontainer'
    image_repo: 'ubuntu'
    image_tag: 'latest'
)!
container.start()!
```

### DockerImage

Handles Docker image operations:
- Image loading/saving
- Deletion
- Export/import
- Image metadata

```v
// Get an image by name
mut image := engine.image_get(
    repo: 'ubuntu'
    tag: 'latest'
)!
```

### DockerCompose

Manages Docker Compose operations:
- Service definitions
- Multi-container deployments
- Network configuration
- Volume management

```v
// Create a new compose configuration
mut composer := engine.compose_new(
    name: 'myapp'
)!

// Add a service
mut service := composer.service_new(C
    name: 'web'
    image: 'nginx:latest'
)!

// Configure service
service.port_expose(80, 8080)!
service.env_add('NGINX_HOST', 'localhost')
service.restart_set()

// Start the compose stack
composer.start()!
```

### DockerRegistry

Provides functionality for:
- Registry setup and management
- Image pushing/pulling
- Authentication
- SSL configuration

## Recipe System

The module includes a powerful recipe system for building Docker images:

### DockerBuilderRecipe

Allows declarative definition of Docker images with:
- Multi-stage builds
- Package installation
- File operations
- Environment configuration
- Service initialization

```v
// Create a new recipe
mut recipe := engine.recipe_new(RecipeArgs{
    name: 'myapp'
    platform: .ubuntu
})!

// Add build steps
recipe.add_package(name: 'nginx,curl')!
recipe.add_copy(source: 'app', dest: '/app')!
recipe.add_env('APP_ENV', 'production')!
recipe.add_expose(ports: ['80/tcp'])!

// Build the image
recipe.build(false)!
```

### Recipe Components

The recipe system supports various Dockerfile instructions through specialized components:

- **FromItem**: Base image specification
- **RunItem**: Command execution
- **CmdItem**: Container entry point
- **EnvItem**: Environment variables
- **WorkDirItem**: Working directory
- **CopyItem**: File copying
- **ExposeItem**: Port exposure
- **VolumeItem**: Volume mounting
- **ZinitItem**: Process management

## Advanced Features

### Platform Support
- Linux/amd64
- Linux/arm64
- Automatic platform detection and configuration

### Process Management
- Zinit integration for process supervision
- Service dependencies
- Logging configuration
- Process lifecycle management

### Development Tools
- Go builder integration
- Rust builder integration
- NodeJS support
- V language support

## Best Practices

1. **Container Management**
   - Use meaningful container names
   - Implement proper cleanup with `delete()`
   - Handle container lifecycle appropriately

2. **Image Building**
   - Leverage multi-stage builds for smaller images
   - Use the recipe system for reproducible builds
   - Implement proper caching strategies

3. **Compose Usage**
   - Define service dependencies clearly
   - Use environment variables for configuration
   - Implement proper volume management

4. **Error Handling**
   - Always check for errors in operations
   - Implement proper cleanup in error cases
   - Use the provided error types for specific scenarios

## Examples

### Basic Container Management
```v
// Create and manage a container
mut engine := docker.new(DockerEngineArgs{name: 'default'})!
mut container := engine.container_create(
    name: 'webserver'
    image_repo: 'nginx'
    forwarded_ports: ['80:8080/tcp']
)!
container.start()!
```

### Custom Image Build
```v
mut recipe := engine.recipe_new(
    name: 'custom-nginx'
    platform: .ubuntu
)!

recipe.add_package(name: 'nginx')!
recipe.add_file_embedded(
    source: 'nginx.conf'
    dest: '/etc/nginx/nginx.conf'
)!
recipe.add_expose(ports: ['80/tcp'])!

recipe.build(false)!
```

### Multi-Container Setup
```v
mut composer := engine.compose_new(name: 'webapp')!

// Web service
mut web := composer.service_new
    name: 'web'
    image: 'nginx'
)!
web.port_expose(80, 8080)!

// Database service
mut db := composer.service_new(
    name: 'db'
    image: 'postgres'
)!
db.env_add('POSTGRES_PASSWORD', 'secret')

composer.start()!
```

## Error Handling

The module provides specific error types for common scenarios:

- **ImageGetError**: Image retrieval issues
- **ContainerGetError**: Container access problems

Always handle these errors appropriately in your code:

```v
engine.image_get(
    repo: 'nonexistent'
) or {
    if err is ImageGetError {
        if err.notfound {
            // Handle missing image
        }
    }
    return err
}
