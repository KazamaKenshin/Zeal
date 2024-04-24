extends Node3D

var pitch = 0.0
var volume = 0.0
var fade = 0.0

	
var maxfades = 0.0

func play():
	for i in get_children():
		i.play()
		
func stop():
	for i in get_children():
		i.stop()
		
func _ready():
	maxfades = float(get_child_count() - 1.0)

func _physics_process(_delta):

		if fade < 0.0:
			fade = 0.0
		elif fade > get_child_count() - 1.0:
			fade = get_child_count() - 1.0
		for i in get_children():
			var maxvol = float(i.get_child(0).name) / 100.0
			var maxpitch = float(i.name) / 100000.0
			
			var index = float(i.get_index())
			var dist = abs(index - fade)
			var vol = 1.0 - dist
			if vol < 0.0:
				vol = 0.0
			elif vol > 1.0:
				vol = 1.0
			#i.unit_db = linear2db((vol * maxvol) * (volume * cache.svolume))
			i.max_db = i.unit_db
			i.pitch_scale = (abs(pitch * maxpitch) + 1e-17)
		
		
