# **WebDAV Server in V**

This project implements a WebDAV server using the `vweb` framework and modules from `crystallib`. The server supports essential WebDAV file operations such as reading, writing, copying, moving, and deleting files and directories. It also includes **authentication** and **request logging** for better control and debugging.

---

## **Features**

- **File Operations**:  
   Supports standard WebDAV methods: `GET`, `PUT`, `DELETE`, `COPY`, `MOVE`, and `MKCOL` (create directory) for files and directories.
- **Authentication**:  
   Basic HTTP authentication using an in-memory user database (`username:password`).
- **Request Logging**:  
   Logs incoming requests for debugging and monitoring purposes.
- **WebDAV Compliance**:  
   Implements WebDAV HTTP methods with proper responses to ensure compatibility with WebDAV clients.
- **Customizable Middleware**:  
   Extend or modify middleware for custom logging, authentication, or request handling.

---

## **Usage**

### Running the Server

```v
module main

import freeflowuniverse.crystallib.vfs.webdav

fn main() {
	mut app := webdav.new_app(
		root_dir: '/tmp/rootdir' // Directory to serve via WebDAV
		user_db: {
			'admin': 'admin' // Username and password for authentication
		}
	)!

	app.run()
}
```

### **Mounting the Server**

Once the server is running, you can mount it as a WebDAV volume:

```bash
sudo mount -t davfs <server_url> <mount_point>
```

For example:
```bash
sudo mount -t davfs http://localhost:8080 /mnt/webdav
```

**Important Note**:  
Ensure the `root_dir` is **not the same as the mount point** to avoid performance issues during operations like `ls`.

---

## **Supported Routes**

| **Method** | **Route**    | **Description**                                          |
|------------|--------------|----------------------------------------------------------|
| `GET`      | `/:path...`  | Retrieves the contents of a file.                        |
| `PUT`      | `/:path...`  | Creates a new file or updates an existing one.           |
| `DELETE`   | `/:path...`  | Deletes a file or directory.                             |
| `COPY`     | `/:path...`  | Copies a file or directory to a new location.            |
| `MOVE`     | `/:path...`  | Moves a file or directory to a new location.             |
| `MKCOL`    | `/:path...`  | Creates a new directory.                                 |
| `OPTIONS`  | `/:path...`  | Lists supported WebDAV methods.                          |
| `PROPFIND` | `/:path...`  | Retrieves properties (e.g., size, date) of a file or directory. |

---

## **Authentication**

This WebDAV server uses **Basic Authentication**.  
Set the `Authorization` header in your client to include your credentials in base64 format:

```http
Authorization: Basic <base64-encoded-credentials>
```

**Example**:  
For the credentials `admin:admin`, the header would look like this:
```http
Authorization: Basic YWRtaW46YWRtaW4=
```

---

## **Configuration**

You can configure the WebDAV server using the following parameters when calling `new_app`:

| **Parameter**   | **Type**          | **Description**                                               |
|-----------------|-------------------|---------------------------------------------------------------|
| `root_dir`      | `string`          | Root directory to serve files from.                           |
| `user_db`       | `map[string]string` | A map containing usernames as keys and passwords as values.   |
| `port` (optional) | `int`           | The port on which the server will run. Defaults to `8080`.    |

---

## **Example Workflow**

1. Start the server:
   ```bash
   v run webdav_server.v
   ```

2. Mount the server using `davfs`:
   ```bash
   sudo mount -t davfs http://localhost:8080 /mnt/webdav
   ```

3. Perform operations:
   - Create a new file:
     ```bash
     echo "Hello WebDAV!" > /mnt/webdav/hello.txt
     ```
   - List files:
     ```bash
     ls /mnt/webdav
     ```
   - Delete a file:
     ```bash
     rm /mnt/webdav/hello.txt
     ```

4. Check server logs for incoming requests and responses.

---

## **Performance Notes**

- Avoid mounting the WebDAV server directly into its own root directory (`root_dir`), as this can cause significant slowdowns for file operations like `ls`.  
- Use tools like `cadaver`, `curl`, or `davfs` for interacting with the WebDAV server.

---

## **Dependencies**

- V Programming Language
- Crystallib VFS Module (for WebDAV support)

---

## **Future Enhancements**

- Support for advanced WebDAV methods like `LOCK` and `UNLOCK`.
- Integration with persistent databases for user credentials.
- TLS/SSL support for secure connections.
