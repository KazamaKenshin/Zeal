extends Node3D

var direction = Vector3.FORWARD
@export_range(1, 10, 0.1) var smooth_speed = 0.5

@export var default_fov = 38.0
var new_fov_throttle = 85.0
var new_fov_brake = 25.0
var new_fov = 0.0
@export var blur_iteration = 5.0
@export var blur_intensity = 0.1
@export var blur_start_rad = 0.5

@onready var motion_blur = preload ("res://assets/motion_blur/blur_material.tres")

func _ready():
	$Camera.fov = default_fov

func _physics_process(delta):
	var current_velocity = get_parent().get_linear_velocity()

	if current_velocity.length_squared() > 1:
		var direction_no_x = Vector3(current_velocity.x, 0, current_velocity.z).normalized()
		direction = lerp(direction, -direction_no_x, smooth_speed * delta)
		var rotation_direction = lerp(direction, -direction_no_x, 1)
		if get_parent().throttle_val != 0:
			new_fov = lerp(new_fov, new_fov_throttle, smooth_speed * delta)
		elif get_parent().brake_val != 0:
			new_fov = lerp(new_fov, new_fov_brake, smooth_speed * delta)
		else:
			new_fov = lerp(new_fov, default_fov, smooth_speed * delta)
		global_transform.basis = get_rotation_from_direction(rotation_direction)
	blur_intensity = 0.0001 * current_velocity.length()
	$Camera.fov = new_fov
	set_shader_parameter()


func get_rotation_from_direction(look_direction: Vector3) -> Basis:
	look_direction = look_direction.normalized()
	var x_axis = look_direction.cross(Vector3.UP)
	return Basis(x_axis, Vector3.UP, -look_direction)

func set_shader_parameter():
	motion_blur.set_shader_parameter("iteration_count", blur_iteration)
	motion_blur.set_shader_parameter("intensity", blur_intensity)
