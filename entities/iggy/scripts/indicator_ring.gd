extends AnimatedSprite2D

# Nodes
@export var iggy: Player

func _physics_process(_delta: float) -> void:
	match iggy.current_state:
		Player.STATE.WATER:
			match iggy.current_water_state:
				Player.WATER_STATE.IDLE:
					visible = true
					play("ring_reset")
				Player.WATER_STATE.SWIMMING:
					visible = false
					
				Player.WATER_STATE.JUMP:
					if iggy.velocity.x < 40.0:
						if iggy.charges_left == 2:
							play("ring_charge")
							visible = true
						elif iggy.charges_left == 1:
							play("ring_last_charge")
							visible = true
						else:
							visible = false
					else:
						visible = false
					
				Player.WATER_STATE.FALL:
					if iggy.velocity.x < 40.0:
						if iggy.charges_left == 2:
							play("ring_charge")
							visible = true
						elif iggy.charges_left == 1:
							play("ring_last_charge")
							visible = true
						else:
							visible = false
					else:
						visible = false
					
				Player.WATER_STATE.CHARGING:
					visible = true
					if iggy.charges_left == 2:
						play("ring_charge")
					elif iggy.charges_left == 1:
						play("ring_last_charge")
					
				Player.WATER_STATE.CHARGED:
					visible = true
					if iggy.charges_left == 2:
						play("ring_charge")
					elif iggy.charges_left == 1:
						play("ring_last_charge")
					
				Player.WATER_STATE.TIRED:
					visible = false
					
		Player.STATE.LAND:
			match iggy.current_land_state:
				Player.LAND_STATE.IDLE:
					visible = true
					play("ring_reset")
					
				Player.LAND_STATE.RUNNING:
					visible = false
					
				Player.LAND_STATE.JUMP:
					if iggy.velocity.x < 40.0:
						if not iggy.gliding_tired:
							visible = true
							play("ring_glide")
						else:
							visible = false
					else:
						visible = false
					
				Player.LAND_STATE.FALL:
					if iggy.velocity.x < 40.0:
						if not iggy.gliding_tired:
							visible = true
							play("ring_glide")
						else:
							visible = false
					else:
						visible = false
					
				Player.LAND_STATE.GLIDING:
					if not iggy.gliding_tired:
						visible = true
						play("ring_glide")
					else:
						visible = false
					
				Player.LAND_STATE.TIRED:
					visible = false
					
