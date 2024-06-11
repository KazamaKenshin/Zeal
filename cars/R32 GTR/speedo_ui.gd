extends Control


var digit1 : Sprite2D
var digit2 : Sprite2D
var digit3 : Sprite2D

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
var speed : int = 0

func _ready():
	for path in DIGIT_TEXTURE_PATHS:
		var texture = load(path)
		digit_textures.append(texture)

func update_speedometer():
	var digit3_value = speed % 10
	var digit2_value = (speed / 10) % 10
	var digit1_value = (speed / 100) % 10

	$digit1.texture = digit_textures[digit1_value]
	$digit2.texture = digit_textures[digit2_value]
	$digit3.texture = digit_textures[digit3_value]
	
func _process(delta):
	speed = $"../..".speed
	update_speedometer()
