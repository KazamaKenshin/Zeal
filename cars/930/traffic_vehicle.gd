class_name TrafficVehicle
extends VehicleBody3D

var ray_directions = []
var interest = []
var chosen_dir = Vector3.ZERO

var look_ahead = 0
var num_rays = 5

var follow_path: RoadLane
var follow_car: VehicleBody3D

var target_speed = 60
var target_steer = 0.0
var car = self

var lane_change_consider = 10.0
var this_lane: RoadLane
var min_forward = 5.0

@onready var road_god = get_node("/root/game/RoadGod")

@onready var brake_lights = $"Node3D/brake_lights"

var previous_speed := linear_velocity.length()
@onready var body = $body

@export var max_engine_force = 300
@export var max_brake_force = 50
var current_speed_mps = 0.0
@onready var last_pos = position
@onready var speed = 0.0
var throttle_val = 0.0
var brake_val = 0.0
var rpm = 0.0

var reverse = false
@onready var reverse_lights = $"reverse lights"

###### QUEUE FREE #####
@onready var braketrail = $braketrail
@onready var dash = $Dash
@onready var engine_sound = $engine_sound
@onready var player_cam = $CamPivot
@onready var smokes = $smokes
@onready var other_sound = $other_sounds
@onready var label = $Label
var turbo_enabled = false
var supercharger_enabled = false
var player_car

var brake_timer = 0.0
var braking = false

func get_speed_kph():
	return current_speed_mps * 3.6

func _ready():
	var free = [braketrail, dash, engine_sound, other_sound, player_cam, smokes, label]
	for node in free:
		node.queue_free()

	$fr.use_as_traction = true
	$fl.use_as_traction = true

	var random_color = Color(randf(), randf(), randf())
	var material = body.mesh.surface_get_material(0).duplicate()
	material.albedo_color = random_color
	body.mesh.surface_set_material(0, material.duplicate())

	player_car = road_god.player_instance
	road_god.total_cars += 1

func _enter_tree():
	interest.resize(num_rays)
	ray_directions.resize(num_rays)
	
	var increment = PI / num_rays
	for i in num_rays:
		var angle = (i + 0.5) * increment
		ray_directions[i] = Vector3(-1, 0, 0).rotated(Vector3(0, 1, 0), angle)

func get_closest_lane(max_distance: float):
	var car_pos = car.global_transform.origin
	var closest_lane = null
	var closest_dist = null
	var all_lanes = get_tree().get_nodes_in_group("road_lanes")
	
	for lane in all_lanes:
		var this_lane_closest = get_closest_path_point(lane, car_pos)
		var this_lane_dist = car_pos.distance_to(this_lane_closest)
		if this_lane_dist > max_distance:
			continue
		elif closest_lane == null:
			closest_lane = lane
			closest_dist = this_lane_dist
		elif this_lane_dist < closest_dist:
			closest_lane = lane
			closest_dist = this_lane_dist
	return closest_lane
	
func get_closest_path_point(path: Path3D, pos: Vector3) -> Vector3:
	if path == null:
		return Vector3()
	var interp_point = path.curve.get_closest_point(path.to_local(pos))
	return path.to_global(interp_point)

