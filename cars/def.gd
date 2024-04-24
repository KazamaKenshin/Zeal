## NISSAN SKYLINE R32 GT-R ##
extends VehicleBody3D

############################################################
@export var max_engine_force = 320
@export var max_brake_force = 30
@export var max_rpm = 7300
@export var idle_rpm = 1100
@export var max_steer = 0.8
@export var gear_ratio = [6.428, 3.85, 2.604, 2, 1.8]
@export var reverse_ratio = -3.0
@export var final_drive = 4.111

enum DRIVE_TYPE{
	FWD,
	RWD,
	AWD,
}
@export var drivetype := DRIVE_TYPE.AWD
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
@onready var rpm

var throttle_speed = 0.4
var brake_speed = 0.6


var gear_shift_time = 0.2
var gear_timer = 0.0
var throttle_val = 0.0
var brake_val = 0.0

var rotation_angle = 0
var wheelspin = -50000

var fov_change 
var steer_decay = 0.005
@onready var speed = 0.0

var normal_friction_slip = 5

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

@onready var audioplayer = $EngineSound


func get_speed_kph():
	return current_speed_mps * 3600.0 / 1000.0

func calculate_rpm() -> float:
	var wheel_circumference : float = 2.0 * PI * $rr.wheel_radius
	var wheel_rotation_speed : float = 60.0 * current_speed_mps / wheel_circumference
	var drive_shaft_rotation_speed : float = wheel_rotation_speed * final_drive
	if current_gear == -1:
		return drive_shaft_rotation_speed * - reverse_ratio + idle_rpm
	elif current_gear <= gear_ratio.size():
		return drive_shaft_rotation_speed * gear_ratio[current_gear - 1] + idle_rpm
	elif current_gear == 0:
		return idle_rpm 
	else:
		return 0.0


func _ready():
	fov_change = 0.0
	
func handbrake():
	var brake_force = -linear_velocity.normalized() * 100
	apply_central_force(global_transform.basis.z.normalized() * brake_force)
	apply_central_force(global_transform.basis.x.normalized() * brake_force)
	$fr.wheel_friction_slip =-2
	$fl.wheel_friction_slip =-2
	$rr.wheel_friction_slip =-2
	$rl.wheel_friction_slip =-2
	
func release_handbrake():
		$fr.wheel_friction_slip = normal_friction_slip
		$fl.wheel_friction_slip = normal_friction_slip
		$rr.wheel_friction_slip = normal_friction_slip
		$rl.wheel_friction_slip = normal_friction_slip

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
		clutch_position = 0.0
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
			if rpm > 0.9* max_rpm and current_gear > 0:
				current_gear = current_gear + 1
				gear_timer = gear_shift_time
				clutch_position = 0.0
			if rpm < 0.5* max_rpm and current_gear > 0:
				current_gear = current_gear - 1
				gear_timer = gear_shift_time
				clutch_position = 0.0
			else: 
				clutch_position = 1.0

func modify_fov(change: float, lerping_speed: float = 1.0):
	fov_change += change
	$CamPivot.new_fov = lerp($CamPivot.new_fov, $CamPivot.default_fov + fov_change, lerping_speed)

func _process(delta : float):
	_process_gear_inputs(delta)
	
	speed = get_speed_kph()
	rpm = calculate_rpm()
	if rpm > max_rpm:
		rpm = max_rpm
	
	var info = '%.0f RPM | Gear %d| NOS %s |%.0f HP | %.0f KMH'  % [rpm, current_gear,nos_active,current_hp, speed] # .0f no decimals
	
	$Label.text = info

	var speedo = '%.0f KM/H' % [ speed ]
	$Speedo.text = speedo




func _physics_process(delta):
	current_speed_mps = (position - last_pos).length() / delta
	var max_steer_at_speed = max_steer - steer_decay * speed
	max_steer_at_speed = max(0.2, max_steer_at_speed)
	steering = move_toward(steering, Input.get_axis("right", "left") * max_steer_at_speed, delta * 2.5)

	throttle_val = clamp(throttle_val + throttle_speed * delta, 0.0, 1.0) if Input.get_action_strength("throttle") else 0.0
	brake_val = clamp(brake_val + brake_speed * delta, 0.0, 1.0) if Input.get_action_strength("brake") else 0.0

		
	if Input.is_action_pressed("hb"):
			handbrake()
	else: 
		release_handbrake()

	if Input.is_action_pressed("nos") and nos >0:
			nitro()

	update_nitro(delta)

	rpm = calculate_rpm()
	var rpm_factor = clamp(rpm / max_rpm, 0.0, 1.0)	
	var power_factor = power_curve.sample_baked(rpm_factor)
	if DRIVE_TYPE.FWD:
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

	elif DRIVE_TYPE.RWD:
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

	elif DRIVE_TYPE.AWD:
			if current_gear == -1:
				front_wheels.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive *max_engine_force * (1 - torque_split)
				rear_wheels.engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive * max_engine_force * torque_split
				$"reverse light/reverse1".show()
				$"reverse light/reverse2".show()

			elif current_gear > 0 and current_gear <= gear_ratio.size():
				front_wheels.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force * (1 - torque_split)
				rear_wheels.engine_force = clutch_position * throttle_val * power_factor * gear_ratio[current_gear - 1] * final_drive * max_engine_force * torque_split				
				$"reverse light/reverse1".hide()
				$"reverse light/reverse2".hide()

			elif current_gear == 0:

				$"reverse light/reverse1".hide()
				$"reverse light/reverse2".hide()
				
	brake = brake_val * max_brake_force
	
	if brake_val == 0.0:
		$braketrail/l1.trailOff()
		$braketrail/l2.trailOff()
		$braketrail/l3.trailOff()
		$braketrail/l4.trailOff()
		
		$brakelight/bl1.hide()
		$brakelight/bl2.hide()
		$brakelight/bl3.hide()
		$brakelight/bl4.hide()
		
	else:
		$braketrail/l1.trailOn()
		$braketrail/l2.trailOn()
		$braketrail/l3.trailOn()
		$braketrail/l4.trailOn()
		
		$brakelight/bl1.show()
		$brakelight/bl2.show()
		$brakelight/bl3.show()
		$brakelight/bl4.show()
		
	if current_speed_mps < 30:
		$braketrail/l1.killall()	
		$braketrail/l2.killall()
		$braketrail/l3.killall()
		$braketrail/l4.killall()
	
	
	# remember where I am
	last_pos = position
	var skidinfos = [$fr.get_skidinfo(), $rr.get_skidinfo(), $fl.get_skidinfo(), $rl.get_skidinfo()]
	var smokes = [$smoke/smoke1, $smoke/smoke2,$smoke/smoke3,$smoke/smoke4]

	for i in range(skidinfos.size()):
		if skidinfos[i] < 0.3:
			smokes[i].emitting = true
		else:
			smokes[i].emitting = false
	play_engine_sound()
	
	
func play_engine_sound():
	var pitch_scaler = rpm / 1000
	if rpm >= idle_rpm and rpm < max_rpm:
		if !audioplayer.playing:
			audioplayer.play()
	if pitch_scaler > 0.1:
		audioplayer.pitch_scale = pitch_scaler

func stop_engine_sound():
	audioplayer.stop()



