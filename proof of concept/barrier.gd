@tool
extends Path3D

@export var distance_between_pillars: float = 1.0:
	set(value):
		distance_between_pillars = value
		is_dirty = true

@export var distance_between_sides: float = 2.0:
	set(value):
		distance_between_sides= value
		is_dirty = true

@export var generate_left_mesh: bool = true
@export var generate_right_mesh: bool = true

var is_dirty: bool = false
var collision_bodies: Array = []

func _ready():
	pass

func _process(delta):
	if is_dirty:
		_update_multimesh()
		_update_collisions()
		is_dirty = false

func set_distance_between_pillars(value):
	distance_between_pillars = value
	is_dirty = true

func set_distance_between_sides(value):
	distance_between_sides = value
	is_dirty = true

func _update_multimesh():
	var path_length = curve.get_baked_length()
	var count = floor(path_length / distance_between_pillars)
	var mm = $MultiMeshInstance3D.multimesh
	mm.instance_count = count * 2
	var offset = distance_between_pillars / 2.0
	
	for i in range(0, count):
		var curve_distance = offset + distance_between_pillars * i
		var position = curve.sample_baked(curve_distance, true)
		var basis = _get_basis_at_distance(curve_distance)

		if generate_left_mesh:
			var left_position = position - basis.x * (distance_between_sides / 2.0) - basis.z * (distance_between_pillars / 2.0)
			left_position.y = position.y  # Aligning with the Y-coordinate of the position
			var transform1 = Transform3D(basis, left_position)
			mm.set_instance_transform(i * 2, transform1)

		if generate_right_mesh:
			var right_position = position + basis.x * (distance_between_sides / 2.0) - basis.z * (distance_between_pillars / 2.0)
			right_position.y = position.y  # Aligning with the Y-coordinate of the position
			var transform2 = Transform3D(basis.rotated(Vector3(0, 1, 0), PI), right_position)
			mm.set_instance_transform(i * 2 + 1, transform2)



func _update_collisions():
	for body in collision_bodies:
		body.queue_free()
	collision_bodies.clear()

	var path_length = curve.get_baked_length()
	var count = floor(path_length / distance_between_pillars)
	var offset = distance_between_pillars / 2.0

	for i in range(0, count):
		var curve_distance = offset + distance_between_pillars * i
		var position = curve.sample_baked(curve_distance, true)
		var basis = _get_basis_at_distance(curve_distance)

		if generate_left_mesh:
			var left_position = position - basis.x * (distance_between_sides / 2.0)
			var transform1 = Transform3D(basis, left_position)
			_create_collision_body(transform1)

		if generate_right_mesh:
			var right_position = position + basis.x * (distance_between_sides / 2.0)
			var transform2 = Transform3D(basis.rotated(Vector3(0, 1, 0), PI), right_position)
			_create_collision_body(transform2)

func _get_basis_at_distance(curve_distance: float) -> Basis:
	var basis = Basis()
	var up = curve.sample_baked_up_vector(curve_distance, true)
	var forward = curve.sample_baked(curve_distance, true).direction_to(curve.sample_baked(curve_distance + 0.1, true))

	basis.y = up
	basis.x = forward.cross(up).normalized()
	basis.z = -forward

	var x_rotation = Basis(Vector3(1, 0, 0), deg_to_rad(-90))
	return basis * x_rotation

func _create_collision_body(transform: Transform3D):
	var body = StaticBody3D.new()
	var shape = BoxShape3D.new()
	var shape_instance = CollisionShape3D.new()
	shape_instance.shape = shape
	body.add_child(shape_instance)
	body.transform = transform
	add_child(body)
	collision_bodies.append(body)

func _on_curve_changed():
	is_dirty = true
