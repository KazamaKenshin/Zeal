extends Resource

const SAVE_GAME_PATH = "res://savedgame.tres"
@export var colour := ""

func save_color():
	ResourceSaver.save(SAVE_GAME_PATH, self)
	
	
	
