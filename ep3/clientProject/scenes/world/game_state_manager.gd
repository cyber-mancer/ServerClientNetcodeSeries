class_name GameStateManager extends Node3D


## The character node for this client.
@onready var character:Character = %Character
@onready var otherCharacterHolder:Node3D = $OtherCharacters

@export var otherCharacterScene:PackedScene

## List of all other characters than this client's player.
var allOtherCharacters:Array[OtherCharacter]

## The clock time at which the most recent time was received - if a new one is
## received with a timestamp older than this, ignore it.
var mostRecentWorldStateTick:int = 0


func _ready() -> void:
	NetworkPlayerState.gameStateManager = self


## Called from the network updates.
func receivePlayerStates(state:Dictionary):
	if state.p.is_empty(): return
	
	# If the new state is older than the previous one (packets arrived in the
	# wrong order), do not use it.
	if state.t < mostRecentWorldStateTick: return
	
	# This state is now the most recent one (so, ignore any that arrive later that have an earlier timestamp).
	mostRecentWorldStateTick = state.t
	
	
	# For this player's authoritative state, just hand it off to the player's
	# movement handler - it will handle rubberbanding.
	# TODO: We will make this more robust next episode!
	var ownState:Dictionary = state.p[NetworkServer.ownId]
	character.mostRecentServerState = ownState
	character.mostRecentServerStateTick = mostRecentWorldStateTick
	
	# Already processed; don't use this for updates to the other characters.
	state.p.erase(NetworkServer.ownId)
	
	
	# Update the states for all characters (other than this one).
	for playerStateId:int in state.p.keys():
		# String of the ID of the player, and the name of the character node in the scene tree
		var playerName:String = str(playerStateId)
		
		var thisPlayerState:Dictionary = state.p[playerStateId]
		
		# Get the player Position and player Rotation, and their velocity for interpolation.
		var thisPlayerPos:Vector3 = thisPlayerState.p
		var thisPlayerRot:Vector3 = thisPlayerState.r
		var thisPlayerVel:Vector3 = thisPlayerState.v
		
		
		# If the player already exists, move it
		if _hasOtherCharacterNode(playerStateId):
			# Will be a CharacterTemplate (hopefully x)
			_getOtherCharacterNode(playerStateId).updateState(
				thisPlayerPos,
				thisPlayerRot,
				thisPlayerVel
			)
		
		# If the player does NOT yet exist, create it, and then it will be moved
		# to its position on the next frame.
		# In many types of games (shooters, racing games, etc), this should
		# never happen, but depending on the type of game (mmo, party game),
		# players may join in the middle of the game, and we want to update
		# them with their data right away (but you may have other logic).
		else:
			print("Client: Spawning new player.")
			
			spawnNewCharacter(playerStateId)


## Creates a new character node and adds it to the scene tree.
func spawnNewCharacter(playerId:int):
	# Don't spawn THIS character on this client, since it should already be present ("main" character).
	if playerId == NetworkServer.ownId: return
	
	# If there's already a player there, don't add it to the list. This could
	# happen in the rare scenario in which the player is spawned in by the update 
	# state call, and then this function is called later because of net delays.
	if _hasOtherCharacterNode(playerId): return
	
	var newPlayer:OtherCharacter = otherCharacterScene.instantiate()
	
	# Store in dictionary
	allOtherCharacters.append(newPlayer)
	
	# Name the node for easy access from scene tree (in addition to being in the dictionary)
	newPlayer.name = str(playerId)
	
	otherCharacterHolder.add_child(newPlayer, true)



func _hasOtherCharacterNode(byId:int) -> bool:
	var result:bool = otherCharacterHolder.has_node(str(byId))
	return result

func _getOtherCharacterNode(byId:int) -> OtherCharacter:
	return otherCharacterHolder.get_node(str(byId))
