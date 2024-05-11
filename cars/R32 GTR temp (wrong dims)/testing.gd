extends VehicleBody3D
## TESTING ##

############################################################
@export var max_engine_force = 320
@export var max_brake_force = 30
@export var max_rpm = 7300
@export var idle_rpm = 1100
@export var max_steer = 0.8
@export var gear_ratio = [6.428, 3.85, 2.604, 2, 1.8]
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
var current_gear = 0
var clutch_position : float = 1.0
var current_speed_mps = 0.0
@onready var last_pos = position
@onready var rpm = 0

@export var whinepitch = 0.0

var throttle_speed = 0.4
var brake_speed = 0.6


var gear_shift_time = 0.5
var gear_timer = 0.0
var last_shift_time = 0
var shift_time = 800
var throttle_val = 0.0
var brake_val = 0.0

var rotation_angle = 0
var wheelspin = -50000

var fov_change
#var steer_decay = 0.02
#var steer_decay = 0.05
#var steer_decay = 0.08
var steer_decay = 0.005

@onready var speed = 0.0

var normal_friction_slip = 5
var ratio = 0.0

enum tranny_type {
	AUTO,
	MANUAL
}

@export var transmission : tranny_type = tranny_type.MANUAL

@onready var rr_wheel = get_node("rr")
@onready var rl_wheel = get_node("rl")
@onready var fr_wheel = get_node("fr")
@onready var fl_wheel = get_node("fl")

@onready var front_wheels = [$fl, $fr]
@onready var rear_wheels = [$rl, $rr]

#####################################

@export var engine_drag = 0.03
@export var engine_brake = 10.0
@export var engine_moment = 0.25
const AV_2_RPM: float = 60 / TAU
var drag_torque: float = 0.0
var torque_out: float = 0.0
var drive_inertia: float = 0.0 #includes every inertia of the drivetrain
var r_split: float = 0.5
var avg_front_spin = 0.0




func calculate_rpm() -> float:
	var wheel_circumference : float = 2.0 * PI * $rr.wheel_radius
	var wheel_rotation_speed : float = 60.0 * current_speed_mps / wheel_circumference
	var drive_shaft_rotation_speed : float = wheel_rotation_speed * final_drive
	if current_gear == -1:
		ratio = reverse_ratio * final_drive * 5
		return drive_shaft_rotation_speed * - reverse_ratio + idle_rpm
	elif current_gear <= gear_ratio.size():
		ratio = gear_ratio[current_gear - 1] * final_drive * 5
		return drive_shaft_rotation_speed * gear_ratio[current_gear - 1] + idle_rpm
	elif current_gear == 0:
		return idle_rpm
	else:
		return 0.0


func _ready():
	fov_change = 0.0

func _process_gear_inputs(delta: float):
	if gear_timer > 0.0:
		gear_timer = max(0.0, gear_timer - delta)
		clutch_position = 1.0
	else:
		if transmission == tranny_type.MANUAL:
			if Input.is_action_pressed("sd") and current_gear > -1:
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
			if rpm < 0.5* max_rpm and current_gear <= gear_ratio.size()  and (Time.get_ticks_msec() - last_shift_time) > shift_time:
				current_gear = current_gear - 1
				gear_timer = gear_shift_time
				last_shift_time = Time.get_ticks_msec()
			if current_gear <= 1:
				current_gear = 1
			else:
				clutch_position = 1.0

func _process(delta : float):
	_process_gear_inputs(delta)
	var wheel_rpm = $rr.get_rpm()
	speed =	PI * $rr.wheel_radius * wheel_rpm * 60/1000
	rpm = calculate_rpm()
	if rpm > max_rpm:
		rpm = max_rpm
	
	var info = 'Brake %.0f Drivetype %s Gear %d| \nFRONT L %.0f | FRONT R %.0f \nREAR L %.0f | REAR R %.0f'  % [brake, drivetype, current_gear, $fr.engine_force, $fl.engine_force, $rl.engine_force, $rr.engine_force] # .0f no decimals
	
	$Label.text = info

	var speedo = '%.0f KM/H' % [ speed ]





