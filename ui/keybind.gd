class_name keybind
extends Resource

const LEFT : String = "left"
const RIGHT : String = "right"
const THROTTLE : String = "throttle"
const BRAKE : String = "brake"
const SHIFT_UP : String = "su"
const SHIFT_DOWN : String = "sd"
const HANDBRAKE : String = "hb"

@export var DEFAULT_LEFT_KEY = InputEventKey.new()
@export var DEFAULT_RIGHT_KEY = InputEventKey.new()
@export var DEFAULT_THROTTLE_KEY = InputEventKey.new()
@export var DEFAULT_BRAKE_KEY = InputEventKey.new()
@export var DEFAULT_SHIFT_UP_KEY = InputEventKey.new()
@export var DEFAULT_SHIFT_DOWN_KEY = InputEventKey.new()
@export var DEFAULT_HANDBRAKE_KEY = InputEventKey.new()

var left_key = InputEventKey.new()
var right_key = InputEventKey.new()
var throttle_key = InputEventKey.new()
var brake_key = InputEventKey.new()
var su_key = InputEventKey.new()
var sd_key = InputEventKey.new()
var hb_key = InputEventKey.new()
