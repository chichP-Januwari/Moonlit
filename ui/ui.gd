extends CanvasLayer

@onready var play: Button = $Control/MarginContainer/VBoxContainer/Play
@onready var restart_checkpoint: Button = $Control/MarginContainer/VBoxContainer/RestartCheckpoint
@onready var restart_game: Button = $Control/MarginContainer/VBoxContainer/RestartGame
@onready var general_label: Label = $Control/MarginContainer/VBoxContainer/GeneralLabel

@onready var stopwatch_label: Label = $Control/MarginContainer/VBoxContainer/Stopwatch
@onready var stopwatch: Stopwatch = $Control/MarginContainer/VBoxContainer/Stopwatch/Stopwatch

@onready var animation: AnimationPlayer = $AnimationPlayer
