extends Node2D

enum GAME_STATE {
	MAIN_MENU,
	PLAYING,
	PAUSED,
	DEAD,
	FINISHED,
}

# Nooddddeeeeesss
@export var ui: CanvasLayer

# Levels
var level_depths_scene = preload("res://levels/level_depths.tscn")

# Trackers
var current_game_state : GAME_STATE = GAME_STATE.MAIN_MENU
var current_level

func _ready() -> void:
	add_child(level_depths_scene.instantiate()) # Instantiate first level
	current_level = $LevelDepths
	$LevelDepths.finished_level.connect(level_finish)

func _physics_process(_delta: float) -> void:
	match current_game_state:
		GAME_STATE.MAIN_MENU:
			ui.play.visible = false
			ui.restart_checkpoint.visible = false
			ui.restart_game.visible = false
			ui.general_label.visible = true
			ui.general_label.text = "Moonlit:
				Press J or K to break your egg"
			
			if Input.is_action_just_pressed("rise"):
				switch_state(GAME_STATE.PLAYING) # To PLAYING
			if Input.is_action_just_pressed("charge"):
				switch_state(GAME_STATE.PLAYING) # To PLAYING
				
		GAME_STATE.PLAYING:
			ui.stopwatch_label.text = ui.stopwatch.get_time_formatted()
			if current_level.player_dead:
				switch_state(GAME_STATE.DEAD)
			
		GAME_STATE.PAUSED:
			pass
			
		GAME_STATE.DEAD:
			switch_state(GAME_STATE.PLAYING)

func switch_state(to_state: GAME_STATE) -> void:
	current_game_state = to_state
	match to_state:
		GAME_STATE.MAIN_MENU:
			ui.play.visible = false
			ui.restart_checkpoint.visible = false
			ui.restart_game.visible = false
			ui.general_label.visible = true
			
		GAME_STATE.PLAYING:
			ui.play.visible = false
			ui.restart_checkpoint.visible = false
			ui.restart_game.visible = false
			ui.general_label.visible = false
			if not ui.stopwatch.running:
				ui.stopwatch.start_time()
			get_tree().paused = false
			
		GAME_STATE.PAUSED:
			ui.general_label.visible = true
			ui.general_label.text = "Thanks for playing Moonlit: Jam Version"
			get_tree().paused = true
			
		GAME_STATE.DEAD:
			ui.play.visible = false
			ui.restart_checkpoint.visible = false
			ui.restart_game.visible = false
			ui.general_label.visible = false
			
			ui.animation.play("fade_out")
			ui.animation.queue("fade_in")
			

func level_finish() -> void:
	switch_state(GAME_STATE.PAUSED)
