## PLAYER VEHICLE ##
class_name PlayerVehicle
extends VehicleBody3D

# TODO: resource file for vehicle parametres instead of whatever this is
# TODO: fuel simulation

# TODO: keeping this here because wheel rad was 0.35 but only stops clipping through the road at 0.4
const PETROL_KG_L: float = 0.7489
const NM_2_KW: int = 9549
const AV_2_RPM: float = 60 / TAU
const KMH_2_MPH: float = 0.621371

############################################################
# SET UP
# NAMING SCHEMES
# wheels: fl, fr, rl, rr
# various lights: Node3D/...
# brake disk: fl/disk, ...
# smokes: smokes

@onready var brake_lights = $"Node3D/brake_lights"
@export var hot_brake_disk = true
var hot_disk_color = Color(255, 10, 0)
var cool_disk_color = Color(0, 0, 0)
var brake_intensity = 0.0
var heat_up_speed = 0.05
var cool_down_speed = 0.01

@onready var reverse_lights = $"reverse lights"
@onready var braketrail = $braketrail
@onready var smokes = $smokes

var previous_speed := linear_velocity.length()

############################################################
# ENGINE
@export var max_engine_force = 353
@export var max_rpm = 7300
@export var idle_rpm = 1100
@export var power_curve: Curve

@export var max_brake_force = 50

var max_hp = 1000.0

@export var nos = 100
@export var nos_duration = 0.5
@export var nos_power = 250
var nos_timer = 0.0
var nos_active = false

############################################################
# TRANSMISSION
enum tranny_type {
	AUTO,
	MANUAL
}

@export var transmission: tranny_type = tranny_type.MANUAL
@export var gear_ratio = [3.214, 1.925, 1.302, 1.000, 0.752]
@export var reverse_ratio = -3.0
@export var final_drive = 4.111

var current_gear = 1
var clutch_position: float = 1.0
var gear_shift_time = 0.5
var gear_timer = 0.0
var last_shift_time = 0
var shift_time = 800

############################################################
# DRIVETRAIN
enum DRIVE_TYPE {
	FWD,
	RWD,
	AWD,
}

@export var drivetype: DRIVE_TYPE = DRIVE_TYPE.AWD
@export var torque_split = 0.7

############################################################
# STEERING
@export var max_steer = 0.7
var steer_decay = 0.08


############################################################
var current_speed_mps = 0.0
@onready var last_pos = position
@onready var rpm = 0
@onready var speed = 0

var throttle_speed = 1.0
var brake_speed = 1.0
var throttle_val = 0.0
var brake_val = 0.0
var auto_reverse_time = 0.0

############################################################
@export var whinepitch = 0.0
@export var turbo_enabled = true
@export var max_psi = 10.0
@export var supercharger_enabled = false

############################################################
enum GAME_STATE{
	OPTIMAL,
	INSANITY,
	TRANCE,
	BLOODTHIRST
}


func get_speed_kph():
	return current_speed_mps * 3600.0 / 1000.0

func calculate_rpm() -> float:
	var wheel_circumference : float = 2.0 * PI * $rr.wheel_radius
	var wheel_rotation_speed : float = 60.0 * current_speed_mps / wheel_circumference
	var drive_shaft_rotation_speed : float = wheel_rotation_speed * final_drive
	if current_gear == 0:
		return drive_shaft_rotation_speed * - reverse_ratio + idle_rpm
	elif current_gear <= gear_ratio.size():
		return drive_shaft_rotation_speed * gear_ratio[current_gear - 1] + idle_rpm
	elif current_gear == 0:
		return idle_rpm
	else:
		return 0.0
		
func _ready():
	# so this doesnt get in the way when in editor
	$smokes.visible = true
	nitro()

func nitro():
	if not nos_active:
		nos_active = true
		nos_timer = nos_duration
		nos -= 1
		
func update_nitro(delta: float):
	if nos_active:
		nos_timer -= delta
		var nitro_direction = global_transform.basis.z.normalized()
		var nitro_force = nitro_direction * nos_power * 100
		apply_force(nitro_force)
		if nos_timer <= 0.0:
			nos_active = false

