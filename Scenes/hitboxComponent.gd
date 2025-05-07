extends Area2D

@export var healthComponent : HealthComponent

func damage(attack: Attack):
	if healthComponent:
		healthComponent.damage(attack)
