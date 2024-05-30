extends Node3D

@onready var road_manager = $RoadManager

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
	road_manager.add_child(first_road_seg)
	_configure_road(first_road_seg, config)
	# is this okay as a starting road?
	second_last_road_seg = first_road_seg
	print("Initial road generated correctly...")
	print("Current last road segement is: ", last_road_seg)
	print("Current second last road segment is: ", second_last_road_seg)

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
	print("New road instantiated! New road: ", new_road)
	last_road_seg = new_road
	print("THIS SHOULD BE EQUAL TO NEW ROAD! Last road seg: ", last_road_seg)
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
	new_road.global_position = data["position"] + Vector3(10,10,10)
	new_road.global_rotation = data["rotation"]
	var random_rotation = randf() * deg_to_rad(10)
	new_road.global_rotation.x += random_rotation

	_configure_road(new_road, config)
	for child in road_manager.get_children():
		if child is RoadContainer:
			child.rebuild_segments()

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
	if Input.is_action_just_pressed("su"):
		print("Generate road pressed...")
		generate_road_sections()
	
	
func _instantiate_random_road():
	var road_type
	
	while true:
		road_type = all_roads[randi() % all_roads.size()]
		if road_type != previous_road_type:
			break
	previous_road_type = road_type
	var random_index = randi() % road_type.size()
	return road_type[random_index].instantiate()
