extends Node2D
class_name HealthComponent

@export var maxHealth := 10
var health : float
signal entity_died(entity) 
signal health_changed(new_health)

func _ready() -> void:
	health = maxHealth
	print("Initial health: ", health, " / ", maxHealth)
	add_to_group("health_component")

func damage(attack: Attack):
	health -= attack.attackDamage
	
	emit_signal("health_changed", health)
	
	if health <= 0:
		emit_signal("entity_died", get_parent())
