extends CharacterBody2D

# Movement variables
@export var gravity: float = 800.0
@export var move_speed: float = 150.0
@export var attack_cooldown: float = 1.5
@export var attack_damage: float = 5.0
@export var knockback_force: float = 200.0
@export var attack_rate: float = 1.0  # Time between damage applications (seconds)

# References to body parts
@onready var body = $Body
@onready var left_arm = $Body/ArmL
@onready var right_arm = $Body/ArmR
@onready var left_leg = $Body/LegL
@onready var right_leg = $Body/LegR
@onready var attack_area = $AttackArea
@onready var attack_timer = $AttackTimer

# References to systems
@onready var fsm = $FSM
@onready var animator = $Animator

# State variables
var can_attack: bool = true
var is_attacking: bool = false
var facing_right: bool = true
var last_damage_time: float = 0.0  # Track when we last dealt damage

func _ready():
	# Add to enemy group for player detection
	add_to_group("enemies")
	attack_area.collision_layer = 32   # Layer 6 (2^5)
	attack_area.collision_mask = 16    # Layer 5 (2^4)
	
	# Setup attack timer
	if attack_timer:
		attack_timer.wait_time = attack_cooldown
		attack_timer.one_shot = true
		attack_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))
		
	# Initialize animator with body parts
	if animator:
		var cactus_parts = {
			"body": body,
			"left_arm": left_arm,
			"right_arm": right_arm,
			"left_leg": left_leg,
			"right_leg": right_leg
		}
		animator.initialize(cactus_parts)
		animator.attack_cooldown = attack_cooldown

func _physics_process(delta):
	# Apply gravity
	velocity.y += gravity * delta
	
	# Handle movement
	move_and_slide()
	
	# Update animator time
	if animator:
		animator.update(delta)
	
	# If attacking, check for player to damage
	if is_attacking:
		# Check for players in the attack area
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_damage_time >= attack_rate:
			_check_for_player_to_damage()

func _follow(_delta, direction):
	# Set horizontal velocity to move toward player
	velocity.x = direction.x * move_speed
	
	# Update facing direction
	if direction.x > 0:
		_flip_body(true)
	elif direction.x < 0:
		_flip_body(false)
	
	# Play move animation
	if animator:
		animator.animate_walk()

func _start_attack():
	if can_attack:
		is_attacking = true
		can_attack = false
		
		# Enable attack area
		if attack_area:
			attack_area.monitoring = true
		
		# Start attack timer
		if attack_timer:
			attack_timer.start()
		
		# Reset damage timing
		last_damage_time = 0.0
		
		# Immediately check for player to damage
		_check_for_player_to_damage()

func _attack(_delta, direction):
	# Slow down movement during attack but keep moving toward player
	velocity.x = direction.x * move_speed * 0.3
	
	# Update facing direction
	if direction.x > 0:
		_flip_body(true)
	elif direction.x < 0:
		_flip_body(false)
	
	# Play attack animation
	if animator and is_attacking:
		animator.animate_attack()

func _end_attack():
	is_attacking = false
	
	# Disable attack area
	if attack_area:
		attack_area.monitoring = false

func _on_attack_timer_timeout():
	can_attack = true
	is_attacking = false

func _flip_body(is_right):
	facing_right = is_right
	if is_right:
		body.scale.x = abs(body.scale.x)
	else:
		body.scale.x = -abs(body.scale.x)

# New direct player damage checking function
func _check_for_player_to_damage():
	var overlapping_areas = attack_area.get_overlapping_areas()
	
	for area in overlapping_areas:
		if area is Area2D and area.has_method("damage"):
			var parent_node = area.get_parent()
			if parent_node and parent_node.is_in_group("player"):
				print("Found player in attack range - applying damage")
				
				# Create attack
				var attack = Attack.new()
				attack.attackDamage = attack_damage
				attack.knockbakForce = knockback_force
				attack.attackPosition = global_position
				
				# Apply damage
				area.damage(attack)
				
				# Set last damage time
				last_damage_time = Time.get_ticks_msec() / 1000.0
				
				print("Damage applied at time: ", last_damage_time)
				break
