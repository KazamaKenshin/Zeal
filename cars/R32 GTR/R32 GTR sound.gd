extends AudioStreamPlayer

var audio_stream: AudioStream
var audio_player: AudioStreamPlayer


var rpm_start = 0
var rpm_end = 7200

func _ready():
	# Load the audio file
	audio_stream = load("res://cars/R32 GTR/untitled.wav")

	# Create an AudioStreamPlayer node
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

func _process(delta):
	var current_rpm = $"..".rpm

	# Calculate the percentage of current RPM within the RPM range
	var rpm_percentage = (current_rpm - rpm_start) / (rpm_end - rpm_start)

	# Ensure the percentage is within bounds
	rpm_percentage = clamp(rpm_percentage, 0.0, 1.0)

	# Calculate the playback position based on the percentage of duration
	var playback_position = rpm_percentage * audio_stream.get_length()

	# Set the audio player's stream and playback position
	audio_player.set_stream(audio_stream)
	audio_player.seek(playback_position)
	audio_player.play()
