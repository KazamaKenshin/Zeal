extends Node3D

@onready var road_manager = $RoadManager

@export var traffic_density = 1.0
var player_vehicle = preload("res://cars/R32 GTR/R32 GTR.tscn")
#var player_vehicle = preload("res://cars/CYBERCAR/Cybercar.tscn")
var player_instance

@onready var total_cars = 0
var max_traffic_cars = 20

var traffic_cars = [
	{"name": "930", "path": preload("res://cars/930/930.tscn")},
	{"name": "GTR R32", "path": preload("res://cars/R32 GTR/R32 GTR.tscn")}
]

var road_straight = [
	{"scene": preload("res://road/long_straight.tscn"), "value": 0},
	{"scene": preload("res://road/straight.tscn"), "value": 0},
]

var road_left = [
	{"scene": preload("res://road/curve_L.tscn"), "value": 45},
]

var road_right = [
	{"scene": preload("res://road/curve_R.tscn"), "value": -45},
]

var all_roads = [
	road_straight,
	road_left,
	road_right
]

var previous_road_type = null
var second_previous_road_type = null

var first_road_seg
var second_last_road_seg
var last_road_seg

var total_rotation = 0

var current_traffic_cars = 0

signal regenerate_pressed

func _ready():
	print("Initialization...")
	var config = {
		"debug": true,
		"_auto_refresh": false,
		"generate_ai_lanes": true
	}

	first_road_seg = road_straight[0]["scene"].instantiate()
	first_road_seg.position = Vector3(0, 0, 0)
	road_manager.add_child(first_road_seg)
	_configure_road(first_road_seg, config)
	second_last_road_seg = first_road_seg
	for i in range(50):
		place_road_section()

	player_instance = player_vehicle.instantiate()
	player_instance.position = Vector3(0, 1, 10)
	player_instance.position = Vector3(-5, 1, 10)
	add_child(player_instance)
	
func place_road_section():
	var second_last_road_seg_last_point
	var last_road_seg_first_point
	var config = {
		"debug": true,
		"_auto_refresh": false,
		"generate_ai_lanes": true
	}
	
	var new_road = generate_random_road()
	road_manager.add_child(new_road)
	last_road_seg = new_road
	second_last_road_seg_last_point = second_last_road_seg.get_last_roadpoint()
	last_road_seg_first_point = last_road_seg.get_first_roadpoint()
	var data = second_last_road_seg_last_point.broadcast_position()
	
	new_road.global_position = data["position"]
	new_road.global_rotation = data["rotation"]
	new_road.global_transform.basis.z = data["z_vector"]
	
	var last_road_seg_last_point = last_road_seg.get_last_roadpoint()
	var random_z = randf() * 100
	var random_position = Vector3(0, 0, random_z)

	var random_scale = Vector3(0, randf() * 2 - 1, 0)
	var random_height = random_scale * Vector3(0, 5, 0)
	last_road_seg_last_point.position += random_position + random_height
	
	_configure_road(new_road, config)
	for child in road_manager.get_children():
		if child is RoadContainer:
			child.rebuild_segments()
			child.update_edges()
			
	road_manager.rebuild_all_containers()

	second_last_road_seg_last_point.connect_container(RoadPoint.PointInit.NEXT, last_road_seg_first_point, RoadPoint.PointInit.PRIOR)
	print("Road section built and connected at pos, rot", second_last_road_seg_last_point.broadcast_position(), "...")
	
	second_last_road_seg = last_road_seg
		
func _configure_road(road_instance, settings):
	for key in settings.keys():
		road_instance.set(key, settings[key])

func _process(delta):
	if current_traffic_cars <= max_traffic_cars:
		generate_traffic()
	else:
		print("max reached???")
		
	if Input.is_action_pressed("freecam"):
		print("May god help you, because I can't...")
	if Input.is_action_just_pressed("shift"):
		pass

func generate_random_road():
	var road_type
	var road_value = 0
	var weights = [0.4, 0.3, 0.3]
	
	while true:
		var random_value = randf()
		var weight_bias = 0.0
		for i in range(all_roads.size()):
			weight_bias += weights[i]
			if random_value < weight_bias:
				road_type = all_roads[i]
				break
		var random_index = randi() % road_type.size()
		road_value = road_type[random_index]["value"]
		if abs(total_rotation + road_value) <= 181 and road_type != previous_road_type:
			total_rotation += road_value
			previous_road_type = road_type
			return road_type[random_index]["scene"].instantiate()

func generate_traffic(lane_num = -1):
	var road_lanes = get_tree().get_nodes_in_group("road_lanes")
	var lane_count = len(road_lanes)
	var lane: RoadLane
	if lane_count == 0 or lane_num > lane_count - 1:
		return
	if lane_num == -1:
		lane_num = randi() % lane_count
	lane = road_lanes[lane_num]
	
	var vehicles_in_lane = lane.get_vehicles()
	var vehicle_count = len(vehicles_in_lane)
	if vehicle_count == 0:
		var pos: float = randf()
		var pos3D: Vector3 = lane.to_global(lane.curve.sample(0, pos))
		var rot: Vector3
		rot = lane.global_rotation
		if lane.reverse_direction:
			rot.y += PI
		var distance_to_player = player_instance.global_position.distance_to(pos3D)
		if distance_to_player <= 300 and distance_to_player >= 200:
			spawn_car(pos3D, rot)

func spawn_car(pos: Vector3, rot: Vector3):
	var available_traffic_cars = traffic_cars.filter(func(car_data):
		return car_data["path"] != player_vehicle
	)
	var car_data = available_traffic_cars[randi() % available_traffic_cars.size()]
	var car_instance = car_data["path"].instantiate()

	car_instance.set_script(load("res://cars/930/traffic_vehicle.gd"))
	add_child(car_instance)
	car_instance.global_position = pos
	car_instance.global_rotation = rot
