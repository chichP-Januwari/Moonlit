extends CharacterBody2D
class_name Player

# States
enum STATE {
	WATER,
	LAND,
}

enum WATER_STATE {
	IDLE,
	SWIMMING,
	JUMP,
	FALL,
	CHARGING,
	CHARGED,
	TIRED,
}

enum LAND_STATE {
	IDLE,
	RUNNING,
	JUMP,
	FALL,
}

# Nodes
@export var collision_larva: CollisionShape2D
@export var collision_fly: CollisionShape2D
@export var water_sprite: AnimatedSprite2D
@export var land_sprite: AnimatedSprite2D
@export var max_charging_time: Timer
@export var max_charge_time: Timer
@export var max_jump_time: Timer
@export var jump_cooldown: Timer
@export var jump_buffer: Timer

# Constants
const WATER_MAX_SPEED := 300.0
const WATER_JUMP_FORCE := -50.0
const WATER_CHARGE_FORCE := 300.0
const WATER_MAX_CHARGES := 2 # You can charge underwater, but you have a speed limit and charge limit

const LAND_MAX_SPEED := 1000.0
const LAND_JUMP_FORCE := -170.0 # You have a high speed limit on land, but you have no charge
const LAND_FLY_FORCE := 250.0 # (instead you glide, which lets you convert gravity to horizontal speed)

var water_friction := 0.05
var land_friction := 0.3

var water_gravity : float = ProjectSettings.get_setting("physics/2d/default_gravity") / 4 # 245
var land_gravity : float = ProjectSettings.get_setting("physics/2d/default_gravity") # 980

# Trackers
@export var current_state : STATE
@export var current_water_state : WATER_STATE
@export var current_land_state : LAND_STATE

var direction : Vector2
var last_direction : Vector2
var last_velocity : Vector2

var charges_left : int = WATER_MAX_CHARGES:
	set(value):
		charges_left = clampi(value, 0, WATER_MAX_CHARGES)

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	direction = Input.get_vector("left", "right", "up", "down").normalized()
	
	if in_water():
		current_state = STATE.WATER
	else:
		current_state = STATE.LAND
	
	match current_state:
		STATE.WATER:
			water_state_machine(current_water_state, delta)
			
			if not current_water_state == WATER_STATE.CHARGED and direction:
				last_direction = Vector2i(direction.round())
			
			if sign(last_direction.x) == 1:
				water_sprite.flip_h = false
			elif sign(last_direction.x) == -1:
				water_sprite.flip_h = true
			
			print(WATER_STATE.find_key(current_water_state))
		
		STATE.LAND:
			land_state_machine(current_land_state, delta)
			
			if direction: # Some states don't track and use it
				last_direction = Vector2i(direction.ceil())
				
			if sign(last_direction.x) == 1:
				land_sprite.flip_h = false
			elif sign(last_direction.x) == -1:
				land_sprite.flip_h = true
			
			print(LAND_STATE.find_key(current_land_state))
	
	move_and_slide()
	print(velocity)

