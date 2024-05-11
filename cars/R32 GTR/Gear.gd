extends Sprite2D


var digit : Sprite2D


const DIGIT_TEXTURE_PATHS: Array = [
	"res://digits/0.png",
	"res://digits/1.png",
	"res://digits/2.png",
	"res://digits/3.png",
	"res://digits/4.png",
	"res://digits/5.png",
	"res://digits/6.png",
	"res://digits/7.png",
	"res://digits/8.png",
	"res://digits/9.png"
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
