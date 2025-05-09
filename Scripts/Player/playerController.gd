extends CharacterBody2D

# References to body parts
@onready var torso = $Body
@onready var left_arm = $Body/ArmL
@onready var right_arm = $Body/ArmR
@onready var left_leg = $Body/LegL
@onready var right_leg = $Body/LegR
@onready var head = $Head
@onready var gun_sprite = $Head/HeadSprite
@onready var crosshair = $Crosshair

# Reference Audio
@onready var playerJumpAudio = $Jump
@onready var playerSchootAudio = $Shoot
@onready var playerWalkAudio = $Walk
@onready var reloadSound = $ReloadSFX

# Animation system
var animator = CharacterAnimator.new()

# Bullet System
var bulletPath = preload("res://Scenes/Bulet/bulet.tscn")
@export var weapon_data: WeaponData
var current_ammo: int = 0
var is_reloading: bool = false
var reload_timer: float = 0.0

# Movement variables
@export var character_scale_factor: float = 1.0
@export var move_speed: float = 200.0
@export var jump_force: float = 400.0
@export var gravity: float = 800.0

# Input variables
var x_input: float = 0.0
var facing_right: bool = true
var mouse_on_right: bool = true

signal ammo_changed(current, maximum)
signal reload_started(reload_time)
signal reload_progress(progress_percent)
signal reload_finished


func _ready():
	# Apply uniform scale to avoid squishing
	scale = Vector2(character_scale_factor, character_scale_factor)
	add_to_group("player")
	
	# Initialize animator with body parts
	var body_parts = {
		"torso": torso,
		"left_arm": left_arm,
		"right_arm": right_arm,
		"left_leg": left_leg,
		"right_leg": right_leg,
		"head": head
	}
	animator.initialize(body_parts)
	
	if $HitboxComponent:
		# Set collision to match what you specified
		$HitboxComponent.collision_layer = 16   # Layer 5 (2^4)
		$HitboxComponent.collision_mask = 32    # Layer 6 (2^5)
		print("Set player hitbox to layer 5, mask includes layer 6")
	
	# Hide system cursor if using custom crosshair
	if crosshair:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		
	if weapon_data:
		current_ammo = weapon_data.max_ammo
	else:
		# Create default weapon data if none assigned
		weapon_data = WeaponData.new()
		current_ammo = weapon_data.max_ammo
		
	call_deferred("update_ammo_ui")

func _physics_process(delta):
	# Apply gravity
	velocity.y += gravity * delta
	
	# Update animator's time
	animator.update(delta)
	
	# Check for jump input every frame
	_handle_jump()
	
	# Move character based on current velocity
	move_and_slide()
	
	if Input.is_action_just_pressed("shoot"):
		fire()
		
	if is_reloading:
			reload_timer += delta
			var progress = (reload_timer / weapon_data.reload_time) * 100
			emit_signal("reload_progress", progress)
			
			if reload_timer >= weapon_data.reload_time:
				# Reload complete
				current_ammo = weapon_data.max_ammo
				is_reloading = false
				emit_signal("reload_finished")
				emit_signal("ammo_changed", current_ammo, weapon_data.max_ammo)
				print("Reload complete. Ammo: ", current_ammo)

func _player_input():
	# Get horizontal input
	x_input = Input.get_axis("moveLeft", "moveRight")
	
	if abs(x_input) > 0 and is_on_floor():
		if not playerWalkAudio.playing:
			playerWalkAudio.play()
	else:
		# Stop the sound if we're not moving or not on floor
		if playerWalkAudio.playing:
			playerWalkAudio.stop()
		
	# Update body facing direction based on input - immediate response
	if x_input < 0:
		facing_right = false
		_flip_body(false)
	elif x_input > 0:
		facing_right = true
		_flip_body(true)

func disable_input():
	set_physics_process(false)
	# Hide crosshair if present
	if crosshair:
		crosshair.visible = false

func _handle_jump():
	# Handle jumping - called every frame
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = -jump_force
		playerJumpAudio.play()

func aim(mouse_position):
	# Determine if mouse is on the right or left side of player
	mouse_on_right = mouse_position.x > global_position.x
	
	# Calculate direction to mouse for aiming
	var direction_to_mouse = mouse_position - head.global_position
	var angle_to_mouse = direction_to_mouse.angle()
	
	# Handle head rotation and orientation based on mouse position
	if mouse_on_right:
		# When mouse is on the right, head faces right
		head.scale.y = abs(head.scale.y)
		head.rotation = angle_to_mouse
	else:
		# When mouse is on the left, head faces left
		# We flip the head vertically and adjust the angle
		head.scale.y = -abs(head.scale.y)
		head.rotation = angle_to_mouse
	
	# Update crosshair position
	if crosshair:
		crosshair.global_position = mouse_position

func fire():
	# Check if currently reloading
	if is_reloading:
		return
	
	# If empty, start reloading
	if current_ammo <= 0:
		start_reload()
		return
	
	# We have ammo and can fire
	current_ammo -= 1
	update_ammo_ui()
	
	# Get bullet scene from weapon data
	var bullet_scene = weapon_data.bullet_scene if weapon_data.bullet_scene else bulletPath
	
	# Create bullet
	var bullet = bullet_scene.instantiate()
	var mouse_pos = get_global_mouse_position()
	playerSchootAudio.play()
	
	# Set bullet properties from weapon data
	bullet.positionB = $Head/FireLocation.global_position
	bullet.directionB = (mouse_pos - $Head/FireLocation.global_position).normalized()
	
	# Pass weapon stats to bullet
	if "bullet_damage" in bullet:
		bullet.bullet_damage = weapon_data.bullet_damage
	if "speed" in bullet:
		bullet.speed = weapon_data.bullet_speed
	if "lifetime" in bullet:
		bullet.lifetime = weapon_data.bullet_lifetime
	if "knockback_force" in bullet:
		bullet.knockback_force = weapon_data.bullet_knockback
	
	get_parent().add_child(bullet)
	
	# Auto-reload when empty
	if current_ammo <= 0:
		start_reload()

func start_reload():
	if is_reloading or current_ammo == weapon_data.max_ammo:
		return
		
	print("Reloading...")
	is_reloading = true
	reload_timer = 0.0
	emit_signal("reload_started", weapon_data.reload_time)
	
	# Play reload sound
	if has_node("ReloadSFX"):
		$ReloadSFX.play()

func update_ammo_ui():
	emit_signal("ammo_changed", current_ammo, weapon_data.max_ammo)

func _flip_body(is_right):
	# Handle body flipping
	if is_right:
		torso.scale.x = abs(torso.scale.x)
	else:
		torso.scale.x = -abs(torso.scale.x)

func _move(delta, input_direction):
	# Set horizontal velocity based on input
	velocity.x = input_direction * move_speed

func _idle():
	# Reset horizontal velocity
	velocity.x = 0
	
	# Play idle animation
	animator.animate_idle()

func _animate_legs():
	# Play walk animation
	animator.animate_walk()

func _animate_jump():
	# Play jump animation
	animator.animate_jump(velocity.y, jump_force)
