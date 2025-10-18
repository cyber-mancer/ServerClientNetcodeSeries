class_name Character extends CharacterBody3D

@export_range(0, 100.0) var gravity:float = 21

# Server will tell us where we SHOULD have been, whenever it sent this data
var mostRecentServerState:Dictionary
var mostRecentServerStateTick:int # The "when"


func _physics_process(delta: float) -> void:
	move(delta)
	sendStateToServer()


## Processes movement input
func move(_delta:float):
	# Use the server's authoritative simulation - ultra simplistic version.
	# TODO: This is where we'll add client-side reconciliation/resimulation.
	if mostRecentServerState:
		# Use server's values, only if populated
		self.global_position = mostRecentServerState.p
		self.velocity = mostRecentServerState.v
	
	
	var inputDir:Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	self.velocity.x = inputDir.x * _delta * 2.0
	self.velocity.z = inputDir.y * _delta * 2.0
	
	# Apply gravity if airborne
	if not self.is_on_floor():
		self.velocity.y -= gravity * _delta
	
	# Spacebar and enter for jumping, for now.
	if Input.is_action_just_pressed("ui_accept") and self.is_on_floor():
		self.velocity.y = 10;
	
	move_and_slide()



## Sends the player's state as a dictionary to the server. Runs in physics loop.
func sendStateToServer():
	var inputDict:Dictionary = {
		"l": Input.is_action_pressed(&"ui_left"),
		"r": Input.is_action_pressed(&"ui_right"),
		"f": Input.is_action_pressed(&"ui_up"), # Forward
		"b": Input.is_action_pressed(&"ui_down"), # Back
		"j": Input.is_action_pressed(&"ui_accept") # Jump
	}
	
	#print("size of input: ", var_to_bytes(self.inputThisFrame).size())
	
	# TODO: Use put_packet() to reduce byte count
	NetworkPlayerState.sendPlayerInput({
		# Record the time at which this information was sent, in order to 
		# replicate accurately on the server.
		"t": NetworkClock.clientTick,
		
		# Input data itself
		"i": inputDict,
		
		# Rotation data. Don't bother sending rotation "input" as it would simply be a Vector2 mouse delta, and the player could, in theory, send any rotation (instantaneous flick) - unlike position, where sending a position on the other side of the map is clearly cheating.
		"r": $Camera3D.global_rotation, 
	})
