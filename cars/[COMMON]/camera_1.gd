extends Node3D

var direction = Vector3.FORWARD
@export_range(1, 10, 0.1) var smooth_speed = 0.1
var new_fov_throttle = 100.0

@export var default_fov = 38.0
var current_fov = 38.0

@export var blur_iteration = 50.0
@export var blur_intensity = 0.01
@export var blur_start_rad = 0.0

@onready var motion_blur = preload("res://assets/motion_blur/blur_material.tres")
@export var period = 0.01
@export var magnitude = 0.0

var initial_transform

func _camera_shake():
	var initial_transform = self.transform 
	var elapsed_time = 0.0

	while elapsed_time < period:
		var offset = Vector3(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude),
			0.0
		)

		self.transform.origin = initial_transform.origin + offset
		elapsed_time += get_process_delta_time()
		await get_tree().process_frame

	self.transform = initial_transform
	
func _ready():
	initial_transform = self.transform
	$Camera.fov = default_fov

func _physics_process(delta):
	var current_velocity = get_parent().get_linear_velocity()

	if current_velocity.length_squared() > 1:
		var direction_no_x = Vector3(current_velocity.x, 0, current_velocity.z).normalized()
		direction = lerp(direction, -direction_no_x, smooth_speed * delta)
		var rotation_direction = lerp(direction, -direction_no_x, 1)
		var rpm = $"..".rpm
		var max_rpm = $"..".max_rpm
		var idle_rpm = $"..".idle_rpm
		var rpm_percentage = (rpm - idle_rpm) / (max_rpm - idle_rpm)
		current_fov = lerp(current_fov, default_fov + (new_fov_throttle - default_fov) * rpm_percentage, smooth_speed * delta)
		
		global_transform.basis = get_rotation_from_direction(rotation_direction)
	else:
		# Restore the initial camera transform when speed is below the threshold
		self.transform = initial_transform

	magnitude = 0.0005 * current_velocity.length()
	$Camera.fov = current_fov
	set_shader_parameter()
	_camera_shake()

func get_rotation_from_direction(look_direction: Vector3) -> Basis:
	look_direction = look_direction.normalized()
	var x_axis = look_direction.cross(Vector3.UP)
	return Basis(x_axis, Vector3.UP, -look_direction)

func set_shader_parameter():
	motion_blur.set_shader_parameter("iteration_count", blur_iteration)
	motion_blur.set_shader_parameter("intensity", blur_intensity)
