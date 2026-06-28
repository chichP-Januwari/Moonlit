extends Area2D

@export var animation_player: AnimationPlayer
@export var collision: CollisionShape2D

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		animation_player.play("earthworm_jim") # Eugh I'm dead...
		collision.call_deferred("set_disabled", true)
		CheckpointManager.last_checkpoint_position = body.position
		CheckpointManager.last_state = body.current_state
		
		queue_free()
