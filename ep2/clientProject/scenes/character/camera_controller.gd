extends Camera3D

@export var defaultFov:float = 100.0

@export_range(0.01, 1) var mouseSensitivity:float = 0.1

# Rotation variables
var yaw:float   = 0.0
var pitch:float = 0.0

# Change (in px) in looking angle, this frame
var lookedThisFrame:Vector2 = Vector2.ZERO

# Function to handle input
func _input(event:InputEvent):
	
	# If the player moved the mouse
	if event is InputEventMouseMotion:
		
		lookedThisFrame = event.relative
		
		# Update the looking angle
		yaw   -= lookedThisFrame.x * mouseSensitivity
		pitch -= lookedThisFrame.y * mouseSensitivity
		pitch = clamp(pitch, -89.9, 89.9)
		
		# Rotate the whole player around
		self.get_parent().rotation_degrees.y = yaw
		# Only rotate the camera up and down
		self.rotation_degrees.x = pitch
