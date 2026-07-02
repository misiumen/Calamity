extends Node
# ponytail: one autoload, one var — menu -> game handoff
var character := "swarm"

func _ready() -> void:
	if OS.get_environment("CAL_CHAR") != "":
		character = OS.get_environment("CAL_CHAR")
