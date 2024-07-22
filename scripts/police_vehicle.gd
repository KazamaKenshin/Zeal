extends VehicleBody3D
class_name PoliceVehicle

@onready var siren = $Siren

var previous_speed := linear_velocity.length()
@export var max_engine_force = 1000
@export var max_brake_force = 300
@export var top_speed = 9999 #230
var current_speed_mps = 0.0
@onready var last_pos = position
var throttle_val = 0.0
var brake_val = 0.0

@onready var speed = 0.0

var throttle_speed = 1.0
var brake_speed = 1.0
var max_steer = 0.7
var steer_decay = 0.05
@onready var brake_lights = $Node3D/brake_lights
var target_steer = 0.0

@export var power_curve: Curve

@onready var road_god = get_node("/root/game/RoadGod")
var car

func _ready():
	car = self

func get_speed_kph() -> float:
	return current_speed_mps * 3.6

func _process(delta):
	speed = get_speed_kph()
	var info = "Throttle: %.1f Brake: %.1f \nPowah: %.0f \nSpeed: %.0f \nSteer %.1f" % [throttle_val, brake_val, engine_force, speed, steering]
	$Label.text = info

func _physics_process(delta):
	if Input.get_action_strength("throttle") > 0:
		throttle_val = clamp(throttle_val + throttle_speed * delta, 0.0, 1.0)
	else:
		throttle_val = 0.0
	
	if Input.get_action_strength("brake") > 0:
		brake_val = clamp(brake_val + brake_speed * delta, 0.0, 1.0)
	else:
		brake_val = 0.0
	
	if Input.is_action_pressed("reset"):
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		
		var road_god = get_tree().current_scene.get_node("RoadGod")
		var road_manager = road_god.get_node("RoadManager")
		var road_containers = road_manager.get_children()
		var player_pos = self.global_transform.origin
		var closest_road_container = null
		var min_distance = INF
		for container in road_containers:
			var distance = container.global_transform.origin.distance_to(player_pos)
			if distance < min_distance:
				min_distance = distance
				closest_road_container = container

		if closest_road_container:
			var new_transform = closest_road_container.global_transform
			new_transform.origin.y += 1
			
			#new_transform.origin.z += 10
			self.global_transform = new_transform
			self.global_rotation.y -= 90
	
	current_speed_mps = (position - last_pos).length() / delta
	last_pos = position
	
	var max_steer_at_speed = max_steer - (steer_decay * speed)
	max_steer_at_speed = max(0.2, max_steer_at_speed)
	steering = move_toward(steering, Input.get_axis("right", "left") * max_steer_at_speed, delta * 1.0)
	
	var power_factor = power_curve.sample_baked(throttle_val)
	engine_force = max_engine_force * 7 * power_factor
	
	if speed > top_speed:
		throttle_val = 0.0
	
	if brake_lights != null:
		if brake_val == 0.0:
			brake_lights.mesh.surface_get_material(0).emission_energy = 0.1
		else:
			brake_lights.mesh.surface_get_material(0).emission_energy = 5
	
	if position.y < -100:
		queue_free()

	previous_speed = linear_velocity.length()
