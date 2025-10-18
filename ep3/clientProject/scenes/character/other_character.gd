class_name OtherCharacter extends CharacterBody3D

@export_range(0, 100.0) var gravity:float = 21

func _physics_process(delta: float) -> void:
	# Move and slide via the velocity that comes from the server every tick.
	# This way, even between frames (and between state updates, if the network
	# is bad), the other characters will still appear to move smooth.
	
	# Also don't forget to update vertical velocity (the only acceleration we can guarantee)
	fall(delta)
	move_and_slide()



## Apply gravity if not on the floor (which is the only acceleration that will
## be applied to other characters, in the absence of a more recent state update).
func fall(delta:float):
	if self.is_on_floor(): return
	
	self.velocity.y -= self.gravity * delta


func updateState(
	thisPlayerPos:Vector3,
	thisPlayerRot:Vector3,
	thisPlayerVel:Vector3
):
	self.global_position   = thisPlayerPos
	# Only sync Y rotation because pitch (x) is only for camera, and
	# roll (z) usually doesn't happen at all.
	self.global_rotation.y = thisPlayerRot.y
	self.velocity          = thisPlayerVel
