extends Node2D

var player 
var playerInInteractionZone = false

func _ready() -> void:
	$KeyInput.visible = false
	$AnimatedSprite2D.flip_h = true

func _process(delta):
	if playerInInteractionZone and Input.is_action_just_pressed("interact") :
		$KeyInput.visible = false
		await FadeManager.fade_and_change_scene("res://Scenes/Level/Level2/world.tscn")
	
func _on_interaction_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		playerInInteractionZone = true 
		$KeyInput.visible = true

func _on_interaction_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		playerInInteractionZone = false
		$KeyInput.visible = false
