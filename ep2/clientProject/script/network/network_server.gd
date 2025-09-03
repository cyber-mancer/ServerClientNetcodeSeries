extends Node

# The port for the client to connect on. (pick something between 10,000 and 40,000)
@export var port = 11909


## Returns a bool representing whether the client is currently connected to the
## server.
var isConnected:bool:
	get:
		var value:int = multiplayer.multiplayer_peer.get_connection_status()
		var ok:int = MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED
		return value == ok


## Updated on peer connected (connected to the server and obtained a client ID)
var ownId:int = -1


var network := ENetMultiplayerPeer.new()


################################################################################
#region LOGIC



func _ready() -> void:
	connectToIp("localhost")



func connectToIp(atIp:String):
	# Initialize the network
	network.create_client(atIp, port)
	
	# Set the multiplayer peer. Now, the scene tree's default
	# "multiplayer" (and, by proxy, the multiplayer variable for
	# all nodes in the scene tree) will refer to the one that we
	# have created.
	multiplayer.multiplayer_peer = network
	
	print("Client: Activated multiplayer instance.")
	
	# Connect network events to our own functions, so that we can give custom behavior,
	# including printing information about connections, to the network variable.
	network.connect("peer_connected", _peerConnected)
	network.connect("peer_disconnected", _peerDisconnected)



func _peerConnected(peerId:int):
	print("Client: Connected to server.")
	
	# Update the id as soon as one exists.
	ownId = multiplayer.get_unique_id()
	
	# Initial ping + begin clock synchronization.
	NetworkClock.requestPing()
	NetworkClock.setupPingTimer()



func _peerDisconnected(peerId:int):
	print("Client: Disconnected from server.")


#endregion 
################################################################################
