extends Node

var last_checkpoint_position : Vector2
var last_state : Player.STATE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
