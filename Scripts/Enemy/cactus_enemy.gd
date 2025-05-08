extends CharacterBody2D

@export var gravity: float = 800.0

func _physics_process(delta):
	# Apply gravity
	velocity.y += gravity * delta
	move_and_slide()
