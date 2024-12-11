# WebDAV Server in V

This project implements a WebDAV server, using the `vweb` framework and modules from `crystallib`. This server allows basic file operations such as reading, writing, copying, moving, and deleting files and directories, with support for authentication and request logging.

## Features

- **File Operations**: Supports `GET`, `PUT`, `DELETE`, `COPY`, `MOVE`, and `MKCOL` (create directory) operations on files and directories.
- **Authentication**: Basic authentication with credentials stored in memory (`username:password`).
- **Logging**: Logs incoming requests for debugging and tracking purposes.
- **WebDAV Compliance**: Implements common WebDAV HTTP methods with responses formatted as required by WebDAV clients.
- **Customizable Middleware**: Custom middleware for authentication and logging.

## Usage

### Routes

| Method    | Route         | Description                                             |
|-----------|---------------|---------------------------------------------------------|
| GET       | `/:path...`   | Retrieves a file's contents.                            |
| PUT       | `/:path...`   | Creates or updates a file.                              |
| DELETE    | `/:path...`   | Deletes a file or directory.                            |
| COPY      | `/:path...`   | Copies a file or directory to a new location.           |
| MOVE      | `/:path...`   | Moves a file or directory to a new location.            |
| MKCOL     | `/:path...`   | Creates a new directory.                                |
| OPTIONS   | `/:path...`   | Lists supported WebDAV methods.                         |
| PROPFIND  | `/:path...`   | Retrieves properties of a file or directory.            |

### Authentication

The server uses basic authentication. Set the `Authorization` header to `Basic <base64-encoded-credentials>`.

## Configuration

- **Root Directory**: Specify the root directory for WebDAV operations by calling `new_app(root_dir: root_path)`.
- **User Credentials**: Specify the credentials for WebDAV operations by calling `new_app(username: <username>, password: <password>)`.
