extends Node3D

var direction = Vector3.FORWARD
@export_range(1, 10, 0.1) var smooth_speed = 2.0
var new_fov_throttle = 100.0

@export var default_fov = 30.0
var current_fov = 30.0
var current_basis: Basis = Basis()

@export var blur_iteration = 10.0
@export var blur_intensity = 0.005
@export var blur_start_rad = 0.0

@onready var motion_blur = preload("res://assets/motion_blur/blur_material.tres")
@export var period = 0.01
@export var magnitude = 0.0

var initial_transform
var shake_offset = Vector3.ZERO

func _camera_shake():
	var elapsed_time = 0.0

	while elapsed_time < period:
		shake_offset = Vector3(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude),
			0.0
		)

		self.transform.origin = initial_transform.origin + shake_offset
		elapsed_time += get_process_delta_time()
		await get_tree().process_frame

	shake_offset = Vector3.ZERO
	self.transform.origin = initial_transform.origin

func _ready():
	initial_transform = self.transform
	$Camera.fov = default_fov
	current_basis = Basis()

func _physics_process(delta):
	var current_velocity = get_parent().get_linear_velocity()

	if current_velocity.length_squared() > 1:
		var direction_no_x = Vector3(current_velocity.x, current_velocity.y, current_velocity.z).normalized()
		direction = direction.lerp(-direction_no_x, smooth_speed * delta)
		var rotation_direction = direction.lerp(-direction_no_x, 1)
		var rpm = $"..".rpm
		var max_rpm = $"..".max_rpm
		var idle_rpm = $"..".idle_rpm
		var rpm_percentage = (rpm - idle_rpm) / (max_rpm - idle_rpm)
		current_fov = lerp(current_fov, default_fov + (new_fov_throttle - default_fov) * rpm_percentage, smooth_speed * delta)
		
		global_transform.basis = get_rotation_from_direction(rotation_direction, delta, smooth_speed)
	else:
		self.transform = initial_transform

	magnitude = 0.0005 * current_velocity.length()
	$Camera.fov = current_fov
	set_shader_parameter()
	_camera_shake()

func get_rotation_from_direction(look_direction: Vector3, delta: float, smoothing_factor: float) -> Basis:
	look_direction = look_direction.normalized()
	var x_axis = look_direction.cross(Vector3.UP).normalized()
	var y_axis = x_axis.cross(look_direction).normalized()
	var target_basis = Basis(x_axis, y_axis, -look_direction)

	current_basis = current_basis.slerp(target_basis, delta * smoothing_factor)
	return current_basis

func set_shader_parameter():
	motion_blur.set_shader_parameter("iteration_count", blur_iteration)
	motion_blur.set_shader_parameter("intensity", blur_intensity)
