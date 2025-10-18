## Handles real-time synchronization of player state - sends their physical data
## like position and rotation every frame.
extends Node



## Stores the most recent input data for each player.
## Key:   playerId,
## Value: input Dictionary
var latestInputByPlayer:Dictionary = {}

## Stores the most recent input data for each player.
## Key:   playerId,
## Value: rotation Vector3
var latestRotationForPlayer:Dictionary = {}

## Stores the most recent input tick for each player.
## Key:   playerId,
## Value: tick int
var latestInputTickByPlayer:Dictionary = {}



####################################################################################################
#region REQUESTS


## Send a snapshot of the entire world to each player. Called by GameStateManager
## every physics tick.
func broadcastPlayerState(state:Dictionary):
	c_receivePlayerStates.rpc_id(0, state)


#endregion
####################################################################################################



####################################################################################################
#region RPCS


## Recieve the input of each player on a given frame, in order to calculate the
## movement of each player this frame.
##
## This function checks whether the input is the newest we have from a given
## player, and only if so, will add it to the playerinput dictionary.
##
## Each frame, the character nodes check the dictionary, use it for their
## movement, and then update the player states to be sent back to all clients.
## This means that, in the case of delays between packets, the most recent
## player input is replicated, as in "assume player holds down inputs for a long
## time" and "assume they don't start doing anything in the meantime", which is
## correct most of the time.
@rpc("any_peer")
func s_recievePlayerInput(packet:Dictionary):
	var playerId:int = multiplayer.get_remote_sender_id()
	var inputTick:int = packet.t # Packet Time information
	
	# If we already have a more recent tick for this player, ignore this input.
	if latestInputTickByPlayer.has(playerId):
		if inputTick <= latestInputTickByPlayer[playerId]:
			return
	
	# Otherwise, store the new input and tick.
	latestInputByPlayer[playerId]     = packet.i # Packet Input information
	latestRotationForPlayer[playerId] = packet.r # Packet Rotation information
	latestInputTickByPlayer[playerId] = inputTick



#endregion
####################################################################################################



####################################################################################################
#region RPC PARITY


@rpc func c_receivePlayerStates(state:Dictionary): pass


#endregion
####################################################################################################
