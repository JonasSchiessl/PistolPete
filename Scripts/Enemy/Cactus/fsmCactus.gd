extends Node 

enum STATES {MOVE, ATTACK}

var state: int = STATES.MOVE

@onready var parent = get_parent()
@export var attack_radius: float = 100.0

func _physics_process(delta):
	run_state(delta)

func run_state(delta):
	# Get player reference
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var distance_to_player = parent.global_position.distance_to(player.global_position)
		var direction_to_player = (player.global_position - parent.global_position).normalized()
		
		# Determine state based on distance to player and ability to attack
		if distance_to_player <= attack_radius and parent.can_attack:
			_set_state(STATES.ATTACK)
		else:
			_set_state(STATES.MOVE)
		
		# Execute state behavior
		match state:
			STATES.MOVE:
				parent._follow(delta, direction_to_player)
			STATES.ATTACK:
				parent._attack(delta, direction_to_player)

func _set_state(new_state: int):
	# Don't interrupt attack animation during the actual swing
	if parent.is_attacking and state == STATES.ATTACK and new_state != STATES.ATTACK:
		if parent.animator and parent.animator.attack_phase < PI * 0.7:
			return
			
	if state == new_state:
		return
		
	# Handle state exit actions
	match state:
		STATES.ATTACK:
			parent._end_attack()
	
	# Set the new state
	state = new_state
	
	# Handle state enter actions
	match state:
		STATES.ATTACK:
			parent._start_attack()
