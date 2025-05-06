extends CharacterBody2D

# References to body parts
@onready var torso = $Body
@onready var leftArm = $Body/ArmL
@onready var rightArm = $Body/ArmR
@onready var leftleg = $Body/LegL
@onready var rightLeg = $Body/LegR
@onready var head = $Head
@onready var gun_sprite = $Head/HeadSprite
@onready var crosshair = $Crosshair

# Store initial rotations
var initial_rotations = {}

# Movement variables
@export var character_scale_factor: float = 1.0
@export var move_speed: float = 200.0
@export var jump_force: float = 400.0
@export var gravity: float = 800.0

# Animation variables
var animation_time: float = 0.0
var walk_speed: float = 5.0
var leg_swing_amount: float = 0.3
var arm_swing_amount: float = 0.2

# Input variables
var x_input: float = 0.0
var facing_right: bool = true
var mouse_on_right: bool = true

func _ready():
	# Apply uniform scale to avoid squishing
	scale = Vector2(character_scale_factor, character_scale_factor)
	
	# Store initial rotations of all parts
	initial_rotations = {
		"torso": torso.rotation,
		"leftArm": leftArm.rotation,
		"rightArm": rightArm.rotation,
		"leftleg": leftleg.rotation,
		"rightLeg": rightLeg.rotation
	}
	
	# Hide system cursor if using custom crosshair
	if crosshair:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _physics_process(delta):
	# Apply gravity
	velocity.y += gravity * delta
	
	# Increment animation timer
	animation_time += delta
	
	# Check for jump input every frame
	_handle_jump()
	
	# Move character based on current velocity
	move_and_slide()

func _player_input():
	# Get horizontal input
	x_input = Input.get_axis("ui_left", "ui_right")
	
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
	
	# Subtle breathing animation
	var breath = sin(animation_time * 2) * 0.05
	
	# Apply rotations with smooth interpolation for idle pose
	# Use initial rotations as the base
	torso.rotation = lerp(torso.rotation, initial_rotations["torso"], 0.2)
	leftArm.rotation = lerp(leftArm.rotation, initial_rotations["leftArm"] - 0.1 + breath, 0.2)
	rightArm.rotation = lerp(rightArm.rotation, initial_rotations["rightArm"] + 0.1 - breath, 0.2)
	leftleg.rotation = lerp(leftleg.rotation, initial_rotations["leftleg"], 0.2)
	rightLeg.rotation = lerp(rightLeg.rotation, initial_rotations["rightLeg"], 0.2)

func _animate_legs():
	# Calculate leg and arm swing based on sine wave
	var swing = sin(animation_time * walk_speed) * leg_swing_amount
	var arm_swing = sin(animation_time * walk_speed) * arm_swing_amount
	
	# Apply rotations with smooth interpolation
	# Use initial rotations as the base
	leftleg.rotation = lerp(leftleg.rotation, initial_rotations["leftleg"] - swing, 0.2)
	rightLeg.rotation = lerp(rightLeg.rotation, initial_rotations["rightLeg"] + swing, 0.2)
	
	# Arms swing opposite to legs for natural walking
	leftArm.rotation = lerp(leftArm.rotation, initial_rotations["leftArm"] + arm_swing, 0.2)
	rightArm.rotation = lerp(rightArm.rotation, initial_rotations["rightArm"] - arm_swing, 0.2)
	
	# Add slight torso movement
	torso.rotation = lerp(torso.rotation, initial_rotations["torso"] + sin(animation_time * walk_speed * 2) * 0.05, 0.1)
