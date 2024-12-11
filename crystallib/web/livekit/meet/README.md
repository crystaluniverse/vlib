# LiveKit Meet

V implementation of livekit meet. This server handles the backend of livekit meet, and serves prebuilt front end from a v web server. 

The templates and static assets in this repo are thus overwritten frequently. The recommended approach is to use the build script in the original repository to make changes to the app. The app, when run, automatically downloads latest pushed templates from the github pages of livekit_meet, which we use sort of like a cdn for the purpose of this project. Note: after updateing templates by rebuilding and pushing original react app, this app must be run twice (first one fetches templates, second one compiles with updated templates)

## Example

`~/code/github/freeflowuniverse/crystallib/examples/webserver/livekit/meet_example.vsh`