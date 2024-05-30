extends Node3D

class_name RoadGod

const RpSrcScene:PackedScene = preload("res://world/biome_gen/biomes/generic_rp2.tscn")
var _open_connections: Array = []
var rp_container: RoadContainer
var default_mat:BaseMaterial3D = preload("res://addons/road-generator/resources/road_texture.material")
var _curve_left = preload("res://world/road_generation/curves/CurveLeft.tscn")
var _curve_right = preload("res://world/road_generation/curves/CurveRight.tscn")
var _curve_straight = preload("res://world/road_generation/curves/CurveStraight.tscn")
var _curve_s = preload("res://world/road_generation/curves/CurveS.tscn")
var _curve_weird = preload("res://world/road_generation/curves/CurveWeird.tscn")

var road_point_map: Array

@onready var road_manager = $"../RoadManager"

enum Curves {
	LEFT,
	RIGHT,
	STRAIGHT,
	S,
	WEIRD
}

func _ready():
	print("Initializing RoadGod...")
	rp_container = RoadContainer.new()
	rp_container.name = "RoadContainer"
	rp_container._auto_refresh = false
	rp_container.material_resource = default_mat
	if road_manager:
		print("Adding RoadContainer to RoadManager")
		road_manager.add_child(rp_container)
		print("Added RoadContainer to RoadManager :>")
	else:
		push_error("RoadManager not found in the scene tree!")
	
	randomize()
	place_random_roadpoints(2)
	connect_roadpoints()

func _init():
	road_point_map = []

func on_road_updated(segments) -> void:
	pass

func get_curve(curve_type) -> Path3D:
	match curve_type:
		Curves.LEFT:
			return _curve_left.instance()
		Curves.RIGHT:
			return _curve_right.instance()
		Curves.STRAIGHT:
			return _curve_straight.instance()
		Curves.S:
			return _curve_s.instance()
		Curves.WEIRD:
			return _curve_weird.instance()
		_:
			return _curve_straight.instance()

func place_next_roadpoint(rp_src: PackedScene, pos: Vector2, rot: Vector3, prior_rp, for_next: bool) -> RoadPoint:
	print("Placing next road point...")
	var new_rp = rp_src.instantiate()
	new_rp.name = "RP"
	rp_container.add_child(new_rp)
	print("Added new road point to rp_container")

	new_rp.position = Vector3(pos.x, 0, pos.y)
	new_rp.rotation = rot
	print("Set position and rotation for the new road point")

	for chnode in new_rp.get_children():
		if chnode is Path3D:
			var crv: Path3D = chnode
			if crv.curve:
				crv.curve = crv.curve.duplicate()

	if is_instance_valid(prior_rp) and prior_rp is RoadPoint:
		new_rp.copy_settings_from(prior_rp)
		print("Copied settings from prior road point")

		if for_next == null:
			push_error("Could not connect new roadpoint, already fully connected")
		elif for_next:
			new_rp.prior_pt_init = new_rp.get_path_to(prior_rp)
			prior_rp.next_pt_init = prior_rp.get_path_to(new_rp)
		else:
			new_rp.next_pt_init = new_rp.get_path_to(prior_rp)
			prior_rp.prior_pt_init = prior_rp.get_path_to(new_rp)
	else:
		new_rp.name = RoadPoint.increment_name("RP001")
		
	_open_connections.erase(prior_rp)
	_open_connections.append(new_rp)
	print("Updated open connections")

	return new_rp

func remove_roadpoint(rp: RoadPoint):
	_open_connections.erase(rp)
	rp.prior_pt_init = ""
	rp.next_pt_init = ""
	rp.call_deferred("queue_free")
	print("Removed road point and cleared connections")

func get_open_connections(refresh: bool = false) -> Array:
	if refresh:
		_open_connections = []
	elif _open_connections:
		return _open_connections

	var open_rps = []
	for child in get_children():
		if child is RoadContainer:
			var rc: RoadContainer = child
			rc.update_edges()
			for idx in len(rc.edge_rp_locals):
				var edge_pt_path = rc.edge_rp_locals[idx]
				var edge_containers_path = rc.edge_containers[idx]
				if edge_containers_path:
					continue

				var edge_pt = rc.get_node(edge_pt_path)
				open_rps.append(edge_pt)

	_open_connections = open_rps
	print("Refreshed open connections")
	return open_rps

func place_random_roadpoints(count: int):
	var prior_rp: RoadPoint = null
	for i in range(count):
		var pos = Vector2(randf_range(0, 100), randf_range(0, 100))  # Ensure positions are within a valid range
		var rot = Vector3(0, randf() * PI * 2, 0)  # Ensure rotation is within a valid range
		var new_rp = place_next_roadpoint(RpSrcScene, pos, rot, prior_rp, true)
		print("Placed random road point at position: ", pos, " with rotation: ", rot)
		prior_rp = new_rp


func connect_roadpoints():
	#for i in range(len(_open_connections) - 1):
		#var this_rp = _open_connections[i]
		#var next_rp = _open_connections[i + 1]
		#this_rp.connect_roadpoint(RoadPoint.PointInit.NEXT, next_rp, RoadPoint.PointInit.PRIOR)
		#print("Connected road points: ", this_rp.name, " and ", next_rp.name)
	pass
