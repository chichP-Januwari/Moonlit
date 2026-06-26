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
	GLIDING,
	TIRED,
}

# Nodes: Player
@export var collision: CollisionShape2D
@export var indicator_ring: AnimatedSprite2D
@export var water_sprite: AnimatedSprite2D
@export var land_sprite: AnimatedSprite2D
@export var max_charging_time: Timer
@export var max_charge_time: Timer
@export var max_jump_time: Timer
@export var max_glide_time: Timer
@export var jump_cooldown: Timer

# Nodes: Level
@export var world_tilemap: TileMapLayer

# Constants
const WATER_MAX_SPEED := 300.0
const WATER_JUMP_FORCE := -40.0
const WATER_CHARGE_FORCE := 300.0
const WATER_MAX_CHARGES := 2   # You can charge underwater, but you have a speed limit and charge limit

const LAND_MAX_SPEED := 1000.0 # You have a high speed limit on land, but you have no charge
const LAND_JUMP_FORCE := -35.0 # Instead you glide~
const LAND_GLIDE_SPEED := 200.0

var water_friction := 0.15 # Lower = slower
var land_friction := 0.30 # Higher = faster
var land_glide_friction := 0.0000005

var water_lerp := 0.30  # W Larps, the difference between friction and this is that
var land_lerp := 0.0125 # W Larps, the former is for going to zero, the latter is for going to max speed
var land_glide_lerp := 0.20 # here its for going to glide speed (vert)

var water_gravity : float = ProjectSettings.get_setting("physics/2d/default_gravity") / 2
var land_gravity : float = ProjectSettings.get_setting("physics/2d/default_gravity")

# Trackers
@export var current_state : STATE
@export var current_water_state : WATER_STATE
@export var current_land_state : LAND_STATE

var direction : Vector2
var last_direction : Vector2i
var last_velocity : Vector2

var tilemap_coordinates : Vector2i
var tilemap_data : TileData

var charges_left : int = WATER_MAX_CHARGES:
	set(value):
		charges_left = clampi(value, 0, WATER_MAX_CHARGES)
var gliding_tired : bool = false

func _physics_process(delta: float) -> void:
	direction = Input.get_vector("left", "right", "up", "down").normalized()
	if world_tilemap:
		tilemap_coordinates = world_tilemap.local_to_map(world_tilemap.to_local(global_position))
		tilemap_data = world_tilemap.get_cell_tile_data(tilemap_coordinates)
	
	if in_water() and current_state != STATE.WATER:
		current_state = STATE.WATER
		switch_water(WATER_STATE.FALL) # To WATER
	elif not in_water() and not current_state == STATE.LAND:
		current_state = STATE.LAND
		switch_land(LAND_STATE.FALL) # To LAND
	
	match current_state:
		STATE.WATER:
			water_state_machine(current_water_state, delta)
			
			if not current_water_state == WATER_STATE.CHARGED and direction:
				last_direction = Vector2i(direction.round())
			
			if sign(last_direction.x) == 1:
				water_sprite.flip_h = false
			elif sign(last_direction.x) == -1:
				water_sprite.flip_h = true
			
			water_sprite.visible = true
			
			land_sprite.visible = false
		
		STATE.LAND:
			land_state_machine(current_land_state, delta)
			
			if not current_land_state == LAND_STATE.GLIDING and direction:
				last_direction = Vector2i(direction.round())
				
			if sign(last_direction.x) == 1:
				land_sprite.flip_h = false
			elif sign(last_direction.x) == -1:
				land_sprite.flip_h = true
			
			water_sprite.visible = false
			
			land_sprite.visible = true
	
	move_and_slide()

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
				velocity.x = lerp(velocity.x, WATER_MAX_SPEED * direction.x , water_lerp)
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
				velocity.x = lerp(velocity.x, WATER_MAX_SPEED * direction.x , water_lerp)
			elif not direction:
				velocity.x = lerp(velocity.x, 0.0, water_friction)
			
			velocity.y += WATER_JUMP_FORCE
			
			if max_jump_time.is_stopped() or Input.is_action_just_released("rise"):
				switch_water(WATER_STATE.FALL) # To FALL
			
		WATER_STATE.FALL:
			if direction:
				velocity.x = lerp(velocity.x, WATER_MAX_SPEED * direction.x , water_lerp)
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
			
			if is_on_floor() and not direction:
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
				velocity.x = lerp(velocity.x, WATER_MAX_SPEED * direction.x , water_lerp)
			elif not direction:
				velocity.x = lerp(velocity.x, 0.0, water_friction)
			velocity.y += water_gravity * delta
			
			if is_on_floor() and not direction:
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
			
			charges_left -= 1
		
		WATER_STATE.TIRED:
			water_sprite.play("larva_tired")

