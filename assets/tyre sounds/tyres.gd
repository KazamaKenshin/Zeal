extends Node3D

var skidding = false

func _physics_process(delta):
	if skidding:
		for child in get_children():
			child.playing = true
			# Calculate the distance between the child and the parent node
			var distance = global_transform.origin.distance_to(child.global_transform.origin)
			var volume = 0.5 - clamp(distance / 10.0, 0.0, 1.0)
			child.volume_db = linear_to_db(volume * child.max_db)
	else:
		for child in get_children():
			child.playing = false
