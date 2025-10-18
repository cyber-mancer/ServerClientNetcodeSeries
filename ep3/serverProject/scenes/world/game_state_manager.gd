class_name GameStateManager extends Node3D

## Private state dictionary
var _allCharacters:Dictionary
## Public (typed) getter
func getCharacter(id:int) -> Character:
	if not _allCharacters.has(id):
		print("ERROR: GameStateManager: Invalid character ID: " + str(id))
	return _allCharacters[id]
## Returns typed array
func getAllCharacters() -> Array[Character]:
	return _allCharacters.values() as Array[Character]

@export var characterScene:PackedScene


func _ready() -> void:
	NetworkServer.gameStateManager = self


## Game update loop. Synchronizes player states with the network, allowing
## constant replication.
func _physics_process(delta: float) -> void:
	if not NetworkServer.isConnected: return # Must have clients connected.
	
	var playerStatesDict := buildPlayerStatesDict()
	
	NetworkPlayerState.broadcastPlayerState(playerStatesDict)


## Gets all player positions and rotations to send to the network player state
## synchronizer, for broadcasting to all clients.
func buildPlayerStatesDict() -> Dictionary:
	var result:Dictionary
	
	# Time data
	result.t = NetworkClock.serverTick
	
	# Player data
	result.p = {}
	
	# For each player, load their state data into the dictionary.
	for playerId:int in _allCharacters.keys():
		var characterNode:Character = getCharacter(playerId)
		
		var thisPlayerInfoDict:Dictionary = {}
		
		# Position, rotation, and velocity properties.
		thisPlayerInfoDict.p = characterNode.global_position
		thisPlayerInfoDict.r = characterNode.cameraNode.global_rotation
		thisPlayerInfoDict.v = characterNode.velocity
		
		result.p[playerId] = thisPlayerInfoDict
	
	return result


func spawnPlayers():
	for playerId:int in NetworkServer.connectedClients:
		spawnNewCharacter(playerId)



func spawnNewCharacter(
	playerId:int,
):
	# Don't create character if it already exists. Should never happen, but just
	# in case.
	if _hasCharacterNode(playerId): return
	
	var newCharacter:Character = characterScene.instantiate()
	
	# Set up character initial values.
	newCharacter.name          = str(playerId)
	newCharacter.global_position = Vector3(
		randf_range(-5, 5),
		2,
		randf_range(-5, 5)
	)
	
	# Add to world and keep track of them all in array.
	%Characters.add_child(newCharacter, true)
	_allCharacters[playerId] = newCharacter



func despawnCharacter(playerId:int):
	if not _hasCharacterNode(playerId): return
	
	%Characters.get_node(str(playerId)).queue_free()
	
	_allCharacters.erase(playerId)




func _hasCharacterNode(byId:int) -> bool:
	var result:bool = %Characters.has_node(str(byId))
	return result

func _getCharacterNode(byId:int) -> Character:
	return %Characters.get_node(str(byId))
