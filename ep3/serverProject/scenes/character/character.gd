class_name Character extends CharacterBody3D

@onready var cameraNode:Node3D = $Camera3D

@export_range(0, 100.0) var gravity:float = 21

## Checks the most recent player info dictionary. Used by items when they need
## to know current player input state.
var inputThisFrame:Dictionary:
	get: return NetworkPlayerState.latestInputByPlayer[self.id] # Assume exists (perhaps risky)

var rotationThisFrame:Vector3:
	get: return NetworkPlayerState.latestRotationForPlayer[self.id]

var id:int:
	get: return int(self.name)

func _physics_process(delta: float):
	if not NetworkPlayerState.latestInputByPlayer.has(self.id): return
	
	# Process movement, given the input data stored in NetworkPlayerState, and
	# use the same client inputs to rotate the camera and this character node.
	move(delta)
	updateCameraRotation()

## Processes movement input
func move(_delta:float):
	var inputDir:Vector2 = getVector()
	# Will improve this system next episode.
	var isJumping:bool = self.inputThisFrame.j
	
	self.velocity.x = inputDir.x * _delta * 60.0
	self.velocity.z = inputDir.y * _delta * 60.0
	
	# Apply gravity if airborne
	if not self.is_on_floor():
		self.velocity.y -= gravity * _delta
	
	# Spacebar and enter for jumping, for now.
	if isJumping and self.is_on_floor():
		self.velocity.y = 10;
	
	move_and_slide()


func updateCameraRotation():
	var newRotation:Vector3 = rotationThisFrame
	
	# Character gets yaw
	self.global_rotation.y = newRotation.y
	
	# Camera gets pitch
	cameraNode.global_rotation.x = newRotation.x
	
	# There is no roll, of course.



## Emulates Input.get_vector() on the server, based on the most-recent stored value that NetworkPlayerState received.
func getVector() -> Vector2:
	var result:Vector2 = Vector2.ZERO

	# Lateral movement: left is -1, right is +1
	if self.inputThisFrame.get(&"l"): result.x -= 1
	if self.inputThisFrame.get(&"r"): result.x += 1
	
	# Foreward/backward movement: forward is -1, back is +1
	if self.inputThisFrame.get(&"f"): result.y -= 1 
	if self.inputThisFrame.get(&"b"): result.y += 1
	
	# Normalize the result so diagonal movement isn't faster
	return result.normalized()
