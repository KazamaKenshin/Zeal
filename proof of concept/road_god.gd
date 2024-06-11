extends Node3D

@onready var road_manager = $RoadManager

var player_scene = preload("res://cars/930/TRAFFIC AI TEST.tscn")
#var player_scene = preload("res://cars/930/PLAYER.tscn")
#var player_scene = preload("res://cars/R32 GTR/PLAYER.tscn")

var road_straight = [
	{"scene": preload("res://proof of concept/long_straight.tscn"), "value": 0},
	{"scene": preload("res://proof of concept/straight.tscn"), "value": 0},

]

var road_left = [
	{"scene": preload("res://proof of concept/curve_L.tscn"), "value": 45},
]

var road_right = [
	{"scene": preload("res://proof of concept/curve_R.tscn"), "value": -45},
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
	print("Current last road segment is: ", last_road_seg)
	print("Current second last road segment is: ", second_last_road_seg)
	
	var player_instance = player_scene.instantiate()
	player_instance.position = Vector3(0, 1, 10)
	add_child(player_instance)
	
	for i in range(50):
		generate_road_sections()
	
func generate_road_sections():
	var second_last_road_seg_last_point
	var last_road_seg_first_point
	var config = {
		"debug": true,
		"_auto_refresh": false,
		"generate_ai_lanes": true
	}
	
	var new_road = _instantiate_random_road()
	road_manager.add_child(new_road)
	last_road_seg = new_road
	second_last_road_seg_last_point = second_last_road_seg.get_last_roadpoint()
	print("Current second last road segment is: ", second_last_road_seg)
	print("Second last road seg last roadpoint is: ", second_last_road_seg.get_last_roadpoint())
	last_road_seg_first_point = last_road_seg.get_first_roadpoint()
	print("Current last road segement is: ", last_road_seg)
	print("Last road seg first roadpoint is: ", last_road_seg.get_first_roadpoint())

	print("second_last_road_seg_point from container: ", second_last_road_seg)
	print("last_road_seg_first_point from container: ", last_road_seg)
	  
	print(second_last_road_seg.get_last_roadpoint().broadcast_position())
	var data = second_last_road_seg_last_point.broadcast_position()
	print("second_last_road_seg_point pos rot", data)
	
	# this works, so Imma leave it at that
	new_road.global_position = data["position"]
	new_road.global_rotation = data["rotation"]
	new_road.global_transform.basis.z = data["z_vector"]
	
	var last_road_seg_last_point = last_road_seg.get_last_roadpoint()
	#var random_position = randf() * Vector3(0, 0, 100)
	var random_z = randf() * 100
	var random_position = Vector3(0, 0, random_z)

	var random_scale = Vector3(0, randf() * 2 - 1, 0)
	var random_height = random_scale * Vector3(0, 10, 0)
	last_road_seg_last_point.position += random_position + random_height
	
	_configure_road(new_road, config)
	for child in road_manager.get_children():
		if child is RoadContainer:
			child.rebuild_segments()
			child.update_edges()
			
	road_manager.rebuild_all_containers()

	second_last_road_seg_last_point.connect_container(RoadPoint.PointInit.NEXT, last_road_seg_first_point, RoadPoint.PointInit.PRIOR)
	print("Road section built and connected at pos, rot", second_last_road_seg_last_point.broadcast_position(), "...")
	print("Current last road segement is: ", last_road_seg)
	print("Current second last road segment is: ", second_last_road_seg)
	
	second_last_road_seg = last_road_seg

func _configure_road(road_instance, settings):
	for key in settings.keys():
		road_instance.set(key, settings[key])

func _process(delta):
	if Input.is_action_pressed("freecam"):
		print("May god help you, because I can't...")
	if Input.is_action_just_pressed("shift"):
		print("Generate road pressed...")
		generate_road_sections()
	
var total_rotation = 0

func _instantiate_random_road():
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
			
