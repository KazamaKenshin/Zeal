extends Sprite2D

@export var min_rotation_deg = -62.0
@export var max_rotation_deg = 113.0

var current_rotation_deg = 0.0
var lerp_speed = 5.0

func _process(delta):
	var rpm = $"../../..".rpm
	update_rev_counter(rpm, delta)

func update_rev_counter(target_rpm: float, delta: float):
	var max_rpm = 7200.0
	var target_rotation = min_rotation_deg + (target_rpm / max_rpm) * (max_rotation_deg - min_rotation_deg)

	target_rotation = clamp(target_rotation, min_rotation_deg, max_rotation_deg)
	var correction_factor = 2.8
	target_rotation -= correction_factor

	current_rotation_deg = lerp(current_rotation_deg, target_rotation, lerp_speed * delta)
	
	rotation_degrees = current_rotation_deg
