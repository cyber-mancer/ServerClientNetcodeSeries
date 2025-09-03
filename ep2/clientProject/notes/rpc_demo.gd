extends Node


## Default values.
##  ("mode",      "sync",        "transfer_mode")
@rpc("authority", "call_remote", "unreliable")
func nothing(): pass



## NOTE: Almost all functions on the client should have this mode (see last
##       function in this list).
@rpc("reliable") func client_from_server_only():
	pass


## "rpc("any_peer")" allows any peer to call this function on any other
## peer.
## NOTE: Client functions should NEVER be any_peer (in a client-server
##       system), but ALL server functions should be.
@rpc("any_peer") func server_from_client():
	pass


## NOTE: "rpc" by itself only allows the server to call this function,
## (since the mode is "authority" by default).
## "unreliable" (default) - used for frequently-called functions. "if we lose
## this packet, by the time we figure it out and send it again, a newer one
## will be sent anyway" mentality.
## WARNING: This should only appear on one or two functions across your
##          entire project - every-frame position/input updates, pings, etc.
@rpc func client_from_server_only_never_misses_packets():
	pass
