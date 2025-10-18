## Handles real-time synchronization of player state - sends their physical data
## like position and rotation every frame.
extends Node


var gameStateManager:GameStateManager


####################################################################################################
#region REQUESTS


# If the client is connected to the server, send the state.
func sendPlayerInput(input:Dictionary):
	if not NetworkServer.isConnected: return
	
	s_recievePlayerInput.rpc_id(1, input)


#endregion 
####################################################################################################



####################################################################################################
#region RPCS


# Recieves data about all the player positions every frame, to be parsed and then affect
# this client's world state in the appropriate synchronized way.
@rpc func c_receivePlayerStates(state:Dictionary):
	
	#print(
		#"Client: Server time: ", state.t,
		#", client time: ", NetworkClock.clientTick,
		#" (packet took ", NetworkClock.clientTick-state.t, " ticks to arrive)"
	#)
	
	gameStateManager.receivePlayerStates(state)


#endregion 
####################################################################################################



####################################################################################################
#region RPC PARITY


@rpc("any_peer") # Default unreliable, since this is an every-frame update.
func s_recievePlayerInput(state:Dictionary): pass


#endregion 
####################################################################################################
