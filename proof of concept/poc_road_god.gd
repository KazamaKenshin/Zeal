extends Node3D

@onready var road_manager = $RoadManager

#var player_scene = preload("res://cars/R32 GTR/PLAYER.tscn")
var player_scene = preload("res://cars/930/PLAYER.tscn")

var road_straight = [
	preload("res://proof of concept/straight.tscn"),
]

var road_left = [
	preload("res://proof of concept/curve_L.tscn"),
]

var road_right = [
	preload("res://proof of concept/curve_R.tscn")
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

	first_road_seg = road_straight[0].instantiate()
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
	var pt1
	var pt2
	var config = {
		"debug": true,
		"_auto_refresh": false,
		"generate_ai_lanes": true
	}
	
	var new_road = _instantiate_random_road()
	road_manager.add_child(new_road)
	last_road_seg = new_road
	pt1 = second_last_road_seg.get_last_roadpoint()
	print("Current second last road segment is: ", second_last_road_seg)
	print("Second last road seg last roadpoint is: ", second_last_road_seg.get_last_roadpoint())
	pt2 = last_road_seg.get_first_roadpoint()
	print("Current last road segement is: ", last_road_seg)
	print("Last road seg first roadpoint is: ", last_road_seg.get_first_roadpoint())

	print("pt1 from container: ", second_last_road_seg)
	print("pt2 from container: ", last_road_seg)
	  
	print(second_last_road_seg.get_last_roadpoint().broadcast_position())
	# HACK: setting new road's container pos and rot to match prev rp

	# pt1.position/rotation is relative, calling broadcast_position to find global pos and rot
	var data = pt1.broadcast_position()
	print("pt1 pos rot", data)
	new_road.global_position = data["position"]
	new_road.global_rotation = data["rotation"]
	
	var pt3 = last_road_seg.get_last_roadpoint()
	var random_position = randf() * Vector3(0, 0, 100)
	pt3.position += random_position 
	#var random_rotation = randf() * deg_to_rad(5)
	#new_road.global_rotation.x += random_rotation

	_configure_road(new_road, config)
	for child in road_manager.get_children():
		if child is RoadContainer:
			child.rebuild_segments()
			
	road_manager.rebuild_all_containers()

	# will this break?
	#new_road.update_edges()
	pt1.connect_container(RoadPoint.PointInit.NEXT, pt2, RoadPoint.PointInit.PRIOR)
	print("Road section built and connected at pos, rot", pt1.broadcast_position(), "...")
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
	
func _instantiate_random_road():
	var road_type

	var weights = [0.5, 0.25, 0.25]
	
	while true:
		var random_value = randf()
		var weight_bias = 0.0
		for i in range(all_roads.size()):
			weight_bias += weights[i]
			if random_value < weight_bias:
				road_type = all_roads[i]
				break
		if road_type != previous_road_type:
			break
	previous_road_type = road_type

	var random_index = randi() % road_type.size()
	
	return road_type[random_index].instantiate()