func _process_gear_inputs(delta: float):
	if gear_timer > 0.0:
		gear_timer = max(0.0, gear_timer - delta)
		clutch_position = 1.0
	else:
		if transmission == tranny_type.MANUAL:
			if Input.is_action_pressed("sd") and current_gear > 0:
				current_gear = current_gear - 1
				gear_timer = gear_shift_time
				clutch_position = 0.0
			elif Input.is_action_pressed("su") and current_gear < gear_ratio.size():
				current_gear = current_gear + 1
				gear_timer = gear_shift_time
				clutch_position = 0.0
			else:
				clutch_position = 1.0
		elif transmission == tranny_type.AUTO:
			if rpm > 0.95 * max_rpm and current_gear > 0 and current_gear < gear_ratio.size() and (Time.get_ticks_msec() - last_shift_time) > shift_time:
				current_gear = current_gear + 1
				gear_timer = gear_shift_time
				last_shift_time = Time.get_ticks_msec()
			elif rpm < 0.55* max_rpm and current_gear <= gear_ratio.size() and current_gear > 1 and(Time.get_ticks_msec() - last_shift_time) > shift_time:
				current_gear = current_gear - 1
				gear_timer = gear_shift_time
			elif current_gear == 1 and auto_reverse_time > 1:
				current_gear = 0
				clutch_position = 1.0
			elif current_gear == 0 and auto_reverse_time < 1 and !Input.is_action_pressed("brake"):
				current_gear = 1
				clutch_position = 1.0
			else:
				clutch_position = 1.0
				
			if Input.is_action_pressed("brake"):
				auto_reverse_time += delta
			else:
				auto_reverse_time = 0.0

func _process(delta : float):
	_process_gear_inputs(delta)
	
	speed = get_speed_kph()
	rpm = calculate_rpm()
	if rpm > max_rpm:
		rpm = max_rpm
	
	var info = 'Brake %.0f Drivetype %s Gear %d| KMH %.0f\nThrottle %.1f Brake %.1f \nFRONT L %.0f | FRONT R %.0f \nREAR L %.0f | REAR R %.0f'  % [brake, drivetype, current_gear, speed, throttle_val,brake_val, $fr.engine_force, $fl.engine_force, $rl.engine_force, $rr.engine_force] # .0f no decimals
	
	$Label.text = info

	var speedo = '%.0f KM/H' % [ speed ]

