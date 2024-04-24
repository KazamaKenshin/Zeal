extends Control

func _ready():
	$VBoxContainer/carkeys.grab_focus()

func _on_carkeys_pressed():
	get_tree().change_scene_to_file("res://WORLD.tscn") #should be level menu
	
func _on_tuning_pressed():
	pass

func _on_park_pressed():
	get_tree().quit()