func land_state_machine(state: LAND_STATE, delta: float):
	match state:
		LAND_STATE.IDLE:
			velocity = velocity.lerp(Vector2.ZERO, land_friction)
			if direction:
				switch_land(LAND_STATE.RUNNING) # To RUNNING
			
			if Input.is_action_just_pressed("rise"):
				switch_land(LAND_STATE.JUMP) # To JUMP
			
			if not is_on_floor():
				switch_land(LAND_STATE.FALL) # To FALL
		
		LAND_STATE.RUNNING:
			if direction:
				velocity.x = lerp(velocity.x, LAND_MAX_SPEED * direction.x, land_lerp)
			elif not direction:
				switch_land(LAND_STATE.IDLE) # To IDLE
			
			if not is_on_floor():
				switch_land(LAND_STATE.FALL) # To FALL
			
			if Input.is_action_just_pressed("rise"):
				switch_land(LAND_STATE.JUMP) # To JUMP
			
		LAND_STATE.JUMP:
			if direction:
				velocity.x = lerp(velocity.x, LAND_MAX_SPEED * direction.x , land_lerp)
			elif not direction:
				velocity.x = lerp(velocity.x, 0.0, land_friction)
			
			velocity.y += LAND_JUMP_FORCE
			
			if max_jump_time.is_stopped() or Input.is_action_just_released("rise"):
				switch_land(LAND_STATE.FALL) # To FALL
			
		LAND_STATE.FALL:
			if direction:
				velocity.x = lerp(velocity.x, LAND_MAX_SPEED * direction.x , land_lerp)
			elif not direction:
				velocity.x = lerp(velocity.x, 0.0, land_friction)
			velocity.y += land_gravity * delta
			
			last_velocity = velocity
			
			if land_sprite.animation == "bug_fall" and direction:
				land_sprite.play("bug_run")
			elif not direction:
				land_sprite.play("bug_fall")
			
			if is_on_floor() and not direction:
				switch_land(LAND_STATE.IDLE) # To IDLE
			elif is_on_floor() and direction:
				switch_land(LAND_STATE.RUNNING) # To RUNNING
			
			if Input.is_action_just_pressed("rise") and not gliding_tired:
				switch_land(LAND_STATE.JUMP) # To JUMP
			elif Input.is_action_just_pressed("rise") and gliding_tired:
				switch_land(LAND_STATE.TIRED) # To TIRED
			
			if Input.is_action_just_pressed("charge") and not gliding_tired:
				switch_land(LAND_STATE.GLIDING) # To GLIDING
			elif Input.is_action_just_pressed("charge") and gliding_tired:
				switch_land(LAND_STATE.TIRED) # To TIRED
				
		LAND_STATE.GLIDING:
			velocity.x = lerp(velocity.x, 0.0, land_glide_friction)
			velocity.y = lerp(velocity.y, 80.0, land_glide_lerp)
			
			if is_on_floor() and not direction:
				switch_land(LAND_STATE.IDLE)
			elif is_on_floor() and direction:
				switch_land(LAND_STATE.RUNNING)
			
			if Input.is_action_just_released("charge") or is_on_wall():
				switch_land(LAND_STATE.FALL) # To FALL
			
			if max_glide_time.is_stopped():
				switch_land(LAND_STATE.TIRED) # To TIRED
			
		LAND_STATE.TIRED:
			if direction:
				velocity.x = lerp(velocity.x, LAND_MAX_SPEED * direction.x , land_lerp)
			elif not direction:
				velocity.x = lerp(velocity.x, 0.0, land_friction)
			velocity.y += land_gravity * delta
			
			if is_on_floor() and not direction:
				switch_land(LAND_STATE.IDLE) # To IDLE
			elif is_on_floor() and direction:
				switch_land(LAND_STATE.RUNNING) # To RUNNING

func switch_land(to_state: LAND_STATE):
	current_land_state = to_state
	match to_state:
		LAND_STATE.IDLE:
			land_sprite.play("bug_idle")
			gliding_tired = false
			
		LAND_STATE.RUNNING:
			land_sprite.play("bug_run")
			gliding_tired = false
			
		LAND_STATE.JUMP:
			land_sprite.play("bug_jump")
			max_jump_time.stop()
			max_jump_time.start()
			
		LAND_STATE.FALL:
			land_sprite.play("bug_fall")
			
		LAND_STATE.GLIDING:
			land_sprite.play("bug_glide")
			max_glide_time.stop()
			max_glide_time.start()
			
			if abs(last_velocity.x) < 50.0: # Handle edge cases of velocity being weird
				last_velocity.x = last_direction.x * LAND_GLIDE_SPEED # If too slow, go faster lol
			
			if last_velocity.y >= 120.0: # Fix for random "jumping" when entering glide
				last_velocity.y = 90.0
			
			velocity = last_velocity
			gliding_tired = true
			
		LAND_STATE.TIRED:
			land_sprite.play("bug_tired")

func in_water():
	if tilemap_data:
		if tilemap_data.has_custom_data("Water"):
			return tilemap_data.get_custom_data("Water")
		elif not tilemap_data.has_custom_data("Water"):
			return false
	elif not tilemap_data:
		return false
