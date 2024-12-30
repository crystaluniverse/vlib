# OpenAPI Server with Redis-Based RPC and Actor

This project demonstrates how to implement a system consisting of:
	1.	An OpenAPI Server: Handles HTTP requests and translates them into procedure calls.
	2.	A Redis-Based RPC Processor: Acts as the communication layer between the server and the actor.
	3.	An Actor: Listens for RPC requests on a Redis queue and executes predefined procedures.

## Features
	•	OpenAPI server to manage HTTP requests.
	•	Redis-based RPC mechanism for message passing.
	•	Actor pattern for executing and responding to RPC tasks.

## Setup Instructions

Prerequisites
	•	Redis installed and running on localhost:6379.
	•	V programming language installed.

Steps to Run

1. OpenAPI Specification

Place the OpenAPI JSON specification file at:

`data/openapi.json`

This file defines the API endpoints and their parameters.

2. Start the Redis Server

Ensure Redis is running locally:

redis-server

3. Start the OpenAPI Server

Run the OpenAPI server:

`server.vsh`

The server listens on port 8080 by default.

4. Start the Actor

Run the actor service:

`actor.vsh`

The actor listens to the procedure_queue for RPC messages.

Usage

API Endpoints

The API supports operations like:
	•	Create a Pet: Adds a new pet.
	•	List Pets: Lists all pets or limits results.
	•	Get Pet by ID: Fetches a specific pet by ID.
	•	Delete Pet: Removes a pet by ID.
	•	Similar operations for users and orders.

Use tools like curl, Postman, or a browser to interact with the endpoints.

Example Requests

Create a Pet

curl -X POST http://localhost:8080/pets -d '{"name": "Buddy", "tag": "dog"}' -H "Content-Type: application/json"

List Pets

curl http://localhost:8080/pets

## Code Overview

1. OpenAPI Server
	•	Reads the OpenAPI JSON file.
	•	Maps HTTP requests to procedure calls using the operation ID.
	•	Sends procedure calls to the Redis RPC queue.

2. Redis-Based RPC
	•	Implements a simple message queue using Redis.
	•	Encodes requests as JSON strings for transport.

3. Actor
	•	Listens to the procedure_queue Redis queue.
	•	Executes tasks like managing pets, orders, and users.
	•	Responds with JSON-encoded results or errors.

## Extending the System

Add New Procedures
	1.	Define new methods in the Actor to handle tasks.
	2.	Add corresponding logic in the DataStore for storage operations.
	3.	Update the OpenAPI JSON file to expose new endpoints.

Modify Data Models
	1.	Update the Pet, Order, and User structs as needed.
	2.	Adjust the DataStore methods to handle the changes.

Troubleshooting
	•	Redis Connection Issues: Ensure Redis is running and accessible on localhost:6379.
	•	JSON Parsing Errors: Validate the input JSON against the OpenAPI specification.
