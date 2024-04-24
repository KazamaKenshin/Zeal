extends RigidBody3D

var speed = 10  # Adjust as needed
@onready var ai_lane = $"../RoadManager/RoadContainer"  # Reference to the AI lane the vehicle should follow

func _physics_process(delta):
	if ai_lane:
		# Move the vehicle along the AI lane
		move_along_lane(delta)

func move_along_lane(delta):
	# Calculate the direction in which the vehicle should move
	var direction = (ai_lane.get_lane_end() - ai_lane.get_lane_start()).normalized()
	var velocity = direction * speed

	# Move the vehicle along the lane
	var new_position = position + velocity * delta


	# Optionally, adjust the vehicle's rotation to match the lane's orientation
	# based on the lane's tangent or normal vectors
	# Example:
	# var tangent = (ai_lane.get_lane_end() - ai_lane.get_lane_start()).normalized()
	# var rotation = Basis(tangent, Vector3.UP)
	# set_global_transform(Transform(rotation, new_position))