func _set_interest_and_next_lane():
	var origin = car.global_transform.origin
	var closest_point = get_closest_path_point(this_lane, origin)

	var closest_offset = this_lane.curve.get_closest_offset(this_lane.to_local(origin))
	var rev = -1 if this_lane.reverse_direction else 1
	var forward_point = this_lane.to_global(this_lane.curve.sample_baked(closest_offset + 0.5 * rev))
	
	var path_dir = forward_point - closest_point
	var facing = 1 if path_dir.dot(car.global_transform.basis.z) > 0 else -1
	var origin_offset = min(car.speed, min_forward)
	var src_pos = origin + car.global_transform.basis.z * origin_offset * facing
	
	closest_offset = this_lane.curve.get_closest_offset(this_lane.to_local(src_pos))
	var forward_offset_point = this_lane.to_global(this_lane.curve.sample_baked(closest_offset + 1 * rev))
	var path_direction = forward_offset_point - car.global_transform.origin

	for i in num_rays:
		var d = ray_directions[i].rotated(Vector3(0, 1, 0), car.rotation.y).dot(path_direction)
		interest[i] = max(0, d)

	var lenc = this_lane.curve.get_baked_length()
	var jump_next = closest_offset / lenc > 0.99 and not this_lane.reverse_direction
	jump_next = jump_next or (closest_offset / lenc < 0.01 and this_lane.reverse_direction)
	if jump_next and this_lane.lane_next:
		var next_target = this_lane.get_node_or_null(this_lane.lane_next)
		if is_instance_valid(next_target):
			this_lane.draw_in_game = false
			this_lane.unregister_vehicle(car)
			this_lane = next_target
			var _seg = this_lane.this_road_segment

func _update_steering():
	var ray_origin = self.global_transform.origin
	var ray_end = ray_origin + Vector3(0, 1, 5)
	var space_state = get_world_3d().direct_space_state
	var ray_query_3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1, [self])
	var result = space_state.intersect_ray(ray_query_3D)
	
	if chosen_dir.x > 0.05 and chosen_dir.x > steering:
		target_steer = min(0.7, chosen_dir.x)
	elif chosen_dir.x < -0.05 and chosen_dir.x < steering:
		target_steer = max(-0.7, chosen_dir.x)
	elif result:
		throttle_val = 0.0
		brake_val = 1.0
		braking = true
		target_steer = 0.0
	else:
		target_steer = 0.0
		brake_val = 0.0

	if speed >= target_speed:
		throttle_val = 0.0
		brake_val = 1.0
		braking = true
	elif abs(steering) >= 0.7 * 0.5:
		throttle_val = 0.0
	else:
		throttle_val = 1.0

	brake = max_brake_force * brake_val

	if braking:
		brake_timer += get_physics_process_delta_time()
		if brake_timer >= 1.0:
			braking = false
			brake_timer = 0.0
		else:
			brake_val = 1.0

func update_inputs():
	awawa()
	_set_interest_and_next_lane()
	_choose_direction()
	_update_steering()
	
func awawa():
	var closest_lane = get_closest_lane(lane_change_consider)
	if closest_lane:
		this_lane = closest_lane
		this_lane.register_vehicle(car)
	else:
		throttle_val = 1.0
		steering = 0.0

func _choose_direction():
	chosen_dir = Vector3.ZERO
	for i in num_rays:
		chosen_dir += ray_directions[i] * interest[i]
	if chosen_dir.z < 0:
		chosen_dir.z = 0
	chosen_dir = chosen_dir.normalized()

func _physics_process(delta):
	current_speed_mps = (position - last_pos).length() / delta
	speed = get_speed_kph()
	
	engine_force = 5 * max_engine_force

	if abs(linear_velocity.length() - previous_speed) > 1.0:
		$impact_sound.play()

	previous_speed = linear_velocity.length()
	update_inputs()
	steering = move_toward(steering, target_steer, delta * 2)

	if reverse == false:
		reverse_lights.hide()
	else:
		reverse_lights.show()
	
	if brake_lights != null:
		if brake_val == 0.0:
			brake_lights.mesh.surface_get_material(0).emission_energy_multiplier = 0.5
		else:
			brake_lights.mesh.surface_get_material(0).emission_energy_multiplier = 5
	
	var player_pos = player_car.global_transform.origin
	if position.y < -100 or position.x - player_pos.x > 300 or position.z - player_pos.z > 300 or position.x < player_pos.x - 100 or position.z < player_pos.z - 100:
		queue_free()
		road_god.total_cars -= 1
		print("Total cars: ", road_god.total_cars)

	last_pos = position