func _physics_process(delta):
	#linear_velocity.x = ai_controller.move.x
	#linear_velocity.y = ai_controller.move.y
	whinepitch = abs(rpm/gear_ratio[current_gear - 1])*1.5
	current_speed_mps = (position - last_pos).length() / delta
	var max_steer_at_speed = max_steer - (steer_decay * speed)
	max_steer_at_speed = max(0.2, max_steer_at_speed)
	steering = move_toward(steering, Input.get_axis("right", "left") * max_steer_at_speed, delta * 2.5)

	throttle_val = clamp(throttle_val + throttle_speed * delta, 0.0, 1.0) if Input.get_action_strength("throttle") else 0.0
	brake_val = clamp(brake_val + brake_speed * delta, 0.0, 1.0) if Input.get_action_strength("brake") else 0.0
	
	
	if Input.is_action_pressed("freecam"):
		$"../FreeLookCamera".current = true
	
	rpm = calculate_rpm()
	var rpm_factor = clamp(rpm / max_rpm, 0.0, 1.0)
	var power_factor = power_curve.sample_baked(rpm_factor)
	if drivetype == DRIVE_TYPE.FWD:
		if current_gear == -1:
			$fl.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive * max_engine_force
			$fr.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive * max_engine_force
			$"reverse light/reverse1".show()
			$"reverse light/reverse2".show()

		elif current_gear > 0 and current_gear <= gear_ratio.size():
			$fl.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force
			$fr.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force
			$"reverse light/reverse1".hide()
			$"reverse light/reverse2".hide()
		elif current_gear == 0:
			#freewheel()	
			$"reverse light/reverse1".hide()
			$"reverse light/reverse2".hide()

	elif drivetype == DRIVE_TYPE.RWD:
		if current_gear == -1:
			$rl.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio *final_drive * max_engine_force
			$rr.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive * max_engine_force
			$"reverse light/reverse1".show()
			$"reverse light/reverse2".show()
		elif current_gear > 0 and current_gear <= gear_ratio.size():
			$rl.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force
			$rr.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force
			$"reverse light/reverse1".hide()
			$"reverse light/reverse2".hide()
		elif current_gear == 0:
		
			$"reverse light/reverse1".hide()
			$"reverse light/reverse2".hide()

	elif drivetype == DRIVE_TYPE.AWD:
		# braindead AWD, ATTESA soon
		if current_gear == -1:
			$fl.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive *max_engine_force * (1 - torque_split)
			$fr.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive *max_engine_force * (1 - torque_split)
			$rr.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive *max_engine_force * torque_split
			$rl.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive *max_engine_force * torque_split
			$"reverse light/reverse1".show()
			$"reverse light/reverse2".show()

		elif current_gear > 0 and current_gear <= gear_ratio.size():
			$fl.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force * (1 - torque_split)
			$fr.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force * (1 - torque_split)
			$rr.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force * torque_split
			$rl.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force * torque_split
			$"reverse light/reverse1".hide()
			$"reverse light/reverse2".hide()

		elif current_gear == 0:

			$"reverse light/reverse1".hide()
			$"reverse light/reverse2".hide()
				
	brake = brake_val * max_brake_force
	if brake > 10:
		$rr.wheel_friction_slip -= 4.5
		$rl.wheel_friction_slip -= 4.5
	else:
		$rr.wheel_friction_slip = normal_friction_slip
		$rl.wheel_friction_slip = normal_friction_slip
	
	if brake_val == 0.0:

		
		$brakelight/bl1.hide()
		$brakelight/bl2.hide()
		$brakelight/bl3.hide()
		$brakelight/bl4.hide()
		
	else:

		$brakelight/bl1.show()
		$brakelight/bl2.show()
		$brakelight/bl3.show()
		$brakelight/bl4.show()
	
	
	# remember where I am
	last_pos = position
	var skidinfos = [$fr.get_skidinfo(), $rr.get_skidinfo(), $fl.get_skidinfo(), $rl.get_skidinfo()]
	var smokes = [$smoke/smoke1, $smoke/smoke2,$smoke/smoke3,$smoke/smoke4]

	for i in range(skidinfos.size()):
		if skidinfos[i] < 0.7:
			smokes[i].emitting = true
			# currently an earrape mess
			#$tyre_sound.skidding = true
		else:
			smokes[i].emitting = false
			$tyre_sound.skidding = false

