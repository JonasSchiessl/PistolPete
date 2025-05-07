extends Node

class_name CharacterAnimator

# References to body parts
var torso
var left_arm
var right_arm
var left_leg
var right_leg
var head

# Animation variables
var animation_time: float = 0.0
var walk_speed: float = 5.0
var leg_swing_amount: float = 0.3
var arm_swing_amount: float = 0.2
var jump_extend_amount: float = 0.4

# Store initial rotations
var initial_rotations = {}

# Initialize with references to body parts
func initialize(body_parts):
	torso = body_parts.torso
	left_arm = body_parts.left_arm
	right_arm = body_parts.right_arm
	left_leg = body_parts.left_leg
	right_leg = body_parts.right_leg
	head = body_parts.head
	
	# Store initial rotations
	initial_rotations = {
		"torso": torso.rotation,
		"left_arm": left_arm.rotation,
		"right_arm": right_arm.rotation,
		"left_leg": left_leg.rotation,
		"right_leg": right_leg.rotation
	}

# Update animation time
func update(delta):
	animation_time += delta

# Idle animation
func animate_idle():
	# Subtle breathing animation
	var breath = sin(animation_time * 2) * 0.05
	
	# Apply rotations with smooth interpolation for idle pose
	torso.rotation = lerp(torso.rotation, initial_rotations["torso"], 0.2)
	left_arm.rotation = lerp(left_arm.rotation, initial_rotations["left_arm"] - 0.1 + breath, 0.2)
	right_arm.rotation = lerp(right_arm.rotation, initial_rotations["right_arm"] + 0.1 - breath, 0.2)
	left_leg.rotation = lerp(left_leg.rotation, initial_rotations["left_leg"], 0.2)
	right_leg.rotation = lerp(right_leg.rotation, initial_rotations["right_leg"], 0.2)

# Walking animation
func animate_walk():
	# Calculate leg and arm swing based on sine wave
	var swing = sin(animation_time * walk_speed) * leg_swing_amount
	var arm_swing = sin(animation_time * walk_speed) * arm_swing_amount
	
	# Apply rotations with smooth interpolation
	left_leg.rotation = lerp(left_leg.rotation, initial_rotations["left_leg"] - swing, 0.2)
	right_leg.rotation = lerp(right_leg.rotation, initial_rotations["right_leg"] + swing, 0.2)
	
	# Arms swing opposite to legs for natural walking
	left_arm.rotation = lerp(left_arm.rotation, initial_rotations["left_arm"] + arm_swing, 0.2)
	right_arm.rotation = lerp(right_arm.rotation, initial_rotations["right_arm"] - arm_swing, 0.2)
	
	# Add slight torso movement
	torso.rotation = lerp(torso.rotation, initial_rotations["torso"] + sin(animation_time * walk_speed * 2) * 0.05, 0.1)

# Jump animation
func animate_jump(vertical_velocity, jump_force):
	# Get the vertical velocity normalized between -1 and 1
	var jump_phase = clamp(vertical_velocity / jump_force, -1.0, 1.0)
	
	# Different poses for rising and falling
	if jump_phase < 0:  # Rising
		# Extend legs downward, arms up for rising phase
		left_leg.rotation = lerp(left_leg.rotation, initial_rotations["left_leg"] + 0.3, 0.2)
		right_leg.rotation = lerp(right_leg.rotation, initial_rotations["right_leg"] + 0.3, 0.2)
		left_arm.rotation = lerp(left_arm.rotation, initial_rotations["left_arm"] + 0.8, 0.2)
		right_arm.rotation = lerp(right_arm.rotation, initial_rotations["right_arm"] - 0.8, 0.2)
		
	else:  # Falling
		# Prepare for landing with legs forward, arms back
		left_leg.rotation = lerp(left_leg.rotation, initial_rotations["left_leg"] - 0.2, 0.2)
		right_leg.rotation = lerp(right_leg.rotation, initial_rotations["right_leg"] - 0.2, 0.2)
		left_arm.rotation = lerp(left_arm.rotation, initial_rotations["left_arm"] + 1.8, 0.2)
		right_arm.rotation = lerp(right_arm.rotation, initial_rotations["right_arm"] - 1.8, 0.2)
		
