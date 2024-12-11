security add-internet-password -s git.ourworld.tf -a despiegk -w mypassword

-s: The server (e.g., git.ourworld.tf).
-a: The account or username (e.g., despiegk).
-w: The password (e.g., mypassword).


security find-internet-password -s git.ourworld.tf -w


security delete-internet-password -s git.ourworld.tf



git config --global credential.helper osxkeychain


