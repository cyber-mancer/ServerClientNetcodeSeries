## Handles server-level network calls - connecting and disconnecting to clients,
## detecting when enough players are in the lobby, etc.
extends Node

## The port for the server to host on. (pick something between 10,000 and 40,000)
@export var port:int = 11909


## Maximum number of players allowed to connect to this server
## before join requests are denied, and the number of players required to 
## begin a game.
@export var maxPlayers:int = 2


var runningHeadless:bool = false # Set in _ready().


var network = ENetMultiplayerPeer.new()


## Returns a bool representing whether the client is currently connected to the
## server.
var isConnected:bool:
	get:
		var value:int = multiplayer.multiplayer_peer.get_connection_status()
		var ok:int = MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED
		return value == ok



var connectedClients:PackedInt32Array:
	get: return multiplayer.get_peers()

var connectedClientCount:int:
	get: return connectedClients.size()


## Tracks number of players that have clicked "ready up" in the lobby.
var clientReadyCount:int = 0



################################################################################
#region LOGIC


func _ready() -> void:
	startServer()


## SERVER SETUP ################################################################


func startServer():
	print(
		"Server: Starting server on ",
		# Probably finds your IPV4, but may not - if it prints something weird,
		# you can use either the windows command "ipconfig" to find your IPV4,
		# or on linux "ip addr".
		IP.get_local_addresses()[0],
		" : ",
		port
	)
	
	print(
		"Server: Players required for game: ",
		maxPlayers
	)
	
	# Initialize the network
	network.create_server(port, maxPlayers)
	
	# Set the multiplayer peer. Now, the scene tree's default
	# "multiplayer" (and, by proxy, the multiplayer variable for
	# all nodes in the scene tree) will refer to the one that we
	# have created.
	multiplayer.multiplayer_peer = network
	
	
	# Connect network events to our own functions, so that we can give custom behavior,
	# including printing information about connections, to the network variable.
	network.connect("peer_connected", self._peerConnected)
	network.connect("peer_disconnected", self._peerDisconnected)


func _peerConnected(connectedClientId:int):
	
	print(
		"Server: User ",
		str(connectedClientId),
		" connected to lobby (",
		len(connectedClients),
		" online)."
	)
	
	# If the server is finally full
	if len(connectedClients) == maxPlayers:
		print("Server: Game full, switching to lobby screen.")
		# TODO next episode!



func _peerDisconnected(disconnectedClientId:int):
	
	print(
		"Server: User ",
		str(disconnectedClientId),
		" disconnected (",
		len(connectedClients),
		" online)."
	)
	
	# Despawn the player on all clients.
	# TODO next episode!


#endregion
####################################################################################################
