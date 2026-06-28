@abstract extends Node2D
class_name BaseLevel

@export var world_tilemap : TileMapLayer
@export var background_tilemap : TileMapLayer
@export var player : Player
@export var music : AudioStreamPlayer
@export var win : Area2D

var player_dead : bool = false

signal finished_level

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE # THIS IS MY STAND'S POWER!! THE WORLD!!
	win.body_entered.connect(win_level)
	player.died.connect(player_died)

func win_level(body) -> void:
	if body is Player:
		finished_level.emit()

func _physics_process(_delta: float) -> void:
	if not player.current_state == Player.STATE.DEAD:
		player_dead = false

func player_died() -> void:
	player_dead = true
