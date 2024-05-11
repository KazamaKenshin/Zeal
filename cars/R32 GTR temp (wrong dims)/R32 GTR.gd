## NISSAN SKYLINE R32 GT-R ##
extends VehicleBody3D

@onready var ai_controller: AIController3D = $AIController3D
const PETROL_KG_L: float = 0.7489
const NM_2_KW: int = 9549
const AV_2_RPM: float = 60 / TAU
############################################################
@export var max_engine_force = 353
@export var max_brake_force = 30
@export var max_rpm = 7300
@export var idle_rpm = 1100
@export var max_steer = 0.6
#@export var gear_ratio = [5.4, 3.47, 2.32, 2, 1.8]
#@export var gear_ratio = [6.428, 3.85, 2.604, 2, 1.8]
@export var gear_ratio = [3.214, 1.925, 1.302, 1.000, 0.752]
#@export var gear_ratio = [4.214, 2.925, 2.302, 2.000,1.752]

@export var reverse_ratio = -3.0
@export var final_drive = 4.111

@export var turbo_enabled = true
@export var max_psi = 10.0

@export var supercharger_enabled = false

enum DRIVE_TYPE{
	FWD,
	RWD,
	AWD,
}
@export var drivetype : DRIVE_TYPE = DRIVE_TYPE.AWD
# for rear
@export var torque_split = 0.7
var max_hp = 1000.0
var current_hp = max_hp

@export var power_curve: Curve

@export var nos = 100 # 1 default
@export var nos_duration = 3.0
@export var nos_power = 250
var nos_timer = 0.0
var nos_active = false

############################################################
var current_gear = 1
var clutch_position : float = 1.0
var current_speed_mps = 0.0
@onready var last_pos = position
@onready var rpm = 0

@export var whinepitch = 0.0

var throttle_speed = 1.0
var brake_speed = 1.0


var gear_shift_time = 0.5
var gear_timer = 0.0
var last_shift_time = 0
var shift_time = 800
var throttle_val = 0.0
var brake_val = 0.0

var rotation_angle = 0


var auto_reverse_time = 0.0
var fov_change
#var steer_decay = 0.02
#var steer_decay = 0.05
#var steer_decay = 0.08
var steer_decay = 0.005

@onready var speed = 0.0
var normal_friction_slip = 1

enum tranny_type {
	AUTO,
	MANUAL
}

@export var transmission : tranny_type = tranny_type.MANUAL



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
	fov_change = 0.0

	

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
			if rpm > 0.9 * max_rpm and current_gear > 0 and current_gear < gear_ratio.size() and (Time.get_ticks_msec() - last_shift_time) > shift_time:
				current_gear = current_gear + 1
				gear_timer = gear_shift_time
				last_shift_time = Time.get_ticks_msec()
			elif rpm < 0.5* max_rpm and current_gear <= gear_ratio.size() and current_gear > 1 and(Time.get_ticks_msec() - last_shift_time) > shift_time:
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
	
	var info = 'Brake %.0f Drivetype %s Gear %d| Clutch Pos %.0f\nThrottle %.1f Brake %.1f \nFRONT L %.0f | FRONT R %.0f \nREAR L %.0f | REAR R %.0f'  % [brake, drivetype, current_gear, clutch_position, throttle_val,brake_val, $fr.engine_force, $fl.engine_force, $rl.engine_force, $rr.engine_force] # .0f no decimals
	
	$Label.text = info

	var speedo = '%.0f KM/H' % [ speed ]

func freewheel():
	pass

func _physics_process(delta):
	#linear_velocity.x = ai_controller.move.x
	#linear_velocity.y = ai_controller.move.y
	whinepitch = abs(rpm/gear_ratio[current_gear - 1])*1.5
	current_speed_mps = (position - last_pos).length() / delta
	var max_steer_at_speed = max_steer - (steer_decay * speed)
	max_steer_at_speed = max(0.2, max_steer_at_speed)
	steering = move_toward(steering, Input.get_axis("right", "left") * max_steer_at_speed, delta * 2.5)

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
		$"../FreeLookCamera".current = true
	
	rpm = calculate_rpm()
	var rpm_factor = clamp(rpm / max_rpm, 0.0, 1.0)
	var power_factor = power_curve.sample_baked(rpm_factor) * 3
	var reverse_lights = $"reverse lights"
	if current_gear == 0:
		for child in reverse_lights.get_children():
			child.show()
	else:
		for child in reverse_lights.get_children():
			child.hide()
			
	if drivetype == DRIVE_TYPE.FWD:
		if current_gear == 0:
			$fl.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive * max_engine_force * 0.5
			$fr.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive * max_engine_force * 0.5
		elif current_gear > 0 and current_gear <= gear_ratio.size():
			$fl.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force * 0.5
			$fr.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force * 0.5

	elif drivetype == DRIVE_TYPE.RWD:
		if current_gear == 0:
			$rl.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio *final_drive * max_engine_force
			$rr.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive * max_engine_force 
		elif current_gear > 0 and current_gear <= gear_ratio.size():
			$rl.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force 
			$rr.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force 

	elif drivetype == DRIVE_TYPE.AWD:
		# braindead AWD
		if current_gear == 0:
			$fl.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive *max_engine_force * (1 - torque_split) * 0.5
			$fr.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive *max_engine_force * (1 - torque_split) * 0.5
			$rr.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive *max_engine_force * torque_split * 0.5
			$rl.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive *max_engine_force * torque_split * 0.5
		elif current_gear > 0 and current_gear <= gear_ratio.size():
			$fl.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force * (1 - torque_split) * 0.5
			$fr.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force * (1 - torque_split) * 0.5
			$rr.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force * torque_split * 0.5
			$rl.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force * torque_split * 0.5

				
	brake = brake_val * max_brake_force
	if brake > 10:
		$fr.wheel_friction_slip -= 1
		$fl.wheel_friction_slip -= 1
		$rr.wheel_friction_slip -= 1
		$rl.wheel_friction_slip -= 1
	else:
		$fr.wheel_friction_slip = normal_friction_slip
		$fl.wheel_friction_slip = normal_friction_slip
		$rr.wheel_friction_slip = normal_friction_slip
		$rl.wheel_friction_slip = normal_friction_slip

	var brake_lights = $brakelights
	if brake_val == 0.0:
		for child in brake_lights.get_children():
			child.hide()
	else:
		for child in brake_lights.get_children():
			child.show()
		#
	#else:
		#$braketrail/l1.trailOn()
		#$braketrail/l2.trailOn()
		#$braketrail/l3.trailOn()
		#$braketrail/l4.trailOn()
		#
		#
	#if current_speed_mps < 30:
		#$braketrail/l1.killall()
		#$braketrail/l2.killall()
		#$braketrail/l3.killall()
		#$braketrail/l4.killall()
	
	
	# remember where I am
	last_pos = position
	var skidinfos = [$fr.get_skidinfo(), $rr.get_skidinfo(), $fl.get_skidinfo(), $rl.get_skidinfo()]
	var smokes = $smokes
	

	for i in range(skidinfos.size()):
		if skidinfos[i] < 0.5:
			for child in smokes.get_children():
				child.emitting = true
			# currently an earrape mess
			#$tyre_sound.skidding = true
		else:
			for child in smokes.get_children():
				child.emitting = false
			$tyre_sound.skidding = false