func water_state_machine(state: WATER_STATE, delta: float):
	match state:
		WATER_STATE.IDLE:
			velocity = velocity.lerp(Vector2.ZERO, water_friction)
			if direction:
				switch_water(WATER_STATE.SWIMMING) # To SWIMMING
			
			if Input.is_action_just_pressed("rise"):
				switch_water(WATER_STATE.JUMP) # To JUMP
			
			if not is_on_floor():
				switch_water(WATER_STATE.FALL) # To FALL
			
			if Input.is_action_just_pressed("charge"):
				switch_water(WATER_STATE.CHARGING) # To CHARGING
			
		WATER_STATE.SWIMMING:
			if direction:
				velocity.x = lerp(velocity.x, WATER_MAX_SPEED * direction.x , water_friction)
			elif not direction:
				switch_water(WATER_STATE.IDLE) # To IDLE
			
			if Input.is_action_just_pressed("rise"):
				switch_water(WATER_STATE.JUMP) # To JUMP
			
			if not is_on_floor():
				switch_water(WATER_STATE.FALL) # To FALL
			
			if Input.is_action_just_pressed("charge"):
				switch_water(WATER_STATE.CHARGING) # To CHARGING
			
		WATER_STATE.JUMP:
			if direction:
				velocity.x = lerp(velocity.x, WATER_MAX_SPEED * direction.x , water_friction)
			elif not direction:
				velocity.x = lerp(velocity.x, 0.0, water_friction)
			
			velocity.y += WATER_JUMP_FORCE
			
			if max_jump_time.is_stopped() or Input.is_action_just_released("rise"):
				switch_water(WATER_STATE.FALL) # To FALL
			
		WATER_STATE.FALL:
			if direction:
				velocity.x = lerp(velocity.x, WATER_MAX_SPEED * direction.x , water_friction)
			elif not direction:
				velocity.x = lerp(velocity.x, 0.0, water_friction)
			velocity.y += water_gravity * delta
			
			if water_sprite.animation == "larva_fall" and direction:
				water_sprite.play("larva_swim")
			elif not direction:
				water_sprite.play("larva_fall")
			
			if Input.is_action_just_pressed("rise") and jump_cooldown.is_stopped():
				switch_water(WATER_STATE.JUMP) # To JUMP
			
			if Input.is_action_pressed("charge") and charges_left:
				switch_water(WATER_STATE.CHARGING) # To CHARGING
			elif Input.is_action_pressed("charge") and not charges_left:
				switch_water(WATER_STATE.TIRED) # To TIRED
			
			if is_on_floor():
				switch_water(WATER_STATE.IDLE) # To IDLE
			elif is_on_floor() and direction:
				switch_water(WATER_STATE.SWIMMING) # To SWIMMING
			
		WATER_STATE.CHARGING:
			if charges_left:
				if Input.is_action_just_released("charge") or max_charging_time.is_stopped():
					switch_water(WATER_STATE.CHARGED) # To CHARGED
			elif charges_left == 0:
				switch_water(WATER_STATE.TIRED) # To TIRED
			velocity = velocity.lerp(Vector2.ZERO, land_friction)
			
		WATER_STATE.CHARGED:
			velocity = Vector2(last_velocity.x, 0.0) + last_direction * WATER_CHARGE_FORCE
			
			if is_on_wall():
				max_charge_time.stop()
			
			if max_charge_time.is_stopped():
				if is_on_floor() and not direction:
					switch_water(WATER_STATE.IDLE) # To IDLE
				elif is_on_floor() and direction:
					switch_water(WATER_STATE.SWIMMING) # To SWIMMING
				elif not is_on_floor():
					switch_water(WATER_STATE.FALL) # To FALL
		
		WATER_STATE.TIRED:
			if direction:
				velocity.x = lerp(velocity.x, WATER_MAX_SPEED * direction.x , water_friction)
			elif not direction:
				velocity.x = lerp(velocity.x, 0.0, water_friction)
			velocity.y += water_gravity * delta
			
			if is_on_floor():
				switch_water(WATER_STATE.IDLE) # To IDLE
			elif is_on_floor() and direction:
				switch_water(WATER_STATE.SWIMMING) # To SWIMMING

func switch_water(to_state: WATER_STATE):
	current_water_state = to_state
	match to_state:
		WATER_STATE.IDLE:
			water_sprite.play("larva_idle")
			charges_left = WATER_MAX_CHARGES
		
		WATER_STATE.SWIMMING:
			water_sprite.play("larva_swim")
			charges_left = WATER_MAX_CHARGES
		
		WATER_STATE.JUMP:
			water_sprite.play("larva_jump")
			max_jump_time.start()
		
		WATER_STATE.FALL:
			water_sprite.play("larva_fall")
			jump_cooldown.start()
			
		WATER_STATE.CHARGING:
			water_sprite.play("larva_charging")
			max_charging_time.start()
			last_velocity = velocity
		
		WATER_STATE.CHARGED:
			water_sprite.play("larva_charge")
			if max_charging_time.is_stopped():
				max_charge_time.wait_time = .25
			else:
				max_charge_time.wait_time = 0.5 - max_charging_time.time_left
				max_charge_time.wait_time *= 0.5
				max_charge_time.stop()
			max_charge_time.start()
			jump_buffer.start()
			
			charges_left -= 1
		
		WATER_STATE.TIRED:
			water_sprite.play("larva_tired")

func land_state_machine(state: LAND_STATE, delta: float):
	match state:
		LAND_STATE.IDLE:
			pass
		LAND_STATE.RUNNING:
			pass
		LAND_STATE.JUMP:
			pass
		LAND_STATE.FALL:
			pass

func switch_land(to_state: LAND_STATE):
	current_land_state = to_state
	match to_state:
		LAND_STATE.IDLE:
			pass
		LAND_STATE.RUNNING:
			pass
		LAND_STATE.JUMP:
			pass
		LAND_STATE.FALL:
			pass

func in_water():
	return true # Placeholder, should convert player vector to tilemap coord, check tile if water, then return true if so
