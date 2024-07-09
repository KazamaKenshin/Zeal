extends Node3D

var siren_active = true

@onready var red_light = $red
@onready var blue_light = $blue
@onready var red_light2 = $red2
@onready var blue_light2 = $blue2
@onready var siren_sound = $siren_sound
var time_passed := 0.0
var flash_state := 0
var flash_time = 0.05
var flash_energy = 4.0

func _physics_process(delta):
	if siren_active == true:
		if not siren_sound.playing:
			siren_sound.play()
		time_passed += delta
		if time_passed >= flash_time:
			time_passed = 0.0
			flash_state += 1
			if flash_state > 7:
				flash_state = 0
			
		match flash_state:
			0, 2:
				blue_light.light_energy = flash_energy
				blue_light2.light_energy = flash_energy
				red_light.light_energy = 0.0
				red_light2.light_energy = 0.0
			1, 3:
				blue_light.light_energy = 0.0
				blue_light2.light_energy = 0.0
				red_light.light_energy = 0.0
				red_light2.light_energy = 0.0
			4, 6:
				blue_light.light_energy = 0.0
				blue_light2.light_energy = 0.0
				red_light.light_energy = flash_energy
				red_light2.light_energy = flash_energy
			5, 7:
				blue_light.light_energy = 0.0
				blue_light2.light_energy = 0.0
				red_light.light_energy = 0.0
				red_light2.light_energy = 0.0
