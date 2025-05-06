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

# Animation system
var animator = CharacterAnimator.new()

# Movement variables
@export var character_scale_factor: float = 1.0
@export var move_speed: float = 200.0
@export var jump_force: float = 400.0
@export var gravity: float = 800.0

# Input variables
var x_input: float = 0.0
var facing_right: bool = true
var mouse_on_right: bool = true

func _ready():
	# Apply uniform scale to avoid squishing
	scale = Vector2(character_scale_factor, character_scale_factor)
	
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
	
	# Hide system cursor if using custom crosshair
	if crosshair:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _physics_process(delta):
	# Apply gravity
	velocity.y += gravity * delta
	
	# Update animator's time
	animator.update(delta)
	
	# Check for jump input every frame
	_handle_jump()
	
	# Move character based on current velocity
	move_and_slide()

func _player_input():
	# Get horizontal input
	x_input = Input.get_axis("moveLeft", "moveRight")
	
	# Update body facing direction based on input - immediate response
	if x_input < 0:
		facing_right = false
		_flip_body(false)
	elif x_input > 0:
		facing_right = true
		_flip_body(true)

func _handle_jump():
	# Handle jumping - called every frame
	if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		velocity.y = -jump_force

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
