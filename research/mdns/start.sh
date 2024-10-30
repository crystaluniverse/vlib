#!/bin/bash


# Define the tmux session name
SESSION_NAME="mdns_test"

cd ~/code/github/freeflowuniverse/crystallib/research/mdns

# Define paths for the client and server scripts
CLIENT_SCRIPT="multi_client.vsh"
SERVER_SCRIPT="multi_server.vsh"

# Kill the previous session if it exists
tmux kill-session -t $SESSION_NAME 2>/dev/null

set -ex

# Start a new tmux session
tmux new-session -d -s $SESSION_NAME

# Split the window into two vertical panes (left and right)
tmux split-window -h

# Select the left pane and run the client script
tmux select-pane -t 0
tmux send-keys "cd $(dirname $CLIENT_SCRIPT) && ./$(basename $CLIENT_SCRIPT)" C-m

# Select the right pane and run the server script
tmux select-pane -t 1
tmux send-keys "cd $(dirname $SERVER_SCRIPT) && ./$(basename $SERVER_SCRIPT)" C-m

# Attach to the tmux session
tmux attach -t $SESSION_NAME
