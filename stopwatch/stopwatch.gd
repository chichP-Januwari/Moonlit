extends Node
class_name Stopwatch

var running : bool
var current_time : float # In seconds

func _physics_process(delta: float) -> void:
	if running:
		current_time += delta # Increment by delta

func start_time() -> void:
	running = true

func get_time_formatted() -> String:
	var hours : int
	var minutes : int
	var seconds : float
	
	if current_time:
		seconds = current_time
		minutes = floor(seconds) / 60
		@warning_ignore("integer_division")
		hours = minutes / 60
		
		seconds -= minutes * 60
		seconds -= hours * 3600
	if hours == 0 and minutes == 0 and seconds:
		return str("%.2f" % seconds)
	elif hours == 0 and minutes and seconds:
		return str("%d:%.2f" % [minutes, seconds])
	else:
		return str("%d:%d:%.2f" % [hours, minutes, seconds])
