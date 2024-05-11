extends Sprite2D

var current_rotation_deg = 0.0
var lerp_speed = 10
var min_rotation_deg = -50.0
var max_rotation_deg = 304.0

var speed

func _process(delta):
	var speed = $"../../..".speed
	update_speedometer(speed, delta)

func update_speedometer(speed, delta):
	var max_speed = 260
	var target_rotation = min_rotation_deg + (speed / max_speed) * (max_rotation_deg - min_rotation_deg)

	target_rotation = clamp(target_rotation, min_rotation_deg, max_rotation_deg)
	var correction_factor = 10
	target_rotation -= correction_factor
	
	current_rotation_deg = lerp(current_rotation_deg, target_rotation, lerp_speed * delta)
	
	rotation_degrees = current_rotation_deg
