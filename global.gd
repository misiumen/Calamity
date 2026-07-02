extends Node
# ponytail: one autoload — menu -> game handoff
var character := "swarm"
var city := "kowloon"

func _ready() -> void:
	if OS.get_environment("CAL_CHAR") != "":
		character = OS.get_environment("CAL_CHAR")
	if OS.get_environment("CAL_CITY") != "":
		city = OS.get_environment("CAL_CITY")
