extends Sprite2D

@export var iggy: Player
@export var iggy_p_cam_2d: PhantomCamera2D

@export var audio: AudioStreamPlayer
@export var music: AudioStreamPlayer


var egg_break_counter := 4

func _ready() -> void:
	iggy.process_mode = Node.PROCESS_MODE_DISABLED
	iggy.visible = false

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("rise"):
		egg_break_counter -= 1
		audio.play()
		
	elif Input.is_action_just_pressed("charge"):
		egg_break_counter -= 1
		audio.play()
	
	if egg_break_counter:
		match egg_break_counter:
			4:
				region_rect = Rect2i(0, 0, 16, 16)
			3:
				region_rect = Rect2i(16, 0, 16, 16)
			2:
				region_rect = Rect2i(32, 0, 16, 16)
			1:
				region_rect = Rect2i(48, 0, 16, 16)
	else:
		$PhantomCamera2D.set_priority(1)
		iggy.process_mode = Node.PROCESS_MODE_INHERIT
		iggy.visible = true
		iggy_p_cam_2d.set_priority(15)
		
		music.play()
		
		queue_free() # Ugh... My life is so boring... Time to get out and touch the moon BLEH :P