func _physics_process(delta):

	whinepitch = abs(rpm/gear_ratio[current_gear - 1])*1.5
	current_speed_mps = (position - last_pos).length() / delta
	var max_steer_at_speed = max_steer - (steer_decay * speed)
	max_steer_at_speed = max(0.2, max_steer_at_speed)
	steering = move_toward(steering, Input.get_axis("right", "left") * max_steer_at_speed, delta * 0.5)

	if transmission == tranny_type.MANUAL:
		throttle_val = clamp(throttle_val + throttle_speed * delta, 0.0, 1.0) if Input.get_action_strength("throttle") else 0.0
		brake_val = clamp(brake_val + brake_speed * delta, 0.0, 1.0) if Input.get_action_strength("brake") else 0.0
	if transmission == tranny_type.AUTO:
		if current_gear > 0:
			throttle_val = clamp(throttle_val + throttle_speed * delta, 0.0, 1.0) if Input.get_action_strength("throttle") else 0.0
			brake_val = clamp(brake_val + brake_speed * delta, 0.0, 1.0) if Input.get_action_strength("brake") else 0.0
		elif current_gear == 0:
			throttle_val = clamp(auto_reverse_time, 0.0, 0.5)
			brake_val = clamp(brake_val + brake_speed * delta, 0.0, 1.0) if Input.get_action_strength("throttle") else 0.0


	if Input.is_action_pressed("nos") and nos >0:
		nitro()
	
	update_nitro(delta)
	
	if Input.is_action_pressed("freecam"):
		$FreeLookCamera.current = true
	#TODO: 
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
			nitro()
		
	
	rpm = calculate_rpm()
	var rpm_factor = clamp(rpm / max_rpm, 0.0, 1.0)
	var power_factor = power_curve.sample_baked(rpm_factor) * 7
	var wheel_power = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force * 0.5
	var wheel_power_reverse = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive * max_engine_force * 0.5

	var front_wheels = [$fl, $fr]
	var rear_wheels = [$rl, $rr]

	if current_gear == 0:
		for child in reverse_lights.get_children():
			child.show()
	else:
		for child in reverse_lights.get_children():
			child.hide()
			
	if drivetype == DRIVE_TYPE.FWD:
		if current_gear == 0:
			for wheel in front_wheels:
				wheel.engine_force = wheel_power_reverse
		elif current_gear > 0 and current_gear <= gear_ratio.size():
			for wheel in front_wheels:
				wheel.engine_force = wheel_power * gear_ratio[current_gear - 1]
			
	elif drivetype == DRIVE_TYPE.RWD:
		if current_gear == 0:
			for wheel in rear_wheels:
				wheel.engine_force = wheel_power_reverse * 2
		elif current_gear > 0 and current_gear <= gear_ratio.size():
			for wheel in rear_wheels:
				wheel.engine_force = wheel_power * gear_ratio[current_gear - 1] * 2
				
	elif drivetype == DRIVE_TYPE.AWD:
		if current_gear == 0:
			for wheel in front_wheels:
				wheel.engine_force = wheel_power_reverse * (1 - torque_split)
			for wheel in rear_wheels:
				wheel.engine_force = wheel_power_reverse * torque_split
		elif current_gear > 0 and current_gear <= gear_ratio.size():
			for wheel in front_wheels:
				wheel.engine_force = wheel_power * gear_ratio[current_gear - 1] * (1 - torque_split)
			for wheel in rear_wheels:
				wheel.engine_force = wheel_power * gear_ratio[current_gear - 1] * torque_split

	brake = brake_val * max_brake_force

	if  brake_lights != null:
		if brake_val == 0.0:
			brake_lights.mesh.surface_get_material(0).emission_energy_multiplier = 0.5
			for child in braketrail.get_children():
				child.trailOff()
		else:
			brake_lights.mesh.surface_get_material(0).emission_energy_multiplier = 5
			for child in braketrail.get_children():
				child.trailOn()
		
	if current_speed_mps < 20:
		for child in braketrail.get_children():
			child.killall()
	
	last_pos = position
	
	var skidinfos = [$fr.get_skidinfo(), $rr.get_skidinfo(), $fl.get_skidinfo(), $rl.get_skidinfo()]
	var max_emission_rate = 2.0
	var min_emission_rate = 0.0
	var smoke_scale_factor = 0.5
	var front_skidinfos = [$fr.get_skidinfo(), $fl.get_skidinfo()]
	
	for i in range(front_skidinfos.size()):
		if front_skidinfos[i] < 0.8:
			torque_split = 0.3
		else:
			torque_split = 0.5
			
	for i in range(skidinfos.size()):
		if skidinfos[i] < 0.3:
			var emission_rate = clamp(skidinfos[i] * smoke_scale_factor, min_emission_rate, max_emission_rate)
			for child in smokes.get_children():
				child.emitting = emission_rate > 0.0
				child.amount_ratio = emission_rate / max_emission_rate
		else:
			for child in smokes.get_children():
				child.emitting = false
		
	# TODO: fix wheel skid sounds
	#$tyre_sound.skidding = skidinfos[0] > 0.5 or skidinfos[1] > 0.5 or skidinfos[2] > 0.5 or skidinfos[3] > 0.5
	if hot_brake_disk == true:
		update_hot_brake_disk(delta)

func update_hot_brake_disk(delta):
	if brake_val > 0.1 and speed > 50:
		brake_intensity = clamp(brake_intensity + heat_up_speed * delta, 0, 1)
	else:
		brake_intensity = clamp(brake_intensity - cool_down_speed * delta, 0, 1)
	
	var all_wheels = [$fl, $fr, $rl, $rr]
	for wheel in all_wheels:
		for child in wheel.get_children():
			if child.name == "disk":
				var material = child.mesh.surface_get_material(0)
				var target_color = cool_disk_color.lerp(hot_disk_color, brake_intensity)
				material.set("emission", target_color)
	

	if abs(linear_velocity.length() - previous_speed) > 1.0:
		$impact_sound.play()
		
	previous_speed = linear_velocity.length()
