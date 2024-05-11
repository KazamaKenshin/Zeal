class_name Save
extends Node

@onready var car_color = $"../../car pos/PLAYER/body".mesh.surface_get_material(0)

func _ready():
	save_game()

func save_game():
	var file = FileAccess.open("res://saves/save.data", FileAccess.WRITE)
	file.store_var(car_color)
	file.close()
	print(car_color)
	
func load_game():
	pass
