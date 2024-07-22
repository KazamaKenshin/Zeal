extends Sprite2D


var digit : Sprite2D


const DIGIT_TEXTURE_PATHS: Array = [
	"res://assets/digits/0.png",
	"res://assets/digits/1.png",
	"res://assets/digits/2.png",
	"res://assets/digits/3.png",
	"res://assets/digits/4.png",
	"res://assets/digits/5.png",
	"res://assets/digits/6.png",
	"res://assets/digits/7.png",
	"res://assets/digits/8.png",
	"res://assets/digits/9.png"
]

var digit_textures: Array = []
var gear : int = 0

func _ready():
	for path in DIGIT_TEXTURE_PATHS:
		var texture = load(path)
		digit_textures.append(texture)

func update_gear():
	$".".texture = digit_textures[gear]

func _process(delta):
	gear = $"../../..".current_gear
	update_gear()
