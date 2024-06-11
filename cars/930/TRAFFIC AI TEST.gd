## PLAYER VEHICLE ##
class_name TrafficVehicle
extends VehicleBody3D

var lane: RoadLane
var current_position: float = 0.0
var speed_limit: float = 100.0

############################################################
const KMH_2_MPH: float = 0.621371

############################################################
@onready var dash = $Dash

@onready var brake_lights = $"Node3D/brake_lights"
@onready var smokes = $smokes
#might need to cleanup
var previous_speed := linear_velocity.length()
############################################################

### In torque
@export var max_engine_force = 100
### In torque
@export var max_brake_force = 50
var current_speed_mps = 0.0
@onready var last_pos = position

@onready var speed = 0.0

func get_speed_kph():
	return current_speed_mps * 3600.0 / 1000.0

func _ready():
	dash.hide()
	# so this doesnt get in the way when in editor
	$smokes.visible = true
	$rr.engine_force = max_engine_force
	$rl.engine_force = max_engine_force

func _process(delta : float):	
	speed = get_speed_kph()

func _physics_process(delta):
	#if  brake_lights != null:
		#if brake_val == 0.0:
			#brake_lights.mesh.surface_get_material(0).emission_energy_multiplier = 0.9
			#
		#else:
			#brake_lights.mesh.surface_get_material(0).emission_energy_multiplier = 7

	var skidinfos = [$fr.get_skidinfo(), $rr.get_skidinfo(), $fl.get_skidinfo(), $rl.get_skidinfo()]
	var max_emission_rate = 1.0 
	var min_emission_rate = 0.0    
	var smoke_scale_factor = 0.5	  
	var front_skidinfos = [$fr.get_skidinfo(), $fl.get_skidinfo()]

			
	for i in range(skidinfos.size()):
		if skidinfos[i] < 0.5:
			var emissionRate = clamp(skidinfos[i] * smoke_scale_factor, min_emission_rate, max_emission_rate)
			for child in smokes.get_children():
				child.emitting = emissionRate > 0.0
				child.amount_ratio = emissionRate / max_emission_rate
		else:
			for child in smokes.get_children():
				child.emitting = false
		
	# TODO: fix wheel skid sounds
	#$tyre_sound.skidding = skidinfos[0] > 0.5 or skidinfos[1] > 0.5 or skidinfos[2] > 0.5 or skidinfos[3] > 0.5

	if abs(linear_velocity.length() - previous_speed) > 1.0:
		$impact_sound.play()
		
	previous_speed = linear_velocity.length()

