extends Node3D

@export var backfire_FuelRichness = 0.2
@export var backfire_FuelDecay = 0.1
@export var backfire_Air = 0.02
@export var backfire_BackfirePrevention = 0.1
@export var backfire_BackfireThreshold = 1.0
@export var backfire_BackfireRate = 1.0
@export var backfire_Volume = 0.5


@export var WhinePitch = 4
@export var WhineVolume = 0.4
 
@export var BlowOffBounceSpeed = 0.0
@export var BlowOffWhineReduction = 1.0
@export var BlowDamping = 0.25
@export var BlowOffVolume = 0.5
@export var BlowOffVolume2 = 0.5
@export var BlowOffPitch1 = 0.5
@export var BlowOffPitch2 = 1.0
@export var MaxWhinePitch = 1.8
@export var SpoolVolume = 0.5
@export var SpoolPitch = 0.5
@export var BlowPitch = 5.0
@export var TurboNoiseRPMAffection = 0.25

@export var engine_sound = NodePath("../engine_sound")

@export var volume = 0.25
var blow_psi = 0.0
var blow_inertia = 0.0

var fueltrace = 0.0
var air = 0.0
var rand = 0.0

func play():
	$blow.stop()
	$spool.stop()
	$whistle.stop()
	$scwhine.stop()

	if get_parent().turbo_enabled:
		$blow.play()
		$spool.play()
		$whistle.play()
	if get_parent().supercharger_enabled:
		$scwhine.play()
			
func stop():
	for i in get_children():
		i.stop()

func _ready():
	play()

func _physics_process(delta):
	fueltrace += (get_parent().throttle_val)*backfire_FuelRichness
	air = (get_parent().throttle_val*get_parent().rpm)*backfire_Air +get_parent().max_psi

	fueltrace -= fueltrace*backfire_FuelDecay
	
	if fueltrace<0.0:
		fueltrace = 0.0
		
	if has_node(engine_sound):
		get_node(engine_sound).pitch_influence -= (get_node(engine_sound).pitch_influence - 1.0)*0.5

	var wh = abs(get_parent().rpm/10000.0)*WhinePitch
	if wh<0.0:
		wh = 0.0
	if wh>0.01:
		$scwhine.volume_db = linear_to_db(WhineVolume*volume)
		$scwhine.max_db = $scwhine.volume_db
		$scwhine.pitch_scale = wh
	else:
		$scwhine.volume_db = linear_to_db(0.0)


	var dist = blow_psi - get_parent().max_psi
	blow_psi -= (blow_psi - get_parent().max_psi)*BlowOffWhineReduction
	blow_inertia += blow_psi - get_parent().max_psi
	blow_inertia -= (blow_inertia - (blow_psi - get_parent().max_psi))*BlowDamping
	blow_psi -= blow_inertia*BlowOffBounceSpeed

	if blow_psi>get_parent().max_psi:
		blow_psi = get_parent().max_psi
		
	var blowvol = dist
	if blowvol<0.0:
		blowvol = 0.0
	elif blowvol>1.0:
		blowvol = 1.0

	var spoolvol = get_parent().max_psi/10.0
	if spoolvol<0.0:
		spoolvol = 0.0
	elif spoolvol>1.0:
		spoolvol = 1.0

	spoolvol += (abs(get_parent().rpm)*(TurboNoiseRPMAffection/1000.0))*spoolvol

	var blow = linear_to_db(volume*(blowvol*BlowOffVolume2))
	if blow<-60.0:
		blow = -60.0
	var spool = linear_to_db(volume*(spoolvol*SpoolVolume))
	if spool<-60.0:
		spool = -60.0

	$blow.volume_db = blow
	$spool.volume_db = spool
	
	$blow.max_db = $blow.volume_db
	$spool.max_db = $spool.volume_db
	var yes = blowvol*BlowOffVolume
	if yes>1.0:
		yes = 1.0
	elif yes<0.0:
		yes = 0.0
	var whistle = linear_to_db(yes)
	if whistle<-60.0:
		whistle = -60.0
	$whistle.volume_db = whistle
	$whistle.max_db = $whistle.volume_db
	var wps = 1.0
	if get_parent().max_psi>0.0:
		wps = blowvol*BlowOffPitch2 +get_parent().max_psi*0.05 +BlowOffPitch1
	else:
		wps = blowvol*BlowOffPitch2 +BlowOffPitch1
	if wps>MaxWhinePitch:
		wps = MaxWhinePitch
	$whistle.pitch_scale = wps
	$spool.pitch_scale = SpoolPitch +spoolvol*0.5
	$blow.pitch_scale = BlowPitch


	var h = get_parent().whinepitch/200.0
	if h>1.0:
		h = 1.0
	elif h<0.5:
		h = 0.5
		





