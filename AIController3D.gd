extends AIController3D

var move = Vector2.ZERO
@onready var target = $"../../Target"
@onready var PLAYER = $".."


func get_obs() -> Dictionary:
	var obs := [
		PLAYER.position.x,
		PLAYER.position.z,
		target.position.x,
		target.position.z
	]
	return {"obs":[]}

func get_reward() -> float:	
	return reward
	
func get_action_space() -> Dictionary:
	return {
		"acceleration": {"size": 1, "action_type": "continuous"},
		"steering": {"size": 1, "action_type": "continuous"},
		}
	
func set_action(action) -> void:
	_player.requested_acceleration = clampf(action.acceleration[0], -1.0, 1.0)
	_player.requested_steering = clampf(action.steering[0], -1.0, 1.0)
	
	# -----------------------------------------------------------------------------#

#-- Methods that can be overridden if needed --#

#func get_obs_space() -> Dictionary:
# May need overriding if the obs space is complex
#	var obs = get_obs()
#	return {
#		"obs": {
#			"size": [len(obs["obs"])],
#			"space": "box"
#		},
#	}
