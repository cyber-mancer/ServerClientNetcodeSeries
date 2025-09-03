## NOTE
##
## 1. this tutorial is for multiplayer within godot, but it
##    is NOT a "godot tutorial"
##
## 2. this tutorial is for a "shooter" game - 2-20 person lobbies
##
## 3. this series will cover:
##    - building a very simple 3D scene
##    - the fundamental things to understand about the way godot
##      handles multiplayer
##    - creating a client-server setup in TWO PROJECTS
##    - writing clean and expandable netcode
##
## 4. this series will NOT cover:
##    - building an entire game from start to finish
##    - godot basics
##    - higher-level network architecture:
##      matchmaking, server chunking, creating user accounts, security, etc.
##    - for more information about network architecture, check the link
##      in the description.


## (Pause if you have never used the Remote tab before!
## It has nothing to do with multiplayer or networking.
## It shows the scene tree as it appears when running,
## all the way up to the root level, which is the game
## window. This view does not show server-side info,
## only the current organization of the project. This
## helps demonstrate how RPC node paths actually work.
