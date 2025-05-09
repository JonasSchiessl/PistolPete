extends Node

class_name CactusAnimator

# References to body parts
var body
var left_arm
var right_arm
var left_leg
var right_leg

# Animation variables
var animation_time: float = 0.0
var walk_speed: float = 4.0
var arm_swing_amount: float = 0.3
var leg_swing_amount: float = 0.2
var attack_cooldown: float = 1.5
var attack_speed: float
var attack_arm_rotation: float = 1.5

# Attack timing variables
var attack_damage_window_start: float = 0.5  
var attack_damage_window_end: float = 0.8 

# Store initial rotations
var initial_rotations = {}
var attack_phase: float = 0.0
var is_attacking: bool = false

# Initialize with references to body parts
func initialize(cactus_parts):
	body = cactus_parts.body
	left_arm = cactus_parts.left_arm
	right_arm = cactus_parts.right_arm
	left_leg = cactus_parts.left_leg
	right_leg = cactus_parts.right_leg
	
	# Store initial rotations
	initial_rotations = {
		"body": body.rotation,
		"left_arm": left_arm.rotation,
		"right_arm": right_arm.rotation,
		"left_leg": left_leg.rotation,
		"right_leg": right_leg.rotation
	}
	
	attack_speed = PI / attack_cooldown

# Update animation time
func update(delta):
	animation_time += delta
	if is_attacking:
		attack_phase += delta * attack_speed
		if attack_phase >= PI:
			is_attacking = false
			attack_phase = 0.0

# Walking animation
func animate_walk():
	# Calculate arm and leg swing based on sine wave
	var swing = sin(animation_time * walk_speed)
	var arm_swing = swing * arm_swing_amount
	var leg_swing = swing * leg_swing_amount
	
	# Apply rotations with smooth interpolation
	left_arm.rotation = lerp(left_arm.rotation, initial_rotations["left_arm"] + arm_swing, 0.2)
	right_arm.rotation = lerp(right_arm.rotation, initial_rotations["right_arm"] - arm_swing, 0.2)
	
	# Animate legs in opposite phase to arms for natural walking
	left_leg.rotation = lerp(left_leg.rotation, initial_rotations["left_leg"] - leg_swing, 0.2)
	right_leg.rotation = lerp(right_leg.rotation, initial_rotations["right_leg"] + leg_swing, 0.2)
	
	# Add slight body movement
	body.rotation = lerp(body.rotation, initial_rotations["body"] + sin(animation_time * walk_speed * 0.5) * 0.05, 0.1)

# Attack animation
func animate_attack():
	is_attacking = true
	
	if attack_phase < PI:
		# First half of attack - wind up
		if attack_phase < PI/2:
			var wind_up = sin(attack_phase) * attack_arm_rotation
			left_arm.rotation = lerp(left_arm.rotation, initial_rotations["left_arm"] + wind_up, 0.3)
			right_arm.rotation = lerp(right_arm.rotation, initial_rotations["right_arm"] - wind_up, 0.3)
			
			# During wind-up, widen stance for stability
			left_leg.rotation = lerp(left_leg.rotation, initial_rotations["left_leg"] - 0.1, 0.2)
			right_leg.rotation = lerp(right_leg.rotation, initial_rotations["right_leg"] + 0.1, 0.2)
		# Second half - swing forward
		else:
			var swing = sin(attack_phase) * attack_arm_rotation * -0.8
			left_arm.rotation = lerp(left_arm.rotation, initial_rotations["left_arm"] + swing, 0.5)
			right_arm.rotation = lerp(right_arm.rotation, initial_rotations["right_arm"] - swing, 0.5)
			
			# During attack swing, lean forward slightly with legs
			left_leg.rotation = lerp(left_leg.rotation, initial_rotations["left_leg"] - 0.15, 0.3)
			right_leg.rotation = lerp(right_leg.rotation, initial_rotations["right_leg"] + 0.15, 0.3)
		
		# Add aggressive body movement
		body.rotation = lerp(body.rotation, initial_rotations["body"] + sin(attack_phase * 2) * 0.1, 0.2)

# Get attack progress (0.0 to 1.0)
func get_attack_progress():
	if is_attacking:
		return attack_phase / PI
	return 0.0

# Check if we're in the damage window of the attack animation
func is_in_damage_window():
	var progress = get_attack_progress()
	return progress >= attack_damage_window_start and progress <= attack_damage_window_end
