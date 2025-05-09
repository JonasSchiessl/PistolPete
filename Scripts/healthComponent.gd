extends Node2D
class_name HealthComponent

@export var maxHealth := 10
var health : float

func _ready() -> void:
	health = maxHealth

func damage(attack: Attack):
	print("Health before: ", health)
	health -= attack.attackDamage
	
	print("Damage received: ", attack.attackDamage)
	print("Health after: ", health)
	if health <= 0:
		print("Health depleted, freeing parent")
		get_parent().queue_free()
